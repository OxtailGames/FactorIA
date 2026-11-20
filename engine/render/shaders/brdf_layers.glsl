// The material layers of M73.6 on top of the engine's GGX BRDF: the dielectric specular (specular, ior, specular colour), anisotropic
// highlights, a cloth sheen lobe and a clear coat (docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "The material layers"). Not compiled
// on its own: mesh_common.glsl @includes this file and includes its blocks where they are used.
//   fa_layers_env     FaLayers and fa_layers_setup(): what one fragment's layers are, worked out once before the light loop, and
//                     fa_layers_ibl(): what the layers add to the image-based lighting. In fa_fs_light and (for fa_sky_light of a
//                     "custom" material) in fa_fs_nolight, after fa_env_funcs.
//   fa_layers_light   fa_layers_light(): the whole BRDF of one light with the layers on, called by the light loop (light_loop.glsl)
//                     in place of the plain Cook-Torrance term. Needs FA_PI: in fa_fs_light only.
// A fragment whose layers are all off (FaLayers.on false: specular 1, ior 1.5, no coat, no sheen, no anisotropy) takes the plain term
// of the loop, so a material that does not use a layer draws the same pixels and pays one branch.
//
// The model is the glTF one (KHR_materials_clearcoat, _sheen, _anisotropy, _specular, _ior): the base layer (diffuse + GGX specular,
// anisotropic when asked) is scaled by the sheen's albedo scaling and gets the sheen lobe added, and the coat lies on top: it scales
// what is under it by 1 - coat * Fresnel(view) and adds its own GGX lobe, with the geometric normal (a normal map does not bend it).

@block fa_layers_env
// The directional albedo of the sheen lobe (Charlie distribution, Ashikhmin visibility; integrated numerically by
// tools/shaders/sheen_albedo.py, 7 roughness x 9 view-angle nodes). The nodes are at roughness 0.1 + 0.9 * (i / 6)^2 and
// cos(view) = (j / 8)^2; the table is read with a bilinear lookup in those coordinates. Worst error against the integral 0.06,
// mean 0.003; it scales the base layer by 1 - max(sheenColor) * E so the layers never add energy.
const float FA_SHEEN_E[63] = float[63](
    1.000, 1.000, 1.000, 0.479, 0.117, 0.012, 0.000, 0.000, 0.000,
    1.000, 1.000, 1.000, 0.578, 0.193, 0.035, 0.003, 0.000, 0.000,
    1.000, 1.000, 1.000, 0.674, 0.346, 0.132, 0.033, 0.004, 0.000,
    0.971, 0.955, 0.829, 0.640, 0.426, 0.245, 0.115, 0.037, 0.003,
    0.747, 0.738, 0.670, 0.563, 0.431, 0.304, 0.194, 0.102, 0.031,
    0.614, 0.609, 0.567, 0.499, 0.412, 0.324, 0.241, 0.162, 0.088,
    0.539, 0.535, 0.506, 0.457, 0.394, 0.329, 0.266, 0.204, 0.142);

float fa_sheen_albedo(float ndv, float rough) {
    float fr = min(sqrt(max(rough - 0.1, 0.0) / 0.9) * 6.0, 5.999);
    float fv = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999);
    int i = int(fr);
    int j = int(fv);
    float tr = fr - float(i);
    float tv = fv - float(j);
    float a = mix(FA_SHEEN_E[i * 9 + j], FA_SHEEN_E[i * 9 + j + 1], tv);
    float b = mix(FA_SHEEN_E[(i + 1) * 9 + j], FA_SHEEN_E[(i + 1) * 9 + j + 1], tv);
    return mix(a, b, tr);
}

// One fragment's layers, made by fa_layers_setup.
struct FaLayers {
    bool on;            // any layer, or a specular / ior / specular colour that is not the default
    float f90;          // reflectance at grazing angles of the base layer: 1, or MeshRenderer.specular for a dielectric
    float keep;         // what the coat lets through of everything under it: 1 - coat * Fresnel at the view angle
    float base_scale;   // keep * the sheen's albedo scaling: multiplies the ambient light of the base layer
    float coat;         // clear coat strength 0..1 (0 = no coat)
    float coat_rough;
    float coat_alpha;   // roughness^2 and its square, as the base layer's alpha and a2
    float coat_a2;
    vec3 nc;            // the coat's normal: the interpolated geometric normal
    float coat_ndv;
    bool sheen_on;
    vec3 sheen;         // sheen colour
    float sheen_rough;
    float sheen_alpha;
    float sheen_scale;  // 1 - max(sheen colour) * E(view angle, roughness): what is left of the base layer under the sheen
    float sheen_e;
    float aniso;        // -1..1, 0 = round highlights
    vec3 t;             // the direction the highlight is stretched along (the tangent turned by anisotropyRotation)
    vec3 b;             // and the one across it
    float at;           // GGX alpha along t and along b
    float ab;
};

// f0 is the base layer's reflectance at normal incidence from the plain model (0.04 for a dielectric, the albedo for a metal); the
// specular, ior and specular colour of the surface change it here.
FaLayers fa_layers_setup(in SurfaceInput i, in Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0) {
    FaLayers L;
    L.on = false;
    L.f90 = 1.0;
    L.keep = 1.0;
    L.base_scale = 1.0;
    L.coat = 0.0;
    L.coat_rough = 0.0;
    L.coat_alpha = 0.0;
    L.coat_a2 = 0.0;
    L.nc = i.world_normal;
    L.coat_ndv = 1.0;
    L.sheen_on = false;
    L.sheen = vec3(0.0);
    L.sheen_rough = 1.0;
    L.sheen_alpha = 1.0;
    L.sheen_scale = 1.0;
    L.sheen_e = 0.0;
    L.aniso = 0.0;
    L.t = vec3(1.0, 0.0, 0.0);
    L.b = vec3(0.0, 0.0, 1.0);
    L.at = 1.0;
    L.ab = 1.0;

    // Specular and ior: the dielectric f0 is ((ior - 1) / (ior + 1))^2 * specularColor * specular and its f90 is specular
    // (KHR_materials_specular); ior 1.5, specular 1 and a white specular colour are the engine's own 0.04 and 1, left untouched.
    float spec = clamp(s.specular, 0.0, 1.0);
    float ior = clamp(s.ior, 1.0, 3.0);
    if (spec != 1.0 || ior != 1.5 || any(notEqual(s.specular_color, vec3(1.0)))) {
        float r = (ior - 1.0) / (ior + 1.0);
        vec3 f0d = min(vec3(r * r) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * spec;
        f0 = mix(f0d, s.albedo, metallic);
        L.f90 = mix(spec, 1.0, metallic);
        L.on = true;
    }

    // Clear coat: a second GGX lobe of a dielectric of index 1.5 (f0 0.04) over the geometric normal.
    float coat = clamp(s.clearcoat, 0.0, 1.0);
    if (coat > 0.0) {
        float cr = clamp(s.clearcoat_roughness, 0.05, 1.0);
        L.coat = coat;
        L.coat_rough = cr;
        L.coat_alpha = cr * cr;
        L.coat_a2 = L.coat_alpha * L.coat_alpha;
        L.coat_ndv = max(dot(L.nc, v), 1e-4);
        L.keep = 1.0 - coat * (0.04 + 0.96 * pow(1.0 - L.coat_ndv, 5.0));
        L.on = true;
    }

    // Sheen: the Charlie lobe, with the albedo scaling of the base layer.
    vec3 sh = max(s.sheen_color, vec3(0.0));
    float shm = max(sh.r, max(sh.g, sh.b));
    if (shm > 0.0) {
        float sr = clamp(s.sheen_roughness, 0.1, 1.0);
        L.sheen_on = true;
        L.sheen = sh;
        L.sheen_rough = sr;
        L.sheen_alpha = sr * sr;
        L.sheen_e = fa_sheen_albedo(max(dot(n, v), 1e-4), sr);
        L.sheen_scale = 1.0 - min(shm * L.sheen_e, 1.0);
        L.on = true;
    }
    L.base_scale = L.keep * L.sheen_scale;

    // Anisotropy: the tangent frame of the mesh, orthogonal to the shading normal and turned by the rotation. A mesh whose tangents
    // are zero (degenerate texture coordinates) gets a tangent from the normal, so the stretch is still defined.
    float an = clamp(s.anisotropy, -1.0, 1.0);
    if (an != 0.0) {
        vec3 t = i.world_tangent.xyz;
        t -= n * dot(n, t);
        if (dot(t, t) < 1e-8) {
            t = cross(abs(n.y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0), n);
        }
        t = normalize(t);
        vec3 b = cross(n, t) * (i.world_tangent.w < 0.0 ? -1.0 : 1.0);
        float c = cos(s.anisotropy_rotation);
        float sn = sin(s.anisotropy_rotation);
        L.t = normalize(t * c + b * sn);
        L.b = cross(n, L.t);
        float alpha = roughness * roughness;
        float spread = mix(alpha, 1.0, an * an);
        L.at = an > 0.0 ? spread : alpha;
        L.ab = an > 0.0 ? alpha : spread;
        L.aniso = an;
        L.on = true;
    }
    return L;
}

// What the layers add to the image-based lighting (the sky), without the occlusion: the base layer's reflection with the
// dielectric f0 / f90 (and, with anisotropy, the normal bent toward the view along the stretch direction, Filament's approximation),
// scaled by base_scale; the sheen as the environment seen along the normal at the sheen roughness, times the sheen colour and the
// sheen's albedo (an approximation: there is no sheen-filtered environment); the coat as a mirror-like reflection of the
// environment along the geometric normal with the coat's roughness and the environment BRDF of f0 0.04.
vec3 fa_layers_ibl(in FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness) {
    float ndv = max(dot(n, v), 1e-4);
    vec3 rn = n;
    if (L.aniso != 0.0) {
        vec3 dir = L.aniso >= 0.0 ? L.b : L.t;
        vec3 an = cross(cross(dir, v), dir);
        rn = normalize(mix(n, an, abs(L.aniso)));
    }
    vec3 r = reflect(-v, rn);
    vec2 ab = fa_env_brdf(roughness, ndv);
    vec3 result = fa_environment(r, roughness) * (f0 * ab.x + vec3(L.f90) * ab.y) * L.base_scale;
    if (L.sheen_on) {
        result += L.sheen * (L.sheen_e * L.keep) * fa_environment(n, L.sheen_rough);
    }
    if (L.coat > 0.0) {
        vec2 abc = fa_env_brdf(L.coat_rough, L.coat_ndv);
        result += fa_environment(reflect(-v, L.nc), L.coat_rough) * (L.coat * (0.04 * abc.x + abc.y));
    }
    return result;
}
@end

@block fa_layers_light
// The anisotropic GGX distribution and the height-correlated visibility with it (Khronos' glTF sample viewer, after Heitz; at and ab
// are the alphas along the tangent and the bitangent).
float fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab) {
    float a2 = at * ab;
    vec3 f = vec3(ab * tdh, at * bdh, a2 * ndh);
    float w2 = a2 / dot(f, f);
    return a2 * w2 * w2 / FA_PI;
}
float fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab) {
    float ggxv = ndl * length(vec3(at * tdv, ab * bdv, ndv));
    float ggxl = ndv * length(vec3(at * tdl, ab * bdl, ndl));
    return clamp(0.5 / max(ggxv + ggxl, 1e-4), 0.0, 1.0);
}
// The sheen distribution of Estevez and Kulla ("Charlie") and Ashikhmin's visibility; alpha is the sheen roughness squared.
float fa_d_charlie(float alpha, float ndh) {
    float inv_a = 1.0 / alpha;
    float sin2h = max(1.0 - ndh * ndh, 0.0078125);
    return (2.0 + inv_a) * pow(sin2h, inv_a * 0.5) / (2.0 * FA_PI);
}
float fa_v_ashikhmin(float ndl, float ndv) {
    return clamp(1.0 / (4.0 * (ndl + ndv - ndl * ndv)), 0.0, 1.0);
}

// The BRDF of one light with the layers on, times the cosine of the incidence (the coat's own for the coat lobe), to be multiplied by
// the light's colour and attenuation. Like the plain loop term, the specular carries the factor pi (the lights are not divided by pi).
// n is the shading normal, h the half vector, ndl, ndv, ndh and vdh their clamped dot products, alpha = roughness^2 and a2 = alpha^2.
vec3 fa_layers_light(in FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv,
                     float ndh, float vdh, float alpha, float a2) {
    float lit_ok = step(0.0001, ndl);
    vec3 fres = f0 + (vec3(L.f90) - f0) * pow(1.0 - vdh, 5.0);
    float d_ggx;
    float vis;
    if (L.aniso != 0.0) {
        d_ggx = fa_d_ggx_aniso(ndh, dot(L.t, h), dot(L.b, h), L.at, L.ab);
        vis = fa_v_ggx_aniso(ndl, ndv, dot(L.t, v), dot(L.b, v), dot(L.t, l), dot(L.b, l), L.at, L.ab);
    } else {
        float dd = ndh * ndh * (a2 - 1.0) + 1.0;
        d_ggx = a2 / (FA_PI * dd * dd);
        vis = 0.5 / max(mix(2.0 * ndl * ndv, ndl + ndv, alpha), 1e-4);
    }
    vec3 base = diffuse_color + fres * (d_ggx * vis * FA_PI) * lit_ok;
    if (L.sheen_on) {
        base = base * L.sheen_scale +
               L.sheen * (fa_d_charlie(L.sheen_alpha, ndh) * fa_v_ashikhmin(ndl, ndv) * FA_PI * lit_ok);
    }
    vec3 result = base * (L.keep * ndl);
    if (L.coat > 0.0) {
        float cdl = max(dot(L.nc, l), 0.0);
        float cdh = max(dot(L.nc, h), 0.0);
        float dd = cdh * cdh * (L.coat_a2 - 1.0) + 1.0;
        float d_c = L.coat_a2 / (FA_PI * dd * dd);
        float vis_c = 0.5 / max(mix(2.0 * cdl * L.coat_ndv, cdl + L.coat_ndv, L.coat_alpha), 1e-4);
        float f_c = 0.04 + 0.96 * pow(1.0 - vdh, 5.0);
        result += vec3(L.coat * f_c * (d_c * vis_c * FA_PI) * step(0.0001, cdl) * cdl);
    }
    return result;
}
@end
