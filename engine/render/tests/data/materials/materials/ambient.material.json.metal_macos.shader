{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "41c86c92dbb0093951c81b6ee249cbb5aa749f4b053c4954c67a5e43bd66f6f3",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_265, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394)\n{\n    bool _399 = _394.fa_cl_info.x < 0.0;\n    bool _406;\n    if (!_399)\n    {\n        _406 = _394.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _406 = _399;\n    }\n    bool _414;\n    if (!_406)\n    {\n        _414 = _394.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _414 = _406;\n    }\n    bool _421;\n    if (!_414)\n    {\n        _421 = _394.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _421 = _414;\n    }\n    bool _428;\n    if (!_421)\n    {\n        _428 = _394.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    if (_428)\n    {\n        return float4(0.0);\n    }\n    float4 _438 = float4(world_pos, 1.0);\n    float _445 = dot(_394.fa_cl_vpw, _438);\n    if (!(_445 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _467 = float2(dot(_394.fa_cl_vpx, _438), dot(_394.fa_cl_vpy, _438)) / float2(_445);\n    int _471 = int(_394.fa_cl_grid.x);\n    int _475 = int(_394.fa_cl_grid.y);\n    int param = (int(_394.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_394.fa_cl_fwd.xyz, world_pos) + _394.fa_cl_fwd.w, _394.fa_cl_grid.w) / _394.fa_cl_grid.w) * _394.fa_cl_grid.z)), 0, int(_394.fa_cl_info.y) - 1) * _475) + clamp(int(floor(((_467.y * 0.5) + 0.5) * _394.fa_cl_grid.y)), 0, _475 - 1)) * _471)) + clamp(int(floor(((_467.x * 0.5) + 0.5) * _394.fa_cl_grid.x)), 0, _471 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394)\n{\n    float3 param = world_pos;\n    float4 _551 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _394);\n    return int2(int(_551.x), int(_551.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_394.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1792 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _394);\n    fa_cl_slot = _1792.x;\n    fa_cl_local = _1792.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1888 = fa_linear_to_srgb(param);\n        c = _1888;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1896 = fa_srgb_to_linear(param_1);\n            c = _1896;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _175;\n    if (bool(i.front_facing))\n    {\n        _175 = i.world_normal;\n    }\n    else\n    {\n        _175 = -i.world_normal;\n    }\n    float3 _199 = fast::normalize(i.world_tangent.xyz - (_175 * dot(_175, i.world_tangent.xyz)));\n    float3 _227 = fast::normalize(((_199 * m.x) + ((cross(_175, _199) * i.world_tangent.w) * m.y)) + (_175 * m.z));\n    float3 _230;\n    if (bool(i.front_facing))\n    {\n        _230 = _227;\n    }\n    else\n    {\n        _230 = -_227;\n    }\n    return _230;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _394, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _394.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1927 = fa_tex_fix(param_2, param_3);\n    float4 _2682 = base_t;\n    _2682.x = _1927.x;\n    _2682.y = _1927.y;\n    _2682.z = _1927.z;\n    base_t = _2682;\n    float4 _1941 = (_2682 * _394.fa_base_color) * i.vertex_color;\n    float3 _2612 = i.world_normal;\n    if (_394.fa_maps.z > 0.5)\n    {\n        float param_4 = _394.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1973 = fa_tex_fix(param_6, param_7);\n        float3 _1976 = (_1973 * 2.0) - float3(1.0);\n        float2 _1981 = _1976.xy * _394.fa_maps.x;\n        float3 _2690 = _1976;\n        _2690.x = _1981.x;\n        _2690.y = _1981.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2690;\n        _2612 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _394.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2010 = fa_tex_fix(param_12, param_13);\n    float4 _2693 = mrt;\n    _2693.x = _2010.x;\n    _2693.y = _2010.y;\n    _2693.z = _2010.z;\n    mrt = _2693;\n    float param_14 = _394.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2049 = fa_tex_fix(param_16, param_17);\n    float param_18 = _394.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2076 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1941.xyz, _1941.w, _2612, fast::clamp(_394.fa_pbr.x * _2010.z, 0.0, 1.0), fast::clamp(_394.fa_pbr.y * _2010.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_394.fa_maps.y * (_2049.x - 1.0)), _394.fa_emissive.xyz + (_394.fa_model_emissive.xyz * _2076) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _632 = rect.zw - rect.xy;\n    float2 _636 = _632 * atlas;\n    float2 _640 = ddx * _636;\n    float2 _644 = ddy * _636;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _632)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_640, _640), dot(_644, _644)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float3 _679 = dfdx(world_pos);\n    float3 _682 = dfdy(world_pos);\n    bool _685 = _394.fa_counts.y < 0.5;\n    bool _692;\n    if (!_685)\n    {\n        _692 = _394.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _692 = _685;\n    }\n    if (_692)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _699 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _394);\n    int _703 = int(_699.w);\n    if (_703 < 1)\n    {\n        return;\n    }\n    int _713 = int(_394.fa_counts.y + 0.5);\n    int param_1 = _713;\n    float4 _717 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _720 = _717.yz;\n    int _724 = int(_717.w);\n    int param_2 = _713 + 1;\n    float4 _729 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _730 = _729.x;\n    int _736 = int(_394.fa_counts.w + 0.5) - 1;\n    int _740 = int(_699.z);\n    float3 _1006;\n    for (int k = 0; k < _703; k++)\n    {\n        int _753 = _740 + k;\n        int param_3 = _724 + (_753 >> 2);\n        int _771 = (_713 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_753 & 3]) * 7);\n        int param_4 = _771 + 6;\n        float4 _776 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_776.w + 0.5) >> _736) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _771;\n        float4 _791 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _771 + 1;\n        float4 _796 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _771 + 2;\n        float4 _801 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _804 = _791.xyz;\n        float _809 = dot(_804, world_pos) + _791.w;\n        float3 _811 = _796.xyz;\n        float _816 = dot(_811, world_pos) + _796.w;\n        float3 _818 = _801.xyz;\n        float _823 = dot(_818, world_pos) + _801.w;\n        bool _828 = abs(_809) > 0.5;\n        bool _836;\n        if (!_828)\n        {\n            _836 = abs(_816) > 0.5;\n        }\n        else\n        {\n            _836 = _828;\n        }\n        bool _844;\n        if (!_836)\n        {\n            _844 = abs(_823) > 0.5;\n        }\n        else\n        {\n            _844 = _836;\n        }\n        if (_844)\n        {\n            continue;\n        }\n        float _859 = fast::clamp(dot(geo_normal, fast::normalize(_818)) * _776.z, 0.0, 1.0);\n        if (_859 <= 0.0)\n        {\n            continue;\n        }\n        float _879 = (fast::clamp((0.5 - abs(_823)) * 10.0, 0.0, 1.0) * _859) * _776.x;\n        float2 _887 = float2(_809 + 0.5, 0.5 - _816);\n        float2 _897 = float2(dot(_804, _679), dot(_811, _679));\n        float2 _907 = float2(dot(_804, _682), dot(_811, _682));\n        int param_8 = _771 + 5;\n        float4 _912 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _771 + 3;\n        float4 _917 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _771 + 4;\n        float4 _922 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _912.xyz;\n        bool _932 = _917.z > _917.x;\n        if (_932)\n        {\n            float4 param_11 = _917;\n            float2 param_12 = _887;\n            float2 param_13 = _720;\n            float2 param_14 = _897;\n            float2 param_15 = _907;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_730 > 0.5) && (_730 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _958 = fa_dc_to_linear(param_16);\n                float4 _2650 = tx;\n                _2650.x = _958.x;\n                _2650.y = _958.y;\n                _2650.z = _958.z;\n                tx = _2650;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_879 * tex_a) * _912.w, 0.0, 1.0)));\n        if (_922.z > _922.x)\n        {\n            float4 param_17 = _922;\n            float2 param_18 = _887;\n            float2 param_19 = _720;\n            float2 param_20 = _897;\n            float2 param_21 = _907;\n            float4 _1002 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_730 > 1.5)\n            {\n                float3 param_22 = _1002.xyz;\n                float3 _1012 = fa_dc_to_srgb(param_22);\n                _1006 = _1012;\n            }\n            else\n            {\n                _1006 = _1002.xyz;\n            }\n            float3 _1022 = (_1006 * 2.0) - float3(1.0);\n            float2 _1027 = _1022.xy * _776.y;\n            float3 _1049 = (fast::normalize(_804) * _1027.x) + (fast::normalize(_811) * _1027.y);\n            float3 _1052 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1052, fast::normalize((_1052 * fast::max(_1022.z, 0.0500000007450580596923828125)) + (_1049 - (_1052 * dot(_1052, _1049)))), float3(fast::clamp(_879 * (_932 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _394, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_394.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _394.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return float3(0.0, ambientColor.y, 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394)\n{\n    int param = (int(_394.fa_cl_info.x) + int(_394.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _394);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _267 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _273 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _276 = _273.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _283 = _276 < 0.5;\n    float3 l;\n    if (_283)\n    {\n        l = fast::normalize(_267.xyz);\n    }\n    else\n    {\n        float3 _295 = _267.xyz - world_pos;\n        float _297 = length(_295);\n        dist = _297;\n        l = _295 / float3(fast::max(_297, 9.9999997473787516355514526367188e-05));\n        float _312 = _297 / fast::max(_267.w, 0.001000000047497451305389404296875);\n        float _318 = fast::clamp(1.0 - (_312 * _312), 0.0, 1.0);\n        atten = _318 * _318;\n        if (_276 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _332 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _342 = _332.w;\n            int param_3 = (li * 4) + 3;\n            float4 _349 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _350 = _349.x;\n            float cos_inner = _350;\n            if (_350 > 1.5)\n            {\n                cos_inner = mix(_342, 1.0, 0.25);\n            }\n            atten *= smoothstep(_342, cos_inner, dot(-l, fast::normalize(_332.xyz)));\n        }\n    }\n    int _380;\n    if (_283)\n    {\n        _380 = 0;\n    }\n    else\n    {\n        _380 = (_276 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _273.xyz * atten, atten, 1.0, dist, _380 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1134)\n{\n    float _1124;\n    if (i == 0)\n    {\n        _1124 = _1134.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1140;\n        if (i == 1)\n        {\n            _1140 = _1134.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1148;\n            if (i == 2)\n            {\n                _1148 = _1134.fa_shadow_split.z;\n            }\n            else\n            {\n                _1148 = _1134.fa_shadow_split.w;\n            }\n            _1140 = _1148;\n        }\n        _1124 = _1140;\n    }\n    return _1124;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1112 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1112), sin(_1112)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1134, texture2d<float> fa_shadow_tex)\n{\n    float _1186 = fast::max(_1134.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1191 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1197 = sqrt(1.0 - (_1191 * _1191));\n    float _1204 = fast::min(_1197 / fast::max(_1191, 0.20000000298023223876953125), 4.0);\n    float _1209;\n    if (_1134.fa_shadow_bias.y > 0.0)\n    {\n        _1209 = _1134.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1209 = 1.5 * _1134.fa_shadow_info[ci].x;\n    }\n    float4 _1234 = _1134.fa_shadow_mat[ci] * float4(world + (n * (_1209 * _1197)), 1.0);\n    float _1241 = _1234.x;\n    bool _1244 = _1241 < _1134.fa_shadow_rect[ci].x;\n    bool _1253;\n    if (!_1244)\n    {\n        _1253 = _1241 > _1134.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1253 = _1244;\n    }\n    bool _1262;\n    if (!_1253)\n    {\n        _1262 = _1234.y < _1134.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1262 = _1253;\n    }\n    bool _1271;\n    if (!_1262)\n    {\n        _1271 = _1234.y > _1134.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1271 = _1262;\n    }\n    bool _1278;\n    if (!_1271)\n    {\n        _1278 = _1234.z > 1.0;\n    }\n    else\n    {\n        _1278 = _1271;\n    }\n    if (_1278)\n    {\n        return -1.0;\n    }\n    float _1287;\n    if (_1134.fa_shadow_bias.x > 0.0)\n    {\n        _1287 = _1134.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1287 = 1.5 * _1134.fa_shadow_info[ci].x;\n    }\n    float _1306 = _1234.z - ((_1287 * (1.0 + (0.5 * _1204))) / _1186);\n    float _1315 = ((_1134.fa_shadow_info[ci].x * fast::min(_1204, 3.0)) * 0.5) / _1186;\n    int _1324 = int(_1134.fa_shadow_cfg.z + 0.5);\n    if (_1324 == 1)\n    {\n        float2 param = _1234.xy;\n        float4 param_1 = _1134.fa_shadow_rect[ci];\n        float _1335 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_1306 <= _1335);\n    }\n    float _1342 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1345 = _1324 == 2;\n    if (_1345)\n    {\n        float _1359 = fast::clamp(((_1134.fa_shadow_cfg.w * _1186) * 0.25) / _1134.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1342;\n            float2 _1378 = fa_shadow_vogel(param_2, param_3, param_4) * _1359;\n            float2 param_5 = _1234.xy + (_1378 * _1134.fa_shadow_bias.zw);\n            float4 param_6 = _1134.fa_shadow_rect[ci];\n            float _1389 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_1389 < (_1306 - (length(_1378) * _1315)))\n            {\n                sum += _1389;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_1306 - (sum / cnt), 0.0) * _1186) * _1134.fa_shadow_cfg.w) / _1134.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1433 = _1345 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1433; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1433;\n        float param_9 = _1342;\n        float2 _1452 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1234.xy + (_1452 * _1134.fa_shadow_bias.zw);\n        float4 param_11 = _1134.fa_shadow_rect[ci];\n        float _1463 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_1306 - (length(_1452) * _1315)) <= _1463);\n    }\n    return lit / float(_1433);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _1134, texture2d<float> fa_shadow_tex)\n{\n    if (_394.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1493 = int(_1134.fa_shadow_cfg.x + 0.5);\n    if (_1493 < 1)\n    {\n        return 1.0;\n    }\n    float _1508 = dot(world - _1134.fa_shadow_eye.xyz, _1134.fa_shadow_fwd.xyz);\n    int param = _1493 - 1;\n    if (_1508 > fa_shadow_split_at(param, _1134))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1520 = _1493 > 1;\n    bool _1527;\n    if (_1520)\n    {\n        _1527 = _1508 > _1134.fa_shadow_split.x;\n    }\n    else\n    {\n        _1527 = _1520;\n    }\n    if (_1527)\n    {\n        ci = 1;\n    }\n    bool _1531 = _1493 > 2;\n    bool _1538;\n    if (_1531)\n    {\n        _1538 = _1508 > _1134.fa_shadow_split.y;\n    }\n    else\n    {\n        _1538 = _1531;\n    }\n    if (_1538)\n    {\n        ci = 2;\n    }\n    bool _1542 = _1493 > 3;\n    bool _1549;\n    if (_1542)\n    {\n        _1549 = _1508 > _1134.fa_shadow_split.z;\n    }\n    else\n    {\n        _1549 = _1542;\n    }\n    if (_1549)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1493)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1575 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1134, fa_shadow_tex);\n        s = _1575;\n        if (_1575 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1134.fa_shadow_cfg.y > 0.0)\n    {\n        float _1600;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1600 = fa_shadow_split_at(param_5, _1134);\n        }\n        else\n        {\n            _1600 = _1134.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1619 = _1134.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1134) - _1600, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1630 = fast::clamp((_1508 - (fa_shadow_split_at(param_7, _1134) - _1619)) / _1619, 0.0, 1.0);\n        if (_1630 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1493)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1651 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1134, fa_shadow_tex);\n                s2 = _1651;\n                if (_1651 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1630);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _1134, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _394, gl_FragCoord, _1134, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _1134, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1820 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2597 = _1820.direction;\n    float3 _2592 = _1820.color;\n    float _2594 = _1820.shadow;\n    int _2602 = _1820.type;\n    if ((_2602 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2597;\n        float _1834 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _394, gl_FragCoord, _1134, fa_shadow_tex, fa_world_pos);\n        _2594 = _1834;\n        _2592 *= _1834;\n    }\n    return LightSample{ _2597, _2592, _1820.attenuation, _2594, _1820._distance, _2602 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1134)\n{\n    if (_1134.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1675 = int(_1134.fa_shadow_cfg.x + 0.5);\n    float _1685 = dot(world - _1134.fa_shadow_eye.xyz, _1134.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1690 = _1675 > 0;\n    bool _1699;\n    if (_1690)\n    {\n        int param = _1675 - 1;\n        _1699 = _1685 <= fa_shadow_split_at(param, _1134);\n    }\n    else\n    {\n        _1699 = _1690;\n    }\n    if (_1699)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1706 = _1675 > 1;\n        bool _1713;\n        if (_1706)\n        {\n            _1713 = _1685 > _1134.fa_shadow_split.x;\n        }\n        else\n        {\n            _1713 = _1706;\n        }\n        if (_1713)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1719 = _1675 > 2;\n        bool _1726;\n        if (_1719)\n        {\n            _1726 = _1685 > _1134.fa_shadow_split.y;\n        }\n        else\n        {\n            _1726 = _1719;\n        }\n        if (_1726)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1732 = _1675 > 3;\n        bool _1739;\n        if (_1732)\n        {\n            _1739 = _1685 > _1134.fa_shadow_split.z;\n        }\n        else\n        {\n            _1739 = _1732;\n        }\n        if (_1739)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _394 [[buffer(1)]], constant fa_shadows& _1134 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_decal_tex [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2475 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2475 = -_2475;\n    }\n    float3 _2119 = fast::normalize(_394.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _394, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2475, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2119, short(gl_FrontFacing) };\n    Surface _2127 = fa_standard_surface(param_1, _394, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2514 = _2127.albedo;\n    float _2515 = _2127.alpha;\n    float3 _2516 = _2127.normal;\n    float _2517 = _2127.metallic;\n    float _2518 = _2127.roughness;\n    float _2519 = _2127.occlusion;\n    float3 _2520 = _2127.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2475, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2119, short(gl_FrontFacing) };\n    Surface param_3 = _2127;\n    surface(param_2, param_3);\n    _2514 = param_3.albedo;\n    _2515 = param_3.alpha;\n    _2516 = param_3.normal;\n    _2517 = param_3.metallic;\n    _2518 = param_3.roughness;\n    _2519 = param_3.occlusion;\n    _2520 = param_3.emission;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _2475;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _394, fa_decal_tex, fa_env_smp);\n    _2514 = param_6;\n    _2516 = param_7;\n    float3 result;\n    if (_394.fa_emissive.w > 0.5)\n    {\n        result = _2514;\n    }\n    else\n    {\n        float3 _2165 = _2516;\n        float3 _2166 = fast::normalize(_2165);\n        _2516 = _2166;\n        float3 param_8 = _2166;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _2475, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2119, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _2514, _2515, _2516, _2517, _2518, _2519, _2520 };\n        float3 param_11 = fa_ambient_light(param_8, _394, fa_env_smp, fa_irr_tex);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _2185 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2185; ln++)\n        {\n            int param_12 = ln;\n            int param_13 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _394, fa_cl_ndir, fa_cl_slot);\n            float3 param_14 = in.fa_world_pos;\n            float3 param_15 = _2475;\n            SurfaceInput param_16 = SurfaceInput{ in.fa_world_pos, _2475, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2119, short(gl_FrontFacing) };\n            Surface param_17 = Surface{ _2514, _2515, _2516, _2517, _2518, _2519, _2520 };\n            LightSample param_18 = fa_light_shadowed(param_13, param_14, param_15, fa_light_tex, fa_shadow_smp, _394, gl_FragCoord, _1134, fa_shadow_tex, in.fa_world_pos);\n            lit += light(param_16, param_17, param_18);\n        }\n        result = lit;\n    }\n    float3 _2222 = result;\n    float3 _2223 = _2222 + _2520;\n    result = _2223;\n    float3 param_19 = _2223;\n    float3 param_20 = in.fa_world_pos;\n    result = fa_shadow_debug(param_19, param_20, _1134);\n    bool _2232 = _394.fa_fog.w > 0.0;\n    bool _2240;\n    if (!_2232)\n    {\n        _2240 = _394.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2240 = _2232;\n    }\n    if (_2240)\n    {\n        float3 _2249 = in.fa_world_pos - _394.fa_camera_pos.xyz;\n        float _2256 = dot(_2249, _394.fa_fog_c.xyz);\n        bool _2260 = _394.fa_fog_c.w > 0.5;\n        float _2261;\n        if (_2260)\n        {\n            _2261 = _2256;\n        }\n        else\n        {\n            _2261 = length(_2249);\n        }\n        float _2273 = _2261 - _394.fa_fog_b.x;\n        if (_2273 > 0.0)\n        {\n            float _2282 = _394.fa_fog.w * _2273;\n            float tau = _2282 * _2282;\n            if (_394.fa_fog_b.y > 0.0)\n            {\n                float _2298;\n                if (_2260)\n                {\n                    _2298 = in.fa_world_pos.y - (_394.fa_fog_c.y * _2256);\n                }\n                else\n                {\n                    _2298 = _394.fa_camera_pos.y;\n                }\n                float _2319 = mix(_2298, in.fa_world_pos.y, fast::clamp(_394.fa_fog_b.x / _2261, 0.0, 1.0));\n                float _2323 = in.fa_world_pos.y - _2319;\n                float _2328 = _2319 - _394.fa_fog_b.z;\n                float _2333 = in.fa_world_pos.y - _394.fa_fog_b.z;\n                bool _2336 = _2328 <= 0.0;\n                bool _2337 = !_2336;\n                bool _2343;\n                if (_2337)\n                {\n                    _2343 = _394.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2343 = _2336;\n                }\n                float _2344;\n                if (_2343)\n                {\n                    _2344 = _394.fa_fog_b.y;\n                }\n                else\n                {\n                    _2344 = _394.fa_fog_b.y * exp(-fast::min(_394.fa_fog_b.w * _2328, 80.0));\n                }\n                bool _2371;\n                if (_2337)\n                {\n                    _2371 = _394.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2371 = _2336;\n                }\n                float _2372;\n                if (_2371)\n                {\n                    _2372 = _394.fa_fog_b.y * _2328;\n                }\n                else\n                {\n                    _2372 = (_394.fa_fog_b.y * (1.0 - exp(-fast::min(_394.fa_fog_b.w * _2328, 80.0)))) / _394.fa_fog_b.w;\n                }\n                bool _2397 = _2333 <= 0.0;\n                bool _2404;\n                if (!_2397)\n                {\n                    _2404 = _394.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2404 = _2397;\n                }\n                float _2405;\n                if (_2404)\n                {\n                    _2405 = _394.fa_fog_b.y * _2333;\n                }\n                else\n                {\n                    _2405 = (_394.fa_fog_b.y * (1.0 - exp(-fast::min(_394.fa_fog_b.w * _2333, 80.0)))) / _394.fa_fog_b.w;\n                }\n                float _2432;\n                if (abs(_2323) < 0.001000000047497451305389404296875)\n                {\n                    _2432 = _2344;\n                }\n                else\n                {\n                    _2432 = (_2405 - _2372) / _2323;\n                }\n                tau += (_2273 * fast::max(_2432, 0.0));\n            }\n            result = mix(result, _394.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2515);\n    return out;\n}\n\n",
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
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_394",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1134",
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
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 8
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 8,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394)\n{\n    bool _399 = _394.fa_cl_info.x < 0.0;\n    bool _406;\n    if (!_399)\n    {\n        _406 = _394.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _406 = _399;\n    }\n    bool _414;\n    if (!_406)\n    {\n        _414 = _394.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _414 = _406;\n    }\n    bool _421;\n    if (!_414)\n    {\n        _421 = _394.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _421 = _414;\n    }\n    bool _428;\n    if (!_421)\n    {\n        _428 = _394.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    if (_428)\n    {\n        return float4(0.0);\n    }\n    float4 _438 = float4(world_pos, 1.0);\n    float _445 = dot(_394.fa_cl_vpw, _438);\n    if (!(_445 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _467 = float2(dot(_394.fa_cl_vpx, _438), dot(_394.fa_cl_vpy, _438)) / float2(_445);\n    int _471 = int(_394.fa_cl_grid.x);\n    int _475 = int(_394.fa_cl_grid.y);\n    int param = (int(_394.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_394.fa_cl_fwd.xyz, world_pos) + _394.fa_cl_fwd.w, _394.fa_cl_grid.w) / _394.fa_cl_grid.w) * _394.fa_cl_grid.z)), 0, int(_394.fa_cl_info.y) - 1) * _475) + clamp(int(floor(((_467.y * 0.5) + 0.5) * _394.fa_cl_grid.y)), 0, _475 - 1)) * _471)) + clamp(int(floor(((_467.x * 0.5) + 0.5) * _394.fa_cl_grid.x)), 0, _471 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394)\n{\n    float3 param = world_pos;\n    float4 _551 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _394);\n    return int2(int(_551.x), int(_551.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_394.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1792 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _394);\n    fa_cl_slot = _1792.x;\n    fa_cl_local = _1792.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1888 = fa_linear_to_srgb(param);\n        c = _1888;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1896 = fa_srgb_to_linear(param_1);\n            c = _1896;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _175;\n    if (bool(i.front_facing))\n    {\n        _175 = i.world_normal;\n    }\n    else\n    {\n        _175 = -i.world_normal;\n    }\n    float3 _199 = fast::normalize(i.world_tangent.xyz - (_175 * dot(_175, i.world_tangent.xyz)));\n    float3 _227 = fast::normalize(((_199 * m.x) + ((cross(_175, _199) * i.world_tangent.w) * m.y)) + (_175 * m.z));\n    float3 _230;\n    if (bool(i.front_facing))\n    {\n        _230 = _227;\n    }\n    else\n    {\n        _230 = -_227;\n    }\n    return _230;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _394, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _394.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1927 = fa_tex_fix(param_2, param_3);\n    float4 _2682 = base_t;\n    _2682.x = _1927.x;\n    _2682.y = _1927.y;\n    _2682.z = _1927.z;\n    base_t = _2682;\n    float4 _1941 = (_2682 * _394.fa_base_color) * i.vertex_color;\n    float3 _2612 = i.world_normal;\n    if (_394.fa_maps.z > 0.5)\n    {\n        float param_4 = _394.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1973 = fa_tex_fix(param_6, param_7);\n        float3 _1976 = (_1973 * 2.0) - float3(1.0);\n        float2 _1981 = _1976.xy * _394.fa_maps.x;\n        float3 _2690 = _1976;\n        _2690.x = _1981.x;\n        _2690.y = _1981.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2690;\n        _2612 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _394.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2010 = fa_tex_fix(param_12, param_13);\n    float4 _2693 = mrt;\n    _2693.x = _2010.x;\n    _2693.y = _2010.y;\n    _2693.z = _2010.z;\n    mrt = _2693;\n    float param_14 = _394.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2049 = fa_tex_fix(param_16, param_17);\n    float param_18 = _394.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2076 = fa_tex_fix(param_20, param_21);\n    return Surface{ _1941.xyz, _1941.w, _2612, fast::clamp(_394.fa_pbr.x * _2010.z, 0.0, 1.0), fast::clamp(_394.fa_pbr.y * _2010.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_394.fa_maps.y * (_2049.x - 1.0)), _394.fa_emissive.xyz + (_394.fa_model_emissive.xyz * _2076) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _632 = rect.zw - rect.xy;\n    float2 _636 = _632 * atlas;\n    float2 _640 = ddx * _636;\n    float2 _644 = ddy * _636;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _632)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_640, _640), dot(_644, _644)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float3 _679 = dfdx(world_pos);\n    float3 _682 = dfdy(world_pos);\n    bool _685 = _394.fa_counts.y < 0.5;\n    bool _692;\n    if (!_685)\n    {\n        _692 = _394.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _692 = _685;\n    }\n    if (_692)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _699 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _394);\n    int _703 = int(_699.w);\n    if (_703 < 1)\n    {\n        return;\n    }\n    int _713 = int(_394.fa_counts.y + 0.5);\n    int param_1 = _713;\n    float4 _717 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _720 = _717.yz;\n    int _724 = int(_717.w);\n    int param_2 = _713 + 1;\n    float4 _729 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _730 = _729.x;\n    int _736 = int(_394.fa_counts.w + 0.5) - 1;\n    int _740 = int(_699.z);\n    float3 _1006;\n    for (int k = 0; k < _703; k++)\n    {\n        int _753 = _740 + k;\n        int param_3 = _724 + (_753 >> 2);\n        int _771 = (_713 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_753 & 3]) * 7);\n        int param_4 = _771 + 6;\n        float4 _776 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_776.w + 0.5) >> _736) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _771;\n        float4 _791 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _771 + 1;\n        float4 _796 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _771 + 2;\n        float4 _801 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _804 = _791.xyz;\n        float _809 = dot(_804, world_pos) + _791.w;\n        float3 _811 = _796.xyz;\n        float _816 = dot(_811, world_pos) + _796.w;\n        float3 _818 = _801.xyz;\n        float _823 = dot(_818, world_pos) + _801.w;\n        bool _828 = abs(_809) > 0.5;\n        bool _836;\n        if (!_828)\n        {\n            _836 = abs(_816) > 0.5;\n        }\n        else\n        {\n            _836 = _828;\n        }\n        bool _844;\n        if (!_836)\n        {\n            _844 = abs(_823) > 0.5;\n        }\n        else\n        {\n            _844 = _836;\n        }\n        if (_844)\n        {\n            continue;\n        }\n        float _859 = fast::clamp(dot(geo_normal, fast::normalize(_818)) * _776.z, 0.0, 1.0);\n        if (_859 <= 0.0)\n        {\n            continue;\n        }\n        float _879 = (fast::clamp((0.5 - abs(_823)) * 10.0, 0.0, 1.0) * _859) * _776.x;\n        float2 _887 = float2(_809 + 0.5, 0.5 - _816);\n        float2 _897 = float2(dot(_804, _679), dot(_811, _679));\n        float2 _907 = float2(dot(_804, _682), dot(_811, _682));\n        int param_8 = _771 + 5;\n        float4 _912 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _771 + 3;\n        float4 _917 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _771 + 4;\n        float4 _922 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _912.xyz;\n        bool _932 = _917.z > _917.x;\n        if (_932)\n        {\n            float4 param_11 = _917;\n            float2 param_12 = _887;\n            float2 param_13 = _720;\n            float2 param_14 = _897;\n            float2 param_15 = _907;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_730 > 0.5) && (_730 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _958 = fa_dc_to_linear(param_16);\n                float4 _2650 = tx;\n                _2650.x = _958.x;\n                _2650.y = _958.y;\n                _2650.z = _958.z;\n                tx = _2650;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_879 * tex_a) * _912.w, 0.0, 1.0)));\n        if (_922.z > _922.x)\n        {\n            float4 param_17 = _922;\n            float2 param_18 = _887;\n            float2 param_19 = _720;\n            float2 param_20 = _897;\n            float2 param_21 = _907;\n            float4 _1002 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_730 > 1.5)\n            {\n                float3 param_22 = _1002.xyz;\n                float3 _1012 = fa_dc_to_srgb(param_22);\n                _1006 = _1012;\n            }\n            else\n            {\n                _1006 = _1002.xyz;\n            }\n            float3 _1022 = (_1006 * 2.0) - float3(1.0);\n            float2 _1027 = _1022.xy * _776.y;\n            float3 _1049 = (fast::normalize(_804) * _1027.x) + (fast::normalize(_811) * _1027.y);\n            float3 _1052 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1052, fast::normalize((_1052 * fast::max(_1022.z, 0.0500000007450580596923828125)) + (_1049 - (_1052 * dot(_1052, _1049)))), float3(fast::clamp(_879 * (_932 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _394, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_394.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _394.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return float3(0.0, ambientColor.y, 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394)\n{\n    int param = (int(_394.fa_cl_info.x) + int(_394.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _394);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _267 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _273 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _276 = _273.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _283 = _276 < 0.5;\n    float3 l;\n    if (_283)\n    {\n        l = fast::normalize(_267.xyz);\n    }\n    else\n    {\n        float3 _295 = _267.xyz - world_pos;\n        float _297 = length(_295);\n        dist = _297;\n        l = _295 / float3(fast::max(_297, 9.9999997473787516355514526367188e-05));\n        float _312 = _297 / fast::max(_267.w, 0.001000000047497451305389404296875);\n        float _318 = fast::clamp(1.0 - (_312 * _312), 0.0, 1.0);\n        atten = _318 * _318;\n        if (_276 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _332 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _342 = _332.w;\n            int param_3 = (li * 4) + 3;\n            float4 _349 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _350 = _349.x;\n            float cos_inner = _350;\n            if (_350 > 1.5)\n            {\n                cos_inner = mix(_342, 1.0, 0.25);\n            }\n            atten *= smoothstep(_342, cos_inner, dot(-l, fast::normalize(_332.xyz)));\n        }\n    }\n    int _380;\n    if (_283)\n    {\n        _380 = 0;\n    }\n    else\n    {\n        _380 = (_276 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _273.xyz * atten, atten, 1.0, dist, _380 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1134)\n{\n    float _1124;\n    if (i == 0)\n    {\n        _1124 = _1134.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1140;\n        if (i == 1)\n        {\n            _1140 = _1134.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1148;\n            if (i == 2)\n            {\n                _1148 = _1134.fa_shadow_split.z;\n            }\n            else\n            {\n                _1148 = _1134.fa_shadow_split.w;\n            }\n            _1140 = _1148;\n        }\n        _1124 = _1140;\n    }\n    return _1124;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1112 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1112), sin(_1112)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1134, texture2d<float> fa_shadow_tex)\n{\n    float _1186 = fast::max(_1134.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1191 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1197 = sqrt(1.0 - (_1191 * _1191));\n    float _1204 = fast::min(_1197 / fast::max(_1191, 0.20000000298023223876953125), 4.0);\n    float _1209;\n    if (_1134.fa_shadow_bias.y > 0.0)\n    {\n        _1209 = _1134.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1209 = 1.5 * _1134.fa_shadow_info[ci].x;\n    }\n    float4 _1234 = _1134.fa_shadow_mat[ci] * float4(world + (n * (_1209 * _1197)), 1.0);\n    float _1241 = _1234.x;\n    bool _1244 = _1241 < _1134.fa_shadow_rect[ci].x;\n    bool _1253;\n    if (!_1244)\n    {\n        _1253 = _1241 > _1134.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1253 = _1244;\n    }\n    bool _1262;\n    if (!_1253)\n    {\n        _1262 = _1234.y < _1134.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1262 = _1253;\n    }\n    bool _1271;\n    if (!_1262)\n    {\n        _1271 = _1234.y > _1134.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1271 = _1262;\n    }\n    bool _1278;\n    if (!_1271)\n    {\n        _1278 = _1234.z > 1.0;\n    }\n    else\n    {\n        _1278 = _1271;\n    }\n    if (_1278)\n    {\n        return -1.0;\n    }\n    float _1287;\n    if (_1134.fa_shadow_bias.x > 0.0)\n    {\n        _1287 = _1134.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1287 = 1.5 * _1134.fa_shadow_info[ci].x;\n    }\n    float _1306 = _1234.z - ((_1287 * (1.0 + (0.5 * _1204))) / _1186);\n    float _1315 = ((_1134.fa_shadow_info[ci].x * fast::min(_1204, 3.0)) * 0.5) / _1186;\n    int _1324 = int(_1134.fa_shadow_cfg.z + 0.5);\n    if (_1324 == 1)\n    {\n        float2 param = _1234.xy;\n        float4 param_1 = _1134.fa_shadow_rect[ci];\n        float _1335 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_1306 <= _1335);\n    }\n    float _1342 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1345 = _1324 == 2;\n    if (_1345)\n    {\n        float _1359 = fast::clamp(((_1134.fa_shadow_cfg.w * _1186) * 0.25) / _1134.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1342;\n            float2 _1378 = fa_shadow_vogel(param_2, param_3, param_4) * _1359;\n            float2 param_5 = _1234.xy + (_1378 * _1134.fa_shadow_bias.zw);\n            float4 param_6 = _1134.fa_shadow_rect[ci];\n            float _1389 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_1389 < (_1306 - (length(_1378) * _1315)))\n            {\n                sum += _1389;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_1306 - (sum / cnt), 0.0) * _1186) * _1134.fa_shadow_cfg.w) / _1134.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1433 = _1345 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1433; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1433;\n        float param_9 = _1342;\n        float2 _1452 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1234.xy + (_1452 * _1134.fa_shadow_bias.zw);\n        float4 param_11 = _1134.fa_shadow_rect[ci];\n        float _1463 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_1306 - (length(_1452) * _1315)) <= _1463);\n    }\n    return lit / float(_1433);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _1134, texture2d<float> fa_shadow_tex)\n{\n    if (_394.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1493 = int(_1134.fa_shadow_cfg.x + 0.5);\n    if (_1493 < 1)\n    {\n        return 1.0;\n    }\n    float _1508 = dot(world - _1134.fa_shadow_eye.xyz, _1134.fa_shadow_fwd.xyz);\n    int param = _1493 - 1;\n    if (_1508 > fa_shadow_split_at(param, _1134))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1520 = _1493 > 1;\n    bool _1527;\n    if (_1520)\n    {\n        _1527 = _1508 > _1134.fa_shadow_split.x;\n    }\n    else\n    {\n        _1527 = _1520;\n    }\n    if (_1527)\n    {\n        ci = 1;\n    }\n    bool _1531 = _1493 > 2;\n    bool _1538;\n    if (_1531)\n    {\n        _1538 = _1508 > _1134.fa_shadow_split.y;\n    }\n    else\n    {\n        _1538 = _1531;\n    }\n    if (_1538)\n    {\n        ci = 2;\n    }\n    bool _1542 = _1493 > 3;\n    bool _1549;\n    if (_1542)\n    {\n        _1549 = _1508 > _1134.fa_shadow_split.z;\n    }\n    else\n    {\n        _1549 = _1542;\n    }\n    if (_1549)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1493)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1575 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1134, fa_shadow_tex);\n        s = _1575;\n        if (_1575 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1134.fa_shadow_cfg.y > 0.0)\n    {\n        float _1600;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1600 = fa_shadow_split_at(param_5, _1134);\n        }\n        else\n        {\n            _1600 = _1134.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1619 = _1134.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1134) - _1600, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1630 = fast::clamp((_1508 - (fa_shadow_split_at(param_7, _1134) - _1619)) / _1619, 0.0, 1.0);\n        if (_1630 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1493)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1651 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1134, fa_shadow_tex);\n                s2 = _1651;\n                if (_1651 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1630);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _1134, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _394, gl_FragCoord, _1134, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _394, thread float4& gl_FragCoord, constant fa_shadows& _1134, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1820 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2597 = _1820.direction;\n    float3 _2592 = _1820.color;\n    float _2594 = _1820.shadow;\n    int _2602 = _1820.type;\n    if ((_2602 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2597;\n        float _1834 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _394, gl_FragCoord, _1134, fa_shadow_tex, fa_world_pos);\n        _2594 = _1834;\n        _2592 *= _1834;\n    }\n    return LightSample{ _2597, _2592, _1820.attenuation, _2594, _1820._distance, _2602 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1134)\n{\n    if (_1134.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1675 = int(_1134.fa_shadow_cfg.x + 0.5);\n    float _1685 = dot(world - _1134.fa_shadow_eye.xyz, _1134.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1690 = _1675 > 0;\n    bool _1699;\n    if (_1690)\n    {\n        int param = _1675 - 1;\n        _1699 = _1685 <= fa_shadow_split_at(param, _1134);\n    }\n    else\n    {\n        _1699 = _1690;\n    }\n    if (_1699)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1706 = _1675 > 1;\n        bool _1713;\n        if (_1706)\n        {\n            _1713 = _1685 > _1134.fa_shadow_split.x;\n        }\n        else\n        {\n            _1713 = _1706;\n        }\n        if (_1713)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1719 = _1675 > 2;\n        bool _1726;\n        if (_1719)\n        {\n            _1726 = _1685 > _1134.fa_shadow_split.y;\n        }\n        else\n        {\n            _1726 = _1719;\n        }\n        if (_1726)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1732 = _1675 > 3;\n        bool _1739;\n        if (_1732)\n        {\n            _1739 = _1685 > _1134.fa_shadow_split.z;\n        }\n        else\n        {\n            _1739 = _1732;\n        }\n        if (_1739)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _394 [[buffer(1)]], constant fa_shadows& _1134 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_decal_tex [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2475 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2475 = -_2475;\n    }\n    float3 _2119 = fast::normalize(_394.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _394, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2475, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2119, short(gl_FrontFacing) };\n    Surface _2127 = fa_standard_surface(param_1, _394, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2514 = _2127.albedo;\n    float _2515 = _2127.alpha;\n    float3 _2516 = _2127.normal;\n    float _2517 = _2127.metallic;\n    float _2518 = _2127.roughness;\n    float _2519 = _2127.occlusion;\n    float3 _2520 = _2127.emission;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2475, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2119, short(gl_FrontFacing) };\n    Surface param_3 = _2127;\n    surface(param_2, param_3);\n    _2514 = param_3.albedo;\n    _2515 = param_3.alpha;\n    _2516 = param_3.normal;\n    _2517 = param_3.metallic;\n    _2518 = param_3.roughness;\n    _2519 = param_3.occlusion;\n    _2520 = param_3.emission;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _2475;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _394, fa_decal_tex, fa_env_smp);\n    _2514 = param_6;\n    _2516 = param_7;\n    float3 result;\n    if (_394.fa_emissive.w > 0.5)\n    {\n        result = _2514;\n    }\n    else\n    {\n        float3 _2165 = _2516;\n        float3 _2166 = fast::normalize(_2165);\n        _2516 = _2166;\n        float3 param_8 = _2166;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _2475, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2119, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _2514, _2515, _2516, _2517, _2518, _2519, _2520 };\n        float3 param_11 = fa_ambient_light(param_8, _394, fa_env_smp, fa_irr_tex);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _2185 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2185; ln++)\n        {\n            int param_12 = ln;\n            int param_13 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _394, fa_cl_ndir, fa_cl_slot);\n            float3 param_14 = in.fa_world_pos;\n            float3 param_15 = _2475;\n            SurfaceInput param_16 = SurfaceInput{ in.fa_world_pos, _2475, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2119, short(gl_FrontFacing) };\n            Surface param_17 = Surface{ _2514, _2515, _2516, _2517, _2518, _2519, _2520 };\n            LightSample param_18 = fa_light_shadowed(param_13, param_14, param_15, fa_light_tex, fa_shadow_smp, _394, gl_FragCoord, _1134, fa_shadow_tex, in.fa_world_pos);\n            lit += light(param_16, param_17, param_18);\n        }\n        result = lit;\n    }\n    float3 _2222 = result;\n    float3 _2223 = _2222 + _2520;\n    result = _2223;\n    float3 param_19 = _2223;\n    float3 param_20 = in.fa_world_pos;\n    result = fa_shadow_debug(param_19, param_20, _1134);\n    bool _2232 = _394.fa_fog.w > 0.0;\n    bool _2240;\n    if (!_2232)\n    {\n        _2240 = _394.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2240 = _2232;\n    }\n    if (_2240)\n    {\n        float3 _2249 = in.fa_world_pos - _394.fa_camera_pos.xyz;\n        float _2256 = dot(_2249, _394.fa_fog_c.xyz);\n        bool _2260 = _394.fa_fog_c.w > 0.5;\n        float _2261;\n        if (_2260)\n        {\n            _2261 = _2256;\n        }\n        else\n        {\n            _2261 = length(_2249);\n        }\n        float _2273 = _2261 - _394.fa_fog_b.x;\n        if (_2273 > 0.0)\n        {\n            float _2282 = _394.fa_fog.w * _2273;\n            float tau = _2282 * _2282;\n            if (_394.fa_fog_b.y > 0.0)\n            {\n                float _2298;\n                if (_2260)\n                {\n                    _2298 = in.fa_world_pos.y - (_394.fa_fog_c.y * _2256);\n                }\n                else\n                {\n                    _2298 = _394.fa_camera_pos.y;\n                }\n                float _2319 = mix(_2298, in.fa_world_pos.y, fast::clamp(_394.fa_fog_b.x / _2261, 0.0, 1.0));\n                float _2323 = in.fa_world_pos.y - _2319;\n                float _2328 = _2319 - _394.fa_fog_b.z;\n                float _2333 = in.fa_world_pos.y - _394.fa_fog_b.z;\n                bool _2336 = _2328 <= 0.0;\n                bool _2337 = !_2336;\n                bool _2343;\n                if (_2337)\n                {\n                    _2343 = _394.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2343 = _2336;\n                }\n                float _2344;\n                if (_2343)\n                {\n                    _2344 = _394.fa_fog_b.y;\n                }\n                else\n                {\n                    _2344 = _394.fa_fog_b.y * exp(-fast::min(_394.fa_fog_b.w * _2328, 80.0));\n                }\n                bool _2371;\n                if (_2337)\n                {\n                    _2371 = _394.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2371 = _2336;\n                }\n                float _2372;\n                if (_2371)\n                {\n                    _2372 = _394.fa_fog_b.y * _2328;\n                }\n                else\n                {\n                    _2372 = (_394.fa_fog_b.y * (1.0 - exp(-fast::min(_394.fa_fog_b.w * _2328, 80.0)))) / _394.fa_fog_b.w;\n                }\n                bool _2397 = _2333 <= 0.0;\n                bool _2404;\n                if (!_2397)\n                {\n                    _2404 = _394.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2404 = _2397;\n                }\n                float _2405;\n                if (_2404)\n                {\n                    _2405 = _394.fa_fog_b.y * _2333;\n                }\n                else\n                {\n                    _2405 = (_394.fa_fog_b.y * (1.0 - exp(-fast::min(_394.fa_fog_b.w * _2333, 80.0)))) / _394.fa_fog_b.w;\n                }\n                float _2432;\n                if (abs(_2323) < 0.001000000047497451305389404296875)\n                {\n                    _2432 = _2344;\n                }\n                else\n                {\n                    _2432 = (_2405 - _2372) / _2323;\n                }\n                tau += (_2273 * fast::max(_2432, 0.0));\n            }\n            result = mix(result, _394.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2515);\n    return out;\n}\n\n",
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
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_394",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1134",
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
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 8
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 8,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _588 = base_t;\n    _588.x = _225.x;\n    _588.y = _225.y;\n    _588.z = _225.z;\n    base_t = _588;\n    float4 _241 = (_588 * _213.fa_base_color) * i.vertex_color;\n    float3 _569 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _596 = _279;\n        _596.x = _284.x;\n        _596.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _596;\n        _569 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _599 = mrt;\n    _599.x = _313.x;\n    _599.y = _313.y;\n    _599.z = _313.z;\n    mrt = _599;\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface{ _241.xyz, _241.w, _569, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_354.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _381) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _516 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _516 = -_516;\n    }\n    float3 _427 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _516, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _516, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _442 = fast::normalize(param_2.normal);\n    float3 _457 = fast::normalize(float3(dot(in.fa_pre_r0, _442), dot(in.fa_pre_r1, _442), dot(in.fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / float2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 320,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _588 = base_t;\n    _588.x = _225.x;\n    _588.y = _225.y;\n    _588.z = _225.z;\n    base_t = _588;\n    float4 _241 = (_588 * _213.fa_base_color) * i.vertex_color;\n    float3 _569 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _596 = _279;\n        _596.x = _284.x;\n        _596.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _596;\n        _569 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _599 = mrt;\n    _599.x = _313.x;\n    _599.y = _313.y;\n    _599.z = _313.z;\n    mrt = _599;\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface{ _241.xyz, _241.w, _569, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_354.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _381) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _516 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _516 = -_516;\n    }\n    float3 _427 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _516, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _516, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _427, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _442 = fast::normalize(param_2.normal);\n    float3 _457 = fast::normalize(float3(dot(in.fa_pre_r0, _442), dot(in.fa_pre_r1, _442), dot(in.fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / float2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 320,
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
