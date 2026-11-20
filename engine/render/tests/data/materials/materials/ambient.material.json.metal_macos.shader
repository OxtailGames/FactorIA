{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "7cd31c28ac6572768802838498bbbd3180b96e0a1bb1bab7ad49d1d6af9d528c",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_265, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394)\n{\n    bool _399 = _394.fa_cl_info.x < 0.0;\n    bool _406;\n    if (!_399)\n    {\n        _406 = _394.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _406 = _399;\n    }\n    bool _414;\n    if (!_406)\n    {\n        _414 = _394.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _414 = _406;\n    }\n    bool _421;\n    if (!_414)\n    {\n        _421 = _394.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _421 = _414;\n    }\n    bool _428;\n    if (!_421)\n    {\n        _428 = _394.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    if (_428)\n    {\n        return int2(0);\n    }\n    float4 _438 = float4(world_pos, 1.0);\n    float _445 = dot(_394.fa_cl_vpw, _438);\n    if (!(_445 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _467 = float2(dot(_394.fa_cl_vpx, _438), dot(_394.fa_cl_vpy, _438)) / float2(_445);\n    int _471 = int(_394.fa_cl_grid.x);\n    int _475 = int(_394.fa_cl_grid.y);\n    int param = (int(_394.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_394.fa_cl_fwd.xyz, world_pos) + _394.fa_cl_fwd.w, _394.fa_cl_grid.w) / _394.fa_cl_grid.w) * _394.fa_cl_grid.z)), 0, int(_394.fa_cl_info.y) - 1) * _475) + clamp(int(floor(((_467.y * 0.5) + 0.5) * _394.fa_cl_grid.y)), 0, _475 - 1)) * _471)) + clamp(int(floor(((_467.x * 0.5) + 0.5) * _394.fa_cl_grid.x)), 0, _471 - 1);\n    float4 _546 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_546.x), int(_546.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_394.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1674 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _394);\n    fa_cl_slot = _1674.x;\n    fa_cl_local = _1674.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1810 = fa_linear_to_srgb(param);\n        c = _1810;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1818 = fa_srgb_to_linear(param_1);\n            c = _1818;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _175;\n    if (bool(i.front_facing))\n    {\n        _175 = i.world_normal;\n    }\n    else\n    {\n        _175 = -i.world_normal;\n    }\n    float3 _199 = fast::normalize(i.world_tangent.xyz - (_175 * dot(_175, i.world_tangent.xyz)));\n    float3 _227 = fast::normalize(((_199 * m.x) + ((cross(_175, _199) * i.world_tangent.w) * m.y)) + (_175 * m.z));\n    float3 _230;\n    if (bool(i.front_facing))\n    {\n        _230 = _227;\n    }\n    else\n    {\n        _230 = -_227;\n    }\n    return _230;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _394, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _394.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1849 = fa_tex_fix(param_2, param_3);\n    float4 _2792 = base_t;\n    _2792.x = _1849.x;\n    _2792.y = _1849.y;\n    _2792.z = _1849.z;\n    base_t = _2792;\n    float4 _1863 = (_2792 * _394.fa_base_color) * i.vertex_color;\n    float3 _2707 = i.world_normal;\n    if (_394.fa_maps.z > 0.5)\n    {\n        float param_4 = _394.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1895 = fa_tex_fix(param_6, param_7);\n        float3 _1899 = (_1895 * 2.0) - float3(1.0);\n        float2 _1904 = _1899.xy * _394.fa_maps.x;\n        float3 _2800 = _1899;\n        _2800.x = _1904.x;\n        _2800.y = _1904.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2800;\n        _2707 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _394.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1933 = fa_tex_fix(param_12, param_13);\n    float4 _2803 = mrt;\n    _2803.x = _1933.x;\n    _2803.y = _1933.y;\n    _2803.z = _1933.z;\n    mrt = _2803;\n    float4 _1962 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _394.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _1962.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1974 = fa_tex_fix(param_16, param_17);\n    float param_18 = _394.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2004 = fa_tex_fix(param_20, param_21);\n    float _2712 = _394.fa_layers_a.x;\n    float _2713 = _394.fa_layers_a.y;\n    float _2716 = _394.fa_layers_a.z;\n    float _2715 = _394.fa_layers_b.w;\n    float _2718 = _394.fa_layers_c.x;\n    if (_394.fa_layers_c.z > 0.5)\n    {\n        if (mod(_394.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2712 *= _1974.y;\n            _2713 *= _1974.z;\n            _2715 *= _1962.w;\n        }\n        if (_394.fa_layers_c.z > 1.5)\n        {\n            _2716 *= mrt.x;\n            _2718 *= mrt.w;\n        }\n    }\n    return Surface{ _1863.xyz, _1863.w, _2707, fast::clamp(_394.fa_pbr.x * _1933.z, 0.0, 1.0), fast::clamp(_394.fa_pbr.y * _1933.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_394.fa_maps.y * (_1974.x - 1.0)), _394.fa_emissive.xyz + (_394.fa_model_emissive.xyz * _2004), _2712, _2713, _394.fa_layers_b.xyz, _2715, _2716, _394.fa_layers_a.w, _2718, _394.fa_layers_c.y, _394.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _394, texturecube<float> fa_irr_tex, sampler fa_env_smp)\n{\n    if (_394.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _394.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return float3(0.0, ambientColor.y, 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394)\n{\n    int param = (int(_394.fa_cl_info.x) + int(_394.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _394);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _267 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _273 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _276 = _273.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _283 = _276 < 0.5;\n    float3 l;\n    if (_283)\n    {\n        l = fast::normalize(_267.xyz);\n    }\n    else\n    {\n        float3 _295 = _267.xyz - world_pos;\n        float _297 = length(_295);\n        dist = _297;\n        l = _295 / float3(fast::max(_297, 9.9999997473787516355514526367188e-05));\n        float _312 = _297 / fast::max(_267.w, 0.001000000047497451305389404296875);\n        float _318 = fast::clamp(1.0 - (_312 * _312), 0.0, 1.0);\n        atten = _318 * _318;\n        if (_276 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _332 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _342 = _332.w;\n            int param_3 = (li * 4) + 3;\n            float4 _349 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _350 = _349.x;\n            float cos_inner = _350;\n            if (_350 > 1.5)\n            {\n                cos_inner = mix(_342, 1.0, 0.25);\n            }\n            atten *= smoothstep(_342, cos_inner, dot(-l, fast::normalize(_332.xyz)));\n        }\n    }\n    int _380;\n    if (_283)\n    {\n        _380 = 0;\n    }\n    else\n    {\n        _380 = (_276 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _273.xyz * atten, atten, 1.0, dist, _380 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _630)\n{\n    float _620;\n    if (i == 0)\n    {\n        _620 = _630.fa_shadow_split.x;\n    }\n    else\n    {\n        float _636;\n        if (i == 1)\n        {\n            _636 = _630.fa_shadow_split.y;\n        }\n        else\n        {\n            float _644;\n            if (i == 2)\n            {\n                _644 = _630.fa_shadow_split.z;\n            }\n            else\n            {\n                _644 = _630.fa_shadow_split.w;\n            }\n            _636 = _644;\n        }\n        _620 = _636;\n    }\n    return _620;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _677 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _681;\n    if (conv.x < 0.5)\n    {\n        _681 = _677;\n    }\n    else\n    {\n        _681 = (conv.y * conv.z) / (conv.z - (_677 * (conv.z - conv.y)));\n    }\n    return _681;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _608 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_608), sin(_608)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _727 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _741 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _727;\n            float2 _760 = fa_shadow_vogel(param_3, param_4, param_5) * _741;\n            float2 param_6 = uv + (_760 * _630.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _772 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_772 < (zr - (length(_760) * plane)))\n            {\n                sum += _772;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _816 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _816; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _816;\n        float param_11 = _727;\n        float2 _835 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_835 * _630.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_835) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_816);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex)\n{\n    float _877 = fast::max(_630.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _882 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _888 = sqrt(1.0 - (_882 * _882));\n    float _896 = fast::min(_888 / fast::max(_882, 0.20000000298023223876953125), 4.0);\n    float _901;\n    if (_630.fa_shadow_bias.y > 0.0)\n    {\n        _901 = _630.fa_shadow_bias.y;\n    }\n    else\n    {\n        _901 = 1.5 * _630.fa_shadow_info[ci].x;\n    }\n    float4 _926 = _630.fa_shadow_mat[ci] * float4(world + (n * (_901 * _888)), 1.0);\n    float _933 = _926.x;\n    bool _936 = _933 < _630.fa_shadow_rect[ci].x;\n    bool _945;\n    if (!_936)\n    {\n        _945 = _933 > _630.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _945 = _936;\n    }\n    bool _954;\n    if (!_945)\n    {\n        _954 = _926.y < _630.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _954 = _945;\n    }\n    bool _963;\n    if (!_954)\n    {\n        _963 = _926.y > _630.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _963 = _954;\n    }\n    bool _970;\n    if (!_963)\n    {\n        _970 = _926.z > 1.0;\n    }\n    else\n    {\n        _970 = _963;\n    }\n    if (_970)\n    {\n        return -1.0;\n    }\n    float _979;\n    if (_630.fa_shadow_bias.x > 0.0)\n    {\n        _979 = _630.fa_shadow_bias.x;\n    }\n    else\n    {\n        _979 = 1.5 * _630.fa_shadow_info[ci].x;\n    }\n    float2 param = _926.xy;\n    float4 param_1 = _630.fa_shadow_rect[ci];\n    float param_2 = _926.z - ((_979 * (1.0 + (0.5 * _896))) / _877);\n    float param_3 = _630.fa_shadow_info[ci].x;\n    float param_4 = _877;\n    float param_5 = _877 * 0.25;\n    float param_6 = ((_630.fa_shadow_info[ci].x * fast::min(_896, 3.0)) * 0.5) / _877;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_630.fa_shadow_cfg.z + 0.5);\n    float param_9 = _630.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _630, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex)\n{\n    if (_394.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1373 = int(_630.fa_shadow_cfg.x + 0.5);\n    if (_1373 < 1)\n    {\n        return 1.0;\n    }\n    float _1389 = dot(world - _630.fa_shadow_eye.xyz, _630.fa_shadow_fwd.xyz);\n    int param = _1373 - 1;\n    if (_1389 > fa_shadow_split_at(param, _630))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1401 = _1373 > 1;\n    bool _1408;\n    if (_1401)\n    {\n        _1408 = _1389 > _630.fa_shadow_split.x;\n    }\n    else\n    {\n        _1408 = _1401;\n    }\n    if (_1408)\n    {\n        ci = 1;\n    }\n    bool _1412 = _1373 > 2;\n    bool _1419;\n    if (_1412)\n    {\n        _1419 = _1389 > _630.fa_shadow_split.y;\n    }\n    else\n    {\n        _1419 = _1412;\n    }\n    if (_1419)\n    {\n        ci = 2;\n    }\n    bool _1423 = _1373 > 3;\n    bool _1430;\n    if (_1423)\n    {\n        _1430 = _1389 > _630.fa_shadow_split.z;\n    }\n    else\n    {\n        _1430 = _1423;\n    }\n    if (_1430)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1373)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1456 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _630, fa_shadow_tex);\n        s = _1456;\n        if (_1456 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_630.fa_shadow_cfg.y > 0.0)\n    {\n        float _1481;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1481 = fa_shadow_split_at(param_5, _630);\n        }\n        else\n        {\n            _1481 = _630.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1500 = _630.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _630) - _1481, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1511 = fast::clamp((_1389 - (fa_shadow_split_at(param_7, _630) - _1500)) / _1500, 0.0, 1.0);\n        if (_1511 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1373)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1532 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _630, fa_shadow_tex);\n                s2 = _1532;\n                if (_1532 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1511);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _394, gl_FragCoord, _630, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex)\n{\n    bool _1038 = _394.fa_pbr.z < 0.5;\n    bool _1046;\n    if (!_1038)\n    {\n        _1046 = _630.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1046 = _1038;\n    }\n    if (_1046)\n    {\n        return 1.0;\n    }\n    int param = (int(_630.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1059 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1060 = _1059.x;\n    if (_1060 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1069 = int(_1060 + 0.5);\n    int param_1 = _1069;\n    float4 _1073 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1069 + 1;\n    float4 _1078 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1081 = _1073.y;\n    if (_1081 > 0.0)\n    {\n        float _1098 = 1.0 - smoothstep(0.75 * _1081, _1081, length(world - _630.fa_shadow_eye.xyz));\n        fade = _1098;\n        if (_1098 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1073.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1117 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1120 = abs(_1117);\n        float _1122 = _1120.x;\n        float _1124 = _1120.y;\n        bool _1125 = _1122 >= _1124;\n        bool _1133;\n        if (_1125)\n        {\n            _1133 = _1122 >= _1120.z;\n        }\n        else\n        {\n            _1133 = _1125;\n        }\n        int _1134;\n        if (_1133)\n        {\n            _1134 = (_1117.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1147;\n            if (_1124 >= _1120.z)\n            {\n                _1147 = (_1117.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1147 = (_1117.z > 0.0) ? 4 : 5;\n            }\n            _1134 = _1147;\n        }\n        face = _1134;\n    }\n    int _1166 = (_1069 + 2) + (face * 6);\n    int param_4 = _1166;\n    int param_5 = _1166 + 1;\n    int param_6 = _1166 + 3;\n    float4 _1180 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1166 + 4;\n    float4 _1185 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1166 + 5;\n    float4 _1190 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1202 = _1190.x * fast::max(dot(_1180, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1207 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1213 = sqrt(1.0 - (_1207 * _1207));\n    float _1219 = fast::min(_1213 / fast::max(_1207, 0.20000000298023223876953125), 4.0);\n    float _1222 = _1078.y;\n    float _1224;\n    if (_1222 > 0.0)\n    {\n        _1224 = _1222;\n    }\n    else\n    {\n        _1224 = 1.5 * _1202;\n    }\n    float4 _1244 = float4(world + (n * (_1224 * _1213)), 1.0);\n    float _1248 = dot(_1180, _1244);\n    float _1251 = _1190.y;\n    if (_1248 < _1251)\n    {\n        return 1.0;\n    }\n    float2 _1266 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1244), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1244)) / float2(_1248);\n    float _1268 = _1266.x;\n    bool _1271 = _1268 < _1185.x;\n    bool _1280;\n    if (!_1271)\n    {\n        _1280 = _1268 > _1185.z;\n    }\n    else\n    {\n        _1280 = _1271;\n    }\n    bool _1289;\n    if (!_1280)\n    {\n        _1289 = _1266.y < _1185.y;\n    }\n    else\n    {\n        _1289 = _1280;\n    }\n    bool _1298;\n    if (!_1289)\n    {\n        _1298 = _1266.y > _1185.w;\n    }\n    else\n    {\n        _1298 = _1289;\n    }\n    if (_1298)\n    {\n        return 1.0;\n    }\n    float _1304 = _1078.x;\n    float _1306;\n    if (_1304 > 0.0)\n    {\n        _1306 = _1304;\n    }\n    else\n    {\n        _1306 = 1.5 * _1202;\n    }\n    float2 param_9 = _1266;\n    float4 param_10 = _1185;\n    float param_11 = _1248 - (_1306 * (1.0 + (0.5 * _1219)));\n    float param_12 = _1202;\n    float param_13 = 1.0;\n    float param_14 = _1190.z * 0.25;\n    float param_15 = (_1202 * fast::min(_1219, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _1251, _1190.z);\n    int param_17 = int(_1073.z + 0.5);\n    float param_18 = _1073.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _630, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1702 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2692 = _1702.direction;\n    float3 _2687 = _1702.color;\n    float _2694 = _1702.attenuation;\n    float _2689 = _1702.shadow;\n    int _2697 = _1702.type;\n    if ((_2697 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2692;\n        float _1716 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _394, gl_FragCoord, _630, fa_shadow_tex, fa_world_pos);\n        _2689 = _1716;\n        _2687 *= _1716;\n    }\n    else\n    {\n        bool _1727 = _2697 != 0;\n        bool _1733;\n        if (_1727)\n        {\n            _1733 = _2694 > 0.0;\n        }\n        else\n        {\n            _1733 = _1727;\n        }\n        if (_1733)\n        {\n            int param_4 = li;\n            float3 param_5 = world_pos;\n            float3 param_6 = gn;\n            float3 param_7 = _2692;\n            float _1745 = fa_shadow_local(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _394, gl_FragCoord, _630, fa_shadow_tex);\n            _2689 = _1745;\n            _2687 *= _1745;\n        }\n    }\n    return LightSample{ _2692, _2687, _2694, _2689, _1702._distance, _2697 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _630)\n{\n    if (_630.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1556 = int(_630.fa_shadow_cfg.x + 0.5);\n    float _1566 = dot(world - _630.fa_shadow_eye.xyz, _630.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1571 = _1556 > 0;\n    bool _1580;\n    if (_1571)\n    {\n        int param = _1556 - 1;\n        _1580 = _1566 <= fa_shadow_split_at(param, _630);\n    }\n    else\n    {\n        _1580 = _1571;\n    }\n    if (_1580)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1587 = _1556 > 1;\n        bool _1594;\n        if (_1587)\n        {\n            _1594 = _1566 > _630.fa_shadow_split.x;\n        }\n        else\n        {\n            _1594 = _1587;\n        }\n        if (_1594)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1600 = _1556 > 2;\n        bool _1607;\n        if (_1600)\n        {\n            _1607 = _1566 > _630.fa_shadow_split.y;\n        }\n        else\n        {\n            _1607 = _1600;\n        }\n        if (_1607)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1613 = _1556 > 3;\n        bool _1620;\n        if (_1613)\n        {\n            _1620 = _1566 > _630.fa_shadow_split.z;\n        }\n        else\n        {\n            _1620 = _1613;\n        }\n        if (_1620)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _394 [[buffer(1)]], constant fa_shadows& _630 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2516 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2516 = -_2516;\n    }\n    float3 _2129 = fast::normalize(_394.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _394, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2516, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2129, short(gl_FrontFacing) };\n    Surface _2137 = fa_standard_surface(param_1, _394, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2555 = _2137.albedo;\n    float _2556 = _2137.alpha;\n    float3 _2557 = _2137.normal;\n    float _2558 = _2137.metallic;\n    float _2559 = _2137.roughness;\n    float _2560 = _2137.occlusion;\n    float3 _2561 = _2137.emission;\n    float _2562 = _2137.clearcoat;\n    float _2563 = _2137.clearcoat_roughness;\n    float3 _2564 = _2137.sheen_color;\n    float _2565 = _2137.sheen_roughness;\n    float _2566 = _2137.anisotropy;\n    float _2567 = _2137.anisotropy_rotation;\n    float _2568 = _2137.specular;\n    float _2569 = _2137.ior;\n    float3 _2570 = _2137.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2516, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2129, short(gl_FrontFacing) };\n    Surface param_3 = _2137;\n    surface(param_2, param_3);\n    _2555 = param_3.albedo;\n    _2556 = param_3.alpha;\n    _2557 = param_3.normal;\n    _2558 = param_3.metallic;\n    _2559 = param_3.roughness;\n    _2560 = param_3.occlusion;\n    _2561 = param_3.emission;\n    _2562 = param_3.clearcoat;\n    _2563 = param_3.clearcoat_roughness;\n    _2564 = param_3.sheen_color;\n    _2565 = param_3.sheen_roughness;\n    _2566 = param_3.anisotropy;\n    _2567 = param_3.anisotropy_rotation;\n    _2568 = param_3.specular;\n    _2569 = param_3.ior;\n    _2570 = param_3.specular_color;\n    float3 result;\n    if (_394.fa_emissive.w > 0.5)\n    {\n        result = _2555;\n    }\n    else\n    {\n        float3 _2158 = _2557;\n        float3 _2159 = fast::normalize(_2158);\n        _2557 = _2159;\n        float3 param_4 = _2159;\n        SurfaceInput param_5 = SurfaceInput{ in.fa_world_pos, _2516, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2129, short(gl_FrontFacing) };\n        Surface param_6 = Surface{ _2555, _2556, _2557, _2558, _2559, _2560, _2561, _2562, _2563, _2564, _2565, _2566, _2567, _2568, _2569, _2570 };\n        float3 param_7 = fa_ambient_light(param_4, _394, fa_irr_tex, fa_env_smp);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _2178 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2178; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8, fa_light_tex, fa_shadow_smp, _394, fa_cl_ndir, fa_cl_slot);\n            float3 param_10 = in.fa_world_pos;\n            float3 param_11 = _2516;\n            SurfaceInput param_12 = SurfaceInput{ in.fa_world_pos, _2516, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2129, short(gl_FrontFacing) };\n            Surface param_13 = Surface{ _2555, _2556, _2557, _2558, _2559, _2560, _2561, _2562, _2563, _2564, _2565, _2566, _2567, _2568, _2569, _2570 };\n            LightSample param_14 = fa_light_shadowed(param_9, param_10, param_11, fa_light_tex, fa_shadow_smp, _394, gl_FragCoord, _630, fa_shadow_tex, in.fa_world_pos);\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    float3 _2215 = result;\n    float3 _2216 = _2215 + _2561;\n    result = _2216;\n    float3 param_15 = _2216;\n    float3 param_16 = in.fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16, _630);\n    bool _2225 = _394.fa_fog.w > 0.0;\n    bool _2232;\n    if (!_2225)\n    {\n        _2232 = _394.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2232 = _2225;\n    }\n    if (_2232)\n    {\n        float3 _2241 = in.fa_world_pos - _394.fa_camera_pos.xyz;\n        float _2247 = dot(_2241, _394.fa_fog_c.xyz);\n        bool _2251 = _394.fa_fog_c.w > 0.5;\n        float _2252;\n        if (_2251)\n        {\n            _2252 = _2247;\n        }\n        else\n        {\n            _2252 = length(_2241);\n        }\n        float _2264 = _2252 - _394.fa_fog_b.x;\n        if (_2264 > 0.0)\n        {\n            float _2273 = _394.fa_fog.w * _2264;\n            float tau = _2273 * _2273;\n            if (_394.fa_fog_b.y > 0.0)\n            {\n                float _2289;\n                if (_2251)\n                {\n                    _2289 = in.fa_world_pos.y - (_394.fa_fog_c.y * _2247);\n                }\n                else\n                {\n                    _2289 = _394.fa_camera_pos.y;\n                }\n                float _2310 = mix(_2289, in.fa_world_pos.y, fast::clamp(_394.fa_fog_b.x / _2252, 0.0, 1.0));\n                float _2314 = in.fa_world_pos.y - _2310;\n                float _2319 = _2310 - _394.fa_fog_b.z;\n                float _2324 = in.fa_world_pos.y - _394.fa_fog_b.z;\n                bool _2327 = _2319 <= 0.0;\n                bool _2328 = !_2327;\n                bool _2334;\n                if (_2328)\n                {\n                    _2334 = _394.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2334 = _2327;\n                }\n                float _2335;\n                if (_2334)\n                {\n                    _2335 = _394.fa_fog_b.y;\n                }\n                else\n                {\n                    _2335 = _394.fa_fog_b.y * exp(-fast::min(_394.fa_fog_b.w * _2319, 80.0));\n                }\n                bool _2362;\n                if (_2328)\n                {\n                    _2362 = _394.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2362 = _2327;\n                }\n                float _2363;\n                if (_2362)\n                {\n                    _2363 = _394.fa_fog_b.y * _2319;\n                }\n                else\n                {\n                    _2363 = (_394.fa_fog_b.y * (1.0 - exp(-fast::min(_394.fa_fog_b.w * _2319, 80.0)))) / _394.fa_fog_b.w;\n                }\n                bool _2388 = _2324 <= 0.0;\n                bool _2395;\n                if (!_2388)\n                {\n                    _2395 = _394.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2395 = _2388;\n                }\n                float _2396;\n                if (_2395)\n                {\n                    _2396 = _394.fa_fog_b.y * _2324;\n                }\n                else\n                {\n                    _2396 = (_394.fa_fog_b.y * (1.0 - exp(-fast::min(_394.fa_fog_b.w * _2324, 80.0)))) / _394.fa_fog_b.w;\n                }\n                float _2423;\n                if (abs(_2314) < 0.001000000047497451305389404296875)\n                {\n                    _2423 = _2335;\n                }\n                else\n                {\n                    _2423 = (_2396 - _2363) / _2314;\n                }\n                tau += (_2264 * fast::max(_2423, 0.0));\n            }\n            result = mix(result, _394.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2556);\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_394",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_630",
            "msl_buffer_n": 7
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 2
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 3
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 4
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          },
          {
            "texture": {
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "msl_texture_n": 6
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 7
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "msl_sampler_n": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 10
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_386, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394)\n{\n    bool _399 = _394.fa_cl_info.x < 0.0;\n    bool _406;\n    if (!_399)\n    {\n        _406 = _394.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _406 = _399;\n    }\n    bool _414;\n    if (!_406)\n    {\n        _414 = _394.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _414 = _406;\n    }\n    bool _421;\n    if (!_414)\n    {\n        _421 = _394.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _421 = _414;\n    }\n    bool _428;\n    if (!_421)\n    {\n        _428 = _394.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    if (_428)\n    {\n        return int2(0);\n    }\n    float4 _438 = float4(world_pos, 1.0);\n    float _445 = dot(_394.fa_cl_vpw, _438);\n    if (!(_445 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _467 = float2(dot(_394.fa_cl_vpx, _438), dot(_394.fa_cl_vpy, _438)) / float2(_445);\n    int _471 = int(_394.fa_cl_grid.x);\n    int _475 = int(_394.fa_cl_grid.y);\n    int param = (int(_394.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_394.fa_cl_fwd.xyz, world_pos) + _394.fa_cl_fwd.w, _394.fa_cl_grid.w) / _394.fa_cl_grid.w) * _394.fa_cl_grid.z)), 0, int(_394.fa_cl_info.y) - 1) * _475) + clamp(int(floor(((_467.y * 0.5) + 0.5) * _394.fa_cl_grid.y)), 0, _475 - 1)) * _471)) + clamp(int(floor(((_467.x * 0.5) + 0.5) * _394.fa_cl_grid.x)), 0, _471 - 1);\n    float4 _546 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_546.x), int(_546.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_394.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1674 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _394);\n    fa_cl_slot = _1674.x;\n    fa_cl_local = _1674.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1810 = fa_linear_to_srgb(param);\n        c = _1810;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1818 = fa_srgb_to_linear(param_1);\n            c = _1818;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _175;\n    if (bool(i.front_facing))\n    {\n        _175 = i.world_normal;\n    }\n    else\n    {\n        _175 = -i.world_normal;\n    }\n    float3 _199 = fast::normalize(i.world_tangent.xyz - (_175 * dot(_175, i.world_tangent.xyz)));\n    float3 _227 = fast::normalize(((_199 * m.x) + ((cross(_175, _199) * i.world_tangent.w) * m.y)) + (_175 * m.z));\n    float3 _230;\n    if (bool(i.front_facing))\n    {\n        _230 = _227;\n    }\n    else\n    {\n        _230 = -_227;\n    }\n    return _230;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _394, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _394.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1849 = fa_tex_fix(param_2, param_3);\n    float4 _2792 = base_t;\n    _2792.x = _1849.x;\n    _2792.y = _1849.y;\n    _2792.z = _1849.z;\n    base_t = _2792;\n    float4 _1863 = (_2792 * _394.fa_base_color) * i.vertex_color;\n    float3 _2707 = i.world_normal;\n    if (_394.fa_maps.z > 0.5)\n    {\n        float param_4 = _394.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1895 = fa_tex_fix(param_6, param_7);\n        float3 _1899 = (_1895 * 2.0) - float3(1.0);\n        float2 _1904 = _1899.xy * _394.fa_maps.x;\n        float3 _2800 = _1899;\n        _2800.x = _1904.x;\n        _2800.y = _1904.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2800;\n        _2707 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _394.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1933 = fa_tex_fix(param_12, param_13);\n    float4 _2803 = mrt;\n    _2803.x = _1933.x;\n    _2803.y = _1933.y;\n    _2803.z = _1933.z;\n    mrt = _2803;\n    float4 _1962 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _394.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _1962.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1974 = fa_tex_fix(param_16, param_17);\n    float param_18 = _394.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2004 = fa_tex_fix(param_20, param_21);\n    float _2712 = _394.fa_layers_a.x;\n    float _2713 = _394.fa_layers_a.y;\n    float _2716 = _394.fa_layers_a.z;\n    float _2715 = _394.fa_layers_b.w;\n    float _2718 = _394.fa_layers_c.x;\n    if (_394.fa_layers_c.z > 0.5)\n    {\n        if (mod(_394.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2712 *= _1974.y;\n            _2713 *= _1974.z;\n            _2715 *= _1962.w;\n        }\n        if (_394.fa_layers_c.z > 1.5)\n        {\n            _2716 *= mrt.x;\n            _2718 *= mrt.w;\n        }\n    }\n    return Surface{ _1863.xyz, _1863.w, _2707, fast::clamp(_394.fa_pbr.x * _1933.z, 0.0, 1.0), fast::clamp(_394.fa_pbr.y * _1933.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_394.fa_maps.y * (_1974.x - 1.0)), _394.fa_emissive.xyz + (_394.fa_model_emissive.xyz * _2004), _2712, _2713, _394.fa_layers_b.xyz, _2715, _2716, _394.fa_layers_a.w, _2718, _394.fa_layers_c.y, _394.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _394, texturecube<float> fa_irr_tex, sampler fa_env_smp)\n{\n    if (_394.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _394.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return float3(0.0, ambientColor.y, 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394)\n{\n    int param = (int(_394.fa_cl_info.x) + int(_394.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _394);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _267 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _273 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _276 = _273.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _283 = _276 < 0.5;\n    float3 l;\n    if (_283)\n    {\n        l = fast::normalize(_267.xyz);\n    }\n    else\n    {\n        float3 _295 = _267.xyz - world_pos;\n        float _297 = length(_295);\n        dist = _297;\n        l = _295 / float3(fast::max(_297, 9.9999997473787516355514526367188e-05));\n        float _312 = _297 / fast::max(_267.w, 0.001000000047497451305389404296875);\n        float _318 = fast::clamp(1.0 - (_312 * _312), 0.0, 1.0);\n        atten = _318 * _318;\n        if (_276 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _332 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _342 = _332.w;\n            int param_3 = (li * 4) + 3;\n            float4 _349 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _350 = _349.x;\n            float cos_inner = _350;\n            if (_350 > 1.5)\n            {\n                cos_inner = mix(_342, 1.0, 0.25);\n            }\n            atten *= smoothstep(_342, cos_inner, dot(-l, fast::normalize(_332.xyz)));\n        }\n    }\n    int _380;\n    if (_283)\n    {\n        _380 = 0;\n    }\n    else\n    {\n        _380 = (_276 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _273.xyz * atten, atten, 1.0, dist, _380 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _630)\n{\n    float _620;\n    if (i == 0)\n    {\n        _620 = _630.fa_shadow_split.x;\n    }\n    else\n    {\n        float _636;\n        if (i == 1)\n        {\n            _636 = _630.fa_shadow_split.y;\n        }\n        else\n        {\n            float _644;\n            if (i == 2)\n            {\n                _644 = _630.fa_shadow_split.z;\n            }\n            else\n            {\n                _644 = _630.fa_shadow_split.w;\n            }\n            _636 = _644;\n        }\n        _620 = _636;\n    }\n    return _620;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _677 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _681;\n    if (conv.x < 0.5)\n    {\n        _681 = _677;\n    }\n    else\n    {\n        _681 = (conv.y * conv.z) / (conv.z - (_677 * (conv.z - conv.y)));\n    }\n    return _681;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _608 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_608), sin(_608)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _727 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _741 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _727;\n            float2 _760 = fa_shadow_vogel(param_3, param_4, param_5) * _741;\n            float2 param_6 = uv + (_760 * _630.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _772 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_772 < (zr - (length(_760) * plane)))\n            {\n                sum += _772;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _816 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _816; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _816;\n        float param_11 = _727;\n        float2 _835 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_835 * _630.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_835) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_816);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex)\n{\n    float _877 = fast::max(_630.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _882 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _888 = sqrt(1.0 - (_882 * _882));\n    float _896 = fast::min(_888 / fast::max(_882, 0.20000000298023223876953125), 4.0);\n    float _901;\n    if (_630.fa_shadow_bias.y > 0.0)\n    {\n        _901 = _630.fa_shadow_bias.y;\n    }\n    else\n    {\n        _901 = 1.5 * _630.fa_shadow_info[ci].x;\n    }\n    float4 _926 = _630.fa_shadow_mat[ci] * float4(world + (n * (_901 * _888)), 1.0);\n    float _933 = _926.x;\n    bool _936 = _933 < _630.fa_shadow_rect[ci].x;\n    bool _945;\n    if (!_936)\n    {\n        _945 = _933 > _630.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _945 = _936;\n    }\n    bool _954;\n    if (!_945)\n    {\n        _954 = _926.y < _630.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _954 = _945;\n    }\n    bool _963;\n    if (!_954)\n    {\n        _963 = _926.y > _630.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _963 = _954;\n    }\n    bool _970;\n    if (!_963)\n    {\n        _970 = _926.z > 1.0;\n    }\n    else\n    {\n        _970 = _963;\n    }\n    if (_970)\n    {\n        return -1.0;\n    }\n    float _979;\n    if (_630.fa_shadow_bias.x > 0.0)\n    {\n        _979 = _630.fa_shadow_bias.x;\n    }\n    else\n    {\n        _979 = 1.5 * _630.fa_shadow_info[ci].x;\n    }\n    float2 param = _926.xy;\n    float4 param_1 = _630.fa_shadow_rect[ci];\n    float param_2 = _926.z - ((_979 * (1.0 + (0.5 * _896))) / _877);\n    float param_3 = _630.fa_shadow_info[ci].x;\n    float param_4 = _877;\n    float param_5 = _877 * 0.25;\n    float param_6 = ((_630.fa_shadow_info[ci].x * fast::min(_896, 3.0)) * 0.5) / _877;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_630.fa_shadow_cfg.z + 0.5);\n    float param_9 = _630.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _630, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex)\n{\n    if (_394.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1373 = int(_630.fa_shadow_cfg.x + 0.5);\n    if (_1373 < 1)\n    {\n        return 1.0;\n    }\n    float _1389 = dot(world - _630.fa_shadow_eye.xyz, _630.fa_shadow_fwd.xyz);\n    int param = _1373 - 1;\n    if (_1389 > fa_shadow_split_at(param, _630))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1401 = _1373 > 1;\n    bool _1408;\n    if (_1401)\n    {\n        _1408 = _1389 > _630.fa_shadow_split.x;\n    }\n    else\n    {\n        _1408 = _1401;\n    }\n    if (_1408)\n    {\n        ci = 1;\n    }\n    bool _1412 = _1373 > 2;\n    bool _1419;\n    if (_1412)\n    {\n        _1419 = _1389 > _630.fa_shadow_split.y;\n    }\n    else\n    {\n        _1419 = _1412;\n    }\n    if (_1419)\n    {\n        ci = 2;\n    }\n    bool _1423 = _1373 > 3;\n    bool _1430;\n    if (_1423)\n    {\n        _1430 = _1389 > _630.fa_shadow_split.z;\n    }\n    else\n    {\n        _1430 = _1423;\n    }\n    if (_1430)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1373)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1456 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _630, fa_shadow_tex);\n        s = _1456;\n        if (_1456 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_630.fa_shadow_cfg.y > 0.0)\n    {\n        float _1481;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1481 = fa_shadow_split_at(param_5, _630);\n        }\n        else\n        {\n            _1481 = _630.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1500 = _630.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _630) - _1481, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1511 = fast::clamp((_1389 - (fa_shadow_split_at(param_7, _630) - _1500)) / _1500, 0.0, 1.0);\n        if (_1511 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1373)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1532 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _630, fa_shadow_tex);\n                s2 = _1532;\n                if (_1532 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1511);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _394, gl_FragCoord, _630, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex)\n{\n    bool _1038 = _394.fa_pbr.z < 0.5;\n    bool _1046;\n    if (!_1038)\n    {\n        _1046 = _630.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1046 = _1038;\n    }\n    if (_1046)\n    {\n        return 1.0;\n    }\n    int param = (int(_630.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1059 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1060 = _1059.x;\n    if (_1060 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1069 = int(_1060 + 0.5);\n    int param_1 = _1069;\n    float4 _1073 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1069 + 1;\n    float4 _1078 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1081 = _1073.y;\n    if (_1081 > 0.0)\n    {\n        float _1098 = 1.0 - smoothstep(0.75 * _1081, _1081, length(world - _630.fa_shadow_eye.xyz));\n        fade = _1098;\n        if (_1098 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1073.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1117 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1120 = abs(_1117);\n        float _1122 = _1120.x;\n        float _1124 = _1120.y;\n        bool _1125 = _1122 >= _1124;\n        bool _1133;\n        if (_1125)\n        {\n            _1133 = _1122 >= _1120.z;\n        }\n        else\n        {\n            _1133 = _1125;\n        }\n        int _1134;\n        if (_1133)\n        {\n            _1134 = (_1117.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1147;\n            if (_1124 >= _1120.z)\n            {\n                _1147 = (_1117.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1147 = (_1117.z > 0.0) ? 4 : 5;\n            }\n            _1134 = _1147;\n        }\n        face = _1134;\n    }\n    int _1166 = (_1069 + 2) + (face * 6);\n    int param_4 = _1166;\n    int param_5 = _1166 + 1;\n    int param_6 = _1166 + 3;\n    float4 _1180 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1166 + 4;\n    float4 _1185 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1166 + 5;\n    float4 _1190 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1202 = _1190.x * fast::max(dot(_1180, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1207 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1213 = sqrt(1.0 - (_1207 * _1207));\n    float _1219 = fast::min(_1213 / fast::max(_1207, 0.20000000298023223876953125), 4.0);\n    float _1222 = _1078.y;\n    float _1224;\n    if (_1222 > 0.0)\n    {\n        _1224 = _1222;\n    }\n    else\n    {\n        _1224 = 1.5 * _1202;\n    }\n    float4 _1244 = float4(world + (n * (_1224 * _1213)), 1.0);\n    float _1248 = dot(_1180, _1244);\n    float _1251 = _1190.y;\n    if (_1248 < _1251)\n    {\n        return 1.0;\n    }\n    float2 _1266 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1244), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1244)) / float2(_1248);\n    float _1268 = _1266.x;\n    bool _1271 = _1268 < _1185.x;\n    bool _1280;\n    if (!_1271)\n    {\n        _1280 = _1268 > _1185.z;\n    }\n    else\n    {\n        _1280 = _1271;\n    }\n    bool _1289;\n    if (!_1280)\n    {\n        _1289 = _1266.y < _1185.y;\n    }\n    else\n    {\n        _1289 = _1280;\n    }\n    bool _1298;\n    if (!_1289)\n    {\n        _1298 = _1266.y > _1185.w;\n    }\n    else\n    {\n        _1298 = _1289;\n    }\n    if (_1298)\n    {\n        return 1.0;\n    }\n    float _1304 = _1078.x;\n    float _1306;\n    if (_1304 > 0.0)\n    {\n        _1306 = _1304;\n    }\n    else\n    {\n        _1306 = 1.5 * _1202;\n    }\n    float2 param_9 = _1266;\n    float4 param_10 = _1185;\n    float param_11 = _1248 - (_1306 * (1.0 + (0.5 * _1219)));\n    float param_12 = _1202;\n    float param_13 = 1.0;\n    float param_14 = _1190.z * 0.25;\n    float param_15 = (_1202 * fast::min(_1219, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _1251, _1190.z);\n    int param_17 = int(_1073.z + 0.5);\n    float param_18 = _1073.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _630, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _630, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1702 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2692 = _1702.direction;\n    float3 _2687 = _1702.color;\n    float _2694 = _1702.attenuation;\n    float _2689 = _1702.shadow;\n    int _2697 = _1702.type;\n    if ((_2697 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2692;\n        float _1716 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _394, gl_FragCoord, _630, fa_shadow_tex, fa_world_pos);\n        _2689 = _1716;\n        _2687 *= _1716;\n    }\n    else\n    {\n        bool _1727 = _2697 != 0;\n        bool _1733;\n        if (_1727)\n        {\n            _1733 = _2694 > 0.0;\n        }\n        else\n        {\n            _1733 = _1727;\n        }\n        if (_1733)\n        {\n            int param_4 = li;\n            float3 param_5 = world_pos;\n            float3 param_6 = gn;\n            float3 param_7 = _2692;\n            float _1745 = fa_shadow_local(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _394, gl_FragCoord, _630, fa_shadow_tex);\n            _2689 = _1745;\n            _2687 *= _1745;\n        }\n    }\n    return LightSample{ _2692, _2687, _2694, _2689, _1702._distance, _2697 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _630)\n{\n    if (_630.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1556 = int(_630.fa_shadow_cfg.x + 0.5);\n    float _1566 = dot(world - _630.fa_shadow_eye.xyz, _630.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1571 = _1556 > 0;\n    bool _1580;\n    if (_1571)\n    {\n        int param = _1556 - 1;\n        _1580 = _1566 <= fa_shadow_split_at(param, _630);\n    }\n    else\n    {\n        _1580 = _1571;\n    }\n    if (_1580)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1587 = _1556 > 1;\n        bool _1594;\n        if (_1587)\n        {\n            _1594 = _1566 > _630.fa_shadow_split.x;\n        }\n        else\n        {\n            _1594 = _1587;\n        }\n        if (_1594)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1600 = _1556 > 2;\n        bool _1607;\n        if (_1600)\n        {\n            _1607 = _1566 > _630.fa_shadow_split.y;\n        }\n        else\n        {\n            _1607 = _1600;\n        }\n        if (_1607)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1613 = _1556 > 3;\n        bool _1620;\n        if (_1613)\n        {\n            _1620 = _1566 > _630.fa_shadow_split.z;\n        }\n        else\n        {\n            _1620 = _1613;\n        }\n        if (_1620)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _394 [[buffer(1)]], constant fa_shadows& _630 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2516 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2516 = -_2516;\n    }\n    float3 _2129 = fast::normalize(_394.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _394, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2516, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2129, short(gl_FrontFacing) };\n    Surface _2137 = fa_standard_surface(param_1, _394, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2555 = _2137.albedo;\n    float _2556 = _2137.alpha;\n    float3 _2557 = _2137.normal;\n    float _2558 = _2137.metallic;\n    float _2559 = _2137.roughness;\n    float _2560 = _2137.occlusion;\n    float3 _2561 = _2137.emission;\n    float _2562 = _2137.clearcoat;\n    float _2563 = _2137.clearcoat_roughness;\n    float3 _2564 = _2137.sheen_color;\n    float _2565 = _2137.sheen_roughness;\n    float _2566 = _2137.anisotropy;\n    float _2567 = _2137.anisotropy_rotation;\n    float _2568 = _2137.specular;\n    float _2569 = _2137.ior;\n    float3 _2570 = _2137.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2516, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2129, short(gl_FrontFacing) };\n    Surface param_3 = _2137;\n    surface(param_2, param_3);\n    _2555 = param_3.albedo;\n    _2556 = param_3.alpha;\n    _2557 = param_3.normal;\n    _2558 = param_3.metallic;\n    _2559 = param_3.roughness;\n    _2560 = param_3.occlusion;\n    _2561 = param_3.emission;\n    _2562 = param_3.clearcoat;\n    _2563 = param_3.clearcoat_roughness;\n    _2564 = param_3.sheen_color;\n    _2565 = param_3.sheen_roughness;\n    _2566 = param_3.anisotropy;\n    _2567 = param_3.anisotropy_rotation;\n    _2568 = param_3.specular;\n    _2569 = param_3.ior;\n    _2570 = param_3.specular_color;\n    float3 result;\n    if (_394.fa_emissive.w > 0.5)\n    {\n        result = _2555;\n    }\n    else\n    {\n        float3 _2158 = _2557;\n        float3 _2159 = fast::normalize(_2158);\n        _2557 = _2159;\n        float3 param_4 = _2159;\n        SurfaceInput param_5 = SurfaceInput{ in.fa_world_pos, _2516, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2129, short(gl_FrontFacing) };\n        Surface param_6 = Surface{ _2555, _2556, _2557, _2558, _2559, _2560, _2561, _2562, _2563, _2564, _2565, _2566, _2567, _2568, _2569, _2570 };\n        float3 param_7 = fa_ambient_light(param_4, _394, fa_irr_tex, fa_env_smp);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _2178 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2178; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8, fa_light_tex, fa_shadow_smp, _394, fa_cl_ndir, fa_cl_slot);\n            float3 param_10 = in.fa_world_pos;\n            float3 param_11 = _2516;\n            SurfaceInput param_12 = SurfaceInput{ in.fa_world_pos, _2516, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2129, short(gl_FrontFacing) };\n            Surface param_13 = Surface{ _2555, _2556, _2557, _2558, _2559, _2560, _2561, _2562, _2563, _2564, _2565, _2566, _2567, _2568, _2569, _2570 };\n            LightSample param_14 = fa_light_shadowed(param_9, param_10, param_11, fa_light_tex, fa_shadow_smp, _394, gl_FragCoord, _630, fa_shadow_tex, in.fa_world_pos);\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    float3 _2215 = result;\n    float3 _2216 = _2215 + _2561;\n    result = _2216;\n    float3 param_15 = _2216;\n    float3 param_16 = in.fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16, _630);\n    bool _2225 = _394.fa_fog.w > 0.0;\n    bool _2232;\n    if (!_2225)\n    {\n        _2232 = _394.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2232 = _2225;\n    }\n    if (_2232)\n    {\n        float3 _2241 = in.fa_world_pos - _394.fa_camera_pos.xyz;\n        float _2247 = dot(_2241, _394.fa_fog_c.xyz);\n        bool _2251 = _394.fa_fog_c.w > 0.5;\n        float _2252;\n        if (_2251)\n        {\n            _2252 = _2247;\n        }\n        else\n        {\n            _2252 = length(_2241);\n        }\n        float _2264 = _2252 - _394.fa_fog_b.x;\n        if (_2264 > 0.0)\n        {\n            float _2273 = _394.fa_fog.w * _2264;\n            float tau = _2273 * _2273;\n            if (_394.fa_fog_b.y > 0.0)\n            {\n                float _2289;\n                if (_2251)\n                {\n                    _2289 = in.fa_world_pos.y - (_394.fa_fog_c.y * _2247);\n                }\n                else\n                {\n                    _2289 = _394.fa_camera_pos.y;\n                }\n                float _2310 = mix(_2289, in.fa_world_pos.y, fast::clamp(_394.fa_fog_b.x / _2252, 0.0, 1.0));\n                float _2314 = in.fa_world_pos.y - _2310;\n                float _2319 = _2310 - _394.fa_fog_b.z;\n                float _2324 = in.fa_world_pos.y - _394.fa_fog_b.z;\n                bool _2327 = _2319 <= 0.0;\n                bool _2328 = !_2327;\n                bool _2334;\n                if (_2328)\n                {\n                    _2334 = _394.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2334 = _2327;\n                }\n                float _2335;\n                if (_2334)\n                {\n                    _2335 = _394.fa_fog_b.y;\n                }\n                else\n                {\n                    _2335 = _394.fa_fog_b.y * exp(-fast::min(_394.fa_fog_b.w * _2319, 80.0));\n                }\n                bool _2362;\n                if (_2328)\n                {\n                    _2362 = _394.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2362 = _2327;\n                }\n                float _2363;\n                if (_2362)\n                {\n                    _2363 = _394.fa_fog_b.y * _2319;\n                }\n                else\n                {\n                    _2363 = (_394.fa_fog_b.y * (1.0 - exp(-fast::min(_394.fa_fog_b.w * _2319, 80.0)))) / _394.fa_fog_b.w;\n                }\n                bool _2388 = _2324 <= 0.0;\n                bool _2395;\n                if (!_2388)\n                {\n                    _2395 = _394.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2395 = _2388;\n                }\n                float _2396;\n                if (_2395)\n                {\n                    _2396 = _394.fa_fog_b.y * _2324;\n                }\n                else\n                {\n                    _2396 = (_394.fa_fog_b.y * (1.0 - exp(-fast::min(_394.fa_fog_b.w * _2324, 80.0)))) / _394.fa_fog_b.w;\n                }\n                float _2423;\n                if (abs(_2314) < 0.001000000047497451305389404296875)\n                {\n                    _2423 = _2335;\n                }\n                else\n                {\n                    _2423 = (_2396 - _2363) / _2314;\n                }\n                tau += (_2264 * fast::max(_2423, 0.0));\n            }\n            result = mix(result, _394.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2556);\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_394",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_630",
            "msl_buffer_n": 7
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 2
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 3
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 4
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          },
          {
            "texture": {
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "msl_texture_n": 6
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 7
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "msl_sampler_n": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 10
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    },
    "prepass": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    float4 _241 = (_783 * _213.fa_base_color) * i.vertex_color;\n    float3 _746 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = _213.fa_layers_a.x;\n    float _752 = _213.fa_layers_a.y;\n    float _755 = _213.fa_layers_a.z;\n    float _754 = _213.fa_layers_b.w;\n    float _757 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _746, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _751, _752, _213.fa_layers_b.xyz, _754, _755, _213.fa_layers_a.w, _757, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _657 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _657, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _657, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "msl_buffer_n": 1
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 1
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 2
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 3
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 4
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    float4 _241 = (_783 * _213.fa_base_color) * i.vertex_color;\n    float3 _746 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = _213.fa_layers_a.x;\n    float _752 = _213.fa_layers_a.y;\n    float _755 = _213.fa_layers_a.z;\n    float _754 = _213.fa_layers_b.w;\n    float _757 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _746, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _751, _752, _213.fa_layers_b.xyz, _754, _755, _213.fa_layers_a.w, _757, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _657 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _657, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _657, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "msl_buffer_n": 1
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 1
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 2
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 3
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 4
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          }
        ]
      }
    }
  }
}
