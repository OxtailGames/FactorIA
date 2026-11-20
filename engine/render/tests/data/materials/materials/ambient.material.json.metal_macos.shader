{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "bccfdbb53ee48b05b8dde63187158cf27ea0b93537445c8a05fdc4dbc713dc01",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_267, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _446)\n{\n    bool _451 = _446.fa_cl_info.x < 0.0;\n    bool _458;\n    if (!_451)\n    {\n        _458 = _446.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _458 = _451;\n    }\n    bool _466;\n    if (!_458)\n    {\n        _466 = _446.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _466 = _458;\n    }\n    bool _473;\n    if (!_466)\n    {\n        _473 = _446.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _473 = _466;\n    }\n    bool _480;\n    if (!_473)\n    {\n        _480 = _446.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _480 = _473;\n    }\n    if (_480)\n    {\n        return float4(0.0);\n    }\n    float4 _490 = float4(world_pos, 1.0);\n    float _497 = dot(_446.fa_cl_vpw, _490);\n    if (!(_497 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _519 = float2(dot(_446.fa_cl_vpx, _490), dot(_446.fa_cl_vpy, _490)) / float2(_497);\n    int _523 = int(_446.fa_cl_grid.x);\n    int _527 = int(_446.fa_cl_grid.y);\n    int param = (int(_446.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_446.fa_cl_fwd.xyz, world_pos) + _446.fa_cl_fwd.w, _446.fa_cl_grid.w) / _446.fa_cl_grid.w) * _446.fa_cl_grid.z)), 0, int(_446.fa_cl_info.y) - 1) * _527) + clamp(int(floor(((_519.y * 0.5) + 0.5) * _446.fa_cl_grid.y)), 0, _527 - 1)) * _523)) + clamp(int(floor(((_519.x * 0.5) + 0.5) * _446.fa_cl_grid.x)), 0, _523 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _446)\n{\n    float3 param = world_pos;\n    float4 _603 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _446);\n    return int2(int(_603.x), int(_603.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _446, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_446.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2260 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _446);\n    fa_cl_slot = _2260.x;\n    fa_cl_local = _2260.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2413 = fa_linear_to_srgb(param);\n        c = _2413;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2421 = fa_srgb_to_linear(param_1);\n            c = _2421;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _210;\n    if (bool(i.front_facing))\n    {\n        _210 = i.world_normal;\n    }\n    else\n    {\n        _210 = -i.world_normal;\n    }\n    float3 _234 = fast::normalize(i.world_tangent.xyz - (_210 * dot(_210, i.world_tangent.xyz)));\n    float3 _262 = fast::normalize(((_234 * m.x) + ((cross(_210, _234) * i.world_tangent.w) * m.y)) + (_210 * m.z));\n    float3 _265;\n    if (bool(i.front_facing))\n    {\n        _265 = _262;\n    }\n    else\n    {\n        _265 = -_262;\n    }\n    return _265;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _446, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _446.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2452 = fa_tex_fix(param_2, param_3);\n    float4 _3489 = base_t;\n    _3489.x = _2452.x;\n    _3489.y = _2452.y;\n    _3489.z = _2452.z;\n    base_t = _3489;\n    float4 _2466 = (_3489 * _446.fa_base_color) * i.vertex_color;\n    float3 _3369 = i.world_normal;\n    if (_446.fa_maps.z > 0.5)\n    {\n        float param_4 = _446.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2498 = fa_tex_fix(param_6, param_7);\n        float3 _2501 = (_2498 * 2.0) - float3(1.0);\n        float2 _2506 = _2501.xy * _446.fa_maps.x;\n        float3 _3497 = _2501;\n        _3497.x = _2506.x;\n        _3497.y = _2506.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3497;\n        _3369 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _446.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2535 = fa_tex_fix(param_12, param_13);\n    float4 _3500 = mrt;\n    _3500.x = _2535.x;\n    _3500.y = _2535.y;\n    _3500.z = _2535.z;\n    mrt = _3500;\n    float4 _2563 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _446.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2563.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2575 = fa_tex_fix(param_16, param_17);\n    float param_18 = _446.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2605 = fa_tex_fix(param_20, param_21);\n    float _3374 = _446.fa_layers_a.x;\n    float _3375 = _446.fa_layers_a.y;\n    float _3378 = _446.fa_layers_a.z;\n    float _3377 = _446.fa_layers_b.w;\n    float _3380 = _446.fa_layers_c.x;\n    if (_446.fa_layers_c.z > 0.5)\n    {\n        if (mod(_446.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3374 *= _2575.y;\n            _3375 *= _2575.z;\n            _3377 *= _2563.w;\n        }\n        if (_446.fa_layers_c.z > 1.5)\n        {\n            _3378 *= mrt.x;\n            _3380 *= mrt.w;\n        }\n    }\n    return Surface{ _2466.xyz, _2466.w, _3369, fast::clamp(_446.fa_pbr.x * _2535.z, 0.0, 1.0), fast::clamp(_446.fa_pbr.y * _2535.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_446.fa_maps.y * (_2575.x - 1.0)), _446.fa_emissive.xyz + (_446.fa_model_emissive.xyz * _2605), _3374, _3375, _446.fa_layers_b.xyz, _3377, _3378, _446.fa_layers_a.w, _3380, _446.fa_layers_c.y, _446.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _684 = rect.zw - rect.xy;\n    float2 _688 = _684 * atlas;\n    float2 _692 = ddx * _688;\n    float2 _696 = ddy * _688;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _684)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_692, _692), dot(_696, _696)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _446, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _731 = _446.fa_counts.y < 0.5;\n    bool _738;\n    if (!_731)\n    {\n        _738 = _446.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _738 = _731;\n    }\n    if (_738)\n    {\n        return;\n    }\n    float3 _744 = dfdx(world_pos);\n    float3 _747 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _751 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _446);\n    int _755 = int(_751.w);\n    if (_755 < 1)\n    {\n        return;\n    }\n    int _765 = int(_446.fa_counts.y + 0.5);\n    int param_1 = _765;\n    float4 _769 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _772 = _769.yz;\n    int _776 = int(_769.w);\n    int param_2 = _765 + 1;\n    float4 _781 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _782 = _781.x;\n    int _788 = int(_446.fa_counts.w + 0.5) - 1;\n    int _792 = int(_751.z);\n    float3 _1058;\n    for (int k = 0; k < _755; k++)\n    {\n        int _805 = _792 + k;\n        int param_3 = _776 + (_805 >> 2);\n        int _823 = (_765 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_805 & 3]) * 7);\n        int param_4 = _823 + 6;\n        float4 _828 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_828.w + 0.5) >> _788) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _823;\n        float4 _843 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _823 + 1;\n        float4 _848 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _823 + 2;\n        float4 _853 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _856 = _843.xyz;\n        float _861 = dot(_856, world_pos) + _843.w;\n        float3 _863 = _848.xyz;\n        float _868 = dot(_863, world_pos) + _848.w;\n        float3 _870 = _853.xyz;\n        float _875 = dot(_870, world_pos) + _853.w;\n        bool _880 = abs(_861) > 0.5;\n        bool _888;\n        if (!_880)\n        {\n            _888 = abs(_868) > 0.5;\n        }\n        else\n        {\n            _888 = _880;\n        }\n        bool _896;\n        if (!_888)\n        {\n            _896 = abs(_875) > 0.5;\n        }\n        else\n        {\n            _896 = _888;\n        }\n        if (_896)\n        {\n            continue;\n        }\n        float _911 = fast::clamp(dot(geo_normal, fast::normalize(_870)) * _828.z, 0.0, 1.0);\n        if (_911 <= 0.0)\n        {\n            continue;\n        }\n        float _931 = (fast::clamp((0.5 - abs(_875)) * 10.0, 0.0, 1.0) * _911) * _828.x;\n        float2 _939 = float2(_861 + 0.5, 0.5 - _868);\n        float2 _949 = float2(dot(_856, _744), dot(_863, _744));\n        float2 _959 = float2(dot(_856, _747), dot(_863, _747));\n        int param_8 = _823 + 5;\n        float4 _964 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _823 + 3;\n        float4 _969 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _823 + 4;\n        float4 _974 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _964.xyz;\n        bool _984 = _969.z > _969.x;\n        if (_984)\n        {\n            float4 param_11 = _969;\n            float2 param_12 = _939;\n            float2 param_13 = _772;\n            float2 param_14 = _949;\n            float2 param_15 = _959;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_782 > 0.5) && (_782 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1010 = fa_dc_to_linear(param_16);\n                float4 _3425 = tx;\n                _3425.x = _1010.x;\n                _3425.y = _1010.y;\n                _3425.z = _1010.z;\n                tx = _3425;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_931 * tex_a) * _964.w, 0.0, 1.0)));\n        if (_974.z > _974.x)\n        {\n            float4 param_17 = _974;\n            float2 param_18 = _939;\n            float2 param_19 = _772;\n            float2 param_20 = _949;\n            float2 param_21 = _959;\n            float4 _1054 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_782 > 1.5)\n            {\n                float3 param_22 = _1054.xyz;\n                float3 _1064 = fa_dc_to_srgb(param_22);\n                _1058 = _1064;\n            }\n            else\n            {\n                _1058 = _1054.xyz;\n            }\n            float3 _1074 = (_1058 * 2.0) - float3(1.0);\n            float2 _1079 = _1074.xy * _828.y;\n            float3 _1101 = (fast::normalize(_856) * _1079.x) + (fast::normalize(_863) * _1079.y);\n            float3 _1104 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1104, fast::normalize((_1104 * fast::max(_1074.z, 0.0500000007450580596923828125)) + (_1101 - (_1104 * dot(_1104, _1101)))), float3(fast::clamp(_931 * (_984 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _446, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_446.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _446.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _446, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _446, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return float3(0.0, ambientColor.y, 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _446)\n{\n    int param = (int(_446.fa_cl_info.x) + int(_446.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _446, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _446);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _321 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _327 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _330 = _327.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _336 = _330 < 0.5;\n    float3 l;\n    if (_336)\n    {\n        l = fast::normalize(_321.xyz);\n    }\n    else\n    {\n        float3 _348 = _321.xyz - world_pos;\n        float _350 = length(_348);\n        dist = _350;\n        l = _348 / float3(fast::max(_350, 9.9999997473787516355514526367188e-05));\n        float _365 = _350 / fast::max(_321.w, 0.001000000047497451305389404296875);\n        float _371 = fast::clamp(1.0 - (_365 * _365), 0.0, 1.0);\n        atten = _371 * _371;\n        if (_330 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _385 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _395 = _385.w;\n            int param_3 = (li * 4) + 3;\n            float4 _401 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _402 = _401.x;\n            float cos_inner = _402;\n            if (_402 > 1.5)\n            {\n                cos_inner = mix(_395, 1.0, 0.25);\n            }\n            atten *= smoothstep(_395, cos_inner, dot(-l, fast::normalize(_385.xyz)));\n        }\n    }\n    int _432;\n    if (_336)\n    {\n        _432 = 0;\n    }\n    else\n    {\n        _432 = (_330 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _327.xyz * atten, atten, 1.0, dist, _432 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1186)\n{\n    float _1176;\n    if (i == 0)\n    {\n        _1176 = _1186.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1192;\n        if (i == 1)\n        {\n            _1192 = _1186.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1200;\n            if (i == 2)\n            {\n                _1200 = _1186.fa_shadow_split.z;\n            }\n            else\n            {\n                _1200 = _1186.fa_shadow_split.w;\n            }\n            _1192 = _1200;\n        }\n        _1176 = _1192;\n    }\n    return _1176;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1233 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1237;\n    if (conv.x < 0.5)\n    {\n        _1237 = _1233;\n    }\n    else\n    {\n        _1237 = (conv.y * conv.z) / (conv.z - (_1233 * (conv.z - conv.y)));\n    }\n    return _1237;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1164 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1164), sin(_1164)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1186, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1283 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1297 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1283;\n            float2 _1316 = fa_shadow_vogel(param_3, param_4, param_5) * _1297;\n            float2 param_6 = uv + (_1316 * _1186.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1328 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1328 < (zr - (length(_1316) * plane)))\n            {\n                sum += _1328;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1372 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1372; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1372;\n        float param_11 = _1283;\n        float2 _1391 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1391 * _1186.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1391) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1372);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1186, texture2d<float> fa_shadow_tex)\n{\n    float _1433 = fast::max(_1186.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1438 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1444 = sqrt(1.0 - (_1438 * _1438));\n    float _1451 = fast::min(_1444 / fast::max(_1438, 0.20000000298023223876953125), 4.0);\n    float _1456;\n    if (_1186.fa_shadow_bias.y > 0.0)\n    {\n        _1456 = _1186.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1456 = 1.5 * _1186.fa_shadow_info[ci].x;\n    }\n    float4 _1481 = _1186.fa_shadow_mat[ci] * float4(world + (n * (_1456 * _1444)), 1.0);\n    float _1488 = _1481.x;\n    bool _1491 = _1488 < _1186.fa_shadow_rect[ci].x;\n    bool _1500;\n    if (!_1491)\n    {\n        _1500 = _1488 > _1186.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1500 = _1491;\n    }\n    bool _1509;\n    if (!_1500)\n    {\n        _1509 = _1481.y < _1186.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1509 = _1500;\n    }\n    bool _1518;\n    if (!_1509)\n    {\n        _1518 = _1481.y > _1186.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1518 = _1509;\n    }\n    bool _1525;\n    if (!_1518)\n    {\n        _1525 = _1481.z > 1.0;\n    }\n    else\n    {\n        _1525 = _1518;\n    }\n    if (_1525)\n    {\n        return -1.0;\n    }\n    float _1534;\n    if (_1186.fa_shadow_bias.x > 0.0)\n    {\n        _1534 = _1186.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1534 = 1.5 * _1186.fa_shadow_info[ci].x;\n    }\n    float2 param = _1481.xy;\n    float4 param_1 = _1186.fa_shadow_rect[ci];\n    float param_2 = _1481.z - ((_1534 * (1.0 + (0.5 * _1451))) / _1433);\n    float param_3 = _1186.fa_shadow_info[ci].x;\n    float param_4 = _1433;\n    float param_5 = _1433 * 0.25;\n    float param_6 = ((_1186.fa_shadow_info[ci].x * fast::min(_1451, 3.0)) * 0.5) / _1433;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1186.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1186.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1186, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _446, thread float4& gl_FragCoord, constant fa_shadows& _1186, texture2d<float> fa_shadow_tex)\n{\n    if (_446.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1961 = int(_1186.fa_shadow_cfg.x + 0.5);\n    if (_1961 < 1)\n    {\n        return 1.0;\n    }\n    float _1976 = dot(world - _1186.fa_shadow_eye.xyz, _1186.fa_shadow_fwd.xyz);\n    int param = _1961 - 1;\n    if (_1976 > fa_shadow_split_at(param, _1186))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1988 = _1961 > 1;\n    bool _1995;\n    if (_1988)\n    {\n        _1995 = _1976 > _1186.fa_shadow_split.x;\n    }\n    else\n    {\n        _1995 = _1988;\n    }\n    if (_1995)\n    {\n        ci = 1;\n    }\n    bool _1999 = _1961 > 2;\n    bool _2006;\n    if (_1999)\n    {\n        _2006 = _1976 > _1186.fa_shadow_split.y;\n    }\n    else\n    {\n        _2006 = _1999;\n    }\n    if (_2006)\n    {\n        ci = 2;\n    }\n    bool _2010 = _1961 > 3;\n    bool _2017;\n    if (_2010)\n    {\n        _2017 = _1976 > _1186.fa_shadow_split.z;\n    }\n    else\n    {\n        _2017 = _2010;\n    }\n    if (_2017)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1961)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2043 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1186, fa_shadow_tex);\n        s = _2043;\n        if (_2043 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1186.fa_shadow_cfg.y > 0.0)\n    {\n        float _2068;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2068 = fa_shadow_split_at(param_5, _1186);\n        }\n        else\n        {\n            _2068 = _1186.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2087 = _1186.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1186) - _2068, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2098 = fast::clamp((_1976 - (fa_shadow_split_at(param_7, _1186) - _2087)) / _2087, 0.0, 1.0);\n        if (_2098 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1961)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2119 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1186, fa_shadow_tex);\n                s2 = _2119;\n                if (_2119 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2098);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _446, thread float4& gl_FragCoord, constant fa_shadows& _1186, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _446, gl_FragCoord, _1186, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _446, thread float4& gl_FragCoord, constant fa_shadows& _1186, texture2d<float> fa_shadow_tex)\n{\n    bool _1592 = _446.fa_pbr.z < 0.5;\n    bool _1600;\n    if (!_1592)\n    {\n        _1600 = _1186.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1600 = _1592;\n    }\n    if (_1600)\n    {\n        return 1.0;\n    }\n    int param = (int(_1186.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1613 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1614 = _1613.x;\n    if (_1614 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1623 = int(_1614 + 0.5);\n    int param_1 = _1623;\n    float4 _1627 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1623 + 1;\n    float4 _1632 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1635 = _1627.y;\n    if (_1635 > 0.0)\n    {\n        float _1652 = 1.0 - smoothstep(0.75 * _1635, _1635, length(world - _1186.fa_shadow_eye.xyz));\n        fade = _1652;\n        if (_1652 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1627.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1671 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1674 = abs(_1671);\n        float _1676 = _1674.x;\n        float _1678 = _1674.y;\n        bool _1679 = _1676 >= _1678;\n        bool _1687;\n        if (_1679)\n        {\n            _1687 = _1676 >= _1674.z;\n        }\n        else\n        {\n            _1687 = _1679;\n        }\n        int _1688;\n        if (_1687)\n        {\n            _1688 = (_1671.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1701;\n            if (_1678 >= _1674.z)\n            {\n                _1701 = (_1671.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1701 = (_1671.z > 0.0) ? 4 : 5;\n            }\n            _1688 = _1701;\n        }\n        face = _1688;\n    }\n    int _1720 = (_1623 + 2) + (face * 6);\n    int param_4 = _1720;\n    int param_5 = _1720 + 1;\n    int param_6 = _1720 + 3;\n    float4 _1734 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1720 + 4;\n    float4 _1739 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1720 + 5;\n    float4 _1744 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1756 = _1744.x * fast::max(dot(_1734, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1761 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1784 = fast::clamp(dot(n, _1734.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1807 = fast::min(sqrt(1.0 - (_1784 * _1784)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1734, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1810 = _1632.y;\n    float _1812;\n    if (_1810 > 0.0)\n    {\n        _1812 = _1810;\n    }\n    else\n    {\n        _1812 = 1.5 * _1756;\n    }\n    float4 _1832 = float4(world + (n * (_1812 * sqrt(1.0 - (_1761 * _1761)))), 1.0);\n    float _1836 = dot(_1734, _1832);\n    float _1839 = _1744.y;\n    if (_1836 < _1839)\n    {\n        return 1.0;\n    }\n    float2 _1854 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1832), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1832)) / float2(_1836);\n    float _1856 = _1854.x;\n    bool _1859 = _1856 < _1739.x;\n    bool _1868;\n    if (!_1859)\n    {\n        _1868 = _1856 > _1739.z;\n    }\n    else\n    {\n        _1868 = _1859;\n    }\n    bool _1877;\n    if (!_1868)\n    {\n        _1877 = _1854.y < _1739.y;\n    }\n    else\n    {\n        _1877 = _1868;\n    }\n    bool _1886;\n    if (!_1877)\n    {\n        _1886 = _1854.y > _1739.w;\n    }\n    else\n    {\n        _1886 = _1877;\n    }\n    if (_1886)\n    {\n        return 1.0;\n    }\n    float _1892 = _1632.x;\n    float _1894;\n    if (_1892 > 0.0)\n    {\n        _1894 = _1892;\n    }\n    else\n    {\n        _1894 = 1.5 * _1756;\n    }\n    float2 param_10 = _1854;\n    float4 param_11 = _1739;\n    float param_12 = _1836 - (_1894 * (1.0 + (0.5 * _1807)));\n    float param_13 = _1756;\n    float param_14 = 1.0;\n    float param_15 = _1744.z * 0.25;\n    float param_16 = (_1756 * fast::min(_1807, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1839, _1744.z);\n    int param_18 = int(_1627.z + 0.5);\n    float param_19 = _1627.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1186, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _446, thread float4& gl_FragCoord, constant fa_shadows& _1186, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _2287 = fa_lm.z > 0.5;\n    bool _2293;\n    if (_2287)\n    {\n        int param = li;\n        _2293 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2293 = _2287;\n    }\n    if (_2293)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2316 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _3354 = _2316.direction;\n    float3 _3349 = _2316.color;\n    float _3356 = _2316.attenuation;\n    float _3351 = _2316.shadow;\n    int _3359 = _2316.type;\n    if ((_3359 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3354;\n        float _2330 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _446, gl_FragCoord, _1186, fa_shadow_tex, fa_world_pos);\n        _3351 = _2330;\n        _3349 *= _2330;\n    }\n    else\n    {\n        bool _2341 = _3359 != 0;\n        bool _2347;\n        if (_2341)\n        {\n            _2347 = _3356 > 0.0;\n        }\n        else\n        {\n            _2347 = _2341;\n        }\n        if (_2347)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3354;\n            float _2359 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _446, gl_FragCoord, _1186, fa_shadow_tex);\n            _3351 = _2359;\n            _3349 *= _2359;\n        }\n    }\n    return LightSample{ _3354, _3349, _3356, _3351, _2316._distance, _3359 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1186)\n{\n    if (_1186.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2143 = int(_1186.fa_shadow_cfg.x + 0.5);\n    float _2153 = dot(world - _1186.fa_shadow_eye.xyz, _1186.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2158 = _2143 > 0;\n    bool _2167;\n    if (_2158)\n    {\n        int param = _2143 - 1;\n        _2167 = _2153 <= fa_shadow_split_at(param, _1186);\n    }\n    else\n    {\n        _2167 = _2158;\n    }\n    if (_2167)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2174 = _2143 > 1;\n        bool _2181;\n        if (_2174)\n        {\n            _2181 = _2153 > _1186.fa_shadow_split.x;\n        }\n        else\n        {\n            _2181 = _2174;\n        }\n        if (_2181)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2187 = _2143 > 2;\n        bool _2194;\n        if (_2187)\n        {\n            _2194 = _2153 > _1186.fa_shadow_split.y;\n        }\n        else\n        {\n            _2194 = _2187;\n        }\n        if (_2194)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2200 = _2143 > 3;\n        bool _2207;\n        if (_2200)\n        {\n            _2207 = _2153 > _1186.fa_shadow_split.z;\n        }\n        else\n        {\n            _2207 = _2200;\n        }\n        if (_2207)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _446 [[buffer(1)]], constant fa_shadows& _1186 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3165 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3165 = -_3165;\n    }\n    float3 _2749 = fast::normalize(_446.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _446, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3165, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2749, short(gl_FrontFacing) };\n    Surface _2757 = fa_standard_surface(param_1, _446, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3204 = _2757.albedo;\n    float _3205 = _2757.alpha;\n    float3 _3206 = _2757.normal;\n    float _3207 = _2757.metallic;\n    float _3208 = _2757.roughness;\n    float _3209 = _2757.occlusion;\n    float3 _3210 = _2757.emission;\n    float _3211 = _2757.clearcoat;\n    float _3212 = _2757.clearcoat_roughness;\n    float3 _3213 = _2757.sheen_color;\n    float _3214 = _2757.sheen_roughness;\n    float _3215 = _2757.anisotropy;\n    float _3216 = _2757.anisotropy_rotation;\n    float _3217 = _2757.specular;\n    float _3218 = _2757.ior;\n    float3 _3219 = _2757.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3165, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2749, short(gl_FrontFacing) };\n    Surface param_3 = _2757;\n    surface(param_2, param_3);\n    _3204 = param_3.albedo;\n    _3205 = param_3.alpha;\n    _3206 = param_3.normal;\n    _3207 = param_3.metallic;\n    _3208 = param_3.roughness;\n    _3209 = param_3.occlusion;\n    _3210 = param_3.emission;\n    _3211 = param_3.clearcoat;\n    _3212 = param_3.clearcoat_roughness;\n    _3213 = param_3.sheen_color;\n    _3214 = param_3.sheen_roughness;\n    _3215 = param_3.anisotropy;\n    _3216 = param_3.anisotropy_rotation;\n    _3217 = param_3.specular;\n    _3218 = param_3.ior;\n    _3219 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _3165;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _446, fa_decal_tex, fa_env_smp);\n    _3204 = param_6;\n    _3206 = param_7;\n    float3 result;\n    if (_446.fa_emissive.w > 0.5)\n    {\n        result = _3204;\n    }\n    else\n    {\n        float3 _2795 = _3206;\n        float3 _2796 = fast::normalize(_2795);\n        _3206 = _2796;\n        float3 param_8 = _2796;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _3165, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2749, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _3204, _3205, _3206, _3207, _3208, _3209, _3210, _3211, _3212, _3213, _3214, _3215, _3216, _3217, _3218, _3219 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _446, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _2815 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2815; ln++)\n        {\n            int param_12 = ln;\n            int _2828 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _446, fa_cl_ndir, fa_cl_slot);\n            bool _2831 = in.fa_lm.z > 0.5;\n            bool _2837;\n            if (_2831)\n            {\n                int param_13 = _2828;\n                _2837 = fa_light_baked(param_13, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _2837 = _2831;\n            }\n            if (_2837)\n            {\n                continue;\n            }\n            int param_14 = _2828;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _3165;\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _3165, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2749, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _3204, _3205, _3206, _3207, _3208, _3209, _3210, _3211, _3212, _3213, _3214, _3215, _3216, _3217, _3218, _3219 };\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16, fa_light_tex, fa_shadow_smp, _446, gl_FragCoord, _1186, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _2864 = result;\n    float3 _2865 = _2864 + _3210;\n    result = _2865;\n    float3 param_20 = _2865;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _1186);\n    bool _2874 = _446.fa_fog.w > 0.0;\n    bool _2881;\n    if (!_2874)\n    {\n        _2881 = _446.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2881 = _2874;\n    }\n    if (_2881)\n    {\n        float3 _2890 = in.fa_world_pos - _446.fa_camera_pos.xyz;\n        float _2896 = dot(_2890, _446.fa_fog_c.xyz);\n        bool _2900 = _446.fa_fog_c.w > 0.5;\n        float _2901;\n        if (_2900)\n        {\n            _2901 = _2896;\n        }\n        else\n        {\n            _2901 = length(_2890);\n        }\n        float _2913 = _2901 - _446.fa_fog_b.x;\n        if (_2913 > 0.0)\n        {\n            float _2922 = _446.fa_fog.w * _2913;\n            float tau = _2922 * _2922;\n            if (_446.fa_fog_b.y > 0.0)\n            {\n                float _2938;\n                if (_2900)\n                {\n                    _2938 = in.fa_world_pos.y - (_446.fa_fog_c.y * _2896);\n                }\n                else\n                {\n                    _2938 = _446.fa_camera_pos.y;\n                }\n                float _2959 = mix(_2938, in.fa_world_pos.y, fast::clamp(_446.fa_fog_b.x / _2901, 0.0, 1.0));\n                float _2963 = in.fa_world_pos.y - _2959;\n                float _2968 = _2959 - _446.fa_fog_b.z;\n                float _2973 = in.fa_world_pos.y - _446.fa_fog_b.z;\n                bool _2976 = _2968 <= 0.0;\n                bool _2977 = !_2976;\n                bool _2983;\n                if (_2977)\n                {\n                    _2983 = _446.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2983 = _2976;\n                }\n                float _2984;\n                if (_2983)\n                {\n                    _2984 = _446.fa_fog_b.y;\n                }\n                else\n                {\n                    _2984 = _446.fa_fog_b.y * exp(-fast::min(_446.fa_fog_b.w * _2968, 80.0));\n                }\n                bool _3011;\n                if (_2977)\n                {\n                    _3011 = _446.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3011 = _2976;\n                }\n                float _3012;\n                if (_3011)\n                {\n                    _3012 = _446.fa_fog_b.y * _2968;\n                }\n                else\n                {\n                    _3012 = (_446.fa_fog_b.y * (1.0 - exp(-fast::min(_446.fa_fog_b.w * _2968, 80.0)))) / _446.fa_fog_b.w;\n                }\n                bool _3037 = _2973 <= 0.0;\n                bool _3044;\n                if (!_3037)\n                {\n                    _3044 = _446.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3044 = _3037;\n                }\n                float _3045;\n                if (_3044)\n                {\n                    _3045 = _446.fa_fog_b.y * _2973;\n                }\n                else\n                {\n                    _3045 = (_446.fa_fog_b.y * (1.0 - exp(-fast::min(_446.fa_fog_b.w * _2973, 80.0)))) / _446.fa_fog_b.w;\n                }\n                float _3072;\n                if (abs(_2963) < 0.001000000047497451305389404296875)\n                {\n                    _3072 = _2984;\n                }\n                else\n                {\n                    _3072 = (_3045 - _3012) / _2963;\n                }\n                tau += (_2913 * fast::max(_3072, 0.0));\n            }\n            result = mix(result, _446.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3205);\n    return out;\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_446",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1186",
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
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 8
            }
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 9
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
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 9,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_388, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _446)\n{\n    bool _451 = _446.fa_cl_info.x < 0.0;\n    bool _458;\n    if (!_451)\n    {\n        _458 = _446.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _458 = _451;\n    }\n    bool _466;\n    if (!_458)\n    {\n        _466 = _446.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _466 = _458;\n    }\n    bool _473;\n    if (!_466)\n    {\n        _473 = _446.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _473 = _466;\n    }\n    bool _480;\n    if (!_473)\n    {\n        _480 = _446.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _480 = _473;\n    }\n    if (_480)\n    {\n        return float4(0.0);\n    }\n    float4 _490 = float4(world_pos, 1.0);\n    float _497 = dot(_446.fa_cl_vpw, _490);\n    if (!(_497 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _519 = float2(dot(_446.fa_cl_vpx, _490), dot(_446.fa_cl_vpy, _490)) / float2(_497);\n    int _523 = int(_446.fa_cl_grid.x);\n    int _527 = int(_446.fa_cl_grid.y);\n    int param = (int(_446.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_446.fa_cl_fwd.xyz, world_pos) + _446.fa_cl_fwd.w, _446.fa_cl_grid.w) / _446.fa_cl_grid.w) * _446.fa_cl_grid.z)), 0, int(_446.fa_cl_info.y) - 1) * _527) + clamp(int(floor(((_519.y * 0.5) + 0.5) * _446.fa_cl_grid.y)), 0, _527 - 1)) * _523)) + clamp(int(floor(((_519.x * 0.5) + 0.5) * _446.fa_cl_grid.x)), 0, _523 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _446)\n{\n    float3 param = world_pos;\n    float4 _603 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _446);\n    return int2(int(_603.x), int(_603.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _446, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_446.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2260 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _446);\n    fa_cl_slot = _2260.x;\n    fa_cl_local = _2260.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2413 = fa_linear_to_srgb(param);\n        c = _2413;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2421 = fa_srgb_to_linear(param_1);\n            c = _2421;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _210;\n    if (bool(i.front_facing))\n    {\n        _210 = i.world_normal;\n    }\n    else\n    {\n        _210 = -i.world_normal;\n    }\n    float3 _234 = fast::normalize(i.world_tangent.xyz - (_210 * dot(_210, i.world_tangent.xyz)));\n    float3 _262 = fast::normalize(((_234 * m.x) + ((cross(_210, _234) * i.world_tangent.w) * m.y)) + (_210 * m.z));\n    float3 _265;\n    if (bool(i.front_facing))\n    {\n        _265 = _262;\n    }\n    else\n    {\n        _265 = -_262;\n    }\n    return _265;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _446, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _446.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2452 = fa_tex_fix(param_2, param_3);\n    float4 _3489 = base_t;\n    _3489.x = _2452.x;\n    _3489.y = _2452.y;\n    _3489.z = _2452.z;\n    base_t = _3489;\n    float4 _2466 = (_3489 * _446.fa_base_color) * i.vertex_color;\n    float3 _3369 = i.world_normal;\n    if (_446.fa_maps.z > 0.5)\n    {\n        float param_4 = _446.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2498 = fa_tex_fix(param_6, param_7);\n        float3 _2501 = (_2498 * 2.0) - float3(1.0);\n        float2 _2506 = _2501.xy * _446.fa_maps.x;\n        float3 _3497 = _2501;\n        _3497.x = _2506.x;\n        _3497.y = _2506.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3497;\n        _3369 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _446.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2535 = fa_tex_fix(param_12, param_13);\n    float4 _3500 = mrt;\n    _3500.x = _2535.x;\n    _3500.y = _2535.y;\n    _3500.z = _2535.z;\n    mrt = _3500;\n    float4 _2563 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _446.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2563.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2575 = fa_tex_fix(param_16, param_17);\n    float param_18 = _446.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2605 = fa_tex_fix(param_20, param_21);\n    float _3374 = _446.fa_layers_a.x;\n    float _3375 = _446.fa_layers_a.y;\n    float _3378 = _446.fa_layers_a.z;\n    float _3377 = _446.fa_layers_b.w;\n    float _3380 = _446.fa_layers_c.x;\n    if (_446.fa_layers_c.z > 0.5)\n    {\n        if (mod(_446.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3374 *= _2575.y;\n            _3375 *= _2575.z;\n            _3377 *= _2563.w;\n        }\n        if (_446.fa_layers_c.z > 1.5)\n        {\n            _3378 *= mrt.x;\n            _3380 *= mrt.w;\n        }\n    }\n    return Surface{ _2466.xyz, _2466.w, _3369, fast::clamp(_446.fa_pbr.x * _2535.z, 0.0, 1.0), fast::clamp(_446.fa_pbr.y * _2535.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_446.fa_maps.y * (_2575.x - 1.0)), _446.fa_emissive.xyz + (_446.fa_model_emissive.xyz * _2605), _3374, _3375, _446.fa_layers_b.xyz, _3377, _3378, _446.fa_layers_a.w, _3380, _446.fa_layers_c.y, _446.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _684 = rect.zw - rect.xy;\n    float2 _688 = _684 * atlas;\n    float2 _692 = ddx * _688;\n    float2 _696 = ddy * _688;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _684)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_692, _692), dot(_696, _696)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _446, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _731 = _446.fa_counts.y < 0.5;\n    bool _738;\n    if (!_731)\n    {\n        _738 = _446.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _738 = _731;\n    }\n    if (_738)\n    {\n        return;\n    }\n    float3 _744 = dfdx(world_pos);\n    float3 _747 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _751 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _446);\n    int _755 = int(_751.w);\n    if (_755 < 1)\n    {\n        return;\n    }\n    int _765 = int(_446.fa_counts.y + 0.5);\n    int param_1 = _765;\n    float4 _769 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _772 = _769.yz;\n    int _776 = int(_769.w);\n    int param_2 = _765 + 1;\n    float4 _781 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _782 = _781.x;\n    int _788 = int(_446.fa_counts.w + 0.5) - 1;\n    int _792 = int(_751.z);\n    float3 _1058;\n    for (int k = 0; k < _755; k++)\n    {\n        int _805 = _792 + k;\n        int param_3 = _776 + (_805 >> 2);\n        int _823 = (_765 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_805 & 3]) * 7);\n        int param_4 = _823 + 6;\n        float4 _828 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_828.w + 0.5) >> _788) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _823;\n        float4 _843 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _823 + 1;\n        float4 _848 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _823 + 2;\n        float4 _853 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _856 = _843.xyz;\n        float _861 = dot(_856, world_pos) + _843.w;\n        float3 _863 = _848.xyz;\n        float _868 = dot(_863, world_pos) + _848.w;\n        float3 _870 = _853.xyz;\n        float _875 = dot(_870, world_pos) + _853.w;\n        bool _880 = abs(_861) > 0.5;\n        bool _888;\n        if (!_880)\n        {\n            _888 = abs(_868) > 0.5;\n        }\n        else\n        {\n            _888 = _880;\n        }\n        bool _896;\n        if (!_888)\n        {\n            _896 = abs(_875) > 0.5;\n        }\n        else\n        {\n            _896 = _888;\n        }\n        if (_896)\n        {\n            continue;\n        }\n        float _911 = fast::clamp(dot(geo_normal, fast::normalize(_870)) * _828.z, 0.0, 1.0);\n        if (_911 <= 0.0)\n        {\n            continue;\n        }\n        float _931 = (fast::clamp((0.5 - abs(_875)) * 10.0, 0.0, 1.0) * _911) * _828.x;\n        float2 _939 = float2(_861 + 0.5, 0.5 - _868);\n        float2 _949 = float2(dot(_856, _744), dot(_863, _744));\n        float2 _959 = float2(dot(_856, _747), dot(_863, _747));\n        int param_8 = _823 + 5;\n        float4 _964 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _823 + 3;\n        float4 _969 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _823 + 4;\n        float4 _974 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _964.xyz;\n        bool _984 = _969.z > _969.x;\n        if (_984)\n        {\n            float4 param_11 = _969;\n            float2 param_12 = _939;\n            float2 param_13 = _772;\n            float2 param_14 = _949;\n            float2 param_15 = _959;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_782 > 0.5) && (_782 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1010 = fa_dc_to_linear(param_16);\n                float4 _3425 = tx;\n                _3425.x = _1010.x;\n                _3425.y = _1010.y;\n                _3425.z = _1010.z;\n                tx = _3425;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_931 * tex_a) * _964.w, 0.0, 1.0)));\n        if (_974.z > _974.x)\n        {\n            float4 param_17 = _974;\n            float2 param_18 = _939;\n            float2 param_19 = _772;\n            float2 param_20 = _949;\n            float2 param_21 = _959;\n            float4 _1054 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_782 > 1.5)\n            {\n                float3 param_22 = _1054.xyz;\n                float3 _1064 = fa_dc_to_srgb(param_22);\n                _1058 = _1064;\n            }\n            else\n            {\n                _1058 = _1054.xyz;\n            }\n            float3 _1074 = (_1058 * 2.0) - float3(1.0);\n            float2 _1079 = _1074.xy * _828.y;\n            float3 _1101 = (fast::normalize(_856) * _1079.x) + (fast::normalize(_863) * _1079.y);\n            float3 _1104 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1104, fast::normalize((_1104 * fast::max(_1074.z, 0.0500000007450580596923828125)) + (_1101 - (_1104 * dot(_1104, _1101)))), float3(fast::clamp(_931 * (_984 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _446, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_446.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _446.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _446, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _446, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return float3(0.0, ambientColor.y, 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _446)\n{\n    int param = (int(_446.fa_cl_info.x) + int(_446.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _446, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _446);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _321 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _327 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _330 = _327.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _336 = _330 < 0.5;\n    float3 l;\n    if (_336)\n    {\n        l = fast::normalize(_321.xyz);\n    }\n    else\n    {\n        float3 _348 = _321.xyz - world_pos;\n        float _350 = length(_348);\n        dist = _350;\n        l = _348 / float3(fast::max(_350, 9.9999997473787516355514526367188e-05));\n        float _365 = _350 / fast::max(_321.w, 0.001000000047497451305389404296875);\n        float _371 = fast::clamp(1.0 - (_365 * _365), 0.0, 1.0);\n        atten = _371 * _371;\n        if (_330 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _385 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _395 = _385.w;\n            int param_3 = (li * 4) + 3;\n            float4 _401 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _402 = _401.x;\n            float cos_inner = _402;\n            if (_402 > 1.5)\n            {\n                cos_inner = mix(_395, 1.0, 0.25);\n            }\n            atten *= smoothstep(_395, cos_inner, dot(-l, fast::normalize(_385.xyz)));\n        }\n    }\n    int _432;\n    if (_336)\n    {\n        _432 = 0;\n    }\n    else\n    {\n        _432 = (_330 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _327.xyz * atten, atten, 1.0, dist, _432 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1186)\n{\n    float _1176;\n    if (i == 0)\n    {\n        _1176 = _1186.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1192;\n        if (i == 1)\n        {\n            _1192 = _1186.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1200;\n            if (i == 2)\n            {\n                _1200 = _1186.fa_shadow_split.z;\n            }\n            else\n            {\n                _1200 = _1186.fa_shadow_split.w;\n            }\n            _1192 = _1200;\n        }\n        _1176 = _1192;\n    }\n    return _1176;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1233 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1237;\n    if (conv.x < 0.5)\n    {\n        _1237 = _1233;\n    }\n    else\n    {\n        _1237 = (conv.y * conv.z) / (conv.z - (_1233 * (conv.z - conv.y)));\n    }\n    return _1237;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1164 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1164), sin(_1164)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1186, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1283 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1297 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1283;\n            float2 _1316 = fa_shadow_vogel(param_3, param_4, param_5) * _1297;\n            float2 param_6 = uv + (_1316 * _1186.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1328 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1328 < (zr - (length(_1316) * plane)))\n            {\n                sum += _1328;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1372 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1372; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1372;\n        float param_11 = _1283;\n        float2 _1391 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1391 * _1186.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1391) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1372);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1186, texture2d<float> fa_shadow_tex)\n{\n    float _1433 = fast::max(_1186.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1438 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1444 = sqrt(1.0 - (_1438 * _1438));\n    float _1451 = fast::min(_1444 / fast::max(_1438, 0.20000000298023223876953125), 4.0);\n    float _1456;\n    if (_1186.fa_shadow_bias.y > 0.0)\n    {\n        _1456 = _1186.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1456 = 1.5 * _1186.fa_shadow_info[ci].x;\n    }\n    float4 _1481 = _1186.fa_shadow_mat[ci] * float4(world + (n * (_1456 * _1444)), 1.0);\n    float _1488 = _1481.x;\n    bool _1491 = _1488 < _1186.fa_shadow_rect[ci].x;\n    bool _1500;\n    if (!_1491)\n    {\n        _1500 = _1488 > _1186.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1500 = _1491;\n    }\n    bool _1509;\n    if (!_1500)\n    {\n        _1509 = _1481.y < _1186.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1509 = _1500;\n    }\n    bool _1518;\n    if (!_1509)\n    {\n        _1518 = _1481.y > _1186.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1518 = _1509;\n    }\n    bool _1525;\n    if (!_1518)\n    {\n        _1525 = _1481.z > 1.0;\n    }\n    else\n    {\n        _1525 = _1518;\n    }\n    if (_1525)\n    {\n        return -1.0;\n    }\n    float _1534;\n    if (_1186.fa_shadow_bias.x > 0.0)\n    {\n        _1534 = _1186.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1534 = 1.5 * _1186.fa_shadow_info[ci].x;\n    }\n    float2 param = _1481.xy;\n    float4 param_1 = _1186.fa_shadow_rect[ci];\n    float param_2 = _1481.z - ((_1534 * (1.0 + (0.5 * _1451))) / _1433);\n    float param_3 = _1186.fa_shadow_info[ci].x;\n    float param_4 = _1433;\n    float param_5 = _1433 * 0.25;\n    float param_6 = ((_1186.fa_shadow_info[ci].x * fast::min(_1451, 3.0)) * 0.5) / _1433;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1186.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1186.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1186, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _446, thread float4& gl_FragCoord, constant fa_shadows& _1186, texture2d<float> fa_shadow_tex)\n{\n    if (_446.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1961 = int(_1186.fa_shadow_cfg.x + 0.5);\n    if (_1961 < 1)\n    {\n        return 1.0;\n    }\n    float _1976 = dot(world - _1186.fa_shadow_eye.xyz, _1186.fa_shadow_fwd.xyz);\n    int param = _1961 - 1;\n    if (_1976 > fa_shadow_split_at(param, _1186))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1988 = _1961 > 1;\n    bool _1995;\n    if (_1988)\n    {\n        _1995 = _1976 > _1186.fa_shadow_split.x;\n    }\n    else\n    {\n        _1995 = _1988;\n    }\n    if (_1995)\n    {\n        ci = 1;\n    }\n    bool _1999 = _1961 > 2;\n    bool _2006;\n    if (_1999)\n    {\n        _2006 = _1976 > _1186.fa_shadow_split.y;\n    }\n    else\n    {\n        _2006 = _1999;\n    }\n    if (_2006)\n    {\n        ci = 2;\n    }\n    bool _2010 = _1961 > 3;\n    bool _2017;\n    if (_2010)\n    {\n        _2017 = _1976 > _1186.fa_shadow_split.z;\n    }\n    else\n    {\n        _2017 = _2010;\n    }\n    if (_2017)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1961)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2043 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1186, fa_shadow_tex);\n        s = _2043;\n        if (_2043 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1186.fa_shadow_cfg.y > 0.0)\n    {\n        float _2068;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2068 = fa_shadow_split_at(param_5, _1186);\n        }\n        else\n        {\n            _2068 = _1186.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2087 = _1186.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1186) - _2068, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2098 = fast::clamp((_1976 - (fa_shadow_split_at(param_7, _1186) - _2087)) / _2087, 0.0, 1.0);\n        if (_2098 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1961)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2119 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1186, fa_shadow_tex);\n                s2 = _2119;\n                if (_2119 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2098);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _446, thread float4& gl_FragCoord, constant fa_shadows& _1186, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _446, gl_FragCoord, _1186, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _446, thread float4& gl_FragCoord, constant fa_shadows& _1186, texture2d<float> fa_shadow_tex)\n{\n    bool _1592 = _446.fa_pbr.z < 0.5;\n    bool _1600;\n    if (!_1592)\n    {\n        _1600 = _1186.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1600 = _1592;\n    }\n    if (_1600)\n    {\n        return 1.0;\n    }\n    int param = (int(_1186.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1613 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1614 = _1613.x;\n    if (_1614 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1623 = int(_1614 + 0.5);\n    int param_1 = _1623;\n    float4 _1627 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1623 + 1;\n    float4 _1632 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1635 = _1627.y;\n    if (_1635 > 0.0)\n    {\n        float _1652 = 1.0 - smoothstep(0.75 * _1635, _1635, length(world - _1186.fa_shadow_eye.xyz));\n        fade = _1652;\n        if (_1652 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1627.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1671 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1674 = abs(_1671);\n        float _1676 = _1674.x;\n        float _1678 = _1674.y;\n        bool _1679 = _1676 >= _1678;\n        bool _1687;\n        if (_1679)\n        {\n            _1687 = _1676 >= _1674.z;\n        }\n        else\n        {\n            _1687 = _1679;\n        }\n        int _1688;\n        if (_1687)\n        {\n            _1688 = (_1671.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1701;\n            if (_1678 >= _1674.z)\n            {\n                _1701 = (_1671.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1701 = (_1671.z > 0.0) ? 4 : 5;\n            }\n            _1688 = _1701;\n        }\n        face = _1688;\n    }\n    int _1720 = (_1623 + 2) + (face * 6);\n    int param_4 = _1720;\n    int param_5 = _1720 + 1;\n    int param_6 = _1720 + 3;\n    float4 _1734 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1720 + 4;\n    float4 _1739 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1720 + 5;\n    float4 _1744 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1756 = _1744.x * fast::max(dot(_1734, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1761 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1784 = fast::clamp(dot(n, _1734.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1807 = fast::min(sqrt(1.0 - (_1784 * _1784)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1734, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1810 = _1632.y;\n    float _1812;\n    if (_1810 > 0.0)\n    {\n        _1812 = _1810;\n    }\n    else\n    {\n        _1812 = 1.5 * _1756;\n    }\n    float4 _1832 = float4(world + (n * (_1812 * sqrt(1.0 - (_1761 * _1761)))), 1.0);\n    float _1836 = dot(_1734, _1832);\n    float _1839 = _1744.y;\n    if (_1836 < _1839)\n    {\n        return 1.0;\n    }\n    float2 _1854 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1832), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1832)) / float2(_1836);\n    float _1856 = _1854.x;\n    bool _1859 = _1856 < _1739.x;\n    bool _1868;\n    if (!_1859)\n    {\n        _1868 = _1856 > _1739.z;\n    }\n    else\n    {\n        _1868 = _1859;\n    }\n    bool _1877;\n    if (!_1868)\n    {\n        _1877 = _1854.y < _1739.y;\n    }\n    else\n    {\n        _1877 = _1868;\n    }\n    bool _1886;\n    if (!_1877)\n    {\n        _1886 = _1854.y > _1739.w;\n    }\n    else\n    {\n        _1886 = _1877;\n    }\n    if (_1886)\n    {\n        return 1.0;\n    }\n    float _1892 = _1632.x;\n    float _1894;\n    if (_1892 > 0.0)\n    {\n        _1894 = _1892;\n    }\n    else\n    {\n        _1894 = 1.5 * _1756;\n    }\n    float2 param_10 = _1854;\n    float4 param_11 = _1739;\n    float param_12 = _1836 - (_1894 * (1.0 + (0.5 * _1807)));\n    float param_13 = _1756;\n    float param_14 = 1.0;\n    float param_15 = _1744.z * 0.25;\n    float param_16 = (_1756 * fast::min(_1807, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1839, _1744.z);\n    int param_18 = int(_1627.z + 0.5);\n    float param_19 = _1627.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1186, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _446, thread float4& gl_FragCoord, constant fa_shadows& _1186, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _2287 = fa_lm.z > 0.5;\n    bool _2293;\n    if (_2287)\n    {\n        int param = li;\n        _2293 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2293 = _2287;\n    }\n    if (_2293)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2316 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _3354 = _2316.direction;\n    float3 _3349 = _2316.color;\n    float _3356 = _2316.attenuation;\n    float _3351 = _2316.shadow;\n    int _3359 = _2316.type;\n    if ((_3359 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3354;\n        float _2330 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _446, gl_FragCoord, _1186, fa_shadow_tex, fa_world_pos);\n        _3351 = _2330;\n        _3349 *= _2330;\n    }\n    else\n    {\n        bool _2341 = _3359 != 0;\n        bool _2347;\n        if (_2341)\n        {\n            _2347 = _3356 > 0.0;\n        }\n        else\n        {\n            _2347 = _2341;\n        }\n        if (_2347)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3354;\n            float _2359 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _446, gl_FragCoord, _1186, fa_shadow_tex);\n            _3351 = _2359;\n            _3349 *= _2359;\n        }\n    }\n    return LightSample{ _3354, _3349, _3356, _3351, _2316._distance, _3359 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1186)\n{\n    if (_1186.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2143 = int(_1186.fa_shadow_cfg.x + 0.5);\n    float _2153 = dot(world - _1186.fa_shadow_eye.xyz, _1186.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2158 = _2143 > 0;\n    bool _2167;\n    if (_2158)\n    {\n        int param = _2143 - 1;\n        _2167 = _2153 <= fa_shadow_split_at(param, _1186);\n    }\n    else\n    {\n        _2167 = _2158;\n    }\n    if (_2167)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2174 = _2143 > 1;\n        bool _2181;\n        if (_2174)\n        {\n            _2181 = _2153 > _1186.fa_shadow_split.x;\n        }\n        else\n        {\n            _2181 = _2174;\n        }\n        if (_2181)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2187 = _2143 > 2;\n        bool _2194;\n        if (_2187)\n        {\n            _2194 = _2153 > _1186.fa_shadow_split.y;\n        }\n        else\n        {\n            _2194 = _2187;\n        }\n        if (_2194)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2200 = _2143 > 3;\n        bool _2207;\n        if (_2200)\n        {\n            _2207 = _2153 > _1186.fa_shadow_split.z;\n        }\n        else\n        {\n            _2207 = _2200;\n        }\n        if (_2207)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _446 [[buffer(1)]], constant fa_shadows& _1186 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3165 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3165 = -_3165;\n    }\n    float3 _2749 = fast::normalize(_446.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _446, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3165, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2749, short(gl_FrontFacing) };\n    Surface _2757 = fa_standard_surface(param_1, _446, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3204 = _2757.albedo;\n    float _3205 = _2757.alpha;\n    float3 _3206 = _2757.normal;\n    float _3207 = _2757.metallic;\n    float _3208 = _2757.roughness;\n    float _3209 = _2757.occlusion;\n    float3 _3210 = _2757.emission;\n    float _3211 = _2757.clearcoat;\n    float _3212 = _2757.clearcoat_roughness;\n    float3 _3213 = _2757.sheen_color;\n    float _3214 = _2757.sheen_roughness;\n    float _3215 = _2757.anisotropy;\n    float _3216 = _2757.anisotropy_rotation;\n    float _3217 = _2757.specular;\n    float _3218 = _2757.ior;\n    float3 _3219 = _2757.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3165, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2749, short(gl_FrontFacing) };\n    Surface param_3 = _2757;\n    surface(param_2, param_3);\n    _3204 = param_3.albedo;\n    _3205 = param_3.alpha;\n    _3206 = param_3.normal;\n    _3207 = param_3.metallic;\n    _3208 = param_3.roughness;\n    _3209 = param_3.occlusion;\n    _3210 = param_3.emission;\n    _3211 = param_3.clearcoat;\n    _3212 = param_3.clearcoat_roughness;\n    _3213 = param_3.sheen_color;\n    _3214 = param_3.sheen_roughness;\n    _3215 = param_3.anisotropy;\n    _3216 = param_3.anisotropy_rotation;\n    _3217 = param_3.specular;\n    _3218 = param_3.ior;\n    _3219 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _3165;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _446, fa_decal_tex, fa_env_smp);\n    _3204 = param_6;\n    _3206 = param_7;\n    float3 result;\n    if (_446.fa_emissive.w > 0.5)\n    {\n        result = _3204;\n    }\n    else\n    {\n        float3 _2795 = _3206;\n        float3 _2796 = fast::normalize(_2795);\n        _3206 = _2796;\n        float3 param_8 = _2796;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _3165, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2749, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _3204, _3205, _3206, _3207, _3208, _3209, _3210, _3211, _3212, _3213, _3214, _3215, _3216, _3217, _3218, _3219 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _446, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _2815 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2815; ln++)\n        {\n            int param_12 = ln;\n            int _2828 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _446, fa_cl_ndir, fa_cl_slot);\n            bool _2831 = in.fa_lm.z > 0.5;\n            bool _2837;\n            if (_2831)\n            {\n                int param_13 = _2828;\n                _2837 = fa_light_baked(param_13, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _2837 = _2831;\n            }\n            if (_2837)\n            {\n                continue;\n            }\n            int param_14 = _2828;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _3165;\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _3165, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2749, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _3204, _3205, _3206, _3207, _3208, _3209, _3210, _3211, _3212, _3213, _3214, _3215, _3216, _3217, _3218, _3219 };\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16, fa_light_tex, fa_shadow_smp, _446, gl_FragCoord, _1186, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _2864 = result;\n    float3 _2865 = _2864 + _3210;\n    result = _2865;\n    float3 param_20 = _2865;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _1186);\n    bool _2874 = _446.fa_fog.w > 0.0;\n    bool _2881;\n    if (!_2874)\n    {\n        _2881 = _446.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2881 = _2874;\n    }\n    if (_2881)\n    {\n        float3 _2890 = in.fa_world_pos - _446.fa_camera_pos.xyz;\n        float _2896 = dot(_2890, _446.fa_fog_c.xyz);\n        bool _2900 = _446.fa_fog_c.w > 0.5;\n        float _2901;\n        if (_2900)\n        {\n            _2901 = _2896;\n        }\n        else\n        {\n            _2901 = length(_2890);\n        }\n        float _2913 = _2901 - _446.fa_fog_b.x;\n        if (_2913 > 0.0)\n        {\n            float _2922 = _446.fa_fog.w * _2913;\n            float tau = _2922 * _2922;\n            if (_446.fa_fog_b.y > 0.0)\n            {\n                float _2938;\n                if (_2900)\n                {\n                    _2938 = in.fa_world_pos.y - (_446.fa_fog_c.y * _2896);\n                }\n                else\n                {\n                    _2938 = _446.fa_camera_pos.y;\n                }\n                float _2959 = mix(_2938, in.fa_world_pos.y, fast::clamp(_446.fa_fog_b.x / _2901, 0.0, 1.0));\n                float _2963 = in.fa_world_pos.y - _2959;\n                float _2968 = _2959 - _446.fa_fog_b.z;\n                float _2973 = in.fa_world_pos.y - _446.fa_fog_b.z;\n                bool _2976 = _2968 <= 0.0;\n                bool _2977 = !_2976;\n                bool _2983;\n                if (_2977)\n                {\n                    _2983 = _446.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2983 = _2976;\n                }\n                float _2984;\n                if (_2983)\n                {\n                    _2984 = _446.fa_fog_b.y;\n                }\n                else\n                {\n                    _2984 = _446.fa_fog_b.y * exp(-fast::min(_446.fa_fog_b.w * _2968, 80.0));\n                }\n                bool _3011;\n                if (_2977)\n                {\n                    _3011 = _446.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3011 = _2976;\n                }\n                float _3012;\n                if (_3011)\n                {\n                    _3012 = _446.fa_fog_b.y * _2968;\n                }\n                else\n                {\n                    _3012 = (_446.fa_fog_b.y * (1.0 - exp(-fast::min(_446.fa_fog_b.w * _2968, 80.0)))) / _446.fa_fog_b.w;\n                }\n                bool _3037 = _2973 <= 0.0;\n                bool _3044;\n                if (!_3037)\n                {\n                    _3044 = _446.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3044 = _3037;\n                }\n                float _3045;\n                if (_3044)\n                {\n                    _3045 = _446.fa_fog_b.y * _2973;\n                }\n                else\n                {\n                    _3045 = (_446.fa_fog_b.y * (1.0 - exp(-fast::min(_446.fa_fog_b.w * _2973, 80.0)))) / _446.fa_fog_b.w;\n                }\n                float _3072;\n                if (abs(_2963) < 0.001000000047497451305389404296875)\n                {\n                    _3072 = _2984;\n                }\n                else\n                {\n                    _3072 = (_3045 - _3012) / _2963;\n                }\n                tau += (_2913 * fast::max(_3072, 0.0));\n            }\n            result = mix(result, _446.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3205);\n    return out;\n}\n\n",
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
            "size": 176,
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
            "inst_name": "_446",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1186",
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
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 8
            }
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 9
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
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 9,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213.fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213.fa_layers_a.x;\n    float _753 = _213.fa_layers_a.y;\n    float _756 = _213.fa_layers_a.z;\n    float _755 = _213.fa_layers_b.w;\n    float _758 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _747, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _752, _753, _213.fa_layers_b.xyz, _755, _756, _213.fa_layers_a.w, _758, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _658 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _658, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _658, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 176,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213.fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213.fa_layers_a.x;\n    float _753 = _213.fa_layers_a.y;\n    float _756 = _213.fa_layers_a.z;\n    float _755 = _213.fa_layers_b.w;\n    float _758 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _747, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _752, _753, _213.fa_layers_b.xyz, _755, _756, _213.fa_layers_a.w, _758, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _658 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _658, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _658, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 176,
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
