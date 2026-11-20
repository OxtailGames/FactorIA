{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5c278b25d8ce4341984c8bf2a53e1ca7890b6a924713889b53c089df056597d0",
  "slang": "metal_macos",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_270, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _452)\n{\n    bool _457 = _452.fa_cl_info.x < 0.0;\n    bool _464;\n    if (!_457)\n    {\n        _464 = _452.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _464 = _457;\n    }\n    bool _472;\n    if (!_464)\n    {\n        _472 = _452.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _472 = _464;\n    }\n    bool _479;\n    if (!_472)\n    {\n        _479 = _452.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _479 = _472;\n    }\n    bool _486;\n    if (!_479)\n    {\n        _486 = _452.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _486 = _479;\n    }\n    if (_486)\n    {\n        return float4(0.0);\n    }\n    float4 _496 = float4(world_pos, 1.0);\n    float _503 = dot(_452.fa_cl_vpw, _496);\n    if (!(_503 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _525 = float2(dot(_452.fa_cl_vpx, _496), dot(_452.fa_cl_vpy, _496)) / float2(_503);\n    int _529 = int(_452.fa_cl_grid.x);\n    int _533 = int(_452.fa_cl_grid.y);\n    int param = (int(_452.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_452.fa_cl_fwd.xyz, world_pos) + _452.fa_cl_fwd.w, _452.fa_cl_grid.w) / _452.fa_cl_grid.w) * _452.fa_cl_grid.z)), 0, int(_452.fa_cl_info.y) - 1) * _533) + clamp(int(floor(((_525.y * 0.5) + 0.5) * _452.fa_cl_grid.y)), 0, _533 - 1)) * _529)) + clamp(int(floor(((_525.x * 0.5) + 0.5) * _452.fa_cl_grid.x)), 0, _529 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _452)\n{\n    float3 param = world_pos;\n    float4 _609 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _452);\n    return int2(int(_609.x), int(_609.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _452, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_452.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2414 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _452);\n    fa_cl_slot = _2414.x;\n    fa_cl_local = _2414.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2588 = fa_linear_to_srgb(param);\n        c = _2588;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2596 = fa_srgb_to_linear(param_1);\n            c = _2596;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _217;\n    if (bool(i.front_facing))\n    {\n        _217 = i.world_normal;\n    }\n    else\n    {\n        _217 = -i.world_normal;\n    }\n    float3 _241 = fast::normalize(i.world_tangent.xyz - (_217 * dot(_217, i.world_tangent.xyz)));\n    float3 _268 = fast::normalize(((_241 * m.x) + ((cross(_217, _241) * i.world_tangent.w) * m.y)) + (_217 * m.z));\n    float3 _271;\n    if (bool(i.front_facing))\n    {\n        _271 = _268;\n    }\n    else\n    {\n        _271 = -_268;\n    }\n    return _271;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _452, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _452.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2627 = fa_tex_fix(param_2, param_3);\n    float4 _3637 = base_t;\n    _3637.x = _2627.x;\n    _3637.y = _2627.y;\n    _3637.z = _2627.z;\n    base_t = _3637;\n    float4 _2641 = (_3637 * _452.fa_base_color) * i.vertex_color;\n    float3 _3517 = i.world_normal;\n    if (_452.fa_maps.z > 0.5)\n    {\n        float param_4 = _452.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2673 = fa_tex_fix(param_6, param_7);\n        float3 _2676 = (_2673 * 2.0) - float3(1.0);\n        float2 _2681 = _2676.xy * _452.fa_maps.x;\n        float3 _3645 = _2676;\n        _3645.x = _2681.x;\n        _3645.y = _2681.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3645;\n        _3517 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _452.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2710 = fa_tex_fix(param_12, param_13);\n    float4 _3648 = mrt;\n    _3648.x = _2710.x;\n    _3648.y = _2710.y;\n    _3648.z = _2710.z;\n    mrt = _3648;\n    float4 _2738 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _452.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2738.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2750 = fa_tex_fix(param_16, param_17);\n    float param_18 = _452.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2780 = fa_tex_fix(param_20, param_21);\n    float _3522 = _452.fa_layers_a.x;\n    float _3523 = _452.fa_layers_a.y;\n    float _3526 = _452.fa_layers_a.z;\n    float _3525 = _452.fa_layers_b.w;\n    float _3528 = _452.fa_layers_c.x;\n    if (_452.fa_layers_c.z > 0.5)\n    {\n        if (mod(_452.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3522 *= _2750.y;\n            _3523 *= _2750.z;\n            _3525 *= _2738.w;\n        }\n        if (_452.fa_layers_c.z > 1.5)\n        {\n            _3526 *= mrt.x;\n            _3528 *= mrt.w;\n        }\n    }\n    return Surface{ _2641.xyz, _2641.w, _3517, fast::clamp(_452.fa_pbr.x * _2710.z, 0.0, 1.0), fast::clamp(_452.fa_pbr.y * _2710.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_452.fa_maps.y * (_2750.x - 1.0)), _452.fa_emissive.xyz + (_452.fa_model_emissive.xyz * _2780), _3522, _3523, _452.fa_layers_b.xyz, _3525, _3526, _452.fa_layers_a.w, _3528, _452.fa_layers_c.y, _452.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _690 = rect.zw - rect.xy;\n    float2 _694 = _690 * atlas;\n    float2 _698 = ddx * _694;\n    float2 _702 = ddy * _694;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _690)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_698, _698), dot(_702, _702)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _452, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _737 = _452.fa_counts.y < 0.5;\n    bool _744;\n    if (!_737)\n    {\n        _744 = _452.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _744 = _737;\n    }\n    if (_744)\n    {\n        return;\n    }\n    float3 _750 = dfdx(world_pos);\n    float3 _753 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _757 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _452);\n    int _761 = int(_757.w);\n    if (_761 < 1)\n    {\n        return;\n    }\n    int _771 = int(_452.fa_counts.y + 0.5);\n    int param_1 = _771;\n    float4 _775 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _778 = _775.yz;\n    int _782 = int(_775.w);\n    int param_2 = _771 + 1;\n    float4 _787 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _788 = _787.x;\n    int _794 = int(_452.fa_counts.w + 0.5) - 1;\n    int _798 = int(_757.z);\n    float3 _1064;\n    for (int k = 0; k < _761; k++)\n    {\n        int _811 = _798 + k;\n        int param_3 = _782 + (_811 >> 2);\n        int _829 = (_771 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_811 & 3]) * 7);\n        int param_4 = _829 + 6;\n        float4 _834 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_834.w + 0.5) >> _794) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _829;\n        float4 _849 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _829 + 1;\n        float4 _854 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _829 + 2;\n        float4 _859 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _862 = _849.xyz;\n        float _867 = dot(_862, world_pos) + _849.w;\n        float3 _869 = _854.xyz;\n        float _874 = dot(_869, world_pos) + _854.w;\n        float3 _876 = _859.xyz;\n        float _881 = dot(_876, world_pos) + _859.w;\n        bool _886 = abs(_867) > 0.5;\n        bool _894;\n        if (!_886)\n        {\n            _894 = abs(_874) > 0.5;\n        }\n        else\n        {\n            _894 = _886;\n        }\n        bool _902;\n        if (!_894)\n        {\n            _902 = abs(_881) > 0.5;\n        }\n        else\n        {\n            _902 = _894;\n        }\n        if (_902)\n        {\n            continue;\n        }\n        float _917 = fast::clamp(dot(geo_normal, fast::normalize(_876)) * _834.z, 0.0, 1.0);\n        if (_917 <= 0.0)\n        {\n            continue;\n        }\n        float _937 = (fast::clamp((0.5 - abs(_881)) * 10.0, 0.0, 1.0) * _917) * _834.x;\n        float2 _945 = float2(_867 + 0.5, 0.5 - _874);\n        float2 _955 = float2(dot(_862, _750), dot(_869, _750));\n        float2 _965 = float2(dot(_862, _753), dot(_869, _753));\n        int param_8 = _829 + 5;\n        float4 _970 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _829 + 3;\n        float4 _975 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _829 + 4;\n        float4 _980 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _970.xyz;\n        bool _990 = _975.z > _975.x;\n        if (_990)\n        {\n            float4 param_11 = _975;\n            float2 param_12 = _945;\n            float2 param_13 = _778;\n            float2 param_14 = _955;\n            float2 param_15 = _965;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_788 > 0.5) && (_788 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1016 = fa_dc_to_linear(param_16);\n                float4 _3573 = tx;\n                _3573.x = _1016.x;\n                _3573.y = _1016.y;\n                _3573.z = _1016.z;\n                tx = _3573;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_937 * tex_a) * _970.w, 0.0, 1.0)));\n        if (_980.z > _980.x)\n        {\n            float4 param_17 = _980;\n            float2 param_18 = _945;\n            float2 param_19 = _778;\n            float2 param_20 = _955;\n            float2 param_21 = _965;\n            float4 _1060 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_788 > 1.5)\n            {\n                float3 param_22 = _1060.xyz;\n                float3 _1070 = fa_dc_to_srgb(param_22);\n                _1064 = _1070;\n            }\n            else\n            {\n                _1064 = _1060.xyz;\n            }\n            float3 _1080 = (_1064 * 2.0) - float3(1.0);\n            float2 _1085 = _1080.xy * _834.y;\n            float3 _1107 = (fast::normalize(_862) * _1085.x) + (fast::normalize(_869) * _1085.y);\n            float3 _1110 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1110, fast::normalize((_1110 * fast::max(_1080.z, 0.0500000007450580596923828125)) + (_1107 - (_1110 * dot(_1110, _1107)))), float3(fast::clamp(_937 * (_990 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _452, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_452.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _2327 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _2327;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _452, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_452.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _452, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _452.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _452, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _452, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _452)\n{\n    int param = (int(_452.fa_cl_info.x) + int(_452.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _452, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _452);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _327 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _333 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _336 = _333.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _342 = _336 < 0.5;\n    float3 l;\n    if (_342)\n    {\n        l = fast::normalize(_327.xyz);\n    }\n    else\n    {\n        float3 _354 = _327.xyz - world_pos;\n        float _356 = length(_354);\n        dist = _356;\n        l = _354 / float3(fast::max(_356, 9.9999997473787516355514526367188e-05));\n        float _371 = _356 / fast::max(_327.w, 0.001000000047497451305389404296875);\n        float _377 = fast::clamp(1.0 - (_371 * _371), 0.0, 1.0);\n        atten = _377 * _377;\n        if (_336 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _391 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _401 = _391.w;\n            int param_3 = (li * 4) + 3;\n            float4 _407 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _408 = _407.x;\n            float cos_inner = _408;\n            if (_408 > 1.5)\n            {\n                cos_inner = mix(_401, 1.0, 0.25);\n            }\n            atten *= smoothstep(_401, cos_inner, dot(-l, fast::normalize(_391.xyz)));\n        }\n    }\n    int _438;\n    if (_342)\n    {\n        _438 = 0;\n    }\n    else\n    {\n        _438 = (_336 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _333.xyz * atten, atten, 1.0, dist, _438 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1192)\n{\n    float _1182;\n    if (i == 0)\n    {\n        _1182 = _1192.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1198;\n        if (i == 1)\n        {\n            _1198 = _1192.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1206;\n            if (i == 2)\n            {\n                _1206 = _1192.fa_shadow_split.z;\n            }\n            else\n            {\n                _1206 = _1192.fa_shadow_split.w;\n            }\n            _1198 = _1206;\n        }\n        _1182 = _1198;\n    }\n    return _1182;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1239 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1243;\n    if (conv.x < 0.5)\n    {\n        _1243 = _1239;\n    }\n    else\n    {\n        _1243 = (conv.y * conv.z) / (conv.z - (_1239 * (conv.z - conv.y)));\n    }\n    return _1243;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1170 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1170), sin(_1170)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1192, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1289 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1303 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1289;\n            float2 _1322 = fa_shadow_vogel(param_3, param_4, param_5) * _1303;\n            float2 param_6 = uv + (_1322 * _1192.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1334 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1334 < (zr - (length(_1322) * plane)))\n            {\n                sum += _1334;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1378 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1378; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1378;\n        float param_11 = _1289;\n        float2 _1397 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1397 * _1192.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1397) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1378);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1192, texture2d<float> fa_shadow_tex)\n{\n    float _1439 = fast::max(_1192.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1444 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1450 = sqrt(1.0 - (_1444 * _1444));\n    float _1457 = fast::min(_1450 / fast::max(_1444, 0.20000000298023223876953125), 4.0);\n    float _1462;\n    if (_1192.fa_shadow_bias.y > 0.0)\n    {\n        _1462 = _1192.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1462 = 1.5 * _1192.fa_shadow_info[ci].x;\n    }\n    float4 _1487 = _1192.fa_shadow_mat[ci] * float4(world + (n * (_1462 * _1450)), 1.0);\n    float _1494 = _1487.x;\n    bool _1497 = _1494 < _1192.fa_shadow_rect[ci].x;\n    bool _1506;\n    if (!_1497)\n    {\n        _1506 = _1494 > _1192.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1506 = _1497;\n    }\n    bool _1515;\n    if (!_1506)\n    {\n        _1515 = _1487.y < _1192.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1515 = _1506;\n    }\n    bool _1524;\n    if (!_1515)\n    {\n        _1524 = _1487.y > _1192.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1524 = _1515;\n    }\n    bool _1531;\n    if (!_1524)\n    {\n        _1531 = _1487.z > 1.0;\n    }\n    else\n    {\n        _1531 = _1524;\n    }\n    if (_1531)\n    {\n        return -1.0;\n    }\n    float _1540;\n    if (_1192.fa_shadow_bias.x > 0.0)\n    {\n        _1540 = _1192.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1540 = 1.5 * _1192.fa_shadow_info[ci].x;\n    }\n    float2 param = _1487.xy;\n    float4 param_1 = _1192.fa_shadow_rect[ci];\n    float param_2 = _1487.z - ((_1540 * (1.0 + (0.5 * _1457))) / _1439);\n    float param_3 = _1192.fa_shadow_info[ci].x;\n    float param_4 = _1439;\n    float param_5 = _1439 * 0.25;\n    float param_6 = ((_1192.fa_shadow_info[ci].x * fast::min(_1457, 3.0)) * 0.5) / _1439;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1192.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1192.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1192, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _452, thread float4& gl_FragCoord, constant fa_shadows& _1192, texture2d<float> fa_shadow_tex)\n{\n    if (_452.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1967 = int(_1192.fa_shadow_cfg.x + 0.5);\n    if (_1967 < 1)\n    {\n        return 1.0;\n    }\n    float _1982 = dot(world - _1192.fa_shadow_eye.xyz, _1192.fa_shadow_fwd.xyz);\n    int param = _1967 - 1;\n    if (_1982 > fa_shadow_split_at(param, _1192))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1994 = _1967 > 1;\n    bool _2001;\n    if (_1994)\n    {\n        _2001 = _1982 > _1192.fa_shadow_split.x;\n    }\n    else\n    {\n        _2001 = _1994;\n    }\n    if (_2001)\n    {\n        ci = 1;\n    }\n    bool _2005 = _1967 > 2;\n    bool _2012;\n    if (_2005)\n    {\n        _2012 = _1982 > _1192.fa_shadow_split.y;\n    }\n    else\n    {\n        _2012 = _2005;\n    }\n    if (_2012)\n    {\n        ci = 2;\n    }\n    bool _2016 = _1967 > 3;\n    bool _2023;\n    if (_2016)\n    {\n        _2023 = _1982 > _1192.fa_shadow_split.z;\n    }\n    else\n    {\n        _2023 = _2016;\n    }\n    if (_2023)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1967)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2049 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1192, fa_shadow_tex);\n        s = _2049;\n        if (_2049 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1192.fa_shadow_cfg.y > 0.0)\n    {\n        float _2074;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2074 = fa_shadow_split_at(param_5, _1192);\n        }\n        else\n        {\n            _2074 = _1192.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2093 = _1192.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1192) - _2074, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2104 = fast::clamp((_1982 - (fa_shadow_split_at(param_7, _1192) - _2093)) / _2093, 0.0, 1.0);\n        if (_2104 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1967)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2125 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1192, fa_shadow_tex);\n                s2 = _2125;\n                if (_2125 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2104);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _452, thread float4& gl_FragCoord, constant fa_shadows& _1192, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _452, gl_FragCoord, _1192, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _452, thread float4& gl_FragCoord, constant fa_shadows& _1192, texture2d<float> fa_shadow_tex)\n{\n    bool _1598 = _452.fa_pbr.z < 0.5;\n    bool _1606;\n    if (!_1598)\n    {\n        _1606 = _1192.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1606 = _1598;\n    }\n    if (_1606)\n    {\n        return 1.0;\n    }\n    int param = (int(_1192.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1619 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1620 = _1619.x;\n    if (_1620 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1629 = int(_1620 + 0.5);\n    int param_1 = _1629;\n    float4 _1633 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1629 + 1;\n    float4 _1638 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1641 = _1633.y;\n    if (_1641 > 0.0)\n    {\n        float _1658 = 1.0 - smoothstep(0.75 * _1641, _1641, length(world - _1192.fa_shadow_eye.xyz));\n        fade = _1658;\n        if (_1658 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1633.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1677 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1680 = abs(_1677);\n        float _1682 = _1680.x;\n        float _1684 = _1680.y;\n        bool _1685 = _1682 >= _1684;\n        bool _1693;\n        if (_1685)\n        {\n            _1693 = _1682 >= _1680.z;\n        }\n        else\n        {\n            _1693 = _1685;\n        }\n        int _1694;\n        if (_1693)\n        {\n            _1694 = (_1677.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1707;\n            if (_1684 >= _1680.z)\n            {\n                _1707 = (_1677.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1707 = (_1677.z > 0.0) ? 4 : 5;\n            }\n            _1694 = _1707;\n        }\n        face = _1694;\n    }\n    int _1726 = (_1629 + 2) + (face * 6);\n    int param_4 = _1726;\n    int param_5 = _1726 + 1;\n    int param_6 = _1726 + 3;\n    float4 _1740 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1726 + 4;\n    float4 _1745 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1726 + 5;\n    float4 _1750 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1762 = _1750.x * fast::max(dot(_1740, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1767 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1790 = fast::clamp(dot(n, _1740.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1813 = fast::min(sqrt(1.0 - (_1790 * _1790)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1740, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1816 = _1638.y;\n    float _1818;\n    if (_1816 > 0.0)\n    {\n        _1818 = _1816;\n    }\n    else\n    {\n        _1818 = 1.5 * _1762;\n    }\n    float4 _1838 = float4(world + (n * (_1818 * sqrt(1.0 - (_1767 * _1767)))), 1.0);\n    float _1842 = dot(_1740, _1838);\n    float _1845 = _1750.y;\n    if (_1842 < _1845)\n    {\n        return 1.0;\n    }\n    float2 _1860 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1838), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1838)) / float2(_1842);\n    float _1862 = _1860.x;\n    bool _1865 = _1862 < _1745.x;\n    bool _1874;\n    if (!_1865)\n    {\n        _1874 = _1862 > _1745.z;\n    }\n    else\n    {\n        _1874 = _1865;\n    }\n    bool _1883;\n    if (!_1874)\n    {\n        _1883 = _1860.y < _1745.y;\n    }\n    else\n    {\n        _1883 = _1874;\n    }\n    bool _1892;\n    if (!_1883)\n    {\n        _1892 = _1860.y > _1745.w;\n    }\n    else\n    {\n        _1892 = _1883;\n    }\n    if (_1892)\n    {\n        return 1.0;\n    }\n    float _1898 = _1638.x;\n    float _1900;\n    if (_1898 > 0.0)\n    {\n        _1900 = _1898;\n    }\n    else\n    {\n        _1900 = 1.5 * _1762;\n    }\n    float2 param_10 = _1860;\n    float4 param_11 = _1745;\n    float param_12 = _1842 - (_1900 * (1.0 + (0.5 * _1813)));\n    float param_13 = _1762;\n    float param_14 = 1.0;\n    float param_15 = _1750.z * 0.25;\n    float param_16 = (_1762 * fast::min(_1813, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1845, _1750.z);\n    int param_18 = int(_1633.z + 0.5);\n    float param_19 = _1633.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1192, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _452, thread float4& gl_FragCoord, constant fa_shadows& _1192, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _2441 = fa_lm.z > 0.5;\n    bool _2447;\n    if (_2441)\n    {\n        int param = li;\n        _2447 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2447 = _2441;\n    }\n    if (_2447)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2470 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _3502 = _2470.direction;\n    float3 _3497 = _2470.color;\n    float _3504 = _2470.attenuation;\n    float _3499 = _2470.shadow;\n    int _3507 = _2470.type;\n    if ((_3507 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3502;\n        float _2484 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _452, gl_FragCoord, _1192, fa_shadow_tex, fa_world_pos);\n        _3499 = _2484;\n        _3497 *= _2484;\n    }\n    else\n    {\n        bool _2495 = _3507 != 0;\n        bool _2501;\n        if (_2495)\n        {\n            _2501 = _3504 > 0.0;\n        }\n        else\n        {\n            _2501 = _2495;\n        }\n        if (_2501)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3502;\n            float _2513 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _452, gl_FragCoord, _1192, fa_shadow_tex);\n            _3499 = _2513;\n            _3497 *= _2513;\n        }\n    }\n    return LightSample{ _3502, _3497, _3504, _3499, _2470._distance, _3507 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l, constant fa_material& _2539)\n{\n    float _2533;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _2533 = 1.0;\n    }\n    else\n    {\n        _2533 = _2539.dark;\n    }\n    return (s.albedo * l.color) * _2533;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1192)\n{\n    if (_1192.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2149 = int(_1192.fa_shadow_cfg.x + 0.5);\n    float _2159 = dot(world - _1192.fa_shadow_eye.xyz, _1192.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2164 = _2149 > 0;\n    bool _2173;\n    if (_2164)\n    {\n        int param = _2149 - 1;\n        _2173 = _2159 <= fa_shadow_split_at(param, _1192);\n    }\n    else\n    {\n        _2173 = _2164;\n    }\n    if (_2173)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2180 = _2149 > 1;\n        bool _2187;\n        if (_2180)\n        {\n            _2187 = _2159 > _1192.fa_shadow_split.x;\n        }\n        else\n        {\n            _2187 = _2180;\n        }\n        if (_2187)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2193 = _2149 > 2;\n        bool _2200;\n        if (_2193)\n        {\n            _2200 = _2159 > _1192.fa_shadow_split.y;\n        }\n        else\n        {\n            _2200 = _2193;\n        }\n        if (_2200)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2206 = _2149 > 3;\n        bool _2213;\n        if (_2206)\n        {\n            _2213 = _2159 > _1192.fa_shadow_split.z;\n        }\n        else\n        {\n            _2213 = _2206;\n        }\n        if (_2213)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _452 [[buffer(1)]], constant fa_material& _2539 [[buffer(5)]], constant fa_shadows& _1192 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3338 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3338 = -_3338;\n    }\n    float3 _2923 = fast::normalize(_452.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _452, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3338, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2923, short(gl_FrontFacing) };\n    Surface _2931 = fa_standard_surface(param_1, _452, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3369 = _2931.albedo;\n    float _3370 = _2931.alpha;\n    float3 _3371 = _2931.normal;\n    float _3372 = _2931.metallic;\n    float _3373 = _2931.roughness;\n    float _3374 = _2931.occlusion;\n    float3 _3375 = _2931.emission;\n    float _3376 = _2931.clearcoat;\n    float _3377 = _2931.clearcoat_roughness;\n    float3 _3378 = _2931.sheen_color;\n    float _3379 = _2931.sheen_roughness;\n    float _3380 = _2931.anisotropy;\n    float _3381 = _2931.anisotropy_rotation;\n    float _3382 = _2931.specular;\n    float _3383 = _2931.ior;\n    float3 _3384 = _2931.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3338, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2923, short(gl_FrontFacing) };\n    Surface param_3 = _2931;\n    surface(param_2, param_3);\n    _3369 = param_3.albedo;\n    _3370 = param_3.alpha;\n    _3371 = param_3.normal;\n    _3372 = param_3.metallic;\n    _3373 = param_3.roughness;\n    _3374 = param_3.occlusion;\n    _3375 = param_3.emission;\n    _3376 = param_3.clearcoat;\n    _3377 = param_3.clearcoat_roughness;\n    _3378 = param_3.sheen_color;\n    _3379 = param_3.sheen_roughness;\n    _3380 = param_3.anisotropy;\n    _3381 = param_3.anisotropy_rotation;\n    _3382 = param_3.specular;\n    _3383 = param_3.ior;\n    _3384 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _3338;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _452, fa_decal_tex, fa_env_smp);\n    _3369 = param_6;\n    _3371 = param_7;\n    float3 result;\n    if (_452.fa_emissive.w > 0.5)\n    {\n        result = _3369;\n    }\n    else\n    {\n        float3 _2969 = _3371;\n        float3 _2970 = fast::normalize(_2969);\n        _3371 = _2970;\n        float3 param_8 = _2970;\n        float3 lit = (fa_indirect_diffuse(param_8, _452, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap) * _3369) * _3374;\n        int _2989 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2989; ln++)\n        {\n            int param_9 = ln;\n            int _3002 = fa_cl_light(param_9, fa_light_tex, fa_shadow_smp, _452, fa_cl_ndir, fa_cl_slot);\n            bool _3005 = in.fa_lm.z > 0.5;\n            bool _3011;\n            if (_3005)\n            {\n                int param_10 = _3002;\n                _3011 = fa_light_baked(param_10, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _3011 = _3005;\n            }\n            if (_3011)\n            {\n                continue;\n            }\n            int param_11 = _3002;\n            float3 param_12 = in.fa_world_pos;\n            float3 param_13 = _3338;\n            SurfaceInput param_14 = SurfaceInput{ in.fa_world_pos, _3338, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2923, short(gl_FrontFacing) };\n            Surface param_15 = Surface{ _3369, _3370, _3371, _3372, _3373, _3374, _3375, _3376, _3377, _3378, _3379, _3380, _3381, _3382, _3383, _3384 };\n            LightSample param_16 = fa_light_shadowed(param_11, param_12, param_13, fa_light_tex, fa_shadow_smp, _452, gl_FragCoord, _1192, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            lit += light(param_14, param_15, param_16, _2539);\n        }\n        result = lit;\n    }\n    float3 _3038 = result;\n    float3 _3039 = _3038 + _3375;\n    result = _3039;\n    float3 param_17 = _3039;\n    float3 param_18 = in.fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18, _1192);\n    bool _3048 = _452.fa_fog.w > 0.0;\n    bool _3055;\n    if (!_3048)\n    {\n        _3055 = _452.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3055 = _3048;\n    }\n    if (_3055)\n    {\n        float3 _3064 = in.fa_world_pos - _452.fa_camera_pos.xyz;\n        float _3070 = dot(_3064, _452.fa_fog_c.xyz);\n        bool _3074 = _452.fa_fog_c.w > 0.5;\n        float _3075;\n        if (_3074)\n        {\n            _3075 = _3070;\n        }\n        else\n        {\n            _3075 = length(_3064);\n        }\n        float _3087 = _3075 - _452.fa_fog_b.x;\n        if (_3087 > 0.0)\n        {\n            float _3096 = _452.fa_fog.w * _3087;\n            float tau = _3096 * _3096;\n            if (_452.fa_fog_b.y > 0.0)\n            {\n                float _3112;\n                if (_3074)\n                {\n                    _3112 = in.fa_world_pos.y - (_452.fa_fog_c.y * _3070);\n                }\n                else\n                {\n                    _3112 = _452.fa_camera_pos.y;\n                }\n                float _3133 = mix(_3112, in.fa_world_pos.y, fast::clamp(_452.fa_fog_b.x / _3075, 0.0, 1.0));\n                float _3137 = in.fa_world_pos.y - _3133;\n                float _3142 = _3133 - _452.fa_fog_b.z;\n                float _3147 = in.fa_world_pos.y - _452.fa_fog_b.z;\n                bool _3150 = _3142 <= 0.0;\n                bool _3151 = !_3150;\n                bool _3157;\n                if (_3151)\n                {\n                    _3157 = _452.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3157 = _3150;\n                }\n                float _3158;\n                if (_3157)\n                {\n                    _3158 = _452.fa_fog_b.y;\n                }\n                else\n                {\n                    _3158 = _452.fa_fog_b.y * exp(-fast::min(_452.fa_fog_b.w * _3142, 80.0));\n                }\n                bool _3185;\n                if (_3151)\n                {\n                    _3185 = _452.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3185 = _3150;\n                }\n                float _3186;\n                if (_3185)\n                {\n                    _3186 = _452.fa_fog_b.y * _3142;\n                }\n                else\n                {\n                    _3186 = (_452.fa_fog_b.y * (1.0 - exp(-fast::min(_452.fa_fog_b.w * _3142, 80.0)))) / _452.fa_fog_b.w;\n                }\n                bool _3211 = _3147 <= 0.0;\n                bool _3218;\n                if (!_3211)\n                {\n                    _3218 = _452.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3218 = _3211;\n                }\n                float _3219;\n                if (_3218)\n                {\n                    _3219 = _452.fa_fog_b.y * _3147;\n                }\n                else\n                {\n                    _3219 = (_452.fa_fog_b.y * (1.0 - exp(-fast::min(_452.fa_fog_b.w * _3147, 80.0)))) / _452.fa_fog_b.w;\n                }\n                float _3246;\n                if (abs(_3137) < 0.001000000047497451305389404296875)\n                {\n                    _3246 = _3158;\n                }\n                else\n                {\n                    _3246 = (_3219 - _3186) / _3137;\n                }\n                tau += (_3087 * fast::max(_3246, 0.0));\n            }\n            result = mix(result, _452.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3370);\n    return out;\n}\n\n",
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
            "inst_name": "_452",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1192",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_2539",
            "msl_buffer_n": 5
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
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_391, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _452)\n{\n    bool _457 = _452.fa_cl_info.x < 0.0;\n    bool _464;\n    if (!_457)\n    {\n        _464 = _452.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _464 = _457;\n    }\n    bool _472;\n    if (!_464)\n    {\n        _472 = _452.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _472 = _464;\n    }\n    bool _479;\n    if (!_472)\n    {\n        _479 = _452.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _479 = _472;\n    }\n    bool _486;\n    if (!_479)\n    {\n        _486 = _452.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _486 = _479;\n    }\n    if (_486)\n    {\n        return float4(0.0);\n    }\n    float4 _496 = float4(world_pos, 1.0);\n    float _503 = dot(_452.fa_cl_vpw, _496);\n    if (!(_503 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _525 = float2(dot(_452.fa_cl_vpx, _496), dot(_452.fa_cl_vpy, _496)) / float2(_503);\n    int _529 = int(_452.fa_cl_grid.x);\n    int _533 = int(_452.fa_cl_grid.y);\n    int param = (int(_452.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_452.fa_cl_fwd.xyz, world_pos) + _452.fa_cl_fwd.w, _452.fa_cl_grid.w) / _452.fa_cl_grid.w) * _452.fa_cl_grid.z)), 0, int(_452.fa_cl_info.y) - 1) * _533) + clamp(int(floor(((_525.y * 0.5) + 0.5) * _452.fa_cl_grid.y)), 0, _533 - 1)) * _529)) + clamp(int(floor(((_525.x * 0.5) + 0.5) * _452.fa_cl_grid.x)), 0, _529 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _452)\n{\n    float3 param = world_pos;\n    float4 _609 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _452);\n    return int2(int(_609.x), int(_609.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _452, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_452.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2414 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _452);\n    fa_cl_slot = _2414.x;\n    fa_cl_local = _2414.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2588 = fa_linear_to_srgb(param);\n        c = _2588;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2596 = fa_srgb_to_linear(param_1);\n            c = _2596;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _217;\n    if (bool(i.front_facing))\n    {\n        _217 = i.world_normal;\n    }\n    else\n    {\n        _217 = -i.world_normal;\n    }\n    float3 _241 = fast::normalize(i.world_tangent.xyz - (_217 * dot(_217, i.world_tangent.xyz)));\n    float3 _268 = fast::normalize(((_241 * m.x) + ((cross(_217, _241) * i.world_tangent.w) * m.y)) + (_217 * m.z));\n    float3 _271;\n    if (bool(i.front_facing))\n    {\n        _271 = _268;\n    }\n    else\n    {\n        _271 = -_268;\n    }\n    return _271;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _452, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _452.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2627 = fa_tex_fix(param_2, param_3);\n    float4 _3637 = base_t;\n    _3637.x = _2627.x;\n    _3637.y = _2627.y;\n    _3637.z = _2627.z;\n    base_t = _3637;\n    float4 _2641 = (_3637 * _452.fa_base_color) * i.vertex_color;\n    float3 _3517 = i.world_normal;\n    if (_452.fa_maps.z > 0.5)\n    {\n        float param_4 = _452.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2673 = fa_tex_fix(param_6, param_7);\n        float3 _2676 = (_2673 * 2.0) - float3(1.0);\n        float2 _2681 = _2676.xy * _452.fa_maps.x;\n        float3 _3645 = _2676;\n        _3645.x = _2681.x;\n        _3645.y = _2681.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3645;\n        _3517 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _452.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2710 = fa_tex_fix(param_12, param_13);\n    float4 _3648 = mrt;\n    _3648.x = _2710.x;\n    _3648.y = _2710.y;\n    _3648.z = _2710.z;\n    mrt = _3648;\n    float4 _2738 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _452.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2738.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2750 = fa_tex_fix(param_16, param_17);\n    float param_18 = _452.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2780 = fa_tex_fix(param_20, param_21);\n    float _3522 = _452.fa_layers_a.x;\n    float _3523 = _452.fa_layers_a.y;\n    float _3526 = _452.fa_layers_a.z;\n    float _3525 = _452.fa_layers_b.w;\n    float _3528 = _452.fa_layers_c.x;\n    if (_452.fa_layers_c.z > 0.5)\n    {\n        if (mod(_452.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3522 *= _2750.y;\n            _3523 *= _2750.z;\n            _3525 *= _2738.w;\n        }\n        if (_452.fa_layers_c.z > 1.5)\n        {\n            _3526 *= mrt.x;\n            _3528 *= mrt.w;\n        }\n    }\n    return Surface{ _2641.xyz, _2641.w, _3517, fast::clamp(_452.fa_pbr.x * _2710.z, 0.0, 1.0), fast::clamp(_452.fa_pbr.y * _2710.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_452.fa_maps.y * (_2750.x - 1.0)), _452.fa_emissive.xyz + (_452.fa_model_emissive.xyz * _2780), _3522, _3523, _452.fa_layers_b.xyz, _3525, _3526, _452.fa_layers_a.w, _3528, _452.fa_layers_c.y, _452.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _690 = rect.zw - rect.xy;\n    float2 _694 = _690 * atlas;\n    float2 _698 = ddx * _694;\n    float2 _702 = ddy * _694;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _690)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_698, _698), dot(_702, _702)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _452, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _737 = _452.fa_counts.y < 0.5;\n    bool _744;\n    if (!_737)\n    {\n        _744 = _452.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _744 = _737;\n    }\n    if (_744)\n    {\n        return;\n    }\n    float3 _750 = dfdx(world_pos);\n    float3 _753 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _757 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _452);\n    int _761 = int(_757.w);\n    if (_761 < 1)\n    {\n        return;\n    }\n    int _771 = int(_452.fa_counts.y + 0.5);\n    int param_1 = _771;\n    float4 _775 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _778 = _775.yz;\n    int _782 = int(_775.w);\n    int param_2 = _771 + 1;\n    float4 _787 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _788 = _787.x;\n    int _794 = int(_452.fa_counts.w + 0.5) - 1;\n    int _798 = int(_757.z);\n    float3 _1064;\n    for (int k = 0; k < _761; k++)\n    {\n        int _811 = _798 + k;\n        int param_3 = _782 + (_811 >> 2);\n        int _829 = (_771 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_811 & 3]) * 7);\n        int param_4 = _829 + 6;\n        float4 _834 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_834.w + 0.5) >> _794) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _829;\n        float4 _849 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _829 + 1;\n        float4 _854 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _829 + 2;\n        float4 _859 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _862 = _849.xyz;\n        float _867 = dot(_862, world_pos) + _849.w;\n        float3 _869 = _854.xyz;\n        float _874 = dot(_869, world_pos) + _854.w;\n        float3 _876 = _859.xyz;\n        float _881 = dot(_876, world_pos) + _859.w;\n        bool _886 = abs(_867) > 0.5;\n        bool _894;\n        if (!_886)\n        {\n            _894 = abs(_874) > 0.5;\n        }\n        else\n        {\n            _894 = _886;\n        }\n        bool _902;\n        if (!_894)\n        {\n            _902 = abs(_881) > 0.5;\n        }\n        else\n        {\n            _902 = _894;\n        }\n        if (_902)\n        {\n            continue;\n        }\n        float _917 = fast::clamp(dot(geo_normal, fast::normalize(_876)) * _834.z, 0.0, 1.0);\n        if (_917 <= 0.0)\n        {\n            continue;\n        }\n        float _937 = (fast::clamp((0.5 - abs(_881)) * 10.0, 0.0, 1.0) * _917) * _834.x;\n        float2 _945 = float2(_867 + 0.5, 0.5 - _874);\n        float2 _955 = float2(dot(_862, _750), dot(_869, _750));\n        float2 _965 = float2(dot(_862, _753), dot(_869, _753));\n        int param_8 = _829 + 5;\n        float4 _970 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _829 + 3;\n        float4 _975 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _829 + 4;\n        float4 _980 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _970.xyz;\n        bool _990 = _975.z > _975.x;\n        if (_990)\n        {\n            float4 param_11 = _975;\n            float2 param_12 = _945;\n            float2 param_13 = _778;\n            float2 param_14 = _955;\n            float2 param_15 = _965;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_788 > 0.5) && (_788 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1016 = fa_dc_to_linear(param_16);\n                float4 _3573 = tx;\n                _3573.x = _1016.x;\n                _3573.y = _1016.y;\n                _3573.z = _1016.z;\n                tx = _3573;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_937 * tex_a) * _970.w, 0.0, 1.0)));\n        if (_980.z > _980.x)\n        {\n            float4 param_17 = _980;\n            float2 param_18 = _945;\n            float2 param_19 = _778;\n            float2 param_20 = _955;\n            float2 param_21 = _965;\n            float4 _1060 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_788 > 1.5)\n            {\n                float3 param_22 = _1060.xyz;\n                float3 _1070 = fa_dc_to_srgb(param_22);\n                _1064 = _1070;\n            }\n            else\n            {\n                _1064 = _1060.xyz;\n            }\n            float3 _1080 = (_1064 * 2.0) - float3(1.0);\n            float2 _1085 = _1080.xy * _834.y;\n            float3 _1107 = (fast::normalize(_862) * _1085.x) + (fast::normalize(_869) * _1085.y);\n            float3 _1110 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1110, fast::normalize((_1110 * fast::max(_1080.z, 0.0500000007450580596923828125)) + (_1107 - (_1110 * dot(_1110, _1107)))), float3(fast::clamp(_937 * (_990 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _452, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_452.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _2327 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _2327;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _452, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_452.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _452, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _452.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _452, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _452, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _452)\n{\n    int param = (int(_452.fa_cl_info.x) + int(_452.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _452, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _452);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _327 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _333 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _336 = _333.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _342 = _336 < 0.5;\n    float3 l;\n    if (_342)\n    {\n        l = fast::normalize(_327.xyz);\n    }\n    else\n    {\n        float3 _354 = _327.xyz - world_pos;\n        float _356 = length(_354);\n        dist = _356;\n        l = _354 / float3(fast::max(_356, 9.9999997473787516355514526367188e-05));\n        float _371 = _356 / fast::max(_327.w, 0.001000000047497451305389404296875);\n        float _377 = fast::clamp(1.0 - (_371 * _371), 0.0, 1.0);\n        atten = _377 * _377;\n        if (_336 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _391 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _401 = _391.w;\n            int param_3 = (li * 4) + 3;\n            float4 _407 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _408 = _407.x;\n            float cos_inner = _408;\n            if (_408 > 1.5)\n            {\n                cos_inner = mix(_401, 1.0, 0.25);\n            }\n            atten *= smoothstep(_401, cos_inner, dot(-l, fast::normalize(_391.xyz)));\n        }\n    }\n    int _438;\n    if (_342)\n    {\n        _438 = 0;\n    }\n    else\n    {\n        _438 = (_336 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _333.xyz * atten, atten, 1.0, dist, _438 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1192)\n{\n    float _1182;\n    if (i == 0)\n    {\n        _1182 = _1192.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1198;\n        if (i == 1)\n        {\n            _1198 = _1192.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1206;\n            if (i == 2)\n            {\n                _1206 = _1192.fa_shadow_split.z;\n            }\n            else\n            {\n                _1206 = _1192.fa_shadow_split.w;\n            }\n            _1198 = _1206;\n        }\n        _1182 = _1198;\n    }\n    return _1182;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1239 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1243;\n    if (conv.x < 0.5)\n    {\n        _1243 = _1239;\n    }\n    else\n    {\n        _1243 = (conv.y * conv.z) / (conv.z - (_1239 * (conv.z - conv.y)));\n    }\n    return _1243;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1170 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1170), sin(_1170)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1192, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1289 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1303 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1289;\n            float2 _1322 = fa_shadow_vogel(param_3, param_4, param_5) * _1303;\n            float2 param_6 = uv + (_1322 * _1192.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1334 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1334 < (zr - (length(_1322) * plane)))\n            {\n                sum += _1334;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1378 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1378; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1378;\n        float param_11 = _1289;\n        float2 _1397 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1397 * _1192.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1397) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1378);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1192, texture2d<float> fa_shadow_tex)\n{\n    float _1439 = fast::max(_1192.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1444 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1450 = sqrt(1.0 - (_1444 * _1444));\n    float _1457 = fast::min(_1450 / fast::max(_1444, 0.20000000298023223876953125), 4.0);\n    float _1462;\n    if (_1192.fa_shadow_bias.y > 0.0)\n    {\n        _1462 = _1192.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1462 = 1.5 * _1192.fa_shadow_info[ci].x;\n    }\n    float4 _1487 = _1192.fa_shadow_mat[ci] * float4(world + (n * (_1462 * _1450)), 1.0);\n    float _1494 = _1487.x;\n    bool _1497 = _1494 < _1192.fa_shadow_rect[ci].x;\n    bool _1506;\n    if (!_1497)\n    {\n        _1506 = _1494 > _1192.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1506 = _1497;\n    }\n    bool _1515;\n    if (!_1506)\n    {\n        _1515 = _1487.y < _1192.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1515 = _1506;\n    }\n    bool _1524;\n    if (!_1515)\n    {\n        _1524 = _1487.y > _1192.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1524 = _1515;\n    }\n    bool _1531;\n    if (!_1524)\n    {\n        _1531 = _1487.z > 1.0;\n    }\n    else\n    {\n        _1531 = _1524;\n    }\n    if (_1531)\n    {\n        return -1.0;\n    }\n    float _1540;\n    if (_1192.fa_shadow_bias.x > 0.0)\n    {\n        _1540 = _1192.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1540 = 1.5 * _1192.fa_shadow_info[ci].x;\n    }\n    float2 param = _1487.xy;\n    float4 param_1 = _1192.fa_shadow_rect[ci];\n    float param_2 = _1487.z - ((_1540 * (1.0 + (0.5 * _1457))) / _1439);\n    float param_3 = _1192.fa_shadow_info[ci].x;\n    float param_4 = _1439;\n    float param_5 = _1439 * 0.25;\n    float param_6 = ((_1192.fa_shadow_info[ci].x * fast::min(_1457, 3.0)) * 0.5) / _1439;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1192.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1192.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1192, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _452, thread float4& gl_FragCoord, constant fa_shadows& _1192, texture2d<float> fa_shadow_tex)\n{\n    if (_452.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1967 = int(_1192.fa_shadow_cfg.x + 0.5);\n    if (_1967 < 1)\n    {\n        return 1.0;\n    }\n    float _1982 = dot(world - _1192.fa_shadow_eye.xyz, _1192.fa_shadow_fwd.xyz);\n    int param = _1967 - 1;\n    if (_1982 > fa_shadow_split_at(param, _1192))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1994 = _1967 > 1;\n    bool _2001;\n    if (_1994)\n    {\n        _2001 = _1982 > _1192.fa_shadow_split.x;\n    }\n    else\n    {\n        _2001 = _1994;\n    }\n    if (_2001)\n    {\n        ci = 1;\n    }\n    bool _2005 = _1967 > 2;\n    bool _2012;\n    if (_2005)\n    {\n        _2012 = _1982 > _1192.fa_shadow_split.y;\n    }\n    else\n    {\n        _2012 = _2005;\n    }\n    if (_2012)\n    {\n        ci = 2;\n    }\n    bool _2016 = _1967 > 3;\n    bool _2023;\n    if (_2016)\n    {\n        _2023 = _1982 > _1192.fa_shadow_split.z;\n    }\n    else\n    {\n        _2023 = _2016;\n    }\n    if (_2023)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1967)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2049 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1192, fa_shadow_tex);\n        s = _2049;\n        if (_2049 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1192.fa_shadow_cfg.y > 0.0)\n    {\n        float _2074;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2074 = fa_shadow_split_at(param_5, _1192);\n        }\n        else\n        {\n            _2074 = _1192.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2093 = _1192.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1192) - _2074, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2104 = fast::clamp((_1982 - (fa_shadow_split_at(param_7, _1192) - _2093)) / _2093, 0.0, 1.0);\n        if (_2104 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1967)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2125 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1192, fa_shadow_tex);\n                s2 = _2125;\n                if (_2125 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2104);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _452, thread float4& gl_FragCoord, constant fa_shadows& _1192, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _452, gl_FragCoord, _1192, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _452, thread float4& gl_FragCoord, constant fa_shadows& _1192, texture2d<float> fa_shadow_tex)\n{\n    bool _1598 = _452.fa_pbr.z < 0.5;\n    bool _1606;\n    if (!_1598)\n    {\n        _1606 = _1192.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1606 = _1598;\n    }\n    if (_1606)\n    {\n        return 1.0;\n    }\n    int param = (int(_1192.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1619 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1620 = _1619.x;\n    if (_1620 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1629 = int(_1620 + 0.5);\n    int param_1 = _1629;\n    float4 _1633 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1629 + 1;\n    float4 _1638 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1641 = _1633.y;\n    if (_1641 > 0.0)\n    {\n        float _1658 = 1.0 - smoothstep(0.75 * _1641, _1641, length(world - _1192.fa_shadow_eye.xyz));\n        fade = _1658;\n        if (_1658 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1633.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1677 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1680 = abs(_1677);\n        float _1682 = _1680.x;\n        float _1684 = _1680.y;\n        bool _1685 = _1682 >= _1684;\n        bool _1693;\n        if (_1685)\n        {\n            _1693 = _1682 >= _1680.z;\n        }\n        else\n        {\n            _1693 = _1685;\n        }\n        int _1694;\n        if (_1693)\n        {\n            _1694 = (_1677.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1707;\n            if (_1684 >= _1680.z)\n            {\n                _1707 = (_1677.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1707 = (_1677.z > 0.0) ? 4 : 5;\n            }\n            _1694 = _1707;\n        }\n        face = _1694;\n    }\n    int _1726 = (_1629 + 2) + (face * 6);\n    int param_4 = _1726;\n    int param_5 = _1726 + 1;\n    int param_6 = _1726 + 3;\n    float4 _1740 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1726 + 4;\n    float4 _1745 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1726 + 5;\n    float4 _1750 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1762 = _1750.x * fast::max(dot(_1740, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1767 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1790 = fast::clamp(dot(n, _1740.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1813 = fast::min(sqrt(1.0 - (_1790 * _1790)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1740, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1816 = _1638.y;\n    float _1818;\n    if (_1816 > 0.0)\n    {\n        _1818 = _1816;\n    }\n    else\n    {\n        _1818 = 1.5 * _1762;\n    }\n    float4 _1838 = float4(world + (n * (_1818 * sqrt(1.0 - (_1767 * _1767)))), 1.0);\n    float _1842 = dot(_1740, _1838);\n    float _1845 = _1750.y;\n    if (_1842 < _1845)\n    {\n        return 1.0;\n    }\n    float2 _1860 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1838), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1838)) / float2(_1842);\n    float _1862 = _1860.x;\n    bool _1865 = _1862 < _1745.x;\n    bool _1874;\n    if (!_1865)\n    {\n        _1874 = _1862 > _1745.z;\n    }\n    else\n    {\n        _1874 = _1865;\n    }\n    bool _1883;\n    if (!_1874)\n    {\n        _1883 = _1860.y < _1745.y;\n    }\n    else\n    {\n        _1883 = _1874;\n    }\n    bool _1892;\n    if (!_1883)\n    {\n        _1892 = _1860.y > _1745.w;\n    }\n    else\n    {\n        _1892 = _1883;\n    }\n    if (_1892)\n    {\n        return 1.0;\n    }\n    float _1898 = _1638.x;\n    float _1900;\n    if (_1898 > 0.0)\n    {\n        _1900 = _1898;\n    }\n    else\n    {\n        _1900 = 1.5 * _1762;\n    }\n    float2 param_10 = _1860;\n    float4 param_11 = _1745;\n    float param_12 = _1842 - (_1900 * (1.0 + (0.5 * _1813)));\n    float param_13 = _1762;\n    float param_14 = 1.0;\n    float param_15 = _1750.z * 0.25;\n    float param_16 = (_1762 * fast::min(_1813, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1845, _1750.z);\n    int param_18 = int(_1633.z + 0.5);\n    float param_19 = _1633.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1192, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _452, thread float4& gl_FragCoord, constant fa_shadows& _1192, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _2441 = fa_lm.z > 0.5;\n    bool _2447;\n    if (_2441)\n    {\n        int param = li;\n        _2447 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2447 = _2441;\n    }\n    if (_2447)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2470 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _3502 = _2470.direction;\n    float3 _3497 = _2470.color;\n    float _3504 = _2470.attenuation;\n    float _3499 = _2470.shadow;\n    int _3507 = _2470.type;\n    if ((_3507 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3502;\n        float _2484 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _452, gl_FragCoord, _1192, fa_shadow_tex, fa_world_pos);\n        _3499 = _2484;\n        _3497 *= _2484;\n    }\n    else\n    {\n        bool _2495 = _3507 != 0;\n        bool _2501;\n        if (_2495)\n        {\n            _2501 = _3504 > 0.0;\n        }\n        else\n        {\n            _2501 = _2495;\n        }\n        if (_2501)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3502;\n            float _2513 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _452, gl_FragCoord, _1192, fa_shadow_tex);\n            _3499 = _2513;\n            _3497 *= _2513;\n        }\n    }\n    return LightSample{ _3502, _3497, _3504, _3499, _2470._distance, _3507 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l, constant fa_material& _2539)\n{\n    float _2533;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _2533 = 1.0;\n    }\n    else\n    {\n        _2533 = _2539.dark;\n    }\n    return (s.albedo * l.color) * _2533;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1192)\n{\n    if (_1192.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2149 = int(_1192.fa_shadow_cfg.x + 0.5);\n    float _2159 = dot(world - _1192.fa_shadow_eye.xyz, _1192.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2164 = _2149 > 0;\n    bool _2173;\n    if (_2164)\n    {\n        int param = _2149 - 1;\n        _2173 = _2159 <= fa_shadow_split_at(param, _1192);\n    }\n    else\n    {\n        _2173 = _2164;\n    }\n    if (_2173)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2180 = _2149 > 1;\n        bool _2187;\n        if (_2180)\n        {\n            _2187 = _2159 > _1192.fa_shadow_split.x;\n        }\n        else\n        {\n            _2187 = _2180;\n        }\n        if (_2187)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2193 = _2149 > 2;\n        bool _2200;\n        if (_2193)\n        {\n            _2200 = _2159 > _1192.fa_shadow_split.y;\n        }\n        else\n        {\n            _2200 = _2193;\n        }\n        if (_2200)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2206 = _2149 > 3;\n        bool _2213;\n        if (_2206)\n        {\n            _2213 = _2159 > _1192.fa_shadow_split.z;\n        }\n        else\n        {\n            _2213 = _2206;\n        }\n        if (_2213)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _452 [[buffer(1)]], constant fa_material& _2539 [[buffer(5)]], constant fa_shadows& _1192 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3338 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3338 = -_3338;\n    }\n    float3 _2923 = fast::normalize(_452.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _452, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3338, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2923, short(gl_FrontFacing) };\n    Surface _2931 = fa_standard_surface(param_1, _452, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3369 = _2931.albedo;\n    float _3370 = _2931.alpha;\n    float3 _3371 = _2931.normal;\n    float _3372 = _2931.metallic;\n    float _3373 = _2931.roughness;\n    float _3374 = _2931.occlusion;\n    float3 _3375 = _2931.emission;\n    float _3376 = _2931.clearcoat;\n    float _3377 = _2931.clearcoat_roughness;\n    float3 _3378 = _2931.sheen_color;\n    float _3379 = _2931.sheen_roughness;\n    float _3380 = _2931.anisotropy;\n    float _3381 = _2931.anisotropy_rotation;\n    float _3382 = _2931.specular;\n    float _3383 = _2931.ior;\n    float3 _3384 = _2931.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3338, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2923, short(gl_FrontFacing) };\n    Surface param_3 = _2931;\n    surface(param_2, param_3);\n    _3369 = param_3.albedo;\n    _3370 = param_3.alpha;\n    _3371 = param_3.normal;\n    _3372 = param_3.metallic;\n    _3373 = param_3.roughness;\n    _3374 = param_3.occlusion;\n    _3375 = param_3.emission;\n    _3376 = param_3.clearcoat;\n    _3377 = param_3.clearcoat_roughness;\n    _3378 = param_3.sheen_color;\n    _3379 = param_3.sheen_roughness;\n    _3380 = param_3.anisotropy;\n    _3381 = param_3.anisotropy_rotation;\n    _3382 = param_3.specular;\n    _3383 = param_3.ior;\n    _3384 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _3338;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _452, fa_decal_tex, fa_env_smp);\n    _3369 = param_6;\n    _3371 = param_7;\n    float3 result;\n    if (_452.fa_emissive.w > 0.5)\n    {\n        result = _3369;\n    }\n    else\n    {\n        float3 _2969 = _3371;\n        float3 _2970 = fast::normalize(_2969);\n        _3371 = _2970;\n        float3 param_8 = _2970;\n        float3 lit = (fa_indirect_diffuse(param_8, _452, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap) * _3369) * _3374;\n        int _2989 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2989; ln++)\n        {\n            int param_9 = ln;\n            int _3002 = fa_cl_light(param_9, fa_light_tex, fa_shadow_smp, _452, fa_cl_ndir, fa_cl_slot);\n            bool _3005 = in.fa_lm.z > 0.5;\n            bool _3011;\n            if (_3005)\n            {\n                int param_10 = _3002;\n                _3011 = fa_light_baked(param_10, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _3011 = _3005;\n            }\n            if (_3011)\n            {\n                continue;\n            }\n            int param_11 = _3002;\n            float3 param_12 = in.fa_world_pos;\n            float3 param_13 = _3338;\n            SurfaceInput param_14 = SurfaceInput{ in.fa_world_pos, _3338, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2923, short(gl_FrontFacing) };\n            Surface param_15 = Surface{ _3369, _3370, _3371, _3372, _3373, _3374, _3375, _3376, _3377, _3378, _3379, _3380, _3381, _3382, _3383, _3384 };\n            LightSample param_16 = fa_light_shadowed(param_11, param_12, param_13, fa_light_tex, fa_shadow_smp, _452, gl_FragCoord, _1192, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            lit += light(param_14, param_15, param_16, _2539);\n        }\n        result = lit;\n    }\n    float3 _3038 = result;\n    float3 _3039 = _3038 + _3375;\n    result = _3039;\n    float3 param_17 = _3039;\n    float3 param_18 = in.fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18, _1192);\n    bool _3048 = _452.fa_fog.w > 0.0;\n    bool _3055;\n    if (!_3048)\n    {\n        _3055 = _452.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3055 = _3048;\n    }\n    if (_3055)\n    {\n        float3 _3064 = in.fa_world_pos - _452.fa_camera_pos.xyz;\n        float _3070 = dot(_3064, _452.fa_fog_c.xyz);\n        bool _3074 = _452.fa_fog_c.w > 0.5;\n        float _3075;\n        if (_3074)\n        {\n            _3075 = _3070;\n        }\n        else\n        {\n            _3075 = length(_3064);\n        }\n        float _3087 = _3075 - _452.fa_fog_b.x;\n        if (_3087 > 0.0)\n        {\n            float _3096 = _452.fa_fog.w * _3087;\n            float tau = _3096 * _3096;\n            if (_452.fa_fog_b.y > 0.0)\n            {\n                float _3112;\n                if (_3074)\n                {\n                    _3112 = in.fa_world_pos.y - (_452.fa_fog_c.y * _3070);\n                }\n                else\n                {\n                    _3112 = _452.fa_camera_pos.y;\n                }\n                float _3133 = mix(_3112, in.fa_world_pos.y, fast::clamp(_452.fa_fog_b.x / _3075, 0.0, 1.0));\n                float _3137 = in.fa_world_pos.y - _3133;\n                float _3142 = _3133 - _452.fa_fog_b.z;\n                float _3147 = in.fa_world_pos.y - _452.fa_fog_b.z;\n                bool _3150 = _3142 <= 0.0;\n                bool _3151 = !_3150;\n                bool _3157;\n                if (_3151)\n                {\n                    _3157 = _452.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3157 = _3150;\n                }\n                float _3158;\n                if (_3157)\n                {\n                    _3158 = _452.fa_fog_b.y;\n                }\n                else\n                {\n                    _3158 = _452.fa_fog_b.y * exp(-fast::min(_452.fa_fog_b.w * _3142, 80.0));\n                }\n                bool _3185;\n                if (_3151)\n                {\n                    _3185 = _452.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3185 = _3150;\n                }\n                float _3186;\n                if (_3185)\n                {\n                    _3186 = _452.fa_fog_b.y * _3142;\n                }\n                else\n                {\n                    _3186 = (_452.fa_fog_b.y * (1.0 - exp(-fast::min(_452.fa_fog_b.w * _3142, 80.0)))) / _452.fa_fog_b.w;\n                }\n                bool _3211 = _3147 <= 0.0;\n                bool _3218;\n                if (!_3211)\n                {\n                    _3218 = _452.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3218 = _3211;\n                }\n                float _3219;\n                if (_3218)\n                {\n                    _3219 = _452.fa_fog_b.y * _3147;\n                }\n                else\n                {\n                    _3219 = (_452.fa_fog_b.y * (1.0 - exp(-fast::min(_452.fa_fog_b.w * _3147, 80.0)))) / _452.fa_fog_b.w;\n                }\n                float _3246;\n                if (abs(_3137) < 0.001000000047497451305389404296875)\n                {\n                    _3246 = _3158;\n                }\n                else\n                {\n                    _3246 = (_3219 - _3186) / _3137;\n                }\n                tau += (_3087 * fast::max(_3246, 0.0));\n            }\n            result = mix(result, _452.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3370);\n    return out;\n}\n\n",
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
            "inst_name": "_452",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1192",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_2539",
            "msl_buffer_n": 5
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
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _786 = base_t;\n    _786.x = _225.x;\n    _786.y = _225.y;\n    _786.z = _225.z;\n    base_t = _786;\n    float4 _241 = (_786 * _213.fa_base_color) * i.vertex_color;\n    float3 _749 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _794 = _279;\n        _794.x = _284.x;\n        _794.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _794;\n        _749 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _797 = mrt;\n    _797.x = _313.x;\n    _797.y = _313.y;\n    _797.z = _313.z;\n    mrt = _797;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _754 = _213.fa_layers_a.x;\n    float _755 = _213.fa_layers_a.y;\n    float _758 = _213.fa_layers_a.z;\n    float _757 = _213.fa_layers_b.w;\n    float _760 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _754 *= _355.y;\n            _755 *= _355.z;\n            _757 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _758 *= mrt.x;\n            _760 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _749, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _754, _755, _213.fa_layers_b.xyz, _757, _758, _213.fa_layers_a.w, _760, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _660 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _660 = -_660;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _660, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _660, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _786 = base_t;\n    _786.x = _225.x;\n    _786.y = _225.y;\n    _786.z = _225.z;\n    base_t = _786;\n    float4 _241 = (_786 * _213.fa_base_color) * i.vertex_color;\n    float3 _749 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _794 = _279;\n        _794.x = _284.x;\n        _794.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _794;\n        _749 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _797 = mrt;\n    _797.x = _313.x;\n    _797.y = _313.y;\n    _797.z = _313.z;\n    mrt = _797;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _754 = _213.fa_layers_a.x;\n    float _755 = _213.fa_layers_a.y;\n    float _758 = _213.fa_layers_a.z;\n    float _757 = _213.fa_layers_b.w;\n    float _760 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _754 *= _355.y;\n            _755 *= _355.z;\n            _757 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _758 *= mrt.x;\n            _760 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _749, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _754, _755, _213.fa_layers_b.xyz, _757, _758, _213.fa_layers_a.w, _760, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _660 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _660 = -_660;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _660, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _660, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
