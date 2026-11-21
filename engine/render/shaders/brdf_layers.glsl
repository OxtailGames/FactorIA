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
        L.keep = 1.0 - coat * (0.04 + 0.96 * pow(clamp(1.0 - L.coat_ndv, 0.0, 1.0), 5.0));
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

// What the layers add to the image-based lighting (the sky): the base layer's reflection with the dielectric f0 / f90 (and, with
// anisotropy, the normal bent toward the view along the stretch direction, the bent normal of McAuley 2015, "Rendering the World of Far
// Cry 4", by how rough the surface is: a mirror has no stretched highlight to bend toward), scaled by base_scale; the sheen as the
// environment seen along the normal at the sheen roughness, times the sheen colour and the sheen's albedo (an approximation: there is no
// sheen-filtered environment); the coat as a mirror-like reflection of the environment along the geometric normal with the coat's
// roughness and the environment BRDF of f0 0.04. `occlusion` (the material's occlusion map) darkens the base layer and the sheen, which
// lie in the surface's crevices; the coat is a smooth film over the whole surface and keeps its reflection.
vec3 fa_layers_ibl(in FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion) {
    float ndv = max(dot(n, v), 1e-4);
    vec3 rn = n;
    if (L.aniso != 0.0) {
        vec3 dir = L.aniso >= 0.0 ? L.b : L.t;
        vec3 an = cross(cross(dir, v), dir);
        rn = normalize(mix(n, an, abs(L.aniso) * smoothstep(0.0, 0.25, roughness)));
    }
    vec3 r = reflect(-v, rn);
    vec2 ab = fa_env_brdf(roughness, ndv);
    vec3 result = fa_environment(r, roughness) * (f0 * ab.x + vec3(L.f90) * ab.y) * L.base_scale;
    if (L.sheen_on) {
        result += L.sheen * (L.sheen_e * L.keep) * fa_environment(n, L.sheen_rough);
    }
    result *= occlusion;
    if (L.coat > 0.0) {
        vec2 abc = fa_env_brdf(L.coat_rough, L.coat_ndv);
        result += fa_environment(reflect(-v, L.nc), L.coat_rough) * (L.coat * (0.04 * abc.x + abc.y));
    }
    return result;
}
@end

@block fa_layers_light
// Anisotropic GGX (Burley 2012, "Physically-Based Shading at Disney"; Heitz 2014, "Understanding the Masking-Shadowing Function in
// Microfacet-Based BRDFs"). at and ab are the roughness alphas along the tangent and the bitangent; t, b and n are the components
// of a direction in the frame (tangent, bitangent, normal).
// Distribution: D = 1 / (pi at ab q^2) with q = (h.t / at)^2 + (h.b / ab)^2 + (h.n)^2.
float fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab) {
    float qt = tdh / at;
    float qb = bdh / ab;
    float q = qt * qt + qb * qb + ndh * ndh;
    return 1.0 / (FA_PI * at * ab * q * q);
}
// Heitz's Lambda of a direction: (sqrt(1 + (at^2 t^2 + ab^2 b^2) / n^2) - 1) / 2.
float fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab) {
    float n2 = max(n * n, 1e-8);
    return 0.5 * (sqrt(1.0 + (at * at * t * t + ab * ab * b * b) / n2) - 1.0);
}
// The visibility G2 / (4 n.l n.v) with the height-correlated masking-shadowing G2 = 1 / (1 + Lambda(v) + Lambda(l)).
float fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab) {
    float lam_v = fa_lambda_ggx_aniso(ndv, tdv, bdv, at, ab);
    float lam_l = fa_lambda_ggx_aniso(ndl, tdl, bdl, at, ab);
    return clamp(1.0 / (4.0 * max(ndl * ndv, 1e-4) * (1.0 + lam_v + lam_l)), 0.0, 1.0);
}
// The sheen lobe of Estevez and Kulla 2017 ("Production Friendly Microfacet Sheen BRDF"): the inverted-Gaussian distribution
// D = (2 + 1 / alpha) sin(theta_h)^(1 / alpha) / (2 pi) and their visibility V = 1 / (4 (n.l + n.v - n.l n.v)); alpha is the sheen
// roughness squared. sin(theta_h) is kept above 0.01 so the power stays finite at the pole of the half vector.
float fa_d_charlie(float alpha, float ndh) {
    float inv_a = 1.0 / alpha;
    float sin_h = sqrt(max(1.0 - ndh * ndh, 1e-4));
    return (2.0 + inv_a) * pow(sin_h, inv_a) / (2.0 * FA_PI);
}
float fa_v_ashikhmin(float ndl, float ndv) {
    return clamp(1.0 / (4.0 * max(ndl + ndv - ndl * ndv, 1e-4)), 0.0, 1.0);
}

// The clear coat's lobe for light direction l (half vector h, vdh = v.h): its GGX specular times the coat's own cosine, times
// coat strength; no light colour. Uses the coat's normal (the geometric one) and roughness; 0 without a coat.
float fa_layers_coat(in FaLayers L, vec3 l, vec3 h, float vdh) {
    float cdl = max(dot(L.nc, l), 0.0);
    float cdh = max(dot(L.nc, h), 0.0);
    float dd = cdh * cdh * (L.coat_a2 - 1.0) + 1.0;
    float d_c = L.coat_a2 / (FA_PI * dd * dd);
    float vis_c = 0.5 / max(mix(2.0 * cdl * L.coat_ndv, cdl + L.coat_ndv, L.coat_alpha), 1e-4);
    float f_c = 0.04 + 0.96 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0);
    return L.coat * f_c * (d_c * vis_c * FA_PI) * step(0.0001, cdl) * cdl;
}

// The BRDF of one light with the layers on, times the cosine of the incidence (the coat's own for the coat lobe), to be multiplied by
// the light's colour and attenuation. Like the plain loop term, the specular carries the factor pi (the lights are not divided by pi).
// n is the shading normal, h the half vector, ndl, ndv, ndh and vdh their clamped dot products, alpha = roughness^2 and a2 = alpha^2.
vec3 fa_layers_light(in FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv,
                     float ndh, float vdh, float alpha, float a2) {
    float lit_ok = step(0.0001, ndl);
    vec3 fres = f0 + (vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0);
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
    if (L.coat > 0.0) { result += vec3(fa_layers_coat(L, l, h, vdh)); }
    return result;
}
@end

// Transmission and volume (M73.6b, KHR_materials_transmission / _volume / _ior): what a glass or liquid surface lets through. Only in
// fa_fs_light (the engine's own lighting; a "custom" lighting draws no transmission). A transmissive draw is a blended-phase draw, so the
// opaque picture is finished when it runs; the renderer (renderer_xmit.h) copied the camera's rectangle of it into the "refraction atlas" bound
// at view 28 and reduced it level by level, each level half the size of the one before:
//
//   level 0 at (0, 0), the size of the camera's rectangle (fa_ct_a.zw); level 1 at (W, 0); level k >= 2 right under level k - 1.
//
// The positions are IMAGE ROWS (row 0 = the image's first row on every backend), and the size of level k is max(floor(size / 2^k), 1): the
// C++ side (xmit_layout in renderer_xmit.h) computes the same numbers. The atlas is read with texelFetch (the slot is declared unfilterable), so
// the bilinear and the blend between two levels are done here.
//
// The model is the glTF one: the light that goes through is (1 - Fresnel) * baseColor * what is behind the surface, bent and blurred. The ray
// leaves the surface along refract(-v, n, 1 / ior), travels `thickness` metres inside (the volume is a thin slab of that depth: no ray
// march, no second interface) and the picture is read where that point is on the screen (the rows of the view-projection matrix of
// fa_ct_vp*), at the level the roughness asks for (roughness * clamp(2 * ior - 2, 0, 1) of the way down the pyramid: glass of ior 1 bends
// nothing, so its roughness blurs nothing). Beer-Lambert tints it over the same distance: exp(-ln(1 / attenuationColor) * d / attenuationDistance),
// so the colour is the one the light has after attenuationDistance metres. What is behind is the OPAQUE picture: another transmissive surface
// (sorted far to near) does not show up in it. The diffuse light of the surface is scaled by 1 - transmission by the caller.
@block fa_transmission
vec2 fa_xm_size(int k) {
    return max(floor(fa_ct_a.zw / float(1 << k)), vec2(1.0));  // an exact power of two (exp2 is not exact on every GPU)
}

// Where level k starts in the atlas, in pixels.
vec2 fa_xm_origin(int k) {
    if (k == 0) { return vec2(0.0); }
    float y = 0.0;
    for (int j = 1; j < k; j++) { y += fa_xm_size(j).y; }
    return vec2(fa_ct_a.z, y);
}

vec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p) {
    vec2 q = clamp(p, vec2(0.0), size - 1.0);
    return texelFetch(sampler2D(fa_screen_tex, fa_shadow_smp), ivec2(origin + q), 0).rgb;
}

// Level k at uv (0..1 over the camera's rectangle in image rows), bilinear.
vec3 fa_xm_level(int k, vec2 uv) {
    vec2 size = fa_xm_size(k);
    vec2 origin = fa_xm_origin(k);
    vec2 p = uv * size - 0.5;
    vec2 f = fract(p);
    vec2 b = floor(p);
    vec3 a0 = fa_xm_texel(size, origin, b);
    vec3 a1 = fa_xm_texel(size, origin, b + vec2(1.0, 0.0));
    vec3 a2 = fa_xm_texel(size, origin, b + vec2(0.0, 1.0));
    vec3 a3 = fa_xm_texel(size, origin, b + vec2(1.0, 1.0));
    return mix(mix(a0, a1, f.x), mix(a2, a3, f.x), f.y);
}

// The atlas at uv, `lod` levels down (a fraction blends the two levels around it).
vec3 fa_xm_sample(vec2 uv, float lod) {
    float top = max(fa_tr_b.w - 1.0, 0.0);
    float l = clamp(lod, 0.0, top);
    int k0 = int(floor(l));
    vec3 c = fa_xm_level(k0, uv);
    float fr = l - float(k0);
    if (fr > 0.001 && float(k0) < top) { c = mix(c, fa_xm_level(k0 + 1, uv), fr); }
    return c;
}

// What the surface adds to the light of the lobes: the light that goes through it. `f0` and `f90` are the reflectances of the base layer at
// normal incidence and at grazing angles (the surface's specular reflection takes that share, the rest goes through), `keep` what the layers on
// top let through (FaLayers.base_scale), `tr` the transmission (already times 1 - metallic). When no atlas is bound (fa_tr_a.w = 2)
// `blend` gets the share of the picture behind the draw lets through, for the caller to turn into a plain alpha blend (the glass keeps
// its reflections and darkens what is behind; no refraction).
vec3 fa_transmitted(in Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend) {
    float ndv = max(dot(n, v), 1e-4);
    vec2 ab = fa_env_brdf(roughness, ndv);
    vec3 refl = clamp(f0 * ab.x + vec3(f90) * ab.y, 0.0, 1.0);
    vec3 through = (vec3(1.0) - refl) * s.albedo * (tr * keep);
    // Beer-Lambert over the distance travelled in the volume.
    float len = max(s.thickness, 0.0);
    if (s.attenuation_distance > 0.0 && len > 0.0) {
        vec3 coef = -log(clamp(s.attenuation_color, vec3(0.0001), vec3(1.0))) / s.attenuation_distance;
        through *= exp(-coef * len);
    }
    if (fa_tr_a.w > 1.5 || fa_tr_a.w < 0.5) {
        blend = clamp(dot(through, vec3(1.0 / 3.0)), 0.0, 0.98);
        return vec3(0.0);
    }
    // Where the light that went through is on the screen.
    vec3 world = fa_world_pos;
    if (len > 0.0) {
        vec3 rd = refract(-v, n, 1.0 / max(s.ior, 1.0));
        world += rd * len;
    }
    vec4 pv = vec4(world, 1.0);
    float w = dot(fa_ct_vpw, pv);
    vec2 uv = vec2(0.5);
    if (w > 1e-4) {
        vec2 ndc = vec2(dot(fa_ct_vpx, pv), dot(fa_ct_vpy, pv)) / w;
        uv = vec2(ndc.x * 0.5 + 0.5, fa_ct_a.y > 0.5 ? ndc.y * 0.5 + 0.5 : 0.5 - ndc.y * 0.5);
    }
    float lod = clamp(roughness, 0.0, 1.0) * clamp(2.0 * s.ior - 2.0, 0.0, 1.0) * max(fa_tr_b.w - 1.0, 0.0);
    return through * fa_xm_sample(clamp(uv, vec2(0.0), vec2(1.0)), lod);
}
@end
