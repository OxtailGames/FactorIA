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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _440)\n{\n    bool _445 = _440.fa_cl_info.x < 0.0;\n    bool _452;\n    if (!_445)\n    {\n        _452 = _440.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _452 = _445;\n    }\n    bool _460;\n    if (!_452)\n    {\n        _460 = _440.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _460 = _452;\n    }\n    bool _467;\n    if (!_460)\n    {\n        _467 = _440.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _467 = _460;\n    }\n    bool _474;\n    if (!_467)\n    {\n        _474 = _440.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _474 = _467;\n    }\n    if (_474)\n    {\n        return float4(0.0);\n    }\n    float4 _484 = float4(world_pos, 1.0);\n    float _491 = dot(_440.fa_cl_vpw, _484);\n    if (!(_491 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _513 = float2(dot(_440.fa_cl_vpx, _484), dot(_440.fa_cl_vpy, _484)) / float2(_491);\n    int _517 = int(_440.fa_cl_grid.x);\n    int _521 = int(_440.fa_cl_grid.y);\n    int param = (int(_440.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_440.fa_cl_fwd.xyz, world_pos) + _440.fa_cl_fwd.w, _440.fa_cl_grid.w) / _440.fa_cl_grid.w) * _440.fa_cl_grid.z)), 0, int(_440.fa_cl_info.y) - 1) * _521) + clamp(int(floor(((_513.y * 0.5) + 0.5) * _440.fa_cl_grid.y)), 0, _521 - 1)) * _517)) + clamp(int(floor(((_513.x * 0.5) + 0.5) * _440.fa_cl_grid.x)), 0, _517 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _440)\n{\n    float3 param = world_pos;\n    float4 _597 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _440);\n    return int2(int(_597.x), int(_597.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _440, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_440.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2254 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _440);\n    fa_cl_slot = _2254.x;\n    fa_cl_local = _2254.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2402 = fa_linear_to_srgb(param);\n        c = _2402;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2410 = fa_srgb_to_linear(param_1);\n            c = _2410;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _204;\n    if (bool(i.front_facing))\n    {\n        _204 = i.world_normal;\n    }\n    else\n    {\n        _204 = -i.world_normal;\n    }\n    float3 _228 = fast::normalize(i.world_tangent.xyz - (_204 * dot(_204, i.world_tangent.xyz)));\n    float3 _256 = fast::normalize(((_228 * m.x) + ((cross(_204, _228) * i.world_tangent.w) * m.y)) + (_204 * m.z));\n    float3 _259;\n    if (bool(i.front_facing))\n    {\n        _259 = _256;\n    }\n    else\n    {\n        _259 = -_256;\n    }\n    return _259;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _440, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _440.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2441 = fa_tex_fix(param_2, param_3);\n    float4 _3453 = base_t;\n    _3453.x = _2441.x;\n    _3453.y = _2441.y;\n    _3453.z = _2441.z;\n    base_t = _3453;\n    float4 _2455 = (_3453 * _440.fa_base_color) * i.vertex_color;\n    float3 _3333 = i.world_normal;\n    if (_440.fa_maps.z > 0.5)\n    {\n        float param_4 = _440.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2487 = fa_tex_fix(param_6, param_7);\n        float3 _2490 = (_2487 * 2.0) - float3(1.0);\n        float2 _2495 = _2490.xy * _440.fa_maps.x;\n        float3 _3461 = _2490;\n        _3461.x = _2495.x;\n        _3461.y = _2495.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3461;\n        _3333 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _440.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2524 = fa_tex_fix(param_12, param_13);\n    float4 _3464 = mrt;\n    _3464.x = _2524.x;\n    _3464.y = _2524.y;\n    _3464.z = _2524.z;\n    mrt = _3464;\n    float4 _2552 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _440.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2552.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2564 = fa_tex_fix(param_16, param_17);\n    float param_18 = _440.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2594 = fa_tex_fix(param_20, param_21);\n    float _3338 = _440.fa_layers_a.x;\n    float _3339 = _440.fa_layers_a.y;\n    float _3342 = _440.fa_layers_a.z;\n    float _3341 = _440.fa_layers_b.w;\n    float _3344 = _440.fa_layers_c.x;\n    if (_440.fa_layers_c.z > 0.5)\n    {\n        if (mod(_440.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3338 *= _2564.y;\n            _3339 *= _2564.z;\n            _3341 *= _2552.w;\n        }\n        if (_440.fa_layers_c.z > 1.5)\n        {\n            _3342 *= mrt.x;\n            _3344 *= mrt.w;\n        }\n    }\n    return Surface{ _2455.xyz, _2455.w, _3333, fast::clamp(_440.fa_pbr.x * _2524.z, 0.0, 1.0), fast::clamp(_440.fa_pbr.y * _2524.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_440.fa_maps.y * (_2564.x - 1.0)), _440.fa_emissive.xyz + (_440.fa_model_emissive.xyz * _2594), _3338, _3339, _440.fa_layers_b.xyz, _3341, _3342, _440.fa_layers_a.w, _3344, _440.fa_layers_c.y, _440.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _678 = rect.zw - rect.xy;\n    float2 _682 = _678 * atlas;\n    float2 _686 = ddx * _682;\n    float2 _690 = ddy * _682;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _678)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_686, _686), dot(_690, _690)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _440, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _725 = _440.fa_counts.y < 0.5;\n    bool _732;\n    if (!_725)\n    {\n        _732 = _440.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _732 = _725;\n    }\n    if (_732)\n    {\n        return;\n    }\n    float3 _738 = dfdx(world_pos);\n    float3 _741 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _745 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _440);\n    int _749 = int(_745.w);\n    if (_749 < 1)\n    {\n        return;\n    }\n    int _759 = int(_440.fa_counts.y + 0.5);\n    int param_1 = _759;\n    float4 _763 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _766 = _763.yz;\n    int _770 = int(_763.w);\n    int param_2 = _759 + 1;\n    float4 _775 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _776 = _775.x;\n    int _782 = int(_440.fa_counts.w + 0.5) - 1;\n    int _786 = int(_745.z);\n    float3 _1052;\n    for (int k = 0; k < _749; k++)\n    {\n        int _799 = _786 + k;\n        int param_3 = _770 + (_799 >> 2);\n        int _817 = (_759 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_799 & 3]) * 7);\n        int param_4 = _817 + 6;\n        float4 _822 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_822.w + 0.5) >> _782) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _817;\n        float4 _837 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _817 + 1;\n        float4 _842 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _817 + 2;\n        float4 _847 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _850 = _837.xyz;\n        float _855 = dot(_850, world_pos) + _837.w;\n        float3 _857 = _842.xyz;\n        float _862 = dot(_857, world_pos) + _842.w;\n        float3 _864 = _847.xyz;\n        float _869 = dot(_864, world_pos) + _847.w;\n        bool _874 = abs(_855) > 0.5;\n        bool _882;\n        if (!_874)\n        {\n            _882 = abs(_862) > 0.5;\n        }\n        else\n        {\n            _882 = _874;\n        }\n        bool _890;\n        if (!_882)\n        {\n            _890 = abs(_869) > 0.5;\n        }\n        else\n        {\n            _890 = _882;\n        }\n        if (_890)\n        {\n            continue;\n        }\n        float _905 = fast::clamp(dot(geo_normal, fast::normalize(_864)) * _822.z, 0.0, 1.0);\n        if (_905 <= 0.0)\n        {\n            continue;\n        }\n        float _925 = (fast::clamp((0.5 - abs(_869)) * 10.0, 0.0, 1.0) * _905) * _822.x;\n        float2 _933 = float2(_855 + 0.5, 0.5 - _862);\n        float2 _943 = float2(dot(_850, _738), dot(_857, _738));\n        float2 _953 = float2(dot(_850, _741), dot(_857, _741));\n        int param_8 = _817 + 5;\n        float4 _958 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _817 + 3;\n        float4 _963 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _817 + 4;\n        float4 _968 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _958.xyz;\n        bool _978 = _963.z > _963.x;\n        if (_978)\n        {\n            float4 param_11 = _963;\n            float2 param_12 = _933;\n            float2 param_13 = _766;\n            float2 param_14 = _943;\n            float2 param_15 = _953;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_776 > 0.5) && (_776 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1004 = fa_dc_to_linear(param_16);\n                float4 _3389 = tx;\n                _3389.x = _1004.x;\n                _3389.y = _1004.y;\n                _3389.z = _1004.z;\n                tx = _3389;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_925 * tex_a) * _958.w, 0.0, 1.0)));\n        if (_968.z > _968.x)\n        {\n            float4 param_17 = _968;\n            float2 param_18 = _933;\n            float2 param_19 = _766;\n            float2 param_20 = _943;\n            float2 param_21 = _953;\n            float4 _1048 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_776 > 1.5)\n            {\n                float3 param_22 = _1048.xyz;\n                float3 _1058 = fa_dc_to_srgb(param_22);\n                _1052 = _1058;\n            }\n            else\n            {\n                _1052 = _1048.xyz;\n            }\n            float3 _1068 = (_1052 * 2.0) - float3(1.0);\n            float2 _1073 = _1068.xy * _822.y;\n            float3 _1095 = (fast::normalize(_850) * _1073.x) + (fast::normalize(_857) * _1073.y);\n            float3 _1098 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1098, fast::normalize((_1098 * fast::max(_1068.z, 0.0500000007450580596923828125)) + (_1095 - (_1098 * dot(_1098, _1095)))), float3(fast::clamp(_925 * (_978 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _440, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_440.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _440.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _440, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _440, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _440)\n{\n    int param = (int(_440.fa_cl_info.x) + int(_440.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _440, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _440);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _315 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _321 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _324 = _321.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _330 = _324 < 0.5;\n    float3 l;\n    if (_330)\n    {\n        l = fast::normalize(_315.xyz);\n    }\n    else\n    {\n        float3 _342 = _315.xyz - world_pos;\n        float _344 = length(_342);\n        dist = _344;\n        l = _342 / float3(fast::max(_344, 9.9999997473787516355514526367188e-05));\n        float _359 = _344 / fast::max(_315.w, 0.001000000047497451305389404296875);\n        float _365 = fast::clamp(1.0 - (_359 * _359), 0.0, 1.0);\n        atten = _365 * _365;\n        if (_324 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _379 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _389 = _379.w;\n            int param_3 = (li * 4) + 3;\n            float4 _395 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _396 = _395.x;\n            float cos_inner = _396;\n            if (_396 > 1.5)\n            {\n                cos_inner = mix(_389, 1.0, 0.25);\n            }\n            atten *= smoothstep(_389, cos_inner, dot(-l, fast::normalize(_379.xyz)));\n        }\n    }\n    int _426;\n    if (_330)\n    {\n        _426 = 0;\n    }\n    else\n    {\n        _426 = (_324 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _321.xyz * atten, atten, 1.0, dist, _426 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1180)\n{\n    float _1170;\n    if (i == 0)\n    {\n        _1170 = _1180.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1186;\n        if (i == 1)\n        {\n            _1186 = _1180.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1194;\n            if (i == 2)\n            {\n                _1194 = _1180.fa_shadow_split.z;\n            }\n            else\n            {\n                _1194 = _1180.fa_shadow_split.w;\n            }\n            _1186 = _1194;\n        }\n        _1170 = _1186;\n    }\n    return _1170;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1227 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1231;\n    if (conv.x < 0.5)\n    {\n        _1231 = _1227;\n    }\n    else\n    {\n        _1231 = (conv.y * conv.z) / (conv.z - (_1227 * (conv.z - conv.y)));\n    }\n    return _1231;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1158 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1158), sin(_1158)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1180, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1277 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1291 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1277;\n            float2 _1310 = fa_shadow_vogel(param_3, param_4, param_5) * _1291;\n            float2 param_6 = uv + (_1310 * _1180.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1322 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1322 < (zr - (length(_1310) * plane)))\n            {\n                sum += _1322;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1366 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1366; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1366;\n        float param_11 = _1277;\n        float2 _1385 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1385 * _1180.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1385) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1366);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1180, texture2d<float> fa_shadow_tex)\n{\n    float _1427 = fast::max(_1180.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1432 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1438 = sqrt(1.0 - (_1432 * _1432));\n    float _1445 = fast::min(_1438 / fast::max(_1432, 0.20000000298023223876953125), 4.0);\n    float _1450;\n    if (_1180.fa_shadow_bias.y > 0.0)\n    {\n        _1450 = _1180.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1450 = 1.5 * _1180.fa_shadow_info[ci].x;\n    }\n    float4 _1475 = _1180.fa_shadow_mat[ci] * float4(world + (n * (_1450 * _1438)), 1.0);\n    float _1482 = _1475.x;\n    bool _1485 = _1482 < _1180.fa_shadow_rect[ci].x;\n    bool _1494;\n    if (!_1485)\n    {\n        _1494 = _1482 > _1180.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1494 = _1485;\n    }\n    bool _1503;\n    if (!_1494)\n    {\n        _1503 = _1475.y < _1180.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1503 = _1494;\n    }\n    bool _1512;\n    if (!_1503)\n    {\n        _1512 = _1475.y > _1180.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1512 = _1503;\n    }\n    bool _1519;\n    if (!_1512)\n    {\n        _1519 = _1475.z > 1.0;\n    }\n    else\n    {\n        _1519 = _1512;\n    }\n    if (_1519)\n    {\n        return -1.0;\n    }\n    float _1528;\n    if (_1180.fa_shadow_bias.x > 0.0)\n    {\n        _1528 = _1180.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1528 = 1.5 * _1180.fa_shadow_info[ci].x;\n    }\n    float2 param = _1475.xy;\n    float4 param_1 = _1180.fa_shadow_rect[ci];\n    float param_2 = _1475.z - ((_1528 * (1.0 + (0.5 * _1445))) / _1427);\n    float param_3 = _1180.fa_shadow_info[ci].x;\n    float param_4 = _1427;\n    float param_5 = _1427 * 0.25;\n    float param_6 = ((_1180.fa_shadow_info[ci].x * fast::min(_1445, 3.0)) * 0.5) / _1427;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1180.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1180.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1180, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _440, thread float4& gl_FragCoord, constant fa_shadows& _1180, texture2d<float> fa_shadow_tex)\n{\n    if (_440.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1955 = int(_1180.fa_shadow_cfg.x + 0.5);\n    if (_1955 < 1)\n    {\n        return 1.0;\n    }\n    float _1970 = dot(world - _1180.fa_shadow_eye.xyz, _1180.fa_shadow_fwd.xyz);\n    int param = _1955 - 1;\n    if (_1970 > fa_shadow_split_at(param, _1180))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1982 = _1955 > 1;\n    bool _1989;\n    if (_1982)\n    {\n        _1989 = _1970 > _1180.fa_shadow_split.x;\n    }\n    else\n    {\n        _1989 = _1982;\n    }\n    if (_1989)\n    {\n        ci = 1;\n    }\n    bool _1993 = _1955 > 2;\n    bool _2000;\n    if (_1993)\n    {\n        _2000 = _1970 > _1180.fa_shadow_split.y;\n    }\n    else\n    {\n        _2000 = _1993;\n    }\n    if (_2000)\n    {\n        ci = 2;\n    }\n    bool _2004 = _1955 > 3;\n    bool _2011;\n    if (_2004)\n    {\n        _2011 = _1970 > _1180.fa_shadow_split.z;\n    }\n    else\n    {\n        _2011 = _2004;\n    }\n    if (_2011)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1955)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2037 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1180, fa_shadow_tex);\n        s = _2037;\n        if (_2037 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1180.fa_shadow_cfg.y > 0.0)\n    {\n        float _2062;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2062 = fa_shadow_split_at(param_5, _1180);\n        }\n        else\n        {\n            _2062 = _1180.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2081 = _1180.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1180) - _2062, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2092 = fast::clamp((_1970 - (fa_shadow_split_at(param_7, _1180) - _2081)) / _2081, 0.0, 1.0);\n        if (_2092 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1955)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2113 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1180, fa_shadow_tex);\n                s2 = _2113;\n                if (_2113 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2092);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _440, thread float4& gl_FragCoord, constant fa_shadows& _1180, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _440, gl_FragCoord, _1180, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _440, thread float4& gl_FragCoord, constant fa_shadows& _1180, texture2d<float> fa_shadow_tex)\n{\n    bool _1586 = _440.fa_pbr.z < 0.5;\n    bool _1594;\n    if (!_1586)\n    {\n        _1594 = _1180.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1594 = _1586;\n    }\n    if (_1594)\n    {\n        return 1.0;\n    }\n    int param = (int(_1180.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1607 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1608 = _1607.x;\n    if (_1608 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1617 = int(_1608 + 0.5);\n    int param_1 = _1617;\n    float4 _1621 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1617 + 1;\n    float4 _1626 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1629 = _1621.y;\n    if (_1629 > 0.0)\n    {\n        float _1646 = 1.0 - smoothstep(0.75 * _1629, _1629, length(world - _1180.fa_shadow_eye.xyz));\n        fade = _1646;\n        if (_1646 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1621.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1665 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1668 = abs(_1665);\n        float _1670 = _1668.x;\n        float _1672 = _1668.y;\n        bool _1673 = _1670 >= _1672;\n        bool _1681;\n        if (_1673)\n        {\n            _1681 = _1670 >= _1668.z;\n        }\n        else\n        {\n            _1681 = _1673;\n        }\n        int _1682;\n        if (_1681)\n        {\n            _1682 = (_1665.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1695;\n            if (_1672 >= _1668.z)\n            {\n                _1695 = (_1665.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1695 = (_1665.z > 0.0) ? 4 : 5;\n            }\n            _1682 = _1695;\n        }\n        face = _1682;\n    }\n    int _1714 = (_1617 + 2) + (face * 6);\n    int param_4 = _1714;\n    int param_5 = _1714 + 1;\n    int param_6 = _1714 + 3;\n    float4 _1728 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1714 + 4;\n    float4 _1733 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1714 + 5;\n    float4 _1738 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1750 = _1738.x * fast::max(dot(_1728, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1755 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1778 = fast::clamp(dot(n, _1728.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1801 = fast::min(sqrt(1.0 - (_1778 * _1778)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1728, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1804 = _1626.y;\n    float _1806;\n    if (_1804 > 0.0)\n    {\n        _1806 = _1804;\n    }\n    else\n    {\n        _1806 = 1.5 * _1750;\n    }\n    float4 _1826 = float4(world + (n * (_1806 * sqrt(1.0 - (_1755 * _1755)))), 1.0);\n    float _1830 = dot(_1728, _1826);\n    float _1833 = _1738.y;\n    if (_1830 < _1833)\n    {\n        return 1.0;\n    }\n    float2 _1848 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1826), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1826)) / float2(_1830);\n    float _1850 = _1848.x;\n    bool _1853 = _1850 < _1733.x;\n    bool _1862;\n    if (!_1853)\n    {\n        _1862 = _1850 > _1733.z;\n    }\n    else\n    {\n        _1862 = _1853;\n    }\n    bool _1871;\n    if (!_1862)\n    {\n        _1871 = _1848.y < _1733.y;\n    }\n    else\n    {\n        _1871 = _1862;\n    }\n    bool _1880;\n    if (!_1871)\n    {\n        _1880 = _1848.y > _1733.w;\n    }\n    else\n    {\n        _1880 = _1871;\n    }\n    if (_1880)\n    {\n        return 1.0;\n    }\n    float _1886 = _1626.x;\n    float _1888;\n    if (_1886 > 0.0)\n    {\n        _1888 = _1886;\n    }\n    else\n    {\n        _1888 = 1.5 * _1750;\n    }\n    float2 param_10 = _1848;\n    float4 param_11 = _1733;\n    float param_12 = _1830 - (_1888 * (1.0 + (0.5 * _1801)));\n    float param_13 = _1750;\n    float param_14 = 1.0;\n    float param_15 = _1738.z * 0.25;\n    float param_16 = (_1750 * fast::min(_1801, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1833, _1738.z);\n    int param_18 = int(_1621.z + 0.5);\n    float param_19 = _1621.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1180, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _440, thread float4& gl_FragCoord, constant fa_shadows& _1180, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _2281 = fa_lm.z > 0.5;\n    bool _2287;\n    if (_2281)\n    {\n        int param = li;\n        _2287 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2287 = _2281;\n    }\n    if (_2287)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2310 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _3318 = _2310.direction;\n    float3 _3313 = _2310.color;\n    float _3320 = _2310.attenuation;\n    float _3315 = _2310.shadow;\n    int _3323 = _2310.type;\n    if ((_3323 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3318;\n        float _2324 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _440, gl_FragCoord, _1180, fa_shadow_tex, fa_world_pos);\n        _3315 = _2324;\n        _3313 *= _2324;\n    }\n    else\n    {\n        bool _2335 = _3323 != 0;\n        bool _2341;\n        if (_2335)\n        {\n            _2341 = _3320 > 0.0;\n        }\n        else\n        {\n            _2341 = _2335;\n        }\n        if (_2341)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3318;\n            float _2353 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _440, gl_FragCoord, _1180, fa_shadow_tex);\n            _3315 = _2353;\n            _3313 *= _2353;\n        }\n    }\n    return LightSample{ _3318, _3313, _3320, _3315, _2310._distance, _3323 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1180)\n{\n    if (_1180.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2137 = int(_1180.fa_shadow_cfg.x + 0.5);\n    float _2147 = dot(world - _1180.fa_shadow_eye.xyz, _1180.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2152 = _2137 > 0;\n    bool _2161;\n    if (_2152)\n    {\n        int param = _2137 - 1;\n        _2161 = _2147 <= fa_shadow_split_at(param, _1180);\n    }\n    else\n    {\n        _2161 = _2152;\n    }\n    if (_2161)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2168 = _2137 > 1;\n        bool _2175;\n        if (_2168)\n        {\n            _2175 = _2147 > _1180.fa_shadow_split.x;\n        }\n        else\n        {\n            _2175 = _2168;\n        }\n        if (_2175)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2181 = _2137 > 2;\n        bool _2188;\n        if (_2181)\n        {\n            _2188 = _2147 > _1180.fa_shadow_split.y;\n        }\n        else\n        {\n            _2188 = _2181;\n        }\n        if (_2188)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2194 = _2137 > 3;\n        bool _2201;\n        if (_2194)\n        {\n            _2201 = _2147 > _1180.fa_shadow_split.z;\n        }\n        else\n        {\n            _2201 = _2194;\n        }\n        if (_2201)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _440 [[buffer(1)]], constant fa_shadows& _1180 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3154 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3154 = -_3154;\n    }\n    float3 _2738 = fast::normalize(_440.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _440, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3154, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2738, short(gl_FrontFacing) };\n    Surface _2746 = fa_standard_surface(param_1, _440, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3185 = _2746.albedo;\n    float _3186 = _2746.alpha;\n    float3 _3187 = _2746.normal;\n    float _3188 = _2746.metallic;\n    float _3189 = _2746.roughness;\n    float _3190 = _2746.occlusion;\n    float3 _3191 = _2746.emission;\n    float _3192 = _2746.clearcoat;\n    float _3193 = _2746.clearcoat_roughness;\n    float3 _3194 = _2746.sheen_color;\n    float _3195 = _2746.sheen_roughness;\n    float _3196 = _2746.anisotropy;\n    float _3197 = _2746.anisotropy_rotation;\n    float _3198 = _2746.specular;\n    float _3199 = _2746.ior;\n    float3 _3200 = _2746.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3154, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2738, short(gl_FrontFacing) };\n    Surface param_3 = _2746;\n    surface(param_2, param_3);\n    _3185 = param_3.albedo;\n    _3186 = param_3.alpha;\n    _3187 = param_3.normal;\n    _3188 = param_3.metallic;\n    _3189 = param_3.roughness;\n    _3190 = param_3.occlusion;\n    _3191 = param_3.emission;\n    _3192 = param_3.clearcoat;\n    _3193 = param_3.clearcoat_roughness;\n    _3194 = param_3.sheen_color;\n    _3195 = param_3.sheen_roughness;\n    _3196 = param_3.anisotropy;\n    _3197 = param_3.anisotropy_rotation;\n    _3198 = param_3.specular;\n    _3199 = param_3.ior;\n    _3200 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _3154;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _440, fa_decal_tex, fa_env_smp);\n    _3185 = param_6;\n    _3187 = param_7;\n    float3 result;\n    if (_440.fa_emissive.w > 0.5)\n    {\n        result = _3185;\n    }\n    else\n    {\n        float3 _2784 = _3187;\n        float3 _2785 = fast::normalize(_2784);\n        _3187 = _2785;\n        float3 param_8 = _2785;\n        float3 lit = (fa_indirect_diffuse(param_8, _440, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap) * _3185) * _3190;\n        int _2804 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2804; ln++)\n        {\n            int param_9 = ln;\n            int _2817 = fa_cl_light(param_9, fa_light_tex, fa_shadow_smp, _440, fa_cl_ndir, fa_cl_slot);\n            bool _2820 = in.fa_lm.z > 0.5;\n            bool _2826;\n            if (_2820)\n            {\n                int param_10 = _2817;\n                _2826 = fa_light_baked(param_10, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _2826 = _2820;\n            }\n            if (_2826)\n            {\n                continue;\n            }\n            int param_11 = _2817;\n            float3 param_12 = in.fa_world_pos;\n            float3 param_13 = _3154;\n            SurfaceInput param_14 = SurfaceInput{ in.fa_world_pos, _3154, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2738, short(gl_FrontFacing) };\n            Surface param_15 = Surface{ _3185, _3186, _3187, _3188, _3189, _3190, _3191, _3192, _3193, _3194, _3195, _3196, _3197, _3198, _3199, _3200 };\n            LightSample param_16 = fa_light_shadowed(param_11, param_12, param_13, fa_light_tex, fa_shadow_smp, _440, gl_FragCoord, _1180, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _2853 = result;\n    float3 _2854 = _2853 + _3191;\n    result = _2854;\n    float3 param_17 = _2854;\n    float3 param_18 = in.fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18, _1180);\n    bool _2863 = _440.fa_fog.w > 0.0;\n    bool _2870;\n    if (!_2863)\n    {\n        _2870 = _440.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2870 = _2863;\n    }\n    if (_2870)\n    {\n        float3 _2879 = in.fa_world_pos - _440.fa_camera_pos.xyz;\n        float _2885 = dot(_2879, _440.fa_fog_c.xyz);\n        bool _2889 = _440.fa_fog_c.w > 0.5;\n        float _2890;\n        if (_2889)\n        {\n            _2890 = _2885;\n        }\n        else\n        {\n            _2890 = length(_2879);\n        }\n        float _2902 = _2890 - _440.fa_fog_b.x;\n        if (_2902 > 0.0)\n        {\n            float _2911 = _440.fa_fog.w * _2902;\n            float tau = _2911 * _2911;\n            if (_440.fa_fog_b.y > 0.0)\n            {\n                float _2927;\n                if (_2889)\n                {\n                    _2927 = in.fa_world_pos.y - (_440.fa_fog_c.y * _2885);\n                }\n                else\n                {\n                    _2927 = _440.fa_camera_pos.y;\n                }\n                float _2948 = mix(_2927, in.fa_world_pos.y, fast::clamp(_440.fa_fog_b.x / _2890, 0.0, 1.0));\n                float _2952 = in.fa_world_pos.y - _2948;\n                float _2957 = _2948 - _440.fa_fog_b.z;\n                float _2962 = in.fa_world_pos.y - _440.fa_fog_b.z;\n                bool _2965 = _2957 <= 0.0;\n                bool _2966 = !_2965;\n                bool _2972;\n                if (_2966)\n                {\n                    _2972 = _440.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2972 = _2965;\n                }\n                float _2973;\n                if (_2972)\n                {\n                    _2973 = _440.fa_fog_b.y;\n                }\n                else\n                {\n                    _2973 = _440.fa_fog_b.y * exp(-fast::min(_440.fa_fog_b.w * _2957, 80.0));\n                }\n                bool _3000;\n                if (_2966)\n                {\n                    _3000 = _440.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3000 = _2965;\n                }\n                float _3001;\n                if (_3000)\n                {\n                    _3001 = _440.fa_fog_b.y * _2957;\n                }\n                else\n                {\n                    _3001 = (_440.fa_fog_b.y * (1.0 - exp(-fast::min(_440.fa_fog_b.w * _2957, 80.0)))) / _440.fa_fog_b.w;\n                }\n                bool _3026 = _2962 <= 0.0;\n                bool _3033;\n                if (!_3026)\n                {\n                    _3033 = _440.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3033 = _3026;\n                }\n                float _3034;\n                if (_3033)\n                {\n                    _3034 = _440.fa_fog_b.y * _2962;\n                }\n                else\n                {\n                    _3034 = (_440.fa_fog_b.y * (1.0 - exp(-fast::min(_440.fa_fog_b.w * _2962, 80.0)))) / _440.fa_fog_b.w;\n                }\n                float _3061;\n                if (abs(_2952) < 0.001000000047497451305389404296875)\n                {\n                    _3061 = _2973;\n                }\n                else\n                {\n                    _3061 = (_3034 - _3001) / _2952;\n                }\n                tau += (_2902 * fast::max(_3061, 0.0));\n            }\n            result = mix(result, _440.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3186);\n    return out;\n}\n\n",
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
            "inst_name": "_440",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1180",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _440)\n{\n    bool _445 = _440.fa_cl_info.x < 0.0;\n    bool _452;\n    if (!_445)\n    {\n        _452 = _440.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _452 = _445;\n    }\n    bool _460;\n    if (!_452)\n    {\n        _460 = _440.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _460 = _452;\n    }\n    bool _467;\n    if (!_460)\n    {\n        _467 = _440.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _467 = _460;\n    }\n    bool _474;\n    if (!_467)\n    {\n        _474 = _440.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _474 = _467;\n    }\n    if (_474)\n    {\n        return float4(0.0);\n    }\n    float4 _484 = float4(world_pos, 1.0);\n    float _491 = dot(_440.fa_cl_vpw, _484);\n    if (!(_491 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _513 = float2(dot(_440.fa_cl_vpx, _484), dot(_440.fa_cl_vpy, _484)) / float2(_491);\n    int _517 = int(_440.fa_cl_grid.x);\n    int _521 = int(_440.fa_cl_grid.y);\n    int param = (int(_440.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_440.fa_cl_fwd.xyz, world_pos) + _440.fa_cl_fwd.w, _440.fa_cl_grid.w) / _440.fa_cl_grid.w) * _440.fa_cl_grid.z)), 0, int(_440.fa_cl_info.y) - 1) * _521) + clamp(int(floor(((_513.y * 0.5) + 0.5) * _440.fa_cl_grid.y)), 0, _521 - 1)) * _517)) + clamp(int(floor(((_513.x * 0.5) + 0.5) * _440.fa_cl_grid.x)), 0, _517 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _440)\n{\n    float3 param = world_pos;\n    float4 _597 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _440);\n    return int2(int(_597.x), int(_597.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _440, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_440.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2254 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _440);\n    fa_cl_slot = _2254.x;\n    fa_cl_local = _2254.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2402 = fa_linear_to_srgb(param);\n        c = _2402;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2410 = fa_srgb_to_linear(param_1);\n            c = _2410;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _204;\n    if (bool(i.front_facing))\n    {\n        _204 = i.world_normal;\n    }\n    else\n    {\n        _204 = -i.world_normal;\n    }\n    float3 _228 = fast::normalize(i.world_tangent.xyz - (_204 * dot(_204, i.world_tangent.xyz)));\n    float3 _256 = fast::normalize(((_228 * m.x) + ((cross(_204, _228) * i.world_tangent.w) * m.y)) + (_204 * m.z));\n    float3 _259;\n    if (bool(i.front_facing))\n    {\n        _259 = _256;\n    }\n    else\n    {\n        _259 = -_256;\n    }\n    return _259;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _440, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _440.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2441 = fa_tex_fix(param_2, param_3);\n    float4 _3453 = base_t;\n    _3453.x = _2441.x;\n    _3453.y = _2441.y;\n    _3453.z = _2441.z;\n    base_t = _3453;\n    float4 _2455 = (_3453 * _440.fa_base_color) * i.vertex_color;\n    float3 _3333 = i.world_normal;\n    if (_440.fa_maps.z > 0.5)\n    {\n        float param_4 = _440.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2487 = fa_tex_fix(param_6, param_7);\n        float3 _2490 = (_2487 * 2.0) - float3(1.0);\n        float2 _2495 = _2490.xy * _440.fa_maps.x;\n        float3 _3461 = _2490;\n        _3461.x = _2495.x;\n        _3461.y = _2495.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3461;\n        _3333 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _440.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2524 = fa_tex_fix(param_12, param_13);\n    float4 _3464 = mrt;\n    _3464.x = _2524.x;\n    _3464.y = _2524.y;\n    _3464.z = _2524.z;\n    mrt = _3464;\n    float4 _2552 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _440.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2552.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2564 = fa_tex_fix(param_16, param_17);\n    float param_18 = _440.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2594 = fa_tex_fix(param_20, param_21);\n    float _3338 = _440.fa_layers_a.x;\n    float _3339 = _440.fa_layers_a.y;\n    float _3342 = _440.fa_layers_a.z;\n    float _3341 = _440.fa_layers_b.w;\n    float _3344 = _440.fa_layers_c.x;\n    if (_440.fa_layers_c.z > 0.5)\n    {\n        if (mod(_440.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3338 *= _2564.y;\n            _3339 *= _2564.z;\n            _3341 *= _2552.w;\n        }\n        if (_440.fa_layers_c.z > 1.5)\n        {\n            _3342 *= mrt.x;\n            _3344 *= mrt.w;\n        }\n    }\n    return Surface{ _2455.xyz, _2455.w, _3333, fast::clamp(_440.fa_pbr.x * _2524.z, 0.0, 1.0), fast::clamp(_440.fa_pbr.y * _2524.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_440.fa_maps.y * (_2564.x - 1.0)), _440.fa_emissive.xyz + (_440.fa_model_emissive.xyz * _2594), _3338, _3339, _440.fa_layers_b.xyz, _3341, _3342, _440.fa_layers_a.w, _3344, _440.fa_layers_c.y, _440.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _678 = rect.zw - rect.xy;\n    float2 _682 = _678 * atlas;\n    float2 _686 = ddx * _682;\n    float2 _690 = ddy * _682;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _678)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_686, _686), dot(_690, _690)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _440, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _725 = _440.fa_counts.y < 0.5;\n    bool _732;\n    if (!_725)\n    {\n        _732 = _440.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _732 = _725;\n    }\n    if (_732)\n    {\n        return;\n    }\n    float3 _738 = dfdx(world_pos);\n    float3 _741 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _745 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _440);\n    int _749 = int(_745.w);\n    if (_749 < 1)\n    {\n        return;\n    }\n    int _759 = int(_440.fa_counts.y + 0.5);\n    int param_1 = _759;\n    float4 _763 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _766 = _763.yz;\n    int _770 = int(_763.w);\n    int param_2 = _759 + 1;\n    float4 _775 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _776 = _775.x;\n    int _782 = int(_440.fa_counts.w + 0.5) - 1;\n    int _786 = int(_745.z);\n    float3 _1052;\n    for (int k = 0; k < _749; k++)\n    {\n        int _799 = _786 + k;\n        int param_3 = _770 + (_799 >> 2);\n        int _817 = (_759 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_799 & 3]) * 7);\n        int param_4 = _817 + 6;\n        float4 _822 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_822.w + 0.5) >> _782) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _817;\n        float4 _837 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _817 + 1;\n        float4 _842 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _817 + 2;\n        float4 _847 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _850 = _837.xyz;\n        float _855 = dot(_850, world_pos) + _837.w;\n        float3 _857 = _842.xyz;\n        float _862 = dot(_857, world_pos) + _842.w;\n        float3 _864 = _847.xyz;\n        float _869 = dot(_864, world_pos) + _847.w;\n        bool _874 = abs(_855) > 0.5;\n        bool _882;\n        if (!_874)\n        {\n            _882 = abs(_862) > 0.5;\n        }\n        else\n        {\n            _882 = _874;\n        }\n        bool _890;\n        if (!_882)\n        {\n            _890 = abs(_869) > 0.5;\n        }\n        else\n        {\n            _890 = _882;\n        }\n        if (_890)\n        {\n            continue;\n        }\n        float _905 = fast::clamp(dot(geo_normal, fast::normalize(_864)) * _822.z, 0.0, 1.0);\n        if (_905 <= 0.0)\n        {\n            continue;\n        }\n        float _925 = (fast::clamp((0.5 - abs(_869)) * 10.0, 0.0, 1.0) * _905) * _822.x;\n        float2 _933 = float2(_855 + 0.5, 0.5 - _862);\n        float2 _943 = float2(dot(_850, _738), dot(_857, _738));\n        float2 _953 = float2(dot(_850, _741), dot(_857, _741));\n        int param_8 = _817 + 5;\n        float4 _958 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _817 + 3;\n        float4 _963 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _817 + 4;\n        float4 _968 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _958.xyz;\n        bool _978 = _963.z > _963.x;\n        if (_978)\n        {\n            float4 param_11 = _963;\n            float2 param_12 = _933;\n            float2 param_13 = _766;\n            float2 param_14 = _943;\n            float2 param_15 = _953;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_776 > 0.5) && (_776 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1004 = fa_dc_to_linear(param_16);\n                float4 _3389 = tx;\n                _3389.x = _1004.x;\n                _3389.y = _1004.y;\n                _3389.z = _1004.z;\n                tx = _3389;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_925 * tex_a) * _958.w, 0.0, 1.0)));\n        if (_968.z > _968.x)\n        {\n            float4 param_17 = _968;\n            float2 param_18 = _933;\n            float2 param_19 = _766;\n            float2 param_20 = _943;\n            float2 param_21 = _953;\n            float4 _1048 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_776 > 1.5)\n            {\n                float3 param_22 = _1048.xyz;\n                float3 _1058 = fa_dc_to_srgb(param_22);\n                _1052 = _1058;\n            }\n            else\n            {\n                _1052 = _1048.xyz;\n            }\n            float3 _1068 = (_1052 * 2.0) - float3(1.0);\n            float2 _1073 = _1068.xy * _822.y;\n            float3 _1095 = (fast::normalize(_850) * _1073.x) + (fast::normalize(_857) * _1073.y);\n            float3 _1098 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1098, fast::normalize((_1098 * fast::max(_1068.z, 0.0500000007450580596923828125)) + (_1095 - (_1098 * dot(_1098, _1095)))), float3(fast::clamp(_925 * (_978 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _440, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_440.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _440.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _440, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _440, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _440)\n{\n    int param = (int(_440.fa_cl_info.x) + int(_440.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _440, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _440);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _315 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _321 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _324 = _321.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _330 = _324 < 0.5;\n    float3 l;\n    if (_330)\n    {\n        l = fast::normalize(_315.xyz);\n    }\n    else\n    {\n        float3 _342 = _315.xyz - world_pos;\n        float _344 = length(_342);\n        dist = _344;\n        l = _342 / float3(fast::max(_344, 9.9999997473787516355514526367188e-05));\n        float _359 = _344 / fast::max(_315.w, 0.001000000047497451305389404296875);\n        float _365 = fast::clamp(1.0 - (_359 * _359), 0.0, 1.0);\n        atten = _365 * _365;\n        if (_324 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _379 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _389 = _379.w;\n            int param_3 = (li * 4) + 3;\n            float4 _395 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _396 = _395.x;\n            float cos_inner = _396;\n            if (_396 > 1.5)\n            {\n                cos_inner = mix(_389, 1.0, 0.25);\n            }\n            atten *= smoothstep(_389, cos_inner, dot(-l, fast::normalize(_379.xyz)));\n        }\n    }\n    int _426;\n    if (_330)\n    {\n        _426 = 0;\n    }\n    else\n    {\n        _426 = (_324 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _321.xyz * atten, atten, 1.0, dist, _426 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1180)\n{\n    float _1170;\n    if (i == 0)\n    {\n        _1170 = _1180.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1186;\n        if (i == 1)\n        {\n            _1186 = _1180.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1194;\n            if (i == 2)\n            {\n                _1194 = _1180.fa_shadow_split.z;\n            }\n            else\n            {\n                _1194 = _1180.fa_shadow_split.w;\n            }\n            _1186 = _1194;\n        }\n        _1170 = _1186;\n    }\n    return _1170;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1227 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1231;\n    if (conv.x < 0.5)\n    {\n        _1231 = _1227;\n    }\n    else\n    {\n        _1231 = (conv.y * conv.z) / (conv.z - (_1227 * (conv.z - conv.y)));\n    }\n    return _1231;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1158 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1158), sin(_1158)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1180, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1277 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1291 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1277;\n            float2 _1310 = fa_shadow_vogel(param_3, param_4, param_5) * _1291;\n            float2 param_6 = uv + (_1310 * _1180.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1322 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1322 < (zr - (length(_1310) * plane)))\n            {\n                sum += _1322;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1366 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1366; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1366;\n        float param_11 = _1277;\n        float2 _1385 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1385 * _1180.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1385) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1366);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1180, texture2d<float> fa_shadow_tex)\n{\n    float _1427 = fast::max(_1180.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1432 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1438 = sqrt(1.0 - (_1432 * _1432));\n    float _1445 = fast::min(_1438 / fast::max(_1432, 0.20000000298023223876953125), 4.0);\n    float _1450;\n    if (_1180.fa_shadow_bias.y > 0.0)\n    {\n        _1450 = _1180.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1450 = 1.5 * _1180.fa_shadow_info[ci].x;\n    }\n    float4 _1475 = _1180.fa_shadow_mat[ci] * float4(world + (n * (_1450 * _1438)), 1.0);\n    float _1482 = _1475.x;\n    bool _1485 = _1482 < _1180.fa_shadow_rect[ci].x;\n    bool _1494;\n    if (!_1485)\n    {\n        _1494 = _1482 > _1180.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1494 = _1485;\n    }\n    bool _1503;\n    if (!_1494)\n    {\n        _1503 = _1475.y < _1180.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1503 = _1494;\n    }\n    bool _1512;\n    if (!_1503)\n    {\n        _1512 = _1475.y > _1180.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1512 = _1503;\n    }\n    bool _1519;\n    if (!_1512)\n    {\n        _1519 = _1475.z > 1.0;\n    }\n    else\n    {\n        _1519 = _1512;\n    }\n    if (_1519)\n    {\n        return -1.0;\n    }\n    float _1528;\n    if (_1180.fa_shadow_bias.x > 0.0)\n    {\n        _1528 = _1180.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1528 = 1.5 * _1180.fa_shadow_info[ci].x;\n    }\n    float2 param = _1475.xy;\n    float4 param_1 = _1180.fa_shadow_rect[ci];\n    float param_2 = _1475.z - ((_1528 * (1.0 + (0.5 * _1445))) / _1427);\n    float param_3 = _1180.fa_shadow_info[ci].x;\n    float param_4 = _1427;\n    float param_5 = _1427 * 0.25;\n    float param_6 = ((_1180.fa_shadow_info[ci].x * fast::min(_1445, 3.0)) * 0.5) / _1427;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1180.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1180.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1180, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _440, thread float4& gl_FragCoord, constant fa_shadows& _1180, texture2d<float> fa_shadow_tex)\n{\n    if (_440.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1955 = int(_1180.fa_shadow_cfg.x + 0.5);\n    if (_1955 < 1)\n    {\n        return 1.0;\n    }\n    float _1970 = dot(world - _1180.fa_shadow_eye.xyz, _1180.fa_shadow_fwd.xyz);\n    int param = _1955 - 1;\n    if (_1970 > fa_shadow_split_at(param, _1180))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1982 = _1955 > 1;\n    bool _1989;\n    if (_1982)\n    {\n        _1989 = _1970 > _1180.fa_shadow_split.x;\n    }\n    else\n    {\n        _1989 = _1982;\n    }\n    if (_1989)\n    {\n        ci = 1;\n    }\n    bool _1993 = _1955 > 2;\n    bool _2000;\n    if (_1993)\n    {\n        _2000 = _1970 > _1180.fa_shadow_split.y;\n    }\n    else\n    {\n        _2000 = _1993;\n    }\n    if (_2000)\n    {\n        ci = 2;\n    }\n    bool _2004 = _1955 > 3;\n    bool _2011;\n    if (_2004)\n    {\n        _2011 = _1970 > _1180.fa_shadow_split.z;\n    }\n    else\n    {\n        _2011 = _2004;\n    }\n    if (_2011)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1955)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2037 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1180, fa_shadow_tex);\n        s = _2037;\n        if (_2037 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1180.fa_shadow_cfg.y > 0.0)\n    {\n        float _2062;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2062 = fa_shadow_split_at(param_5, _1180);\n        }\n        else\n        {\n            _2062 = _1180.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2081 = _1180.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1180) - _2062, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2092 = fast::clamp((_1970 - (fa_shadow_split_at(param_7, _1180) - _2081)) / _2081, 0.0, 1.0);\n        if (_2092 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1955)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2113 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1180, fa_shadow_tex);\n                s2 = _2113;\n                if (_2113 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2092);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _440, thread float4& gl_FragCoord, constant fa_shadows& _1180, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _440, gl_FragCoord, _1180, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _440, thread float4& gl_FragCoord, constant fa_shadows& _1180, texture2d<float> fa_shadow_tex)\n{\n    bool _1586 = _440.fa_pbr.z < 0.5;\n    bool _1594;\n    if (!_1586)\n    {\n        _1594 = _1180.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1594 = _1586;\n    }\n    if (_1594)\n    {\n        return 1.0;\n    }\n    int param = (int(_1180.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1607 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1608 = _1607.x;\n    if (_1608 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1617 = int(_1608 + 0.5);\n    int param_1 = _1617;\n    float4 _1621 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1617 + 1;\n    float4 _1626 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1629 = _1621.y;\n    if (_1629 > 0.0)\n    {\n        float _1646 = 1.0 - smoothstep(0.75 * _1629, _1629, length(world - _1180.fa_shadow_eye.xyz));\n        fade = _1646;\n        if (_1646 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1621.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1665 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1668 = abs(_1665);\n        float _1670 = _1668.x;\n        float _1672 = _1668.y;\n        bool _1673 = _1670 >= _1672;\n        bool _1681;\n        if (_1673)\n        {\n            _1681 = _1670 >= _1668.z;\n        }\n        else\n        {\n            _1681 = _1673;\n        }\n        int _1682;\n        if (_1681)\n        {\n            _1682 = (_1665.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1695;\n            if (_1672 >= _1668.z)\n            {\n                _1695 = (_1665.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1695 = (_1665.z > 0.0) ? 4 : 5;\n            }\n            _1682 = _1695;\n        }\n        face = _1682;\n    }\n    int _1714 = (_1617 + 2) + (face * 6);\n    int param_4 = _1714;\n    int param_5 = _1714 + 1;\n    int param_6 = _1714 + 3;\n    float4 _1728 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1714 + 4;\n    float4 _1733 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1714 + 5;\n    float4 _1738 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1750 = _1738.x * fast::max(dot(_1728, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1755 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1778 = fast::clamp(dot(n, _1728.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1801 = fast::min(sqrt(1.0 - (_1778 * _1778)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1728, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1804 = _1626.y;\n    float _1806;\n    if (_1804 > 0.0)\n    {\n        _1806 = _1804;\n    }\n    else\n    {\n        _1806 = 1.5 * _1750;\n    }\n    float4 _1826 = float4(world + (n * (_1806 * sqrt(1.0 - (_1755 * _1755)))), 1.0);\n    float _1830 = dot(_1728, _1826);\n    float _1833 = _1738.y;\n    if (_1830 < _1833)\n    {\n        return 1.0;\n    }\n    float2 _1848 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1826), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1826)) / float2(_1830);\n    float _1850 = _1848.x;\n    bool _1853 = _1850 < _1733.x;\n    bool _1862;\n    if (!_1853)\n    {\n        _1862 = _1850 > _1733.z;\n    }\n    else\n    {\n        _1862 = _1853;\n    }\n    bool _1871;\n    if (!_1862)\n    {\n        _1871 = _1848.y < _1733.y;\n    }\n    else\n    {\n        _1871 = _1862;\n    }\n    bool _1880;\n    if (!_1871)\n    {\n        _1880 = _1848.y > _1733.w;\n    }\n    else\n    {\n        _1880 = _1871;\n    }\n    if (_1880)\n    {\n        return 1.0;\n    }\n    float _1886 = _1626.x;\n    float _1888;\n    if (_1886 > 0.0)\n    {\n        _1888 = _1886;\n    }\n    else\n    {\n        _1888 = 1.5 * _1750;\n    }\n    float2 param_10 = _1848;\n    float4 param_11 = _1733;\n    float param_12 = _1830 - (_1888 * (1.0 + (0.5 * _1801)));\n    float param_13 = _1750;\n    float param_14 = 1.0;\n    float param_15 = _1738.z * 0.25;\n    float param_16 = (_1750 * fast::min(_1801, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1833, _1738.z);\n    int param_18 = int(_1621.z + 0.5);\n    float param_19 = _1621.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1180, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _440, thread float4& gl_FragCoord, constant fa_shadows& _1180, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _2281 = fa_lm.z > 0.5;\n    bool _2287;\n    if (_2281)\n    {\n        int param = li;\n        _2287 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2287 = _2281;\n    }\n    if (_2287)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2310 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _3318 = _2310.direction;\n    float3 _3313 = _2310.color;\n    float _3320 = _2310.attenuation;\n    float _3315 = _2310.shadow;\n    int _3323 = _2310.type;\n    if ((_3323 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3318;\n        float _2324 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _440, gl_FragCoord, _1180, fa_shadow_tex, fa_world_pos);\n        _3315 = _2324;\n        _3313 *= _2324;\n    }\n    else\n    {\n        bool _2335 = _3323 != 0;\n        bool _2341;\n        if (_2335)\n        {\n            _2341 = _3320 > 0.0;\n        }\n        else\n        {\n            _2341 = _2335;\n        }\n        if (_2341)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3318;\n            float _2353 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _440, gl_FragCoord, _1180, fa_shadow_tex);\n            _3315 = _2353;\n            _3313 *= _2353;\n        }\n    }\n    return LightSample{ _3318, _3313, _3320, _3315, _2310._distance, _3323 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1180)\n{\n    if (_1180.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2137 = int(_1180.fa_shadow_cfg.x + 0.5);\n    float _2147 = dot(world - _1180.fa_shadow_eye.xyz, _1180.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2152 = _2137 > 0;\n    bool _2161;\n    if (_2152)\n    {\n        int param = _2137 - 1;\n        _2161 = _2147 <= fa_shadow_split_at(param, _1180);\n    }\n    else\n    {\n        _2161 = _2152;\n    }\n    if (_2161)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2168 = _2137 > 1;\n        bool _2175;\n        if (_2168)\n        {\n            _2175 = _2147 > _1180.fa_shadow_split.x;\n        }\n        else\n        {\n            _2175 = _2168;\n        }\n        if (_2175)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2181 = _2137 > 2;\n        bool _2188;\n        if (_2181)\n        {\n            _2188 = _2147 > _1180.fa_shadow_split.y;\n        }\n        else\n        {\n            _2188 = _2181;\n        }\n        if (_2188)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2194 = _2137 > 3;\n        bool _2201;\n        if (_2194)\n        {\n            _2201 = _2147 > _1180.fa_shadow_split.z;\n        }\n        else\n        {\n            _2201 = _2194;\n        }\n        if (_2201)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _440 [[buffer(1)]], constant fa_shadows& _1180 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3154 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3154 = -_3154;\n    }\n    float3 _2738 = fast::normalize(_440.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _440, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3154, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2738, short(gl_FrontFacing) };\n    Surface _2746 = fa_standard_surface(param_1, _440, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3185 = _2746.albedo;\n    float _3186 = _2746.alpha;\n    float3 _3187 = _2746.normal;\n    float _3188 = _2746.metallic;\n    float _3189 = _2746.roughness;\n    float _3190 = _2746.occlusion;\n    float3 _3191 = _2746.emission;\n    float _3192 = _2746.clearcoat;\n    float _3193 = _2746.clearcoat_roughness;\n    float3 _3194 = _2746.sheen_color;\n    float _3195 = _2746.sheen_roughness;\n    float _3196 = _2746.anisotropy;\n    float _3197 = _2746.anisotropy_rotation;\n    float _3198 = _2746.specular;\n    float _3199 = _2746.ior;\n    float3 _3200 = _2746.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3154, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2738, short(gl_FrontFacing) };\n    Surface param_3 = _2746;\n    surface(param_2, param_3);\n    _3185 = param_3.albedo;\n    _3186 = param_3.alpha;\n    _3187 = param_3.normal;\n    _3188 = param_3.metallic;\n    _3189 = param_3.roughness;\n    _3190 = param_3.occlusion;\n    _3191 = param_3.emission;\n    _3192 = param_3.clearcoat;\n    _3193 = param_3.clearcoat_roughness;\n    _3194 = param_3.sheen_color;\n    _3195 = param_3.sheen_roughness;\n    _3196 = param_3.anisotropy;\n    _3197 = param_3.anisotropy_rotation;\n    _3198 = param_3.specular;\n    _3199 = param_3.ior;\n    _3200 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _3154;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _440, fa_decal_tex, fa_env_smp);\n    _3185 = param_6;\n    _3187 = param_7;\n    float3 result;\n    if (_440.fa_emissive.w > 0.5)\n    {\n        result = _3185;\n    }\n    else\n    {\n        float3 _2784 = _3187;\n        float3 _2785 = fast::normalize(_2784);\n        _3187 = _2785;\n        float3 param_8 = _2785;\n        float3 lit = (fa_indirect_diffuse(param_8, _440, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap) * _3185) * _3190;\n        int _2804 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2804; ln++)\n        {\n            int param_9 = ln;\n            int _2817 = fa_cl_light(param_9, fa_light_tex, fa_shadow_smp, _440, fa_cl_ndir, fa_cl_slot);\n            bool _2820 = in.fa_lm.z > 0.5;\n            bool _2826;\n            if (_2820)\n            {\n                int param_10 = _2817;\n                _2826 = fa_light_baked(param_10, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _2826 = _2820;\n            }\n            if (_2826)\n            {\n                continue;\n            }\n            int param_11 = _2817;\n            float3 param_12 = in.fa_world_pos;\n            float3 param_13 = _3154;\n            SurfaceInput param_14 = SurfaceInput{ in.fa_world_pos, _3154, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2738, short(gl_FrontFacing) };\n            Surface param_15 = Surface{ _3185, _3186, _3187, _3188, _3189, _3190, _3191, _3192, _3193, _3194, _3195, _3196, _3197, _3198, _3199, _3200 };\n            LightSample param_16 = fa_light_shadowed(param_11, param_12, param_13, fa_light_tex, fa_shadow_smp, _440, gl_FragCoord, _1180, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _2853 = result;\n    float3 _2854 = _2853 + _3191;\n    result = _2854;\n    float3 param_17 = _2854;\n    float3 param_18 = in.fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18, _1180);\n    bool _2863 = _440.fa_fog.w > 0.0;\n    bool _2870;\n    if (!_2863)\n    {\n        _2870 = _440.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2870 = _2863;\n    }\n    if (_2870)\n    {\n        float3 _2879 = in.fa_world_pos - _440.fa_camera_pos.xyz;\n        float _2885 = dot(_2879, _440.fa_fog_c.xyz);\n        bool _2889 = _440.fa_fog_c.w > 0.5;\n        float _2890;\n        if (_2889)\n        {\n            _2890 = _2885;\n        }\n        else\n        {\n            _2890 = length(_2879);\n        }\n        float _2902 = _2890 - _440.fa_fog_b.x;\n        if (_2902 > 0.0)\n        {\n            float _2911 = _440.fa_fog.w * _2902;\n            float tau = _2911 * _2911;\n            if (_440.fa_fog_b.y > 0.0)\n            {\n                float _2927;\n                if (_2889)\n                {\n                    _2927 = in.fa_world_pos.y - (_440.fa_fog_c.y * _2885);\n                }\n                else\n                {\n                    _2927 = _440.fa_camera_pos.y;\n                }\n                float _2948 = mix(_2927, in.fa_world_pos.y, fast::clamp(_440.fa_fog_b.x / _2890, 0.0, 1.0));\n                float _2952 = in.fa_world_pos.y - _2948;\n                float _2957 = _2948 - _440.fa_fog_b.z;\n                float _2962 = in.fa_world_pos.y - _440.fa_fog_b.z;\n                bool _2965 = _2957 <= 0.0;\n                bool _2966 = !_2965;\n                bool _2972;\n                if (_2966)\n                {\n                    _2972 = _440.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2972 = _2965;\n                }\n                float _2973;\n                if (_2972)\n                {\n                    _2973 = _440.fa_fog_b.y;\n                }\n                else\n                {\n                    _2973 = _440.fa_fog_b.y * exp(-fast::min(_440.fa_fog_b.w * _2957, 80.0));\n                }\n                bool _3000;\n                if (_2966)\n                {\n                    _3000 = _440.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3000 = _2965;\n                }\n                float _3001;\n                if (_3000)\n                {\n                    _3001 = _440.fa_fog_b.y * _2957;\n                }\n                else\n                {\n                    _3001 = (_440.fa_fog_b.y * (1.0 - exp(-fast::min(_440.fa_fog_b.w * _2957, 80.0)))) / _440.fa_fog_b.w;\n                }\n                bool _3026 = _2962 <= 0.0;\n                bool _3033;\n                if (!_3026)\n                {\n                    _3033 = _440.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3033 = _3026;\n                }\n                float _3034;\n                if (_3033)\n                {\n                    _3034 = _440.fa_fog_b.y * _2962;\n                }\n                else\n                {\n                    _3034 = (_440.fa_fog_b.y * (1.0 - exp(-fast::min(_440.fa_fog_b.w * _2962, 80.0)))) / _440.fa_fog_b.w;\n                }\n                float _3061;\n                if (abs(_2952) < 0.001000000047497451305389404296875)\n                {\n                    _3061 = _2973;\n                }\n                else\n                {\n                    _3061 = (_3034 - _3001) / _2952;\n                }\n                tau += (_2902 * fast::max(_3061, 0.0));\n            }\n            result = mix(result, _440.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3186);\n    return out;\n}\n\n",
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
            "inst_name": "_440",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1180",
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
