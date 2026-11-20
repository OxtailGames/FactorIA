{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5c278b25d8ce4341984c8bf2a53e1ca7890b6a924713889b53c089df056597d0",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_267, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nconstant spvUnsafeArray<float, 63> _2695 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _503)\n{\n    bool _508 = _503.fa_cl_info.x < 0.0;\n    bool _515;\n    if (!_508)\n    {\n        _515 = _503.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _515 = _508;\n    }\n    bool _523;\n    if (!_515)\n    {\n        _523 = _503.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _523 = _515;\n    }\n    bool _530;\n    if (!_523)\n    {\n        _530 = _503.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _530 = _523;\n    }\n    bool _537;\n    if (!_530)\n    {\n        _537 = _503.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _537 = _530;\n    }\n    if (_537)\n    {\n        return float4(0.0);\n    }\n    float4 _547 = float4(world_pos, 1.0);\n    float _554 = dot(_503.fa_cl_vpw, _547);\n    if (!(_554 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _576 = float2(dot(_503.fa_cl_vpx, _547), dot(_503.fa_cl_vpy, _547)) / float2(_554);\n    int _580 = int(_503.fa_cl_grid.x);\n    int _584 = int(_503.fa_cl_grid.y);\n    int param = (int(_503.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_503.fa_cl_fwd.xyz, world_pos) + _503.fa_cl_fwd.w, _503.fa_cl_grid.w) / _503.fa_cl_grid.w) * _503.fa_cl_grid.z)), 0, int(_503.fa_cl_info.y) - 1) * _584) + clamp(int(floor(((_576.y * 0.5) + 0.5) * _503.fa_cl_grid.y)), 0, _584 - 1)) * _580)) + clamp(int(floor(((_576.x * 0.5) + 0.5) * _503.fa_cl_grid.x)), 0, _580 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _503)\n{\n    float3 param = world_pos;\n    float4 _660 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _503);\n    return int2(int(_660.x), int(_660.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _503, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_503.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3230 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _503);\n    fa_cl_slot = _3230.x;\n    fa_cl_local = _3230.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3384 = fa_linear_to_srgb(param);\n        c = _3384;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3392 = fa_srgb_to_linear(param_1);\n            c = _3392;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _268;\n    if (bool(i.front_facing))\n    {\n        _268 = i.world_normal;\n    }\n    else\n    {\n        _268 = -i.world_normal;\n    }\n    float3 _292 = fast::normalize(i.world_tangent.xyz - (_268 * dot(_268, i.world_tangent.xyz)));\n    float3 _319 = fast::normalize(((_292 * m.x) + ((cross(_268, _292) * i.world_tangent.w) * m.y)) + (_268 * m.z));\n    float3 _322;\n    if (bool(i.front_facing))\n    {\n        _322 = _319;\n    }\n    else\n    {\n        _322 = -_319;\n    }\n    return _322;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _503, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _503.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3423 = fa_tex_fix(param_2, param_3);\n    float4 _4525 = base_t;\n    _4525.x = _3423.x;\n    _4525.y = _3423.y;\n    _4525.z = _3423.z;\n    base_t = _4525;\n    float4 _3437 = (_4525 * _503.fa_base_color) * i.vertex_color;\n    float3 _4392 = i.world_normal;\n    if (_503.fa_maps.z > 0.5)\n    {\n        float param_4 = _503.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3469 = fa_tex_fix(param_6, param_7);\n        float3 _3472 = (_3469 * 2.0) - float3(1.0);\n        float2 _3477 = _3472.xy * _503.fa_maps.x;\n        float3 _4533 = _3472;\n        _4533.x = _3477.x;\n        _4533.y = _3477.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4533;\n        _4392 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _503.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3506 = fa_tex_fix(param_12, param_13);\n    float4 _4536 = mrt;\n    _4536.x = _3506.x;\n    _4536.y = _3506.y;\n    _4536.z = _3506.z;\n    mrt = _4536;\n    float4 _3534 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _503.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3534.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3546 = fa_tex_fix(param_16, param_17);\n    float param_18 = _503.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3576 = fa_tex_fix(param_20, param_21);\n    float _4397 = _503.fa_layers_a.x;\n    float _4398 = _503.fa_layers_a.y;\n    float _4401 = _503.fa_layers_a.z;\n    float _4400 = _503.fa_layers_b.w;\n    float _4403 = _503.fa_layers_c.x;\n    if (_503.fa_layers_c.z > 0.5)\n    {\n        if (mod(_503.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4397 *= _3546.y;\n            _4398 *= _3546.z;\n            _4400 *= _3534.w;\n        }\n        if (_503.fa_layers_c.z > 1.5)\n        {\n            _4401 *= mrt.x;\n            _4403 *= mrt.w;\n        }\n    }\n    return Surface{ _3437.xyz, _3437.w, _4392, fast::clamp(_503.fa_pbr.x * _3506.z, 0.0, 1.0), fast::clamp(_503.fa_pbr.y * _3506.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_503.fa_maps.y * (_3546.x - 1.0)), _503.fa_emissive.xyz + (_503.fa_model_emissive.xyz * _3576), _4397, _4398, _503.fa_layers_b.xyz, _4400, _4401, _503.fa_layers_a.w, _4403, _503.fa_layers_c.y, _503.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _741 = rect.zw - rect.xy;\n    float2 _745 = _741 * atlas;\n    float2 _749 = ddx * _745;\n    float2 _753 = ddy * _745;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _741)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_749, _749), dot(_753, _753)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _503, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _788 = _503.fa_counts.y < 0.5;\n    bool _795;\n    if (!_788)\n    {\n        _795 = _503.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _795 = _788;\n    }\n    if (_795)\n    {\n        return;\n    }\n    float3 _801 = dfdx(world_pos);\n    float3 _804 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _808 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _503);\n    int _812 = int(_808.w);\n    if (_812 < 1)\n    {\n        return;\n    }\n    int _822 = int(_503.fa_counts.y + 0.5);\n    int param_1 = _822;\n    float4 _826 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _829 = _826.yz;\n    int _833 = int(_826.w);\n    int param_2 = _822 + 1;\n    float4 _838 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _839 = _838.x;\n    int _845 = int(_503.fa_counts.w + 0.5) - 1;\n    int _849 = int(_808.z);\n    float3 _1115;\n    for (int k = 0; k < _812; k++)\n    {\n        int _862 = _849 + k;\n        int param_3 = _833 + (_862 >> 2);\n        int _880 = (_822 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_862 & 3]) * 7);\n        int param_4 = _880 + 6;\n        float4 _885 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_885.w + 0.5) >> _845) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _880;\n        float4 _900 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _880 + 1;\n        float4 _905 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _880 + 2;\n        float4 _910 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _913 = _900.xyz;\n        float _918 = dot(_913, world_pos) + _900.w;\n        float3 _920 = _905.xyz;\n        float _925 = dot(_920, world_pos) + _905.w;\n        float3 _927 = _910.xyz;\n        float _932 = dot(_927, world_pos) + _910.w;\n        bool _937 = abs(_918) > 0.5;\n        bool _945;\n        if (!_937)\n        {\n            _945 = abs(_925) > 0.5;\n        }\n        else\n        {\n            _945 = _937;\n        }\n        bool _953;\n        if (!_945)\n        {\n            _953 = abs(_932) > 0.5;\n        }\n        else\n        {\n            _953 = _945;\n        }\n        if (_953)\n        {\n            continue;\n        }\n        float _968 = fast::clamp(dot(geo_normal, fast::normalize(_927)) * _885.z, 0.0, 1.0);\n        if (_968 <= 0.0)\n        {\n            continue;\n        }\n        float _988 = (fast::clamp((0.5 - abs(_932)) * 10.0, 0.0, 1.0) * _968) * _885.x;\n        float2 _996 = float2(_918 + 0.5, 0.5 - _925);\n        float2 _1006 = float2(dot(_913, _801), dot(_920, _801));\n        float2 _1016 = float2(dot(_913, _804), dot(_920, _804));\n        int param_8 = _880 + 5;\n        float4 _1021 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _880 + 3;\n        float4 _1026 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _880 + 4;\n        float4 _1031 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1021.xyz;\n        bool _1041 = _1026.z > _1026.x;\n        if (_1041)\n        {\n            float4 param_11 = _1026;\n            float2 param_12 = _996;\n            float2 param_13 = _829;\n            float2 param_14 = _1006;\n            float2 param_15 = _1016;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_839 > 0.5) && (_839 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1067 = fa_dc_to_linear(param_16);\n                float4 _4448 = tx;\n                _4448.x = _1067.x;\n                _4448.y = _1067.y;\n                _4448.z = _1067.z;\n                tx = _4448;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_988 * tex_a) * _1021.w, 0.0, 1.0)));\n        if (_1031.z > _1031.x)\n        {\n            float4 param_17 = _1031;\n            float2 param_18 = _996;\n            float2 param_19 = _829;\n            float2 param_20 = _1006;\n            float2 param_21 = _1016;\n            float4 _1111 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_839 > 1.5)\n            {\n                float3 param_22 = _1111.xyz;\n                float3 _1121 = fa_dc_to_srgb(param_22);\n                _1115 = _1121;\n            }\n            else\n            {\n                _1115 = _1111.xyz;\n            }\n            float3 _1131 = (_1115 * 2.0) - float3(1.0);\n            float2 _1136 = _1131.xy * _885.y;\n            float3 _1158 = (fast::normalize(_913) * _1136.x) + (fast::normalize(_920) * _1136.y);\n            float3 _1161 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1161, fast::normalize((_1161 * fast::max(_1131.z, 0.0500000007450580596923828125)) + (_1158 - (_1161 * dot(_1161, _1158)))), float3(fast::clamp(_988 * (_1041 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _503, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_503.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _2378 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _2378;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _503, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_503.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _503, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _503.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _503, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _503, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _2621 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2628 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2631 = int(_2621);\n    int _2634 = int(_2628);\n    float _2644 = _2628 - float(_2634);\n    int _2699 = (_2631 * 9) + _2634;\n    int _2719 = ((_2631 + 1) * 9) + _2634;\n    return mix(mix(_2695[_2699], _2695[_2699 + 1], _2644), mix(_2695[_2719], _2695[_2719 + 1], _2644), _2621 - float(_2631));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4251 = false;\n    float _4252 = 1.0;\n    float _4253 = 1.0;\n    float _4254 = 1.0;\n    float _4255 = 0.0;\n    float _4256 = 0.0;\n    float _4257 = 0.0;\n    float _4258 = 0.0;\n    float _4260 = 1.0;\n    bool _4261 = false;\n    float3 _4262 = float3(0.0);\n    float _4263 = 1.0;\n    float _4264 = 1.0;\n    float _4265 = 1.0;\n    float _4266 = 0.0;\n    float _4267 = 0.0;\n    float3 _4268 = float3(1.0, 0.0, 0.0);\n    float3 _4269 = float3(0.0, 0.0, 1.0);\n    float _4270 = 1.0;\n    float _4271 = 1.0;\n    float _2772 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2776 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2781 = (_2772 != 1.0) || (_2776 != 1.5);\n    bool _2791;\n    if (!_2781)\n    {\n        _2791 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2791 = _2781;\n    }\n    if (_2791)\n    {\n        float _2799 = (_2776 - 1.0) / (_2776 + 1.0);\n        f0 = mix(fast::min(float3(_2799 * _2799) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2772, s.albedo, float3(metallic));\n        _4252 = mix(_2772, 1.0, metallic);\n        _4251 = true;\n    }\n    float _2827 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2827 > 0.0)\n    {\n        float _2835 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4255 = _2827;\n        _4256 = _2835;\n        float _2842 = _2835 * _2835;\n        _4257 = _2842;\n        _4258 = _2842 * _2842;\n        float _2854 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4260 = _2854;\n        _4253 = 1.0 - (_2827 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2854, 0.0, 1.0), 5.0))));\n        _4251 = true;\n    }\n    float3 _2873 = fast::max(s.sheen_color, float3(0.0));\n    float _2882 = fast::max(_2873.x, fast::max(_2873.y, _2873.z));\n    if (_2882 > 0.0)\n    {\n        float _2890 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4261 = true;\n        _4262 = _2873;\n        _4263 = _2890;\n        _4264 = _2890 * _2890;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2890;\n        float _2907 = fa_sheen_albedo(param, param_1);\n        _4266 = _2907;\n        _4265 = 1.0 - fast::min(_2882 * _2907, 1.0);\n        _4251 = true;\n    }\n    _4254 = _4253 * _4265;\n    float _2926 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2926 != 0.0)\n    {\n        float3 _2941 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2941;\n        if (dot(_2941, _2941) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2958 = t;\n        float3 _2959 = fast::normalize(_2958);\n        t = _2959;\n        float3 _2984 = fast::normalize((_2959 * cos(s.anisotropy_rotation)) + ((cross(n, _2959) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4268 = _2984;\n        _4269 = cross(n, _2984);\n        float _2994 = roughness * roughness;\n        float _3000 = mix(_2994, 1.0, _2926 * _2926);\n        bool _3002 = _2926 > 0.0;\n        _4270 = _3002 ? _3000 : _2994;\n        _4271 = _3002 ? _2994 : _3000;\n        _4267 = _2926;\n        _4251 = true;\n    }\n    return FaLayers{ short(_4251), _4252, _4253, _4254, _4255, _4256, _4257, _4258, i.world_normal, _4260, short(_4261), _4262, _4263, _4264, _4265, _4266, _4267, _4268, _4269, _4270, _4271 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _2553 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2556 = _2553.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_2556 * _2556, exp2((-9.27999973297119140625) * ndv)) * _2556) + _2553.y)) + _2553.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _503, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_503.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _503.fa_env_horizon.w)).xyz;\n    }\n    float _2407 = rough * rough;\n    float _2437 = 0.60000002384185791015625 * _2407;\n    return mix(mix(_503.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_503.fa_env_horizon.xyz, _503.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _2407)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _2437, 0.0500000007450580596923828125 + _2437, d.y))), ((_503.fa_env_sky.xyz + _503.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_2407 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _503, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _3035;\n        if (L.aniso >= 0.0)\n        {\n            _3035 = L.b;\n        }\n        else\n        {\n            _3035 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_3035, v), _3035), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3068 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _503, fa_env_smp, fa_env_tex) * ((f0 * _3068.x) + (float3(L.f90) * _3068.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _503, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3123 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _503, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _3123.x) + _3123.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _503, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2595 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _503, fa_env_smp, fa_env_tex) * ((f0 * _2595.x) + float3(_2595.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _503, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float _3152 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _3156 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _3163 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_3152));\n    float3 f0 = _3163;\n    float3 _3167 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3167;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3152;\n    float param_5 = _3156;\n    float3 param_6 = _3163;\n    FaLayers _3184 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3184.on)\n    {\n        FaLayers param_7 = _3184;\n        float3 param_8 = _3167;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3156;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _503, fa_env_smp, fa_env_tex) * s.occlusion;\n    }\n    float3 param_12 = _3167;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3156;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _503, fa_env_smp, fa_env_tex) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor, constant fa_mesh_fs_params& _503, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1, _503, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _503)\n{\n    int param = (int(_503.fa_cl_info.x) + int(_503.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _503, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _503);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _378 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _384 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _387 = _384.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _393 = _387 < 0.5;\n    float3 l;\n    if (_393)\n    {\n        l = fast::normalize(_378.xyz);\n    }\n    else\n    {\n        float3 _405 = _378.xyz - world_pos;\n        float _407 = length(_405);\n        dist = _407;\n        l = _405 / float3(fast::max(_407, 9.9999997473787516355514526367188e-05));\n        float _422 = _407 / fast::max(_378.w, 0.001000000047497451305389404296875);\n        float _428 = fast::clamp(1.0 - (_422 * _422), 0.0, 1.0);\n        atten = _428 * _428;\n        if (_387 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _442 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _452 = _442.w;\n            int param_3 = (li * 4) + 3;\n            float4 _458 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _459 = _458.x;\n            float cos_inner = _459;\n            if (_459 > 1.5)\n            {\n                cos_inner = mix(_452, 1.0, 0.25);\n            }\n            atten *= smoothstep(_452, cos_inner, dot(-l, fast::normalize(_442.xyz)));\n        }\n    }\n    int _489;\n    if (_393)\n    {\n        _489 = 0;\n    }\n    else\n    {\n        _489 = (_387 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _384.xyz * atten, atten, 1.0, dist, _489 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1243)\n{\n    float _1233;\n    if (i == 0)\n    {\n        _1233 = _1243.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1249;\n        if (i == 1)\n        {\n            _1249 = _1243.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1257;\n            if (i == 2)\n            {\n                _1257 = _1243.fa_shadow_split.z;\n            }\n            else\n            {\n                _1257 = _1243.fa_shadow_split.w;\n            }\n            _1249 = _1257;\n        }\n        _1233 = _1249;\n    }\n    return _1233;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1290 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1294;\n    if (conv.x < 0.5)\n    {\n        _1294 = _1290;\n    }\n    else\n    {\n        _1294 = (conv.y * conv.z) / (conv.z - (_1290 * (conv.z - conv.y)));\n    }\n    return _1294;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1221 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1221), sin(_1221)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1243, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1340 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1354 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1340;\n            float2 _1373 = fa_shadow_vogel(param_3, param_4, param_5) * _1354;\n            float2 param_6 = uv + (_1373 * _1243.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1385 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1385 < (zr - (length(_1373) * plane)))\n            {\n                sum += _1385;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1429 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1429; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1429;\n        float param_11 = _1340;\n        float2 _1448 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1448 * _1243.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1448) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1429);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1243, texture2d<float> fa_shadow_tex)\n{\n    float _1490 = fast::max(_1243.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1495 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1501 = sqrt(1.0 - (_1495 * _1495));\n    float _1508 = fast::min(_1501 / fast::max(_1495, 0.20000000298023223876953125), 4.0);\n    float _1513;\n    if (_1243.fa_shadow_bias.y > 0.0)\n    {\n        _1513 = _1243.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1513 = 1.5 * _1243.fa_shadow_info[ci].x;\n    }\n    float4 _1538 = _1243.fa_shadow_mat[ci] * float4(world + (n * (_1513 * _1501)), 1.0);\n    float _1545 = _1538.x;\n    bool _1548 = _1545 < _1243.fa_shadow_rect[ci].x;\n    bool _1557;\n    if (!_1548)\n    {\n        _1557 = _1545 > _1243.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1557 = _1548;\n    }\n    bool _1566;\n    if (!_1557)\n    {\n        _1566 = _1538.y < _1243.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1566 = _1557;\n    }\n    bool _1575;\n    if (!_1566)\n    {\n        _1575 = _1538.y > _1243.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1575 = _1566;\n    }\n    bool _1582;\n    if (!_1575)\n    {\n        _1582 = _1538.z > 1.0;\n    }\n    else\n    {\n        _1582 = _1575;\n    }\n    if (_1582)\n    {\n        return -1.0;\n    }\n    float _1591;\n    if (_1243.fa_shadow_bias.x > 0.0)\n    {\n        _1591 = _1243.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1591 = 1.5 * _1243.fa_shadow_info[ci].x;\n    }\n    float2 param = _1538.xy;\n    float4 param_1 = _1243.fa_shadow_rect[ci];\n    float param_2 = _1538.z - ((_1591 * (1.0 + (0.5 * _1508))) / _1490);\n    float param_3 = _1243.fa_shadow_info[ci].x;\n    float param_4 = _1490;\n    float param_5 = _1490 * 0.25;\n    float param_6 = ((_1243.fa_shadow_info[ci].x * fast::min(_1508, 3.0)) * 0.5) / _1490;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1243.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1243.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1243, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _503, thread float4& gl_FragCoord, constant fa_shadows& _1243, texture2d<float> fa_shadow_tex)\n{\n    if (_503.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2018 = int(_1243.fa_shadow_cfg.x + 0.5);\n    if (_2018 < 1)\n    {\n        return 1.0;\n    }\n    float _2033 = dot(world - _1243.fa_shadow_eye.xyz, _1243.fa_shadow_fwd.xyz);\n    int param = _2018 - 1;\n    if (_2033 > fa_shadow_split_at(param, _1243))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2045 = _2018 > 1;\n    bool _2052;\n    if (_2045)\n    {\n        _2052 = _2033 > _1243.fa_shadow_split.x;\n    }\n    else\n    {\n        _2052 = _2045;\n    }\n    if (_2052)\n    {\n        ci = 1;\n    }\n    bool _2056 = _2018 > 2;\n    bool _2063;\n    if (_2056)\n    {\n        _2063 = _2033 > _1243.fa_shadow_split.y;\n    }\n    else\n    {\n        _2063 = _2056;\n    }\n    if (_2063)\n    {\n        ci = 2;\n    }\n    bool _2067 = _2018 > 3;\n    bool _2074;\n    if (_2067)\n    {\n        _2074 = _2033 > _1243.fa_shadow_split.z;\n    }\n    else\n    {\n        _2074 = _2067;\n    }\n    if (_2074)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2018)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2100 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1243, fa_shadow_tex);\n        s = _2100;\n        if (_2100 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1243.fa_shadow_cfg.y > 0.0)\n    {\n        float _2125;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2125 = fa_shadow_split_at(param_5, _1243);\n        }\n        else\n        {\n            _2125 = _1243.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2144 = _1243.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1243) - _2125, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2155 = fast::clamp((_2033 - (fa_shadow_split_at(param_7, _1243) - _2144)) / _2144, 0.0, 1.0);\n        if (_2155 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2018)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2176 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1243, fa_shadow_tex);\n                s2 = _2176;\n                if (_2176 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2155);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _503, thread float4& gl_FragCoord, constant fa_shadows& _1243, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _503, gl_FragCoord, _1243, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _503, thread float4& gl_FragCoord, constant fa_shadows& _1243, texture2d<float> fa_shadow_tex)\n{\n    bool _1649 = _503.fa_pbr.z < 0.5;\n    bool _1657;\n    if (!_1649)\n    {\n        _1657 = _1243.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1657 = _1649;\n    }\n    if (_1657)\n    {\n        return 1.0;\n    }\n    int param = (int(_1243.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1670 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1671 = _1670.x;\n    if (_1671 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1680 = int(_1671 + 0.5);\n    int param_1 = _1680;\n    float4 _1684 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1680 + 1;\n    float4 _1689 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1692 = _1684.y;\n    if (_1692 > 0.0)\n    {\n        float _1709 = 1.0 - smoothstep(0.75 * _1692, _1692, length(world - _1243.fa_shadow_eye.xyz));\n        fade = _1709;\n        if (_1709 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1684.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1728 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1731 = abs(_1728);\n        float _1733 = _1731.x;\n        float _1735 = _1731.y;\n        bool _1736 = _1733 >= _1735;\n        bool _1744;\n        if (_1736)\n        {\n            _1744 = _1733 >= _1731.z;\n        }\n        else\n        {\n            _1744 = _1736;\n        }\n        int _1745;\n        if (_1744)\n        {\n            _1745 = (_1728.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1758;\n            if (_1735 >= _1731.z)\n            {\n                _1758 = (_1728.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1758 = (_1728.z > 0.0) ? 4 : 5;\n            }\n            _1745 = _1758;\n        }\n        face = _1745;\n    }\n    int _1777 = (_1680 + 2) + (face * 6);\n    int param_4 = _1777;\n    int param_5 = _1777 + 1;\n    int param_6 = _1777 + 3;\n    float4 _1791 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1777 + 4;\n    float4 _1796 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1777 + 5;\n    float4 _1801 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1813 = _1801.x * fast::max(dot(_1791, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1818 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1841 = fast::clamp(dot(n, _1791.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1864 = fast::min(sqrt(1.0 - (_1841 * _1841)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1791, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1867 = _1689.y;\n    float _1869;\n    if (_1867 > 0.0)\n    {\n        _1869 = _1867;\n    }\n    else\n    {\n        _1869 = 1.5 * _1813;\n    }\n    float4 _1889 = float4(world + (n * (_1869 * sqrt(1.0 - (_1818 * _1818)))), 1.0);\n    float _1893 = dot(_1791, _1889);\n    float _1896 = _1801.y;\n    if (_1893 < _1896)\n    {\n        return 1.0;\n    }\n    float2 _1911 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1889), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1889)) / float2(_1893);\n    float _1913 = _1911.x;\n    bool _1916 = _1913 < _1796.x;\n    bool _1925;\n    if (!_1916)\n    {\n        _1925 = _1913 > _1796.z;\n    }\n    else\n    {\n        _1925 = _1916;\n    }\n    bool _1934;\n    if (!_1925)\n    {\n        _1934 = _1911.y < _1796.y;\n    }\n    else\n    {\n        _1934 = _1925;\n    }\n    bool _1943;\n    if (!_1934)\n    {\n        _1943 = _1911.y > _1796.w;\n    }\n    else\n    {\n        _1943 = _1934;\n    }\n    if (_1943)\n    {\n        return 1.0;\n    }\n    float _1949 = _1689.x;\n    float _1951;\n    if (_1949 > 0.0)\n    {\n        _1951 = _1949;\n    }\n    else\n    {\n        _1951 = 1.5 * _1813;\n    }\n    float2 param_10 = _1911;\n    float4 param_11 = _1796;\n    float param_12 = _1893 - (_1951 * (1.0 + (0.5 * _1864)));\n    float param_13 = _1813;\n    float param_14 = 1.0;\n    float param_15 = _1801.z * 0.25;\n    float param_16 = (_1813 * fast::min(_1864, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1896, _1801.z);\n    int param_18 = int(_1684.z + 0.5);\n    float param_19 = _1684.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1243, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _503, thread float4& gl_FragCoord, constant fa_shadows& _1243, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3257 = fa_lm.z > 0.5;\n    bool _3263;\n    if (_3257)\n    {\n        int param = li;\n        _3263 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3263 = _3257;\n    }\n    if (_3263)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3285 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _4377 = _3285.direction;\n    float3 _4372 = _3285.color;\n    float _4379 = _3285.attenuation;\n    float _4374 = _3285.shadow;\n    int _4382 = _3285.type;\n    if ((_4382 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4377;\n        float _3299 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _503, gl_FragCoord, _1243, fa_shadow_tex, fa_world_pos);\n        _4374 = _3299;\n        _4372 *= _3299;\n    }\n    else\n    {\n        bool _3310 = _4382 != 0;\n        bool _3316;\n        if (_3310)\n        {\n            _3316 = _4379 > 0.0;\n        }\n        else\n        {\n            _3316 = _3310;\n        }\n        if (_3316)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4377;\n            float _3328 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _503, gl_FragCoord, _1243, fa_shadow_tex);\n            _4374 = _3328;\n            _4372 *= _3328;\n        }\n    }\n    return LightSample{ _4377, _4372, _4379, _4374, _3285._distance, _4382 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1243)\n{\n    if (_1243.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2200 = int(_1243.fa_shadow_cfg.x + 0.5);\n    float _2210 = dot(world - _1243.fa_shadow_eye.xyz, _1243.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2215 = _2200 > 0;\n    bool _2224;\n    if (_2215)\n    {\n        int param = _2200 - 1;\n        _2224 = _2210 <= fa_shadow_split_at(param, _1243);\n    }\n    else\n    {\n        _2224 = _2215;\n    }\n    if (_2224)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2231 = _2200 > 1;\n        bool _2238;\n        if (_2231)\n        {\n            _2238 = _2210 > _1243.fa_shadow_split.x;\n        }\n        else\n        {\n            _2238 = _2231;\n        }\n        if (_2238)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2244 = _2200 > 2;\n        bool _2251;\n        if (_2244)\n        {\n            _2251 = _2210 > _1243.fa_shadow_split.y;\n        }\n        else\n        {\n            _2251 = _2244;\n        }\n        if (_2251)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2257 = _2200 > 3;\n        bool _2264;\n        if (_2257)\n        {\n            _2264 = _2210 > _1243.fa_shadow_split.z;\n        }\n        else\n        {\n            _2264 = _2257;\n        }\n        if (_2264)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _503 [[buffer(1)]], constant fa_shadows& _1243 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4081 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4081 = -_4081;\n    }\n    float3 _3716 = fast::normalize(_503.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _503, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4081, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3716, short(gl_FrontFacing) };\n    Surface _3724 = fa_standard_surface(param_1, _503, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4120 = _3724.albedo;\n    float _4121 = _3724.alpha;\n    float3 _4122 = _3724.normal;\n    float _4123 = _3724.metallic;\n    float _4124 = _3724.roughness;\n    float _4125 = _3724.occlusion;\n    float3 _4126 = _3724.emission;\n    float _4127 = _3724.clearcoat;\n    float _4128 = _3724.clearcoat_roughness;\n    float3 _4129 = _3724.sheen_color;\n    float _4130 = _3724.sheen_roughness;\n    float _4131 = _3724.anisotropy;\n    float _4132 = _3724.anisotropy_rotation;\n    float _4133 = _3724.specular;\n    float _4134 = _3724.ior;\n    float3 _4135 = _3724.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4081, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3716, short(gl_FrontFacing) };\n    Surface param_3 = _3724;\n    surface(param_2, param_3);\n    _4120 = param_3.albedo;\n    _4121 = param_3.alpha;\n    _4122 = param_3.normal;\n    _4123 = param_3.metallic;\n    _4124 = param_3.roughness;\n    _4125 = param_3.occlusion;\n    _4126 = param_3.emission;\n    _4127 = param_3.clearcoat;\n    _4128 = param_3.clearcoat_roughness;\n    _4129 = param_3.sheen_color;\n    _4130 = param_3.sheen_roughness;\n    _4131 = param_3.anisotropy;\n    _4132 = param_3.anisotropy_rotation;\n    _4133 = param_3.specular;\n    _4134 = param_3.ior;\n    _4135 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4081;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _503, fa_decal_tex, fa_env_smp);\n    _4120 = param_6;\n    _4122 = param_7;\n    float3 result;\n    if (_503.fa_emissive.w > 0.5)\n    {\n        result = _4120;\n    }\n    else\n    {\n        float3 _3762 = _4122;\n        float3 _3763 = fast::normalize(_3762);\n        _4122 = _3763;\n        float3 param_8 = _3763;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _4081, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3716, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _4120, _4121, _4122, _4123, _4124, _4125, _4126, _4127, _4128, _4129, _4130, _4131, _4132, _4133, _4134, _4135 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _503, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11, _503, fa_env_smp, fa_env_tex);\n        int _3782 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3782; ln++)\n        {\n            int param_12 = ln;\n            int _3795 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _503, fa_cl_ndir, fa_cl_slot);\n            bool _3798 = in.fa_lm.z > 0.5;\n            bool _3804;\n            if (_3798)\n            {\n                int param_13 = _3795;\n                _3804 = fa_light_baked(param_13, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _3804 = _3798;\n            }\n            if (_3804)\n            {\n                continue;\n            }\n            int param_14 = _3795;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _4081;\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _4081, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3716, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _4120, _4121, _4122, _4123, _4124, _4125, _4126, _4127, _4128, _4129, _4130, _4131, _4132, _4133, _4134, _4135 };\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16, fa_light_tex, fa_shadow_smp, _503, gl_FragCoord, _1243, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _3831 = result;\n    float3 _3832 = _3831 + _4126;\n    result = _3832;\n    float3 param_20 = _3832;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _1243);\n    bool _3841 = _503.fa_fog.w > 0.0;\n    bool _3848;\n    if (!_3841)\n    {\n        _3848 = _503.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3848 = _3841;\n    }\n    if (_3848)\n    {\n        float3 _3857 = in.fa_world_pos - _503.fa_camera_pos.xyz;\n        float _3863 = dot(_3857, _503.fa_fog_c.xyz);\n        bool _3867 = _503.fa_fog_c.w > 0.5;\n        float _3868;\n        if (_3867)\n        {\n            _3868 = _3863;\n        }\n        else\n        {\n            _3868 = length(_3857);\n        }\n        float _3880 = _3868 - _503.fa_fog_b.x;\n        if (_3880 > 0.0)\n        {\n            float _3889 = _503.fa_fog.w * _3880;\n            float tau = _3889 * _3889;\n            if (_503.fa_fog_b.y > 0.0)\n            {\n                float _3905;\n                if (_3867)\n                {\n                    _3905 = in.fa_world_pos.y - (_503.fa_fog_c.y * _3863);\n                }\n                else\n                {\n                    _3905 = _503.fa_camera_pos.y;\n                }\n                float _3926 = mix(_3905, in.fa_world_pos.y, fast::clamp(_503.fa_fog_b.x / _3868, 0.0, 1.0));\n                float _3930 = in.fa_world_pos.y - _3926;\n                float _3935 = _3926 - _503.fa_fog_b.z;\n                float _3940 = in.fa_world_pos.y - _503.fa_fog_b.z;\n                bool _3943 = _3935 <= 0.0;\n                bool _3944 = !_3943;\n                bool _3950;\n                if (_3944)\n                {\n                    _3950 = _503.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3950 = _3943;\n                }\n                float _3951;\n                if (_3950)\n                {\n                    _3951 = _503.fa_fog_b.y;\n                }\n                else\n                {\n                    _3951 = _503.fa_fog_b.y * exp(-fast::min(_503.fa_fog_b.w * _3935, 80.0));\n                }\n                bool _3978;\n                if (_3944)\n                {\n                    _3978 = _503.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3978 = _3943;\n                }\n                float _3979;\n                if (_3978)\n                {\n                    _3979 = _503.fa_fog_b.y * _3935;\n                }\n                else\n                {\n                    _3979 = (_503.fa_fog_b.y * (1.0 - exp(-fast::min(_503.fa_fog_b.w * _3935, 80.0)))) / _503.fa_fog_b.w;\n                }\n                bool _4004 = _3940 <= 0.0;\n                bool _4011;\n                if (!_4004)\n                {\n                    _4011 = _503.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4011 = _4004;\n                }\n                float _4012;\n                if (_4011)\n                {\n                    _4012 = _503.fa_fog_b.y * _3940;\n                }\n                else\n                {\n                    _4012 = (_503.fa_fog_b.y * (1.0 - exp(-fast::min(_503.fa_fog_b.w * _3940, 80.0)))) / _503.fa_fog_b.w;\n                }\n                float _4039;\n                if (abs(_3930) < 0.001000000047497451305389404296875)\n                {\n                    _4039 = _3951;\n                }\n                else\n                {\n                    _4039 = (_4012 - _3979) / _3930;\n                }\n                tau += (_3880 * fast::max(_4039, 0.0));\n            }\n            result = mix(result, _503.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4121);\n    return out;\n}\n\n",
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
            "inst_name": "_503",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1243",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_388, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nconstant spvUnsafeArray<float, 63> _2695 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _503)\n{\n    bool _508 = _503.fa_cl_info.x < 0.0;\n    bool _515;\n    if (!_508)\n    {\n        _515 = _503.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _515 = _508;\n    }\n    bool _523;\n    if (!_515)\n    {\n        _523 = _503.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _523 = _515;\n    }\n    bool _530;\n    if (!_523)\n    {\n        _530 = _503.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _530 = _523;\n    }\n    bool _537;\n    if (!_530)\n    {\n        _537 = _503.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _537 = _530;\n    }\n    if (_537)\n    {\n        return float4(0.0);\n    }\n    float4 _547 = float4(world_pos, 1.0);\n    float _554 = dot(_503.fa_cl_vpw, _547);\n    if (!(_554 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _576 = float2(dot(_503.fa_cl_vpx, _547), dot(_503.fa_cl_vpy, _547)) / float2(_554);\n    int _580 = int(_503.fa_cl_grid.x);\n    int _584 = int(_503.fa_cl_grid.y);\n    int param = (int(_503.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_503.fa_cl_fwd.xyz, world_pos) + _503.fa_cl_fwd.w, _503.fa_cl_grid.w) / _503.fa_cl_grid.w) * _503.fa_cl_grid.z)), 0, int(_503.fa_cl_info.y) - 1) * _584) + clamp(int(floor(((_576.y * 0.5) + 0.5) * _503.fa_cl_grid.y)), 0, _584 - 1)) * _580)) + clamp(int(floor(((_576.x * 0.5) + 0.5) * _503.fa_cl_grid.x)), 0, _580 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _503)\n{\n    float3 param = world_pos;\n    float4 _660 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _503);\n    return int2(int(_660.x), int(_660.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _503, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_503.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3230 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _503);\n    fa_cl_slot = _3230.x;\n    fa_cl_local = _3230.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3384 = fa_linear_to_srgb(param);\n        c = _3384;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3392 = fa_srgb_to_linear(param_1);\n            c = _3392;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _268;\n    if (bool(i.front_facing))\n    {\n        _268 = i.world_normal;\n    }\n    else\n    {\n        _268 = -i.world_normal;\n    }\n    float3 _292 = fast::normalize(i.world_tangent.xyz - (_268 * dot(_268, i.world_tangent.xyz)));\n    float3 _319 = fast::normalize(((_292 * m.x) + ((cross(_268, _292) * i.world_tangent.w) * m.y)) + (_268 * m.z));\n    float3 _322;\n    if (bool(i.front_facing))\n    {\n        _322 = _319;\n    }\n    else\n    {\n        _322 = -_319;\n    }\n    return _322;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _503, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _503.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3423 = fa_tex_fix(param_2, param_3);\n    float4 _4525 = base_t;\n    _4525.x = _3423.x;\n    _4525.y = _3423.y;\n    _4525.z = _3423.z;\n    base_t = _4525;\n    float4 _3437 = (_4525 * _503.fa_base_color) * i.vertex_color;\n    float3 _4392 = i.world_normal;\n    if (_503.fa_maps.z > 0.5)\n    {\n        float param_4 = _503.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3469 = fa_tex_fix(param_6, param_7);\n        float3 _3472 = (_3469 * 2.0) - float3(1.0);\n        float2 _3477 = _3472.xy * _503.fa_maps.x;\n        float3 _4533 = _3472;\n        _4533.x = _3477.x;\n        _4533.y = _3477.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4533;\n        _4392 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _503.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3506 = fa_tex_fix(param_12, param_13);\n    float4 _4536 = mrt;\n    _4536.x = _3506.x;\n    _4536.y = _3506.y;\n    _4536.z = _3506.z;\n    mrt = _4536;\n    float4 _3534 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _503.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3534.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3546 = fa_tex_fix(param_16, param_17);\n    float param_18 = _503.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3576 = fa_tex_fix(param_20, param_21);\n    float _4397 = _503.fa_layers_a.x;\n    float _4398 = _503.fa_layers_a.y;\n    float _4401 = _503.fa_layers_a.z;\n    float _4400 = _503.fa_layers_b.w;\n    float _4403 = _503.fa_layers_c.x;\n    if (_503.fa_layers_c.z > 0.5)\n    {\n        if (mod(_503.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4397 *= _3546.y;\n            _4398 *= _3546.z;\n            _4400 *= _3534.w;\n        }\n        if (_503.fa_layers_c.z > 1.5)\n        {\n            _4401 *= mrt.x;\n            _4403 *= mrt.w;\n        }\n    }\n    return Surface{ _3437.xyz, _3437.w, _4392, fast::clamp(_503.fa_pbr.x * _3506.z, 0.0, 1.0), fast::clamp(_503.fa_pbr.y * _3506.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_503.fa_maps.y * (_3546.x - 1.0)), _503.fa_emissive.xyz + (_503.fa_model_emissive.xyz * _3576), _4397, _4398, _503.fa_layers_b.xyz, _4400, _4401, _503.fa_layers_a.w, _4403, _503.fa_layers_c.y, _503.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _741 = rect.zw - rect.xy;\n    float2 _745 = _741 * atlas;\n    float2 _749 = ddx * _745;\n    float2 _753 = ddy * _745;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _741)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_749, _749), dot(_753, _753)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _503, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _788 = _503.fa_counts.y < 0.5;\n    bool _795;\n    if (!_788)\n    {\n        _795 = _503.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _795 = _788;\n    }\n    if (_795)\n    {\n        return;\n    }\n    float3 _801 = dfdx(world_pos);\n    float3 _804 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _808 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _503);\n    int _812 = int(_808.w);\n    if (_812 < 1)\n    {\n        return;\n    }\n    int _822 = int(_503.fa_counts.y + 0.5);\n    int param_1 = _822;\n    float4 _826 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _829 = _826.yz;\n    int _833 = int(_826.w);\n    int param_2 = _822 + 1;\n    float4 _838 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _839 = _838.x;\n    int _845 = int(_503.fa_counts.w + 0.5) - 1;\n    int _849 = int(_808.z);\n    float3 _1115;\n    for (int k = 0; k < _812; k++)\n    {\n        int _862 = _849 + k;\n        int param_3 = _833 + (_862 >> 2);\n        int _880 = (_822 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_862 & 3]) * 7);\n        int param_4 = _880 + 6;\n        float4 _885 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_885.w + 0.5) >> _845) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _880;\n        float4 _900 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _880 + 1;\n        float4 _905 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _880 + 2;\n        float4 _910 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _913 = _900.xyz;\n        float _918 = dot(_913, world_pos) + _900.w;\n        float3 _920 = _905.xyz;\n        float _925 = dot(_920, world_pos) + _905.w;\n        float3 _927 = _910.xyz;\n        float _932 = dot(_927, world_pos) + _910.w;\n        bool _937 = abs(_918) > 0.5;\n        bool _945;\n        if (!_937)\n        {\n            _945 = abs(_925) > 0.5;\n        }\n        else\n        {\n            _945 = _937;\n        }\n        bool _953;\n        if (!_945)\n        {\n            _953 = abs(_932) > 0.5;\n        }\n        else\n        {\n            _953 = _945;\n        }\n        if (_953)\n        {\n            continue;\n        }\n        float _968 = fast::clamp(dot(geo_normal, fast::normalize(_927)) * _885.z, 0.0, 1.0);\n        if (_968 <= 0.0)\n        {\n            continue;\n        }\n        float _988 = (fast::clamp((0.5 - abs(_932)) * 10.0, 0.0, 1.0) * _968) * _885.x;\n        float2 _996 = float2(_918 + 0.5, 0.5 - _925);\n        float2 _1006 = float2(dot(_913, _801), dot(_920, _801));\n        float2 _1016 = float2(dot(_913, _804), dot(_920, _804));\n        int param_8 = _880 + 5;\n        float4 _1021 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _880 + 3;\n        float4 _1026 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _880 + 4;\n        float4 _1031 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1021.xyz;\n        bool _1041 = _1026.z > _1026.x;\n        if (_1041)\n        {\n            float4 param_11 = _1026;\n            float2 param_12 = _996;\n            float2 param_13 = _829;\n            float2 param_14 = _1006;\n            float2 param_15 = _1016;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_839 > 0.5) && (_839 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1067 = fa_dc_to_linear(param_16);\n                float4 _4448 = tx;\n                _4448.x = _1067.x;\n                _4448.y = _1067.y;\n                _4448.z = _1067.z;\n                tx = _4448;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_988 * tex_a) * _1021.w, 0.0, 1.0)));\n        if (_1031.z > _1031.x)\n        {\n            float4 param_17 = _1031;\n            float2 param_18 = _996;\n            float2 param_19 = _829;\n            float2 param_20 = _1006;\n            float2 param_21 = _1016;\n            float4 _1111 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_839 > 1.5)\n            {\n                float3 param_22 = _1111.xyz;\n                float3 _1121 = fa_dc_to_srgb(param_22);\n                _1115 = _1121;\n            }\n            else\n            {\n                _1115 = _1111.xyz;\n            }\n            float3 _1131 = (_1115 * 2.0) - float3(1.0);\n            float2 _1136 = _1131.xy * _885.y;\n            float3 _1158 = (fast::normalize(_913) * _1136.x) + (fast::normalize(_920) * _1136.y);\n            float3 _1161 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1161, fast::normalize((_1161 * fast::max(_1131.z, 0.0500000007450580596923828125)) + (_1158 - (_1161 * dot(_1161, _1158)))), float3(fast::clamp(_988 * (_1041 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _503, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_503.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _2378 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _2378;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _503, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_503.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _503, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _503.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _503, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _503, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _2621 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2628 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2631 = int(_2621);\n    int _2634 = int(_2628);\n    float _2644 = _2628 - float(_2634);\n    int _2699 = (_2631 * 9) + _2634;\n    int _2719 = ((_2631 + 1) * 9) + _2634;\n    return mix(mix(_2695[_2699], _2695[_2699 + 1], _2644), mix(_2695[_2719], _2695[_2719 + 1], _2644), _2621 - float(_2631));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4251 = false;\n    float _4252 = 1.0;\n    float _4253 = 1.0;\n    float _4254 = 1.0;\n    float _4255 = 0.0;\n    float _4256 = 0.0;\n    float _4257 = 0.0;\n    float _4258 = 0.0;\n    float _4260 = 1.0;\n    bool _4261 = false;\n    float3 _4262 = float3(0.0);\n    float _4263 = 1.0;\n    float _4264 = 1.0;\n    float _4265 = 1.0;\n    float _4266 = 0.0;\n    float _4267 = 0.0;\n    float3 _4268 = float3(1.0, 0.0, 0.0);\n    float3 _4269 = float3(0.0, 0.0, 1.0);\n    float _4270 = 1.0;\n    float _4271 = 1.0;\n    float _2772 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2776 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2781 = (_2772 != 1.0) || (_2776 != 1.5);\n    bool _2791;\n    if (!_2781)\n    {\n        _2791 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2791 = _2781;\n    }\n    if (_2791)\n    {\n        float _2799 = (_2776 - 1.0) / (_2776 + 1.0);\n        f0 = mix(fast::min(float3(_2799 * _2799) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2772, s.albedo, float3(metallic));\n        _4252 = mix(_2772, 1.0, metallic);\n        _4251 = true;\n    }\n    float _2827 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2827 > 0.0)\n    {\n        float _2835 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4255 = _2827;\n        _4256 = _2835;\n        float _2842 = _2835 * _2835;\n        _4257 = _2842;\n        _4258 = _2842 * _2842;\n        float _2854 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4260 = _2854;\n        _4253 = 1.0 - (_2827 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2854, 0.0, 1.0), 5.0))));\n        _4251 = true;\n    }\n    float3 _2873 = fast::max(s.sheen_color, float3(0.0));\n    float _2882 = fast::max(_2873.x, fast::max(_2873.y, _2873.z));\n    if (_2882 > 0.0)\n    {\n        float _2890 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4261 = true;\n        _4262 = _2873;\n        _4263 = _2890;\n        _4264 = _2890 * _2890;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2890;\n        float _2907 = fa_sheen_albedo(param, param_1);\n        _4266 = _2907;\n        _4265 = 1.0 - fast::min(_2882 * _2907, 1.0);\n        _4251 = true;\n    }\n    _4254 = _4253 * _4265;\n    float _2926 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2926 != 0.0)\n    {\n        float3 _2941 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2941;\n        if (dot(_2941, _2941) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2958 = t;\n        float3 _2959 = fast::normalize(_2958);\n        t = _2959;\n        float3 _2984 = fast::normalize((_2959 * cos(s.anisotropy_rotation)) + ((cross(n, _2959) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4268 = _2984;\n        _4269 = cross(n, _2984);\n        float _2994 = roughness * roughness;\n        float _3000 = mix(_2994, 1.0, _2926 * _2926);\n        bool _3002 = _2926 > 0.0;\n        _4270 = _3002 ? _3000 : _2994;\n        _4271 = _3002 ? _2994 : _3000;\n        _4267 = _2926;\n        _4251 = true;\n    }\n    return FaLayers{ short(_4251), _4252, _4253, _4254, _4255, _4256, _4257, _4258, i.world_normal, _4260, short(_4261), _4262, _4263, _4264, _4265, _4266, _4267, _4268, _4269, _4270, _4271 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _2553 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2556 = _2553.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_2556 * _2556, exp2((-9.27999973297119140625) * ndv)) * _2556) + _2553.y)) + _2553.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _503, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_503.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _503.fa_env_horizon.w)).xyz;\n    }\n    float _2407 = rough * rough;\n    float _2437 = 0.60000002384185791015625 * _2407;\n    return mix(mix(_503.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_503.fa_env_horizon.xyz, _503.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _2407)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _2437, 0.0500000007450580596923828125 + _2437, d.y))), ((_503.fa_env_sky.xyz + _503.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_2407 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _503, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _3035;\n        if (L.aniso >= 0.0)\n        {\n            _3035 = L.b;\n        }\n        else\n        {\n            _3035 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_3035, v), _3035), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3068 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _503, fa_env_smp, fa_env_tex) * ((f0 * _3068.x) + (float3(L.f90) * _3068.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _503, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3123 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _503, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _3123.x) + _3123.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _503, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2595 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _503, fa_env_smp, fa_env_tex) * ((f0 * _2595.x) + float3(_2595.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _503, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float _3152 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _3156 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _3163 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_3152));\n    float3 f0 = _3163;\n    float3 _3167 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3167;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3152;\n    float param_5 = _3156;\n    float3 param_6 = _3163;\n    FaLayers _3184 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3184.on)\n    {\n        FaLayers param_7 = _3184;\n        float3 param_8 = _3167;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3156;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _503, fa_env_smp, fa_env_tex) * s.occlusion;\n    }\n    float3 param_12 = _3167;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3156;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _503, fa_env_smp, fa_env_tex) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor, constant fa_mesh_fs_params& _503, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1, _503, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _503)\n{\n    int param = (int(_503.fa_cl_info.x) + int(_503.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _503, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _503);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _378 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _384 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _387 = _384.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _393 = _387 < 0.5;\n    float3 l;\n    if (_393)\n    {\n        l = fast::normalize(_378.xyz);\n    }\n    else\n    {\n        float3 _405 = _378.xyz - world_pos;\n        float _407 = length(_405);\n        dist = _407;\n        l = _405 / float3(fast::max(_407, 9.9999997473787516355514526367188e-05));\n        float _422 = _407 / fast::max(_378.w, 0.001000000047497451305389404296875);\n        float _428 = fast::clamp(1.0 - (_422 * _422), 0.0, 1.0);\n        atten = _428 * _428;\n        if (_387 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _442 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _452 = _442.w;\n            int param_3 = (li * 4) + 3;\n            float4 _458 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _459 = _458.x;\n            float cos_inner = _459;\n            if (_459 > 1.5)\n            {\n                cos_inner = mix(_452, 1.0, 0.25);\n            }\n            atten *= smoothstep(_452, cos_inner, dot(-l, fast::normalize(_442.xyz)));\n        }\n    }\n    int _489;\n    if (_393)\n    {\n        _489 = 0;\n    }\n    else\n    {\n        _489 = (_387 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _384.xyz * atten, atten, 1.0, dist, _489 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1243)\n{\n    float _1233;\n    if (i == 0)\n    {\n        _1233 = _1243.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1249;\n        if (i == 1)\n        {\n            _1249 = _1243.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1257;\n            if (i == 2)\n            {\n                _1257 = _1243.fa_shadow_split.z;\n            }\n            else\n            {\n                _1257 = _1243.fa_shadow_split.w;\n            }\n            _1249 = _1257;\n        }\n        _1233 = _1249;\n    }\n    return _1233;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1290 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1294;\n    if (conv.x < 0.5)\n    {\n        _1294 = _1290;\n    }\n    else\n    {\n        _1294 = (conv.y * conv.z) / (conv.z - (_1290 * (conv.z - conv.y)));\n    }\n    return _1294;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1221 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1221), sin(_1221)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1243, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1340 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1354 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1340;\n            float2 _1373 = fa_shadow_vogel(param_3, param_4, param_5) * _1354;\n            float2 param_6 = uv + (_1373 * _1243.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1385 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1385 < (zr - (length(_1373) * plane)))\n            {\n                sum += _1385;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1429 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1429; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1429;\n        float param_11 = _1340;\n        float2 _1448 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1448 * _1243.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1448) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1429);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1243, texture2d<float> fa_shadow_tex)\n{\n    float _1490 = fast::max(_1243.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1495 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1501 = sqrt(1.0 - (_1495 * _1495));\n    float _1508 = fast::min(_1501 / fast::max(_1495, 0.20000000298023223876953125), 4.0);\n    float _1513;\n    if (_1243.fa_shadow_bias.y > 0.0)\n    {\n        _1513 = _1243.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1513 = 1.5 * _1243.fa_shadow_info[ci].x;\n    }\n    float4 _1538 = _1243.fa_shadow_mat[ci] * float4(world + (n * (_1513 * _1501)), 1.0);\n    float _1545 = _1538.x;\n    bool _1548 = _1545 < _1243.fa_shadow_rect[ci].x;\n    bool _1557;\n    if (!_1548)\n    {\n        _1557 = _1545 > _1243.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1557 = _1548;\n    }\n    bool _1566;\n    if (!_1557)\n    {\n        _1566 = _1538.y < _1243.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1566 = _1557;\n    }\n    bool _1575;\n    if (!_1566)\n    {\n        _1575 = _1538.y > _1243.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1575 = _1566;\n    }\n    bool _1582;\n    if (!_1575)\n    {\n        _1582 = _1538.z > 1.0;\n    }\n    else\n    {\n        _1582 = _1575;\n    }\n    if (_1582)\n    {\n        return -1.0;\n    }\n    float _1591;\n    if (_1243.fa_shadow_bias.x > 0.0)\n    {\n        _1591 = _1243.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1591 = 1.5 * _1243.fa_shadow_info[ci].x;\n    }\n    float2 param = _1538.xy;\n    float4 param_1 = _1243.fa_shadow_rect[ci];\n    float param_2 = _1538.z - ((_1591 * (1.0 + (0.5 * _1508))) / _1490);\n    float param_3 = _1243.fa_shadow_info[ci].x;\n    float param_4 = _1490;\n    float param_5 = _1490 * 0.25;\n    float param_6 = ((_1243.fa_shadow_info[ci].x * fast::min(_1508, 3.0)) * 0.5) / _1490;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1243.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1243.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1243, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _503, thread float4& gl_FragCoord, constant fa_shadows& _1243, texture2d<float> fa_shadow_tex)\n{\n    if (_503.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2018 = int(_1243.fa_shadow_cfg.x + 0.5);\n    if (_2018 < 1)\n    {\n        return 1.0;\n    }\n    float _2033 = dot(world - _1243.fa_shadow_eye.xyz, _1243.fa_shadow_fwd.xyz);\n    int param = _2018 - 1;\n    if (_2033 > fa_shadow_split_at(param, _1243))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2045 = _2018 > 1;\n    bool _2052;\n    if (_2045)\n    {\n        _2052 = _2033 > _1243.fa_shadow_split.x;\n    }\n    else\n    {\n        _2052 = _2045;\n    }\n    if (_2052)\n    {\n        ci = 1;\n    }\n    bool _2056 = _2018 > 2;\n    bool _2063;\n    if (_2056)\n    {\n        _2063 = _2033 > _1243.fa_shadow_split.y;\n    }\n    else\n    {\n        _2063 = _2056;\n    }\n    if (_2063)\n    {\n        ci = 2;\n    }\n    bool _2067 = _2018 > 3;\n    bool _2074;\n    if (_2067)\n    {\n        _2074 = _2033 > _1243.fa_shadow_split.z;\n    }\n    else\n    {\n        _2074 = _2067;\n    }\n    if (_2074)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2018)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2100 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1243, fa_shadow_tex);\n        s = _2100;\n        if (_2100 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1243.fa_shadow_cfg.y > 0.0)\n    {\n        float _2125;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2125 = fa_shadow_split_at(param_5, _1243);\n        }\n        else\n        {\n            _2125 = _1243.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2144 = _1243.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1243) - _2125, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2155 = fast::clamp((_2033 - (fa_shadow_split_at(param_7, _1243) - _2144)) / _2144, 0.0, 1.0);\n        if (_2155 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2018)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2176 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1243, fa_shadow_tex);\n                s2 = _2176;\n                if (_2176 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2155);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _503, thread float4& gl_FragCoord, constant fa_shadows& _1243, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _503, gl_FragCoord, _1243, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _503, thread float4& gl_FragCoord, constant fa_shadows& _1243, texture2d<float> fa_shadow_tex)\n{\n    bool _1649 = _503.fa_pbr.z < 0.5;\n    bool _1657;\n    if (!_1649)\n    {\n        _1657 = _1243.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1657 = _1649;\n    }\n    if (_1657)\n    {\n        return 1.0;\n    }\n    int param = (int(_1243.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1670 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1671 = _1670.x;\n    if (_1671 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1680 = int(_1671 + 0.5);\n    int param_1 = _1680;\n    float4 _1684 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1680 + 1;\n    float4 _1689 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1692 = _1684.y;\n    if (_1692 > 0.0)\n    {\n        float _1709 = 1.0 - smoothstep(0.75 * _1692, _1692, length(world - _1243.fa_shadow_eye.xyz));\n        fade = _1709;\n        if (_1709 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1684.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1728 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1731 = abs(_1728);\n        float _1733 = _1731.x;\n        float _1735 = _1731.y;\n        bool _1736 = _1733 >= _1735;\n        bool _1744;\n        if (_1736)\n        {\n            _1744 = _1733 >= _1731.z;\n        }\n        else\n        {\n            _1744 = _1736;\n        }\n        int _1745;\n        if (_1744)\n        {\n            _1745 = (_1728.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1758;\n            if (_1735 >= _1731.z)\n            {\n                _1758 = (_1728.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1758 = (_1728.z > 0.0) ? 4 : 5;\n            }\n            _1745 = _1758;\n        }\n        face = _1745;\n    }\n    int _1777 = (_1680 + 2) + (face * 6);\n    int param_4 = _1777;\n    int param_5 = _1777 + 1;\n    int param_6 = _1777 + 3;\n    float4 _1791 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1777 + 4;\n    float4 _1796 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1777 + 5;\n    float4 _1801 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1813 = _1801.x * fast::max(dot(_1791, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1818 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1841 = fast::clamp(dot(n, _1791.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1864 = fast::min(sqrt(1.0 - (_1841 * _1841)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1791, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1867 = _1689.y;\n    float _1869;\n    if (_1867 > 0.0)\n    {\n        _1869 = _1867;\n    }\n    else\n    {\n        _1869 = 1.5 * _1813;\n    }\n    float4 _1889 = float4(world + (n * (_1869 * sqrt(1.0 - (_1818 * _1818)))), 1.0);\n    float _1893 = dot(_1791, _1889);\n    float _1896 = _1801.y;\n    if (_1893 < _1896)\n    {\n        return 1.0;\n    }\n    float2 _1911 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1889), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1889)) / float2(_1893);\n    float _1913 = _1911.x;\n    bool _1916 = _1913 < _1796.x;\n    bool _1925;\n    if (!_1916)\n    {\n        _1925 = _1913 > _1796.z;\n    }\n    else\n    {\n        _1925 = _1916;\n    }\n    bool _1934;\n    if (!_1925)\n    {\n        _1934 = _1911.y < _1796.y;\n    }\n    else\n    {\n        _1934 = _1925;\n    }\n    bool _1943;\n    if (!_1934)\n    {\n        _1943 = _1911.y > _1796.w;\n    }\n    else\n    {\n        _1943 = _1934;\n    }\n    if (_1943)\n    {\n        return 1.0;\n    }\n    float _1949 = _1689.x;\n    float _1951;\n    if (_1949 > 0.0)\n    {\n        _1951 = _1949;\n    }\n    else\n    {\n        _1951 = 1.5 * _1813;\n    }\n    float2 param_10 = _1911;\n    float4 param_11 = _1796;\n    float param_12 = _1893 - (_1951 * (1.0 + (0.5 * _1864)));\n    float param_13 = _1813;\n    float param_14 = 1.0;\n    float param_15 = _1801.z * 0.25;\n    float param_16 = (_1813 * fast::min(_1864, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1896, _1801.z);\n    int param_18 = int(_1684.z + 0.5);\n    float param_19 = _1684.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1243, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _503, thread float4& gl_FragCoord, constant fa_shadows& _1243, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3257 = fa_lm.z > 0.5;\n    bool _3263;\n    if (_3257)\n    {\n        int param = li;\n        _3263 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3263 = _3257;\n    }\n    if (_3263)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3285 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _4377 = _3285.direction;\n    float3 _4372 = _3285.color;\n    float _4379 = _3285.attenuation;\n    float _4374 = _3285.shadow;\n    int _4382 = _3285.type;\n    if ((_4382 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4377;\n        float _3299 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _503, gl_FragCoord, _1243, fa_shadow_tex, fa_world_pos);\n        _4374 = _3299;\n        _4372 *= _3299;\n    }\n    else\n    {\n        bool _3310 = _4382 != 0;\n        bool _3316;\n        if (_3310)\n        {\n            _3316 = _4379 > 0.0;\n        }\n        else\n        {\n            _3316 = _3310;\n        }\n        if (_3316)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4377;\n            float _3328 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _503, gl_FragCoord, _1243, fa_shadow_tex);\n            _4374 = _3328;\n            _4372 *= _3328;\n        }\n    }\n    return LightSample{ _4377, _4372, _4379, _4374, _3285._distance, _4382 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1243)\n{\n    if (_1243.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2200 = int(_1243.fa_shadow_cfg.x + 0.5);\n    float _2210 = dot(world - _1243.fa_shadow_eye.xyz, _1243.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2215 = _2200 > 0;\n    bool _2224;\n    if (_2215)\n    {\n        int param = _2200 - 1;\n        _2224 = _2210 <= fa_shadow_split_at(param, _1243);\n    }\n    else\n    {\n        _2224 = _2215;\n    }\n    if (_2224)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2231 = _2200 > 1;\n        bool _2238;\n        if (_2231)\n        {\n            _2238 = _2210 > _1243.fa_shadow_split.x;\n        }\n        else\n        {\n            _2238 = _2231;\n        }\n        if (_2238)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2244 = _2200 > 2;\n        bool _2251;\n        if (_2244)\n        {\n            _2251 = _2210 > _1243.fa_shadow_split.y;\n        }\n        else\n        {\n            _2251 = _2244;\n        }\n        if (_2251)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2257 = _2200 > 3;\n        bool _2264;\n        if (_2257)\n        {\n            _2264 = _2210 > _1243.fa_shadow_split.z;\n        }\n        else\n        {\n            _2264 = _2257;\n        }\n        if (_2264)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _503 [[buffer(1)]], constant fa_shadows& _1243 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4081 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4081 = -_4081;\n    }\n    float3 _3716 = fast::normalize(_503.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _503, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4081, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3716, short(gl_FrontFacing) };\n    Surface _3724 = fa_standard_surface(param_1, _503, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4120 = _3724.albedo;\n    float _4121 = _3724.alpha;\n    float3 _4122 = _3724.normal;\n    float _4123 = _3724.metallic;\n    float _4124 = _3724.roughness;\n    float _4125 = _3724.occlusion;\n    float3 _4126 = _3724.emission;\n    float _4127 = _3724.clearcoat;\n    float _4128 = _3724.clearcoat_roughness;\n    float3 _4129 = _3724.sheen_color;\n    float _4130 = _3724.sheen_roughness;\n    float _4131 = _3724.anisotropy;\n    float _4132 = _3724.anisotropy_rotation;\n    float _4133 = _3724.specular;\n    float _4134 = _3724.ior;\n    float3 _4135 = _3724.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4081, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3716, short(gl_FrontFacing) };\n    Surface param_3 = _3724;\n    surface(param_2, param_3);\n    _4120 = param_3.albedo;\n    _4121 = param_3.alpha;\n    _4122 = param_3.normal;\n    _4123 = param_3.metallic;\n    _4124 = param_3.roughness;\n    _4125 = param_3.occlusion;\n    _4126 = param_3.emission;\n    _4127 = param_3.clearcoat;\n    _4128 = param_3.clearcoat_roughness;\n    _4129 = param_3.sheen_color;\n    _4130 = param_3.sheen_roughness;\n    _4131 = param_3.anisotropy;\n    _4132 = param_3.anisotropy_rotation;\n    _4133 = param_3.specular;\n    _4134 = param_3.ior;\n    _4135 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4081;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _503, fa_decal_tex, fa_env_smp);\n    _4120 = param_6;\n    _4122 = param_7;\n    float3 result;\n    if (_503.fa_emissive.w > 0.5)\n    {\n        result = _4120;\n    }\n    else\n    {\n        float3 _3762 = _4122;\n        float3 _3763 = fast::normalize(_3762);\n        _4122 = _3763;\n        float3 param_8 = _3763;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _4081, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3716, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _4120, _4121, _4122, _4123, _4124, _4125, _4126, _4127, _4128, _4129, _4130, _4131, _4132, _4133, _4134, _4135 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _503, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11, _503, fa_env_smp, fa_env_tex);\n        int _3782 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3782; ln++)\n        {\n            int param_12 = ln;\n            int _3795 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _503, fa_cl_ndir, fa_cl_slot);\n            bool _3798 = in.fa_lm.z > 0.5;\n            bool _3804;\n            if (_3798)\n            {\n                int param_13 = _3795;\n                _3804 = fa_light_baked(param_13, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _3804 = _3798;\n            }\n            if (_3804)\n            {\n                continue;\n            }\n            int param_14 = _3795;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _4081;\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _4081, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3716, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _4120, _4121, _4122, _4123, _4124, _4125, _4126, _4127, _4128, _4129, _4130, _4131, _4132, _4133, _4134, _4135 };\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16, fa_light_tex, fa_shadow_smp, _503, gl_FragCoord, _1243, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _3831 = result;\n    float3 _3832 = _3831 + _4126;\n    result = _3832;\n    float3 param_20 = _3832;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _1243);\n    bool _3841 = _503.fa_fog.w > 0.0;\n    bool _3848;\n    if (!_3841)\n    {\n        _3848 = _503.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3848 = _3841;\n    }\n    if (_3848)\n    {\n        float3 _3857 = in.fa_world_pos - _503.fa_camera_pos.xyz;\n        float _3863 = dot(_3857, _503.fa_fog_c.xyz);\n        bool _3867 = _503.fa_fog_c.w > 0.5;\n        float _3868;\n        if (_3867)\n        {\n            _3868 = _3863;\n        }\n        else\n        {\n            _3868 = length(_3857);\n        }\n        float _3880 = _3868 - _503.fa_fog_b.x;\n        if (_3880 > 0.0)\n        {\n            float _3889 = _503.fa_fog.w * _3880;\n            float tau = _3889 * _3889;\n            if (_503.fa_fog_b.y > 0.0)\n            {\n                float _3905;\n                if (_3867)\n                {\n                    _3905 = in.fa_world_pos.y - (_503.fa_fog_c.y * _3863);\n                }\n                else\n                {\n                    _3905 = _503.fa_camera_pos.y;\n                }\n                float _3926 = mix(_3905, in.fa_world_pos.y, fast::clamp(_503.fa_fog_b.x / _3868, 0.0, 1.0));\n                float _3930 = in.fa_world_pos.y - _3926;\n                float _3935 = _3926 - _503.fa_fog_b.z;\n                float _3940 = in.fa_world_pos.y - _503.fa_fog_b.z;\n                bool _3943 = _3935 <= 0.0;\n                bool _3944 = !_3943;\n                bool _3950;\n                if (_3944)\n                {\n                    _3950 = _503.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3950 = _3943;\n                }\n                float _3951;\n                if (_3950)\n                {\n                    _3951 = _503.fa_fog_b.y;\n                }\n                else\n                {\n                    _3951 = _503.fa_fog_b.y * exp(-fast::min(_503.fa_fog_b.w * _3935, 80.0));\n                }\n                bool _3978;\n                if (_3944)\n                {\n                    _3978 = _503.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3978 = _3943;\n                }\n                float _3979;\n                if (_3978)\n                {\n                    _3979 = _503.fa_fog_b.y * _3935;\n                }\n                else\n                {\n                    _3979 = (_503.fa_fog_b.y * (1.0 - exp(-fast::min(_503.fa_fog_b.w * _3935, 80.0)))) / _503.fa_fog_b.w;\n                }\n                bool _4004 = _3940 <= 0.0;\n                bool _4011;\n                if (!_4004)\n                {\n                    _4011 = _503.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4011 = _4004;\n                }\n                float _4012;\n                if (_4011)\n                {\n                    _4012 = _503.fa_fog_b.y * _3940;\n                }\n                else\n                {\n                    _4012 = (_503.fa_fog_b.y * (1.0 - exp(-fast::min(_503.fa_fog_b.w * _3940, 80.0)))) / _503.fa_fog_b.w;\n                }\n                float _4039;\n                if (abs(_3930) < 0.001000000047497451305389404296875)\n                {\n                    _4039 = _3951;\n                }\n                else\n                {\n                    _4039 = (_4012 - _3979) / _3930;\n                }\n                tau += (_3880 * fast::max(_4039, 0.0));\n            }\n            result = mix(result, _503.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4121);\n    return out;\n}\n\n",
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
            "inst_name": "_503",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1243",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
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
