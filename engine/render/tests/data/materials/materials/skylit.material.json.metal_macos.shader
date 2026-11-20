{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "fc5698cd941e0af057040ef4c307a7106b1e2971cc74f7501935817daedb7ce8",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_267, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nconstant spvUnsafeArray<float, 63> _3366 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1343 = _365.fa_cl_info.x < 0.0;\n    bool _1350;\n    if (!_1343)\n    {\n        _1350 = _365.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1350 = _1343;\n    }\n    bool _1358;\n    if (!_1350)\n    {\n        _1358 = _365.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1358 = _1350;\n    }\n    bool _1365;\n    if (!_1358)\n    {\n        _1365 = _365.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1365 = _1358;\n    }\n    bool _1372;\n    if (!_1365)\n    {\n        _1372 = _365.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1372 = _1365;\n    }\n    if (_1372)\n    {\n        return float4(0.0);\n    }\n    float4 _1382 = float4(world_pos, 1.0);\n    float _1388 = dot(_365.fa_cl_vpw, _1382);\n    if (!(_1388 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1410 = float2(dot(_365.fa_cl_vpx, _1382), dot(_365.fa_cl_vpy, _1382)) / float2(_1388);\n    int _1414 = int(_365.fa_cl_grid.x);\n    int _1418 = int(_365.fa_cl_grid.y);\n    int param = (int(_365.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_365.fa_cl_fwd.xyz, world_pos) + _365.fa_cl_fwd.w, _365.fa_cl_grid.w) / _365.fa_cl_grid.w) * _365.fa_cl_grid.z)), 0, int(_365.fa_cl_info.y) - 1) * _1418) + clamp(int(floor(((_1410.y * 0.5) + 0.5) * _365.fa_cl_grid.y)), 0, _1418 - 1)) * _1414)) + clamp(int(floor(((_1410.x * 0.5) + 0.5) * _365.fa_cl_grid.x)), 0, _1414 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1494 = fa_cluster_texel(param, _365, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1494.x), int(_1494.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_365.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3898 = fa_cluster_lookup(param, _365, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3898.x;\n    fa_cl_local = _3898.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _4054 = fa_linear_to_srgb(param);\n        c = _4054;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _4062 = fa_srgb_to_linear(param_1);\n            c = _4062;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _297;\n    if (bool(i.front_facing))\n    {\n        _297 = i.world_normal;\n    }\n    else\n    {\n        _297 = -i.world_normal;\n    }\n    float3 _321 = fast::normalize(i.world_tangent.xyz - (_297 * dot(_297, i.world_tangent.xyz)));\n    float3 _349 = fast::normalize(((_321 * m.x) + ((cross(_297, _321) * i.world_tangent.w) * m.y)) + (_297 * m.z));\n    float3 _352;\n    if (bool(i.front_facing))\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _365, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _365.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4093 = fa_tex_fix(param_2, param_3);\n    float4 _5208 = base_t;\n    _5208.x = _4093.x;\n    _5208.y = _4093.y;\n    _5208.z = _4093.z;\n    base_t = _5208;\n    float4 _4107 = (_5208 * _365.fa_base_color) * i.vertex_color;\n    float3 _5060 = i.world_normal;\n    if (_365.fa_maps.z > 0.5)\n    {\n        float param_4 = _365.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4139 = fa_tex_fix(param_6, param_7);\n        float3 _4142 = (_4139 * 2.0) - float3(1.0);\n        float2 _4147 = _4142.xy * _365.fa_maps.x;\n        float3 _5216 = _4142;\n        _5216.x = _4147.x;\n        _5216.y = _4147.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5216;\n        _5060 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _365.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4175 = fa_tex_fix(param_12, param_13);\n    float4 _5219 = mrt;\n    _5219.x = _4175.x;\n    _5219.y = _4175.y;\n    _5219.z = _4175.z;\n    mrt = _5219;\n    float4 _4203 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _365.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _4203.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4214 = fa_tex_fix(param_16, param_17);\n    float param_18 = _365.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4244 = fa_tex_fix(param_20, param_21);\n    float _5065 = _365.fa_layers_a.x;\n    float _5066 = _365.fa_layers_a.y;\n    float _5069 = _365.fa_layers_a.z;\n    float _5068 = _365.fa_layers_b.w;\n    float _5071 = _365.fa_layers_c.x;\n    if (_365.fa_layers_c.z > 0.5)\n    {\n        if (mod(_365.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _5065 *= _4214.y;\n            _5066 *= _4214.z;\n            _5068 *= _4203.w;\n        }\n        if (_365.fa_layers_c.z > 1.5)\n        {\n            _5069 *= mrt.x;\n            _5071 *= mrt.w;\n        }\n    }\n    return Surface{ _4107.xyz, _4107.w, _5060, fast::clamp(_365.fa_pbr.x * _4175.z, 0.0, 1.0), fast::clamp(_365.fa_pbr.y * _4175.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_365.fa_maps.y * (_4214.x - 1.0)), _365.fa_emissive.xyz + (_365.fa_model_emissive.xyz * _4244), _5065, _5066, _365.fa_layers_b.xyz, _5068, _5069, _365.fa_layers_a.w, _5071, _365.fa_layers_c.y, _365.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1574 = rect.zw - rect.xy;\n    float2 _1578 = _1574 * atlas;\n    float2 _1582 = ddx * _1578;\n    float2 _1586 = ddy * _1578;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1574)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1582, _1582), dot(_1586, _1586)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1619 = _365.fa_counts.y < 0.5;\n    bool _1626;\n    if (!_1619)\n    {\n        _1626 = _365.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1626 = _1619;\n    }\n    if (_1626)\n    {\n        return;\n    }\n    float3 _1632 = dfdx(world_pos);\n    float3 _1635 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1639 = fa_cluster_texel(param, _365, fa_light_tex, fa_shadow_smp);\n    int _1643 = int(_1639.w);\n    if (_1643 < 1)\n    {\n        return;\n    }\n    int _1653 = int(_365.fa_counts.y + 0.5);\n    int param_1 = _1653;\n    float4 _1657 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1660 = _1657.yz;\n    int _1664 = int(_1657.w);\n    int param_2 = _1653 + 1;\n    float4 _1669 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1670 = _1669.x;\n    int _1676 = int(_365.fa_counts.w + 0.5) - 1;\n    int _1680 = int(_1639.z);\n    float3 _1945;\n    for (int k = 0; k < _1643; k++)\n    {\n        int _1693 = _1680 + k;\n        int param_3 = _1664 + (_1693 >> 2);\n        int _1710 = (_1653 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1693 & 3]) * 7);\n        int param_4 = _1710 + 6;\n        float4 _1715 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1715.w + 0.5) >> _1676) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1710;\n        float4 _1730 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1710 + 1;\n        float4 _1735 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1710 + 2;\n        float4 _1740 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1743 = _1730.xyz;\n        float _1748 = dot(_1743, world_pos) + _1730.w;\n        float3 _1750 = _1735.xyz;\n        float _1755 = dot(_1750, world_pos) + _1735.w;\n        float3 _1757 = _1740.xyz;\n        float _1762 = dot(_1757, world_pos) + _1740.w;\n        bool _1767 = abs(_1748) > 0.5;\n        bool _1775;\n        if (!_1767)\n        {\n            _1775 = abs(_1755) > 0.5;\n        }\n        else\n        {\n            _1775 = _1767;\n        }\n        bool _1783;\n        if (!_1775)\n        {\n            _1783 = abs(_1762) > 0.5;\n        }\n        else\n        {\n            _1783 = _1775;\n        }\n        if (_1783)\n        {\n            continue;\n        }\n        float _1798 = fast::clamp(dot(geo_normal, fast::normalize(_1757)) * _1715.z, 0.0, 1.0);\n        if (_1798 <= 0.0)\n        {\n            continue;\n        }\n        float _1818 = (fast::clamp((0.5 - abs(_1762)) * 10.0, 0.0, 1.0) * _1798) * _1715.x;\n        float2 _1826 = float2(_1748 + 0.5, 0.5 - _1755);\n        float2 _1836 = float2(dot(_1743, _1632), dot(_1750, _1632));\n        float2 _1846 = float2(dot(_1743, _1635), dot(_1750, _1635));\n        int param_8 = _1710 + 5;\n        float4 _1851 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1710 + 3;\n        float4 _1856 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1710 + 4;\n        float4 _1861 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1851.xyz;\n        bool _1871 = _1856.z > _1856.x;\n        if (_1871)\n        {\n            float4 param_11 = _1856;\n            float2 param_12 = _1826;\n            float2 param_13 = _1660;\n            float2 param_14 = _1836;\n            float2 param_15 = _1846;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1670 > 0.5) && (_1670 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1897 = fa_dc_to_linear(param_16);\n                float4 _5140 = tx;\n                _5140.x = _1897.x;\n                _5140.y = _1897.y;\n                _5140.z = _1897.z;\n                tx = _5140;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1818 * tex_a) * _1851.w, 0.0, 1.0)));\n        if (_1861.z > _1861.x)\n        {\n            float4 param_17 = _1861;\n            float2 param_18 = _1826;\n            float2 param_19 = _1660;\n            float2 param_20 = _1836;\n            float2 param_21 = _1846;\n            float4 _1941 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1670 > 1.5)\n            {\n                float3 param_22 = _1941.xyz;\n                float3 _1951 = fa_dc_to_srgb(param_22);\n                _1945 = _1951;\n            }\n            else\n            {\n                _1945 = _1941.xyz;\n            }\n            float3 _1960 = (_1945 * 2.0) - float3(1.0);\n            float2 _1965 = _1960.xy * _1715.y;\n            float3 _1987 = (fast::normalize(_1743) * _1965.x) + (fast::normalize(_1750) * _1965.y);\n            float3 _1990 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1990, fast::normalize((_1990 * fast::max(_1960.z, 0.0500000007450580596923828125)) + (_1987 - (_1990 * dot(_1990, _1987)))), float3(fast::clamp(_1818 * (_1871 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_365.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _365.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _365, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _3291 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3299 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3302 = int(_3291);\n    int _3305 = int(_3299);\n    float _3315 = _3299 - float(_3305);\n    int _3371 = (_3302 * 9) + _3305;\n    int _3391 = ((_3302 + 1) * 9) + _3305;\n    return mix(mix(_3366[_3371], _3366[_3371 + 1], _3315), mix(_3366[_3391], _3366[_3391 + 1], _3315), _3291 - float(_3302));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4919 = false;\n    float _4920 = 1.0;\n    float _4921 = 1.0;\n    float _4922 = 1.0;\n    float _4923 = 0.0;\n    float _4924 = 0.0;\n    float _4925 = 0.0;\n    float _4926 = 0.0;\n    float _4928 = 1.0;\n    bool _4929 = false;\n    float3 _4930 = float3(0.0);\n    float _4931 = 1.0;\n    float _4932 = 1.0;\n    float _4933 = 1.0;\n    float _4934 = 0.0;\n    float _4935 = 0.0;\n    float3 _4936 = float3(1.0, 0.0, 0.0);\n    float3 _4937 = float3(0.0, 0.0, 1.0);\n    float _4938 = 1.0;\n    float _4939 = 1.0;\n    float _3442 = fast::clamp(s.specular, 0.0, 1.0);\n    float _3446 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _3451 = (_3442 != 1.0) || (_3446 != 1.5);\n    bool _3460;\n    if (!_3451)\n    {\n        _3460 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _3460 = _3451;\n    }\n    if (_3460)\n    {\n        float _3468 = (_3446 - 1.0) / (_3446 + 1.0);\n        f0 = mix(fast::min(float3(_3468 * _3468) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _3442, s.albedo, float3(metallic));\n        _4920 = mix(_3442, 1.0, metallic);\n        _4919 = true;\n    }\n    float _3495 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_3495 > 0.0)\n    {\n        float _3503 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4923 = _3495;\n        _4924 = _3503;\n        float _3510 = _3503 * _3503;\n        _4925 = _3510;\n        _4926 = _3510 * _3510;\n        float _3522 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4928 = _3522;\n        _4921 = 1.0 - (_3495 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _3522, 0.0, 1.0), 5.0))));\n        _4919 = true;\n    }\n    float3 _3542 = fast::max(s.sheen_color, float3(0.0));\n    float _3551 = fast::max(_3542.x, fast::max(_3542.y, _3542.z));\n    if (_3551 > 0.0)\n    {\n        float _3559 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4929 = true;\n        _4930 = _3542;\n        _4931 = _3559;\n        _4932 = _3559 * _3559;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3559;\n        float _3576 = fa_sheen_albedo(param, param_1);\n        _4934 = _3576;\n        _4933 = 1.0 - fast::min(_3551 * _3576, 1.0);\n        _4919 = true;\n    }\n    _4922 = _4921 * _4933;\n    float _3595 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_3595 != 0.0)\n    {\n        float3 _3610 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3610;\n        if (dot(_3610, _3610) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _3626 = t;\n        float3 _3627 = fast::normalize(_3626);\n        t = _3627;\n        float3 _3652 = fast::normalize((_3627 * cos(s.anisotropy_rotation)) + ((cross(n, _3627) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4936 = _3652;\n        _4937 = cross(n, _3652);\n        float _3662 = roughness * roughness;\n        float _3668 = mix(_3662, 1.0, _3595 * _3595);\n        bool _3670 = _3595 > 0.0;\n        _4938 = _3670 ? _3668 : _3662;\n        _4939 = _3670 ? _3662 : _3668;\n        _4935 = _3595;\n        _4919 = true;\n    }\n    return FaLayers{ short(_4919), _4920, _4921, _4922, _4923, _4924, _4925, _4926, i.world_normal, _4928, short(_4929), _4930, _4931, _4932, _4933, _4934, _4935, _4936, _4937, _4938, _4939 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _3223 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3226 = _3223.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_3226 * _3226, exp2((-9.27999973297119140625) * ndv)) * _3226) + _3223.y)) + _3223.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_365.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _365.fa_env_horizon.w)).xyz;\n    }\n    float _3129 = rough * rough;\n    float _3159 = 0.60000002384185791015625 * _3129;\n    return mix(mix(_365.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_365.fa_env_horizon.xyz, _365.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _3129)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _3159, 0.0500000007450580596923828125 + _3159, d.y))), ((_365.fa_env_sky.xyz + _365.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_3129 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _3703;\n        if (L.aniso >= 0.0)\n        {\n            _3703 = L.b;\n        }\n        else\n        {\n            _3703 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_3703, v), _3703), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3736 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _365, fa_env_smp, fa_env_tex) * ((f0 * _3736.x) + (float3(L.f90) * _3736.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _365, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3791 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _365, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _3791.x) + _3791.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3265 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _365, fa_env_smp, fa_env_tex) * ((f0 * _3265.x) + float3(_3265.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float _3820 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _3824 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _3831 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_3820));\n    float3 f0 = _3831;\n    float3 _3835 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3835;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3820;\n    float param_5 = _3824;\n    float3 param_6 = _3831;\n    FaLayers _3852 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3852.on)\n    {\n        FaLayers param_7 = _3852;\n        float3 param_8 = _3835;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3824;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _365, fa_env_smp, fa_env_tex) * s.occlusion;\n    }\n    float3 param_12 = _3835;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3824;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _365, fa_env_smp, fa_env_tex) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1, _365, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_365.fa_cl_info.x) + int(_365.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _365, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _365)\n{\n    return li * ((_365.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _365) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _365) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _593 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _606 = (c - (ru * hx)) - p;\n        float3 _612 = ru * (2.0 * hx);\n        float _618 = fast::max(dot(_612, _612), 9.9999999392252902907785028219223e-09);\n        float _622 = dot(_606, _612);\n        float t = fast::clamp((-_622) / _618, 0.0, 1.0);\n        if (_593)\n        {\n            float _637 = dot(r, _612);\n            float _643 = _618 - (_637 * _637);\n            if (abs(_643) > (9.9999997473787516355514526367188e-06 * _618))\n            {\n                t = fast::clamp(((dot(r, _606) * _637) - _622) / _643, 0.0, 1.0);\n            }\n        }\n        return (p + _606) + (_612 * t);\n    }\n    float3 q = p;\n    float _675 = dot(r, axis);\n    bool _683;\n    if (_593)\n    {\n        _683 = abs(_675) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _683 = _593;\n    }\n    if (_683)\n    {\n        float _693 = dot(c - p, axis) / _675;\n        if (_693 > 0.0)\n        {\n            q = p + (r * _693);\n        }\n    }\n    float3 _706 = q - c;\n    float2 xy = float2(dot(_706, ru), dot(_706, uu));\n    if (shape > 0.5)\n    {\n        float _721 = length(xy);\n        if (_721 > hx)\n        {\n            xy *= (hx / _721);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _514 = abs(d);\n    float _516 = _514.x;\n    float _518 = _514.y;\n    bool _519 = _516 >= _518;\n    bool _527;\n    if (_519)\n    {\n        _527 = _516 >= _514.z;\n    }\n    else\n    {\n        _527 = _519;\n    }\n    int _528;\n    if (_527)\n    {\n        _528 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _541;\n        if (_518 >= _514.z)\n        {\n            _541 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _541 = (d.z > 0.0) ? 4 : 5;\n        }\n        _528 = _541;\n    }\n    return _528;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _467 = dot(d, right);\n    float _471 = dot(d, up);\n    float _482;\n    if (((_467 * _467) + (_471 * _471)) > 1.0000000133514319600180897396058e-10)\n    {\n        _482 = precise::atan2(_471, _467) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _482 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_482 - floor(_482)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _759 = fa_light_base(param, _365);\n    bool _763 = _365.fa_ambient.w > 4.5;\n    int param_1 = _759;\n    float4 _767 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _759 + 1;\n    float4 _772 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _775 = _772.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _787 = _763 && (_775 > 2.5);\n    fa_light_is_area = _787;\n    bool _789 = _775 < 0.5;\n    float3 l;\n    if (_789)\n    {\n        l = fast::normalize(_767.xyz);\n        if (_763)\n        {\n            int param_3 = _759 + 6;\n            float4 _803 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_803.z > 0.5)\n            {\n                int param_4 = _759 + 4;\n                float4 _813 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _759 + 5;\n                float4 _818 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _803.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _813.xyz) * _813.w, (-dot(world_pos, _818.xyz)) * _818.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _848 = _767.xyz;\n        float3 _850 = _848 - world_pos;\n        float3 to_light = _850;\n        float _853 = length(_850);\n        float reach = _853;\n        bool front = true;\n        if (_787)\n        {\n            int param_8 = _759 + 7;\n            reach = fast::max(_853 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _759 + 4;\n            float4 _877 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _759 + 5;\n            float4 _882 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _759 + 6;\n            float4 _887 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _888 = _887.w;\n            int param_12 = _759 + 2;\n            float3 _895 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _897 = _888 > 1.5;\n            bool _905;\n            if (!_897)\n            {\n                _905 = dot(_895, to_light) < 0.0;\n            }\n            else\n            {\n                _905 = _897;\n            }\n            front = _905;\n            float3 r = float3(0.0);\n            float3 _914 = _365.fa_camera_pos.xyz - world_pos;\n            bool _918 = dot(n, n) > 0.5;\n            bool _926;\n            if (_918)\n            {\n                _926 = dot(_914, _914) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _926 = _918;\n            }\n            if (_926)\n            {\n                r = reflect(-fast::normalize(_914), fast::normalize(n));\n            }\n            float3 param_13 = _848;\n            float3 param_14 = _895;\n            float3 param_15 = _877.xyz;\n            float3 param_16 = _882.xyz;\n            float param_17 = _877.w;\n            float param_18 = _882.w;\n            float param_19 = _888;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _962 = length(to_light);\n        dist = _962;\n        l = to_light / float3(fast::max(_962, 9.9999997473787516355514526367188e-05));\n        float _976 = reach / fast::max(_767.w, 0.001000000047497451305389404296875);\n        float _982 = fast::clamp(1.0 - (_976 * _976), 0.0, 1.0);\n        float _984;\n        if (front)\n        {\n            _984 = _982 * _982;\n        }\n        else\n        {\n            _984 = 0.0;\n        }\n        atten = _984;\n        bool _995 = _775 < 2.5;\n        if ((_775 > 1.5) && _995)\n        {\n            int param_22 = _759 + 2;\n            float4 _1003 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _1013 = _1003.w;\n            int param_23 = _759 + 3;\n            float4 _1018 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _1019 = _1018.x;\n            float cos_inner = _1019;\n            if (_1019 > 1.5)\n            {\n                cos_inner = mix(_1013, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1013, cos_inner, dot(-l, fast::normalize(_1003.xyz)));\n        }\n        if (_763 && (_775 < 1.5))\n        {\n            int param_24 = _759 + 6;\n            float4 _1043 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1043.z > 0.5)\n            {\n                float3 _1051 = -to_light;\n                int param_25 = _759 + 4;\n                int param_26 = _759 + 5;\n                float3 _1065 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1069 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1078 = float3(dot(_1051, _1065), dot(_1051, _1069), dot(_1051, cross(_1065, _1069)));\n                float3 param_27 = _1078;\n                int _1082 = fa_cube_face(param_27);\n                int param_28 = _1082;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1109 = float2(dot(_1078, cross(param_29, param_30)), dot(_1078, param_30)) / float2(fast::max(dot(_1078, param_29), 9.9999997473787516355514526367188e-05));\n                int _1113 = _1082 / 3;\n                float2 param_31 = _1043.xy + (float2(float(_1082 - (_1113 * 3)), float(_1113)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1109.x), 0.5 - (0.5 * _1109.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _759 + 7;\n            float4 _1143 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1143.z > 0.5)\n            {\n                int param_34 = _759 + 2;\n                int param_35 = _759 + 4;\n                int param_36 = _759 + 5;\n                float2 param_37 = _1143.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_763 && _995)\n            {\n                int param_42 = _759 + 6;\n                float4 _1190 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _759 + 7;\n                float4 _1195 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1198 = _1190.z > 0.5;\n                bool _1205;\n                if (!_1198)\n                {\n                    _1205 = _1195.z > 0.5;\n                }\n                else\n                {\n                    _1205 = _1198;\n                }\n                if (_1205)\n                {\n                    int param_44 = _759 + 2;\n                    float4 _1212 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1216 = fast::normalize(_1212.xyz);\n                    int param_45 = _759 + 4;\n                    float4 _1221 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _759 + 5;\n                    float4 _1226 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1198)\n                    {\n                        float3 _1234 = -to_light;\n                        float _1241 = _1212.w;\n                        float _1257 = 0.5 / fast::max(dot(_1234, _1216) * (sqrt(fast::max(1.0 - (_1241 * _1241), 0.0)) / fast::max(_1241, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1190.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1234, _1221.xyz) * _1257), 0.5 - (dot(_1234, _1226.xyz) * _1257));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1195.z > 0.5)\n                    {\n                        float2 param_49 = _1195.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1216;\n                        float3 param_52 = _1221.xyz;\n                        float3 param_53 = _1226.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4907 = _772.xyz * atten;\n    if (_763)\n    {\n        _4907 *= fa_light_tint;\n    }\n    int _1325;\n    if (_789)\n    {\n        _1325 = 0;\n    }\n    else\n    {\n        _1325 = ((_775 > 1.5) && (_775 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4907, atten, 1.0, dist, _1325 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2072)\n{\n    float _2062;\n    if (i == 0)\n    {\n        _2062 = _2072.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2078;\n        if (i == 1)\n        {\n            _2078 = _2072.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2086;\n            if (i == 2)\n            {\n                _2086 = _2072.fa_shadow_split.z;\n            }\n            else\n            {\n                _2086 = _2072.fa_shadow_split.w;\n            }\n            _2078 = _2086;\n        }\n        _2062 = _2078;\n    }\n    return _2062;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2119 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2123;\n    if (conv.x < 0.5)\n    {\n        _2123 = _2119;\n    }\n    else\n    {\n        _2123 = (conv.y * conv.z) / (conv.z - (_2119 * (conv.z - conv.y)));\n    }\n    return _2123;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2050 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2050), sin(_2050)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2072, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2169 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2178;\n        if (k < 0.0)\n        {\n            _2178 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2178 = k;\n        }\n        float _2198 = fast::clamp((_2178 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2169;\n            float2 _2217 = fa_shadow_vogel(param_3, param_4, param_5) * _2198;\n            float2 param_6 = uv + (_2217 * _2072.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2229 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2229 < (zr - (length(_2217) * plane)))\n            {\n                sum += _2229;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2255 = sum / cnt;\n        float _2265;\n        if (k < 0.0)\n        {\n            _2265 = (-k) / fast::max(_2255, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2265 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2255, 0.0) * unit) * _2265) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2287 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2287; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2287;\n        float param_11 = _2169;\n        float2 _2306 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2306 * _2072.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2306) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2287);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2072, texture2d<float> fa_shadow_tex)\n{\n    float _2348 = fast::max(_2072.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2353 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2359 = sqrt(1.0 - (_2353 * _2353));\n    float _2366 = fast::min(_2359 / fast::max(_2353, 0.20000000298023223876953125), 4.0);\n    float _2371;\n    if (_2072.fa_shadow_bias.y > 0.0)\n    {\n        _2371 = _2072.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2371 = 1.5 * _2072.fa_shadow_info[ci].x;\n    }\n    float4 _2396 = _2072.fa_shadow_mat[ci] * float4(world + (n * (_2371 * _2359)), 1.0);\n    float _2403 = _2396.x;\n    bool _2406 = _2403 < _2072.fa_shadow_rect[ci].x;\n    bool _2415;\n    if (!_2406)\n    {\n        _2415 = _2403 > _2072.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2415 = _2406;\n    }\n    bool _2424;\n    if (!_2415)\n    {\n        _2424 = _2396.y < _2072.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2424 = _2415;\n    }\n    bool _2433;\n    if (!_2424)\n    {\n        _2433 = _2396.y > _2072.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2433 = _2424;\n    }\n    bool _2440;\n    if (!_2433)\n    {\n        _2440 = _2396.z > 1.0;\n    }\n    else\n    {\n        _2440 = _2433;\n    }\n    if (_2440)\n    {\n        return -1.0;\n    }\n    float _2448;\n    if (_2072.fa_shadow_bias.x > 0.0)\n    {\n        _2448 = _2072.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2448 = 1.5 * _2072.fa_shadow_info[ci].x;\n    }\n    float2 param = _2396.xy;\n    float4 param_1 = _2072.fa_shadow_rect[ci];\n    float param_2 = _2396.z - ((_2448 * (1.0 + (0.5 * _2366))) / _2348);\n    float param_3 = _2072.fa_shadow_info[ci].x;\n    float param_4 = _2348;\n    float param_5 = _2348 * 0.25;\n    float param_6 = ((_2072.fa_shadow_info[ci].x * fast::min(_2366, 3.0)) * 0.5) / _2348;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2072.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2072.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2072, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _365, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2072, texture2d<float> fa_shadow_tex)\n{\n    if (_365.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2836 = int(_2072.fa_shadow_cfg.x + 0.5);\n    if (_2836 < 1)\n    {\n        return 1.0;\n    }\n    float _2851 = dot(world - _2072.fa_shadow_eye.xyz, _2072.fa_shadow_fwd.xyz);\n    int param = _2836 - 1;\n    if (_2851 > fa_shadow_split_at(param, _2072))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2863 = _2836 > 1;\n    bool _2870;\n    if (_2863)\n    {\n        _2870 = _2851 > _2072.fa_shadow_split.x;\n    }\n    else\n    {\n        _2870 = _2863;\n    }\n    if (_2870)\n    {\n        ci = 1;\n    }\n    bool _2874 = _2836 > 2;\n    bool _2881;\n    if (_2874)\n    {\n        _2881 = _2851 > _2072.fa_shadow_split.y;\n    }\n    else\n    {\n        _2881 = _2874;\n    }\n    if (_2881)\n    {\n        ci = 2;\n    }\n    bool _2885 = _2836 > 3;\n    bool _2892;\n    if (_2885)\n    {\n        _2892 = _2851 > _2072.fa_shadow_split.z;\n    }\n    else\n    {\n        _2892 = _2885;\n    }\n    if (_2892)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2836)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2918 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2072, fa_shadow_tex);\n        s = _2918;\n        if (_2918 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2072.fa_shadow_cfg.y > 0.0)\n    {\n        float _2943;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2943 = fa_shadow_split_at(param_5, _2072);\n        }\n        else\n        {\n            _2943 = _2072.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2962 = _2072.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2072) - _2943, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2973 = fast::clamp((_2851 - (fa_shadow_split_at(param_7, _2072) - _2962)) / _2962, 0.0, 1.0);\n        if (_2973 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2836)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2994 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2072, fa_shadow_tex);\n                s2 = _2994;\n                if (_2994 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2973);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _365, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2072, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _365, fa_shadow_smp, gl_FragCoord, _2072, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2072, texture2d<float> fa_shadow_tex)\n{\n    bool _2506 = _365.fa_pbr.z < 0.5;\n    bool _2513;\n    if (!_2506)\n    {\n        _2513 = _2072.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2513 = _2506;\n    }\n    if (_2513)\n    {\n        return 1.0;\n    }\n    int param = (int(_2072.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2526 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2527 = _2526.x;\n    if (_2527 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2536 = int(_2527 + 0.5);\n    int param_1 = _2536;\n    float4 _2540 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2536 + 1;\n    float4 _2545 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2548 = _2540.y;\n    if (_2548 > 0.0)\n    {\n        float _2565 = 1.0 - smoothstep(0.75 * _2548, _2548, length(world - _2072.fa_shadow_eye.xyz));\n        fade = _2565;\n        if (_2565 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2540.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3, _365);\n        float3 param_5 = world - fa_light_texel(param_4, fa_light_tex, fa_shadow_smp).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2594 = (_2536 + 2) + (face * 6);\n    int param_6 = _2594;\n    int param_7 = _2594 + 1;\n    int param_8 = _2594 + 3;\n    float4 _2608 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    int param_9 = _2594 + 4;\n    float4 _2613 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n    int param_10 = _2594 + 5;\n    float4 _2618 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n    float _2630 = _2618.x * fast::max(dot(_2608, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2635 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2658 = fast::clamp(dot(n, _2608.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11, _365);\n    float _2682 = fast::min(sqrt(1.0 - (_2658 * _2658)) / fast::max(abs(dot(n, world - fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_2608, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2685 = _2545.y;\n    float _2687;\n    if (_2685 > 0.0)\n    {\n        _2687 = _2685;\n    }\n    else\n    {\n        _2687 = 1.5 * _2630;\n    }\n    float4 _2707 = float4(world + (n * (_2687 * sqrt(1.0 - (_2635 * _2635)))), 1.0);\n    float _2711 = dot(_2608, _2707);\n    float _2714 = _2618.y;\n    if (_2711 < _2714)\n    {\n        return 1.0;\n    }\n    float2 _2729 = float2(dot(fa_light_texel(param_6, fa_light_tex, fa_shadow_smp), _2707), dot(fa_light_texel(param_7, fa_light_tex, fa_shadow_smp), _2707)) / float2(_2711);\n    float _2731 = _2729.x;\n    bool _2734 = _2731 < _2613.x;\n    bool _2743;\n    if (!_2734)\n    {\n        _2743 = _2731 > _2613.z;\n    }\n    else\n    {\n        _2743 = _2734;\n    }\n    bool _2752;\n    if (!_2743)\n    {\n        _2752 = _2729.y < _2613.y;\n    }\n    else\n    {\n        _2752 = _2743;\n    }\n    bool _2761;\n    if (!_2752)\n    {\n        _2761 = _2729.y > _2613.w;\n    }\n    else\n    {\n        _2761 = _2752;\n    }\n    if (_2761)\n    {\n        return 1.0;\n    }\n    float _2767 = _2545.x;\n    float _2769;\n    if (_2767 > 0.0)\n    {\n        _2769 = _2767;\n    }\n    else\n    {\n        _2769 = 1.5 * _2630;\n    }\n    float2 param_13 = _2729;\n    float4 param_14 = _2613;\n    float param_15 = _2711 - (_2769 * (1.0 + (0.5 * _2682)));\n    float param_16 = _2630;\n    float param_17 = 1.0;\n    float param_18 = _2618.z * 0.25;\n    float param_19 = (_2630 * fast::min(_2682, 3.0)) * 0.5;\n    float3 param_20 = float3(1.0, _2714, _2618.z);\n    int param_21 = int(_2540.z + 0.5);\n    float param_22 = _2540.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, fa_shadow_smp, gl_FragCoord, _2072, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2072, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3925 = fa_lm.z > 0.5;\n    bool _3931;\n    if (_3925)\n    {\n        int param = li;\n        _3931 = fa_light_baked(param, _365, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3931 = _3925;\n    }\n    if (_3931)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _365, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3955 = fa_light_sample_n(param_2, param_3, param_4, _365, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _5040 = _3955.color;\n    float _5042 = _3955.shadow;\n    if ((_3955.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3955.direction;\n        float _3969 = fa_shadow_factor(param_5, param_6, _365, fa_shadow_smp, gl_FragCoord, _2072, fa_shadow_tex, fa_world_pos);\n        _5042 = _3969;\n        _5040 *= _3969;\n    }\n    else\n    {\n        bool _3980 = _3955.type != 0;\n        bool _3986;\n        if (_3980)\n        {\n            _3986 = _3955.attenuation > 0.0;\n        }\n        else\n        {\n            _3986 = _3980;\n        }\n        if (_3986)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _3955.direction;\n            float _3998 = fa_shadow_local(param_7, param_8, param_9, param_10, _365, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2072, fa_shadow_tex);\n            _5042 = _3998;\n            _5040 *= _3998;\n        }\n    }\n    return LightSample{ _3955.direction, _5040, _3955.attenuation, _5042, _3955._distance, _3955.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2072)\n{\n    if (_2072.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _3018 = int(_2072.fa_shadow_cfg.x + 0.5);\n    float _3028 = dot(world - _2072.fa_shadow_eye.xyz, _2072.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _3033 = _3018 > 0;\n    bool _3042;\n    if (_3033)\n    {\n        int param = _3018 - 1;\n        _3042 = _3028 <= fa_shadow_split_at(param, _2072);\n    }\n    else\n    {\n        _3042 = _3033;\n    }\n    if (_3042)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3048 = _3018 > 1;\n        bool _3055;\n        if (_3048)\n        {\n            _3055 = _3028 > _2072.fa_shadow_split.x;\n        }\n        else\n        {\n            _3055 = _3048;\n        }\n        if (_3055)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3061 = _3018 > 2;\n        bool _3068;\n        if (_3061)\n        {\n            _3068 = _3028 > _2072.fa_shadow_split.y;\n        }\n        else\n        {\n            _3068 = _3061;\n        }\n        if (_3068)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3074 = _3018 > 3;\n        bool _3081;\n        if (_3074)\n        {\n            _3081 = _3028 > _2072.fa_shadow_split.z;\n        }\n        else\n        {\n            _3081 = _3074;\n        }\n        if (_3081)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _365 [[buffer(1)]], constant fa_shadows& _2072 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_light_atlas [[texture(9)]], texture2d<float> fa_lightmap [[texture(10)]], texture2d<float> fa_decal_tex [[texture(11)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4749 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4749 = -_4749;\n    }\n    float3 _4384 = fast::normalize(_365.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _365, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4749, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4384, short(gl_FrontFacing) };\n    Surface _4392 = fa_standard_surface(param_1, _365, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4788 = _4392.albedo;\n    float _4789 = _4392.alpha;\n    float3 _4790 = _4392.normal;\n    float _4791 = _4392.metallic;\n    float _4792 = _4392.roughness;\n    float _4793 = _4392.occlusion;\n    float3 _4794 = _4392.emission;\n    float _4795 = _4392.clearcoat;\n    float _4796 = _4392.clearcoat_roughness;\n    float3 _4797 = _4392.sheen_color;\n    float _4798 = _4392.sheen_roughness;\n    float _4799 = _4392.anisotropy;\n    float _4800 = _4392.anisotropy_rotation;\n    float _4801 = _4392.specular;\n    float _4802 = _4392.ior;\n    float3 _4803 = _4392.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4749, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4384, short(gl_FrontFacing) };\n    Surface param_3 = _4392;\n    surface(param_2, param_3);\n    _4788 = param_3.albedo;\n    _4789 = param_3.alpha;\n    _4790 = param_3.normal;\n    _4791 = param_3.metallic;\n    _4792 = param_3.roughness;\n    _4793 = param_3.occlusion;\n    _4794 = param_3.emission;\n    _4795 = param_3.clearcoat;\n    _4796 = param_3.clearcoat_roughness;\n    _4797 = param_3.sheen_color;\n    _4798 = param_3.sheen_roughness;\n    _4799 = param_3.anisotropy;\n    _4800 = param_3.anisotropy_rotation;\n    _4801 = param_3.specular;\n    _4802 = param_3.ior;\n    _4803 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4749;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _365, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4788 = param_6;\n    _4790 = param_7;\n    float3 result;\n    if (_365.fa_emissive.w > 0.5)\n    {\n        result = _4788;\n    }\n    else\n    {\n        float3 _4430 = _4790;\n        float3 _4431 = fast::normalize(_4430);\n        _4790 = _4431;\n        float3 param_8 = _4431;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _4749, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4384, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _4788, _4789, _4790, _4791, _4792, _4793, _4794, _4795, _4796, _4797, _4798, _4799, _4800, _4801, _4802, _4803 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _365, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11, _365, fa_env_smp, fa_env_tex);\n        int _4450 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4450; ln++)\n        {\n            int param_12 = ln;\n            int _4463 = fa_cl_light(param_12, _365, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            bool _4466 = in.fa_lm.z > 0.5;\n            bool _4472;\n            if (_4466)\n            {\n                int param_13 = _4463;\n                _4472 = fa_light_baked(param_13, _365, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _4472 = _4466;\n            }\n            if (_4472)\n            {\n                continue;\n            }\n            int param_14 = _4463;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _4749;\n            LightSample _4484 = fa_light_shadowed(param_14, param_15, param_16, _365, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2072, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _4749, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4384, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _4788, _4789, _4790, _4791, _4792, _4793, _4794, _4795, _4796, _4797, _4798, _4799, _4800, _4801, _4802, _4803 };\n            LightSample param_19 = _4484;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4499 = result;\n    float3 _4500 = _4499 + _4794;\n    result = _4500;\n    float3 param_20 = _4500;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _2072);\n    bool _4509 = _365.fa_fog.w > 0.0;\n    bool _4516;\n    if (!_4509)\n    {\n        _4516 = _365.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4516 = _4509;\n    }\n    if (_4516)\n    {\n        float3 _4525 = in.fa_world_pos - _365.fa_camera_pos.xyz;\n        float _4531 = dot(_4525, _365.fa_fog_c.xyz);\n        bool _4535 = _365.fa_fog_c.w > 0.5;\n        float _4536;\n        if (_4535)\n        {\n            _4536 = _4531;\n        }\n        else\n        {\n            _4536 = length(_4525);\n        }\n        float _4548 = _4536 - _365.fa_fog_b.x;\n        if (_4548 > 0.0)\n        {\n            float _4557 = _365.fa_fog.w * _4548;\n            float tau = _4557 * _4557;\n            if (_365.fa_fog_b.y > 0.0)\n            {\n                float _4573;\n                if (_4535)\n                {\n                    _4573 = in.fa_world_pos.y - (_365.fa_fog_c.y * _4531);\n                }\n                else\n                {\n                    _4573 = _365.fa_camera_pos.y;\n                }\n                float _4594 = mix(_4573, in.fa_world_pos.y, fast::clamp(_365.fa_fog_b.x / _4536, 0.0, 1.0));\n                float _4598 = in.fa_world_pos.y - _4594;\n                float _4603 = _4594 - _365.fa_fog_b.z;\n                float _4608 = in.fa_world_pos.y - _365.fa_fog_b.z;\n                bool _4611 = _4603 <= 0.0;\n                bool _4612 = !_4611;\n                bool _4618;\n                if (_4612)\n                {\n                    _4618 = _365.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4618 = _4611;\n                }\n                float _4619;\n                if (_4618)\n                {\n                    _4619 = _365.fa_fog_b.y;\n                }\n                else\n                {\n                    _4619 = _365.fa_fog_b.y * exp(-fast::min(_365.fa_fog_b.w * _4603, 80.0));\n                }\n                bool _4646;\n                if (_4612)\n                {\n                    _4646 = _365.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4646 = _4611;\n                }\n                float _4647;\n                if (_4646)\n                {\n                    _4647 = _365.fa_fog_b.y * _4603;\n                }\n                else\n                {\n                    _4647 = (_365.fa_fog_b.y * (1.0 - exp(-fast::min(_365.fa_fog_b.w * _4603, 80.0)))) / _365.fa_fog_b.w;\n                }\n                bool _4672 = _4608 <= 0.0;\n                bool _4679;\n                if (!_4672)\n                {\n                    _4679 = _365.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4679 = _4672;\n                }\n                float _4680;\n                if (_4679)\n                {\n                    _4680 = _365.fa_fog_b.y * _4608;\n                }\n                else\n                {\n                    _4680 = (_365.fa_fog_b.y * (1.0 - exp(-fast::min(_365.fa_fog_b.w * _4608, 80.0)))) / _365.fa_fog_b.w;\n                }\n                float _4707;\n                if (abs(_4598) < 0.001000000047497451305389404296875)\n                {\n                    _4707 = _4619;\n                }\n                else\n                {\n                    _4707 = (_4680 - _4647) / _4598;\n                }\n                tau += (_4548 * fast::max(_4707, 0.0));\n            }\n            result = mix(result, _365.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4789);\n    return out;\n}\n\n",
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
            "inst_name": "_365",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2072",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "msl_texture_n": 7
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
              "msl_texture_n": 8
            }
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 9
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
              "msl_texture_n": 10
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
              "msl_texture_n": 11
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 11,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nconstant spvUnsafeArray<float, 63> _3366 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1343 = _365.fa_cl_info.x < 0.0;\n    bool _1350;\n    if (!_1343)\n    {\n        _1350 = _365.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1350 = _1343;\n    }\n    bool _1358;\n    if (!_1350)\n    {\n        _1358 = _365.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1358 = _1350;\n    }\n    bool _1365;\n    if (!_1358)\n    {\n        _1365 = _365.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1365 = _1358;\n    }\n    bool _1372;\n    if (!_1365)\n    {\n        _1372 = _365.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1372 = _1365;\n    }\n    if (_1372)\n    {\n        return float4(0.0);\n    }\n    float4 _1382 = float4(world_pos, 1.0);\n    float _1388 = dot(_365.fa_cl_vpw, _1382);\n    if (!(_1388 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1410 = float2(dot(_365.fa_cl_vpx, _1382), dot(_365.fa_cl_vpy, _1382)) / float2(_1388);\n    int _1414 = int(_365.fa_cl_grid.x);\n    int _1418 = int(_365.fa_cl_grid.y);\n    int param = (int(_365.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_365.fa_cl_fwd.xyz, world_pos) + _365.fa_cl_fwd.w, _365.fa_cl_grid.w) / _365.fa_cl_grid.w) * _365.fa_cl_grid.z)), 0, int(_365.fa_cl_info.y) - 1) * _1418) + clamp(int(floor(((_1410.y * 0.5) + 0.5) * _365.fa_cl_grid.y)), 0, _1418 - 1)) * _1414)) + clamp(int(floor(((_1410.x * 0.5) + 0.5) * _365.fa_cl_grid.x)), 0, _1414 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1494 = fa_cluster_texel(param, _365, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1494.x), int(_1494.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_365.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3898 = fa_cluster_lookup(param, _365, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3898.x;\n    fa_cl_local = _3898.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _4054 = fa_linear_to_srgb(param);\n        c = _4054;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _4062 = fa_srgb_to_linear(param_1);\n            c = _4062;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _297;\n    if (bool(i.front_facing))\n    {\n        _297 = i.world_normal;\n    }\n    else\n    {\n        _297 = -i.world_normal;\n    }\n    float3 _321 = fast::normalize(i.world_tangent.xyz - (_297 * dot(_297, i.world_tangent.xyz)));\n    float3 _349 = fast::normalize(((_321 * m.x) + ((cross(_297, _321) * i.world_tangent.w) * m.y)) + (_297 * m.z));\n    float3 _352;\n    if (bool(i.front_facing))\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _365, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _365.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4093 = fa_tex_fix(param_2, param_3);\n    float4 _5208 = base_t;\n    _5208.x = _4093.x;\n    _5208.y = _4093.y;\n    _5208.z = _4093.z;\n    base_t = _5208;\n    float4 _4107 = (_5208 * _365.fa_base_color) * i.vertex_color;\n    float3 _5060 = i.world_normal;\n    if (_365.fa_maps.z > 0.5)\n    {\n        float param_4 = _365.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4139 = fa_tex_fix(param_6, param_7);\n        float3 _4142 = (_4139 * 2.0) - float3(1.0);\n        float2 _4147 = _4142.xy * _365.fa_maps.x;\n        float3 _5216 = _4142;\n        _5216.x = _4147.x;\n        _5216.y = _4147.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5216;\n        _5060 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _365.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4175 = fa_tex_fix(param_12, param_13);\n    float4 _5219 = mrt;\n    _5219.x = _4175.x;\n    _5219.y = _4175.y;\n    _5219.z = _4175.z;\n    mrt = _5219;\n    float4 _4203 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _365.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _4203.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4214 = fa_tex_fix(param_16, param_17);\n    float param_18 = _365.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4244 = fa_tex_fix(param_20, param_21);\n    float _5065 = _365.fa_layers_a.x;\n    float _5066 = _365.fa_layers_a.y;\n    float _5069 = _365.fa_layers_a.z;\n    float _5068 = _365.fa_layers_b.w;\n    float _5071 = _365.fa_layers_c.x;\n    if (_365.fa_layers_c.z > 0.5)\n    {\n        if (mod(_365.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _5065 *= _4214.y;\n            _5066 *= _4214.z;\n            _5068 *= _4203.w;\n        }\n        if (_365.fa_layers_c.z > 1.5)\n        {\n            _5069 *= mrt.x;\n            _5071 *= mrt.w;\n        }\n    }\n    return Surface{ _4107.xyz, _4107.w, _5060, fast::clamp(_365.fa_pbr.x * _4175.z, 0.0, 1.0), fast::clamp(_365.fa_pbr.y * _4175.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_365.fa_maps.y * (_4214.x - 1.0)), _365.fa_emissive.xyz + (_365.fa_model_emissive.xyz * _4244), _5065, _5066, _365.fa_layers_b.xyz, _5068, _5069, _365.fa_layers_a.w, _5071, _365.fa_layers_c.y, _365.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1574 = rect.zw - rect.xy;\n    float2 _1578 = _1574 * atlas;\n    float2 _1582 = ddx * _1578;\n    float2 _1586 = ddy * _1578;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1574)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1582, _1582), dot(_1586, _1586)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1619 = _365.fa_counts.y < 0.5;\n    bool _1626;\n    if (!_1619)\n    {\n        _1626 = _365.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1626 = _1619;\n    }\n    if (_1626)\n    {\n        return;\n    }\n    float3 _1632 = dfdx(world_pos);\n    float3 _1635 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1639 = fa_cluster_texel(param, _365, fa_light_tex, fa_shadow_smp);\n    int _1643 = int(_1639.w);\n    if (_1643 < 1)\n    {\n        return;\n    }\n    int _1653 = int(_365.fa_counts.y + 0.5);\n    int param_1 = _1653;\n    float4 _1657 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1660 = _1657.yz;\n    int _1664 = int(_1657.w);\n    int param_2 = _1653 + 1;\n    float4 _1669 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1670 = _1669.x;\n    int _1676 = int(_365.fa_counts.w + 0.5) - 1;\n    int _1680 = int(_1639.z);\n    float3 _1945;\n    for (int k = 0; k < _1643; k++)\n    {\n        int _1693 = _1680 + k;\n        int param_3 = _1664 + (_1693 >> 2);\n        int _1710 = (_1653 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1693 & 3]) * 7);\n        int param_4 = _1710 + 6;\n        float4 _1715 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1715.w + 0.5) >> _1676) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1710;\n        float4 _1730 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1710 + 1;\n        float4 _1735 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1710 + 2;\n        float4 _1740 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1743 = _1730.xyz;\n        float _1748 = dot(_1743, world_pos) + _1730.w;\n        float3 _1750 = _1735.xyz;\n        float _1755 = dot(_1750, world_pos) + _1735.w;\n        float3 _1757 = _1740.xyz;\n        float _1762 = dot(_1757, world_pos) + _1740.w;\n        bool _1767 = abs(_1748) > 0.5;\n        bool _1775;\n        if (!_1767)\n        {\n            _1775 = abs(_1755) > 0.5;\n        }\n        else\n        {\n            _1775 = _1767;\n        }\n        bool _1783;\n        if (!_1775)\n        {\n            _1783 = abs(_1762) > 0.5;\n        }\n        else\n        {\n            _1783 = _1775;\n        }\n        if (_1783)\n        {\n            continue;\n        }\n        float _1798 = fast::clamp(dot(geo_normal, fast::normalize(_1757)) * _1715.z, 0.0, 1.0);\n        if (_1798 <= 0.0)\n        {\n            continue;\n        }\n        float _1818 = (fast::clamp((0.5 - abs(_1762)) * 10.0, 0.0, 1.0) * _1798) * _1715.x;\n        float2 _1826 = float2(_1748 + 0.5, 0.5 - _1755);\n        float2 _1836 = float2(dot(_1743, _1632), dot(_1750, _1632));\n        float2 _1846 = float2(dot(_1743, _1635), dot(_1750, _1635));\n        int param_8 = _1710 + 5;\n        float4 _1851 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1710 + 3;\n        float4 _1856 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1710 + 4;\n        float4 _1861 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1851.xyz;\n        bool _1871 = _1856.z > _1856.x;\n        if (_1871)\n        {\n            float4 param_11 = _1856;\n            float2 param_12 = _1826;\n            float2 param_13 = _1660;\n            float2 param_14 = _1836;\n            float2 param_15 = _1846;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1670 > 0.5) && (_1670 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1897 = fa_dc_to_linear(param_16);\n                float4 _5140 = tx;\n                _5140.x = _1897.x;\n                _5140.y = _1897.y;\n                _5140.z = _1897.z;\n                tx = _5140;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1818 * tex_a) * _1851.w, 0.0, 1.0)));\n        if (_1861.z > _1861.x)\n        {\n            float4 param_17 = _1861;\n            float2 param_18 = _1826;\n            float2 param_19 = _1660;\n            float2 param_20 = _1836;\n            float2 param_21 = _1846;\n            float4 _1941 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1670 > 1.5)\n            {\n                float3 param_22 = _1941.xyz;\n                float3 _1951 = fa_dc_to_srgb(param_22);\n                _1945 = _1951;\n            }\n            else\n            {\n                _1945 = _1941.xyz;\n            }\n            float3 _1960 = (_1945 * 2.0) - float3(1.0);\n            float2 _1965 = _1960.xy * _1715.y;\n            float3 _1987 = (fast::normalize(_1743) * _1965.x) + (fast::normalize(_1750) * _1965.y);\n            float3 _1990 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1990, fast::normalize((_1990 * fast::max(_1960.z, 0.0500000007450580596923828125)) + (_1987 - (_1990 * dot(_1990, _1987)))), float3(fast::clamp(_1818 * (_1871 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_365.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _365.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _365, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _3291 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3299 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3302 = int(_3291);\n    int _3305 = int(_3299);\n    float _3315 = _3299 - float(_3305);\n    int _3371 = (_3302 * 9) + _3305;\n    int _3391 = ((_3302 + 1) * 9) + _3305;\n    return mix(mix(_3366[_3371], _3366[_3371 + 1], _3315), mix(_3366[_3391], _3366[_3391 + 1], _3315), _3291 - float(_3302));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4919 = false;\n    float _4920 = 1.0;\n    float _4921 = 1.0;\n    float _4922 = 1.0;\n    float _4923 = 0.0;\n    float _4924 = 0.0;\n    float _4925 = 0.0;\n    float _4926 = 0.0;\n    float _4928 = 1.0;\n    bool _4929 = false;\n    float3 _4930 = float3(0.0);\n    float _4931 = 1.0;\n    float _4932 = 1.0;\n    float _4933 = 1.0;\n    float _4934 = 0.0;\n    float _4935 = 0.0;\n    float3 _4936 = float3(1.0, 0.0, 0.0);\n    float3 _4937 = float3(0.0, 0.0, 1.0);\n    float _4938 = 1.0;\n    float _4939 = 1.0;\n    float _3442 = fast::clamp(s.specular, 0.0, 1.0);\n    float _3446 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _3451 = (_3442 != 1.0) || (_3446 != 1.5);\n    bool _3460;\n    if (!_3451)\n    {\n        _3460 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _3460 = _3451;\n    }\n    if (_3460)\n    {\n        float _3468 = (_3446 - 1.0) / (_3446 + 1.0);\n        f0 = mix(fast::min(float3(_3468 * _3468) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _3442, s.albedo, float3(metallic));\n        _4920 = mix(_3442, 1.0, metallic);\n        _4919 = true;\n    }\n    float _3495 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_3495 > 0.0)\n    {\n        float _3503 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4923 = _3495;\n        _4924 = _3503;\n        float _3510 = _3503 * _3503;\n        _4925 = _3510;\n        _4926 = _3510 * _3510;\n        float _3522 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4928 = _3522;\n        _4921 = 1.0 - (_3495 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _3522, 0.0, 1.0), 5.0))));\n        _4919 = true;\n    }\n    float3 _3542 = fast::max(s.sheen_color, float3(0.0));\n    float _3551 = fast::max(_3542.x, fast::max(_3542.y, _3542.z));\n    if (_3551 > 0.0)\n    {\n        float _3559 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4929 = true;\n        _4930 = _3542;\n        _4931 = _3559;\n        _4932 = _3559 * _3559;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3559;\n        float _3576 = fa_sheen_albedo(param, param_1);\n        _4934 = _3576;\n        _4933 = 1.0 - fast::min(_3551 * _3576, 1.0);\n        _4919 = true;\n    }\n    _4922 = _4921 * _4933;\n    float _3595 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_3595 != 0.0)\n    {\n        float3 _3610 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3610;\n        if (dot(_3610, _3610) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _3626 = t;\n        float3 _3627 = fast::normalize(_3626);\n        t = _3627;\n        float3 _3652 = fast::normalize((_3627 * cos(s.anisotropy_rotation)) + ((cross(n, _3627) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4936 = _3652;\n        _4937 = cross(n, _3652);\n        float _3662 = roughness * roughness;\n        float _3668 = mix(_3662, 1.0, _3595 * _3595);\n        bool _3670 = _3595 > 0.0;\n        _4938 = _3670 ? _3668 : _3662;\n        _4939 = _3670 ? _3662 : _3668;\n        _4935 = _3595;\n        _4919 = true;\n    }\n    return FaLayers{ short(_4919), _4920, _4921, _4922, _4923, _4924, _4925, _4926, i.world_normal, _4928, short(_4929), _4930, _4931, _4932, _4933, _4934, _4935, _4936, _4937, _4938, _4939 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _3223 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3226 = _3223.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_3226 * _3226, exp2((-9.27999973297119140625) * ndv)) * _3226) + _3223.y)) + _3223.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_365.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _365.fa_env_horizon.w)).xyz;\n    }\n    float _3129 = rough * rough;\n    float _3159 = 0.60000002384185791015625 * _3129;\n    return mix(mix(_365.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_365.fa_env_horizon.xyz, _365.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _3129)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _3159, 0.0500000007450580596923828125 + _3159, d.y))), ((_365.fa_env_sky.xyz + _365.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_3129 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _3703;\n        if (L.aniso >= 0.0)\n        {\n            _3703 = L.b;\n        }\n        else\n        {\n            _3703 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_3703, v), _3703), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3736 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _365, fa_env_smp, fa_env_tex) * ((f0 * _3736.x) + (float3(L.f90) * _3736.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _365, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3791 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _365, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _3791.x) + _3791.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3265 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _365, fa_env_smp, fa_env_tex) * ((f0 * _3265.x) + float3(_3265.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float _3820 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _3824 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _3831 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_3820));\n    float3 f0 = _3831;\n    float3 _3835 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3835;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3820;\n    float param_5 = _3824;\n    float3 param_6 = _3831;\n    FaLayers _3852 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3852.on)\n    {\n        FaLayers param_7 = _3852;\n        float3 param_8 = _3835;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3824;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _365, fa_env_smp, fa_env_tex) * s.occlusion;\n    }\n    float3 param_12 = _3835;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3824;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _365, fa_env_smp, fa_env_tex) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1, _365, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_365.fa_cl_info.x) + int(_365.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _365, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _365)\n{\n    return li * ((_365.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _365) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _365) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _593 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _606 = (c - (ru * hx)) - p;\n        float3 _612 = ru * (2.0 * hx);\n        float _618 = fast::max(dot(_612, _612), 9.9999999392252902907785028219223e-09);\n        float _622 = dot(_606, _612);\n        float t = fast::clamp((-_622) / _618, 0.0, 1.0);\n        if (_593)\n        {\n            float _637 = dot(r, _612);\n            float _643 = _618 - (_637 * _637);\n            if (abs(_643) > (9.9999997473787516355514526367188e-06 * _618))\n            {\n                t = fast::clamp(((dot(r, _606) * _637) - _622) / _643, 0.0, 1.0);\n            }\n        }\n        return (p + _606) + (_612 * t);\n    }\n    float3 q = p;\n    float _675 = dot(r, axis);\n    bool _683;\n    if (_593)\n    {\n        _683 = abs(_675) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _683 = _593;\n    }\n    if (_683)\n    {\n        float _693 = dot(c - p, axis) / _675;\n        if (_693 > 0.0)\n        {\n            q = p + (r * _693);\n        }\n    }\n    float3 _706 = q - c;\n    float2 xy = float2(dot(_706, ru), dot(_706, uu));\n    if (shape > 0.5)\n    {\n        float _721 = length(xy);\n        if (_721 > hx)\n        {\n            xy *= (hx / _721);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _514 = abs(d);\n    float _516 = _514.x;\n    float _518 = _514.y;\n    bool _519 = _516 >= _518;\n    bool _527;\n    if (_519)\n    {\n        _527 = _516 >= _514.z;\n    }\n    else\n    {\n        _527 = _519;\n    }\n    int _528;\n    if (_527)\n    {\n        _528 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _541;\n        if (_518 >= _514.z)\n        {\n            _541 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _541 = (d.z > 0.0) ? 4 : 5;\n        }\n        _528 = _541;\n    }\n    return _528;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _467 = dot(d, right);\n    float _471 = dot(d, up);\n    float _482;\n    if (((_467 * _467) + (_471 * _471)) > 1.0000000133514319600180897396058e-10)\n    {\n        _482 = precise::atan2(_471, _467) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _482 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_482 - floor(_482)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _759 = fa_light_base(param, _365);\n    bool _763 = _365.fa_ambient.w > 4.5;\n    int param_1 = _759;\n    float4 _767 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _759 + 1;\n    float4 _772 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _775 = _772.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _787 = _763 && (_775 > 2.5);\n    fa_light_is_area = _787;\n    bool _789 = _775 < 0.5;\n    float3 l;\n    if (_789)\n    {\n        l = fast::normalize(_767.xyz);\n        if (_763)\n        {\n            int param_3 = _759 + 6;\n            float4 _803 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_803.z > 0.5)\n            {\n                int param_4 = _759 + 4;\n                float4 _813 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _759 + 5;\n                float4 _818 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _803.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _813.xyz) * _813.w, (-dot(world_pos, _818.xyz)) * _818.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _848 = _767.xyz;\n        float3 _850 = _848 - world_pos;\n        float3 to_light = _850;\n        float _853 = length(_850);\n        float reach = _853;\n        bool front = true;\n        if (_787)\n        {\n            int param_8 = _759 + 7;\n            reach = fast::max(_853 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _759 + 4;\n            float4 _877 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _759 + 5;\n            float4 _882 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _759 + 6;\n            float4 _887 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _888 = _887.w;\n            int param_12 = _759 + 2;\n            float3 _895 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _897 = _888 > 1.5;\n            bool _905;\n            if (!_897)\n            {\n                _905 = dot(_895, to_light) < 0.0;\n            }\n            else\n            {\n                _905 = _897;\n            }\n            front = _905;\n            float3 r = float3(0.0);\n            float3 _914 = _365.fa_camera_pos.xyz - world_pos;\n            bool _918 = dot(n, n) > 0.5;\n            bool _926;\n            if (_918)\n            {\n                _926 = dot(_914, _914) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _926 = _918;\n            }\n            if (_926)\n            {\n                r = reflect(-fast::normalize(_914), fast::normalize(n));\n            }\n            float3 param_13 = _848;\n            float3 param_14 = _895;\n            float3 param_15 = _877.xyz;\n            float3 param_16 = _882.xyz;\n            float param_17 = _877.w;\n            float param_18 = _882.w;\n            float param_19 = _888;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _962 = length(to_light);\n        dist = _962;\n        l = to_light / float3(fast::max(_962, 9.9999997473787516355514526367188e-05));\n        float _976 = reach / fast::max(_767.w, 0.001000000047497451305389404296875);\n        float _982 = fast::clamp(1.0 - (_976 * _976), 0.0, 1.0);\n        float _984;\n        if (front)\n        {\n            _984 = _982 * _982;\n        }\n        else\n        {\n            _984 = 0.0;\n        }\n        atten = _984;\n        bool _995 = _775 < 2.5;\n        if ((_775 > 1.5) && _995)\n        {\n            int param_22 = _759 + 2;\n            float4 _1003 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _1013 = _1003.w;\n            int param_23 = _759 + 3;\n            float4 _1018 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _1019 = _1018.x;\n            float cos_inner = _1019;\n            if (_1019 > 1.5)\n            {\n                cos_inner = mix(_1013, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1013, cos_inner, dot(-l, fast::normalize(_1003.xyz)));\n        }\n        if (_763 && (_775 < 1.5))\n        {\n            int param_24 = _759 + 6;\n            float4 _1043 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1043.z > 0.5)\n            {\n                float3 _1051 = -to_light;\n                int param_25 = _759 + 4;\n                int param_26 = _759 + 5;\n                float3 _1065 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1069 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1078 = float3(dot(_1051, _1065), dot(_1051, _1069), dot(_1051, cross(_1065, _1069)));\n                float3 param_27 = _1078;\n                int _1082 = fa_cube_face(param_27);\n                int param_28 = _1082;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1109 = float2(dot(_1078, cross(param_29, param_30)), dot(_1078, param_30)) / float2(fast::max(dot(_1078, param_29), 9.9999997473787516355514526367188e-05));\n                int _1113 = _1082 / 3;\n                float2 param_31 = _1043.xy + (float2(float(_1082 - (_1113 * 3)), float(_1113)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1109.x), 0.5 - (0.5 * _1109.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _759 + 7;\n            float4 _1143 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1143.z > 0.5)\n            {\n                int param_34 = _759 + 2;\n                int param_35 = _759 + 4;\n                int param_36 = _759 + 5;\n                float2 param_37 = _1143.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_763 && _995)\n            {\n                int param_42 = _759 + 6;\n                float4 _1190 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _759 + 7;\n                float4 _1195 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1198 = _1190.z > 0.5;\n                bool _1205;\n                if (!_1198)\n                {\n                    _1205 = _1195.z > 0.5;\n                }\n                else\n                {\n                    _1205 = _1198;\n                }\n                if (_1205)\n                {\n                    int param_44 = _759 + 2;\n                    float4 _1212 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1216 = fast::normalize(_1212.xyz);\n                    int param_45 = _759 + 4;\n                    float4 _1221 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _759 + 5;\n                    float4 _1226 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1198)\n                    {\n                        float3 _1234 = -to_light;\n                        float _1241 = _1212.w;\n                        float _1257 = 0.5 / fast::max(dot(_1234, _1216) * (sqrt(fast::max(1.0 - (_1241 * _1241), 0.0)) / fast::max(_1241, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1190.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1234, _1221.xyz) * _1257), 0.5 - (dot(_1234, _1226.xyz) * _1257));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1195.z > 0.5)\n                    {\n                        float2 param_49 = _1195.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1216;\n                        float3 param_52 = _1221.xyz;\n                        float3 param_53 = _1226.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4907 = _772.xyz * atten;\n    if (_763)\n    {\n        _4907 *= fa_light_tint;\n    }\n    int _1325;\n    if (_789)\n    {\n        _1325 = 0;\n    }\n    else\n    {\n        _1325 = ((_775 > 1.5) && (_775 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4907, atten, 1.0, dist, _1325 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2072)\n{\n    float _2062;\n    if (i == 0)\n    {\n        _2062 = _2072.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2078;\n        if (i == 1)\n        {\n            _2078 = _2072.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2086;\n            if (i == 2)\n            {\n                _2086 = _2072.fa_shadow_split.z;\n            }\n            else\n            {\n                _2086 = _2072.fa_shadow_split.w;\n            }\n            _2078 = _2086;\n        }\n        _2062 = _2078;\n    }\n    return _2062;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2119 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2123;\n    if (conv.x < 0.5)\n    {\n        _2123 = _2119;\n    }\n    else\n    {\n        _2123 = (conv.y * conv.z) / (conv.z - (_2119 * (conv.z - conv.y)));\n    }\n    return _2123;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2050 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2050), sin(_2050)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2072, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2169 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2178;\n        if (k < 0.0)\n        {\n            _2178 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2178 = k;\n        }\n        float _2198 = fast::clamp((_2178 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2169;\n            float2 _2217 = fa_shadow_vogel(param_3, param_4, param_5) * _2198;\n            float2 param_6 = uv + (_2217 * _2072.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2229 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2229 < (zr - (length(_2217) * plane)))\n            {\n                sum += _2229;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2255 = sum / cnt;\n        float _2265;\n        if (k < 0.0)\n        {\n            _2265 = (-k) / fast::max(_2255, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2265 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2255, 0.0) * unit) * _2265) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2287 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2287; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2287;\n        float param_11 = _2169;\n        float2 _2306 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2306 * _2072.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2306) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2287);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2072, texture2d<float> fa_shadow_tex)\n{\n    float _2348 = fast::max(_2072.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2353 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2359 = sqrt(1.0 - (_2353 * _2353));\n    float _2366 = fast::min(_2359 / fast::max(_2353, 0.20000000298023223876953125), 4.0);\n    float _2371;\n    if (_2072.fa_shadow_bias.y > 0.0)\n    {\n        _2371 = _2072.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2371 = 1.5 * _2072.fa_shadow_info[ci].x;\n    }\n    float4 _2396 = _2072.fa_shadow_mat[ci] * float4(world + (n * (_2371 * _2359)), 1.0);\n    float _2403 = _2396.x;\n    bool _2406 = _2403 < _2072.fa_shadow_rect[ci].x;\n    bool _2415;\n    if (!_2406)\n    {\n        _2415 = _2403 > _2072.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2415 = _2406;\n    }\n    bool _2424;\n    if (!_2415)\n    {\n        _2424 = _2396.y < _2072.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2424 = _2415;\n    }\n    bool _2433;\n    if (!_2424)\n    {\n        _2433 = _2396.y > _2072.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2433 = _2424;\n    }\n    bool _2440;\n    if (!_2433)\n    {\n        _2440 = _2396.z > 1.0;\n    }\n    else\n    {\n        _2440 = _2433;\n    }\n    if (_2440)\n    {\n        return -1.0;\n    }\n    float _2448;\n    if (_2072.fa_shadow_bias.x > 0.0)\n    {\n        _2448 = _2072.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2448 = 1.5 * _2072.fa_shadow_info[ci].x;\n    }\n    float2 param = _2396.xy;\n    float4 param_1 = _2072.fa_shadow_rect[ci];\n    float param_2 = _2396.z - ((_2448 * (1.0 + (0.5 * _2366))) / _2348);\n    float param_3 = _2072.fa_shadow_info[ci].x;\n    float param_4 = _2348;\n    float param_5 = _2348 * 0.25;\n    float param_6 = ((_2072.fa_shadow_info[ci].x * fast::min(_2366, 3.0)) * 0.5) / _2348;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2072.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2072.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2072, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _365, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2072, texture2d<float> fa_shadow_tex)\n{\n    if (_365.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2836 = int(_2072.fa_shadow_cfg.x + 0.5);\n    if (_2836 < 1)\n    {\n        return 1.0;\n    }\n    float _2851 = dot(world - _2072.fa_shadow_eye.xyz, _2072.fa_shadow_fwd.xyz);\n    int param = _2836 - 1;\n    if (_2851 > fa_shadow_split_at(param, _2072))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2863 = _2836 > 1;\n    bool _2870;\n    if (_2863)\n    {\n        _2870 = _2851 > _2072.fa_shadow_split.x;\n    }\n    else\n    {\n        _2870 = _2863;\n    }\n    if (_2870)\n    {\n        ci = 1;\n    }\n    bool _2874 = _2836 > 2;\n    bool _2881;\n    if (_2874)\n    {\n        _2881 = _2851 > _2072.fa_shadow_split.y;\n    }\n    else\n    {\n        _2881 = _2874;\n    }\n    if (_2881)\n    {\n        ci = 2;\n    }\n    bool _2885 = _2836 > 3;\n    bool _2892;\n    if (_2885)\n    {\n        _2892 = _2851 > _2072.fa_shadow_split.z;\n    }\n    else\n    {\n        _2892 = _2885;\n    }\n    if (_2892)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2836)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2918 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2072, fa_shadow_tex);\n        s = _2918;\n        if (_2918 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2072.fa_shadow_cfg.y > 0.0)\n    {\n        float _2943;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2943 = fa_shadow_split_at(param_5, _2072);\n        }\n        else\n        {\n            _2943 = _2072.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2962 = _2072.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2072) - _2943, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2973 = fast::clamp((_2851 - (fa_shadow_split_at(param_7, _2072) - _2962)) / _2962, 0.0, 1.0);\n        if (_2973 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2836)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2994 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2072, fa_shadow_tex);\n                s2 = _2994;\n                if (_2994 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2973);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _365, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2072, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _365, fa_shadow_smp, gl_FragCoord, _2072, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2072, texture2d<float> fa_shadow_tex)\n{\n    bool _2506 = _365.fa_pbr.z < 0.5;\n    bool _2513;\n    if (!_2506)\n    {\n        _2513 = _2072.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2513 = _2506;\n    }\n    if (_2513)\n    {\n        return 1.0;\n    }\n    int param = (int(_2072.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2526 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2527 = _2526.x;\n    if (_2527 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2536 = int(_2527 + 0.5);\n    int param_1 = _2536;\n    float4 _2540 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2536 + 1;\n    float4 _2545 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2548 = _2540.y;\n    if (_2548 > 0.0)\n    {\n        float _2565 = 1.0 - smoothstep(0.75 * _2548, _2548, length(world - _2072.fa_shadow_eye.xyz));\n        fade = _2565;\n        if (_2565 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2540.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3, _365);\n        float3 param_5 = world - fa_light_texel(param_4, fa_light_tex, fa_shadow_smp).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2594 = (_2536 + 2) + (face * 6);\n    int param_6 = _2594;\n    int param_7 = _2594 + 1;\n    int param_8 = _2594 + 3;\n    float4 _2608 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    int param_9 = _2594 + 4;\n    float4 _2613 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n    int param_10 = _2594 + 5;\n    float4 _2618 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n    float _2630 = _2618.x * fast::max(dot(_2608, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2635 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2658 = fast::clamp(dot(n, _2608.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11, _365);\n    float _2682 = fast::min(sqrt(1.0 - (_2658 * _2658)) / fast::max(abs(dot(n, world - fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_2608, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2685 = _2545.y;\n    float _2687;\n    if (_2685 > 0.0)\n    {\n        _2687 = _2685;\n    }\n    else\n    {\n        _2687 = 1.5 * _2630;\n    }\n    float4 _2707 = float4(world + (n * (_2687 * sqrt(1.0 - (_2635 * _2635)))), 1.0);\n    float _2711 = dot(_2608, _2707);\n    float _2714 = _2618.y;\n    if (_2711 < _2714)\n    {\n        return 1.0;\n    }\n    float2 _2729 = float2(dot(fa_light_texel(param_6, fa_light_tex, fa_shadow_smp), _2707), dot(fa_light_texel(param_7, fa_light_tex, fa_shadow_smp), _2707)) / float2(_2711);\n    float _2731 = _2729.x;\n    bool _2734 = _2731 < _2613.x;\n    bool _2743;\n    if (!_2734)\n    {\n        _2743 = _2731 > _2613.z;\n    }\n    else\n    {\n        _2743 = _2734;\n    }\n    bool _2752;\n    if (!_2743)\n    {\n        _2752 = _2729.y < _2613.y;\n    }\n    else\n    {\n        _2752 = _2743;\n    }\n    bool _2761;\n    if (!_2752)\n    {\n        _2761 = _2729.y > _2613.w;\n    }\n    else\n    {\n        _2761 = _2752;\n    }\n    if (_2761)\n    {\n        return 1.0;\n    }\n    float _2767 = _2545.x;\n    float _2769;\n    if (_2767 > 0.0)\n    {\n        _2769 = _2767;\n    }\n    else\n    {\n        _2769 = 1.5 * _2630;\n    }\n    float2 param_13 = _2729;\n    float4 param_14 = _2613;\n    float param_15 = _2711 - (_2769 * (1.0 + (0.5 * _2682)));\n    float param_16 = _2630;\n    float param_17 = 1.0;\n    float param_18 = _2618.z * 0.25;\n    float param_19 = (_2630 * fast::min(_2682, 3.0)) * 0.5;\n    float3 param_20 = float3(1.0, _2714, _2618.z);\n    int param_21 = int(_2540.z + 0.5);\n    float param_22 = _2540.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, fa_shadow_smp, gl_FragCoord, _2072, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2072, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3925 = fa_lm.z > 0.5;\n    bool _3931;\n    if (_3925)\n    {\n        int param = li;\n        _3931 = fa_light_baked(param, _365, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3931 = _3925;\n    }\n    if (_3931)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _365, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3955 = fa_light_sample_n(param_2, param_3, param_4, _365, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _5040 = _3955.color;\n    float _5042 = _3955.shadow;\n    if ((_3955.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3955.direction;\n        float _3969 = fa_shadow_factor(param_5, param_6, _365, fa_shadow_smp, gl_FragCoord, _2072, fa_shadow_tex, fa_world_pos);\n        _5042 = _3969;\n        _5040 *= _3969;\n    }\n    else\n    {\n        bool _3980 = _3955.type != 0;\n        bool _3986;\n        if (_3980)\n        {\n            _3986 = _3955.attenuation > 0.0;\n        }\n        else\n        {\n            _3986 = _3980;\n        }\n        if (_3986)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _3955.direction;\n            float _3998 = fa_shadow_local(param_7, param_8, param_9, param_10, _365, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2072, fa_shadow_tex);\n            _5042 = _3998;\n            _5040 *= _3998;\n        }\n    }\n    return LightSample{ _3955.direction, _5040, _3955.attenuation, _5042, _3955._distance, _3955.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2072)\n{\n    if (_2072.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _3018 = int(_2072.fa_shadow_cfg.x + 0.5);\n    float _3028 = dot(world - _2072.fa_shadow_eye.xyz, _2072.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _3033 = _3018 > 0;\n    bool _3042;\n    if (_3033)\n    {\n        int param = _3018 - 1;\n        _3042 = _3028 <= fa_shadow_split_at(param, _2072);\n    }\n    else\n    {\n        _3042 = _3033;\n    }\n    if (_3042)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3048 = _3018 > 1;\n        bool _3055;\n        if (_3048)\n        {\n            _3055 = _3028 > _2072.fa_shadow_split.x;\n        }\n        else\n        {\n            _3055 = _3048;\n        }\n        if (_3055)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3061 = _3018 > 2;\n        bool _3068;\n        if (_3061)\n        {\n            _3068 = _3028 > _2072.fa_shadow_split.y;\n        }\n        else\n        {\n            _3068 = _3061;\n        }\n        if (_3068)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3074 = _3018 > 3;\n        bool _3081;\n        if (_3074)\n        {\n            _3081 = _3028 > _2072.fa_shadow_split.z;\n        }\n        else\n        {\n            _3081 = _3074;\n        }\n        if (_3081)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _365 [[buffer(1)]], constant fa_shadows& _2072 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_light_atlas [[texture(9)]], texture2d<float> fa_lightmap [[texture(10)]], texture2d<float> fa_decal_tex [[texture(11)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4749 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4749 = -_4749;\n    }\n    float3 _4384 = fast::normalize(_365.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _365, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4749, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4384, short(gl_FrontFacing) };\n    Surface _4392 = fa_standard_surface(param_1, _365, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4788 = _4392.albedo;\n    float _4789 = _4392.alpha;\n    float3 _4790 = _4392.normal;\n    float _4791 = _4392.metallic;\n    float _4792 = _4392.roughness;\n    float _4793 = _4392.occlusion;\n    float3 _4794 = _4392.emission;\n    float _4795 = _4392.clearcoat;\n    float _4796 = _4392.clearcoat_roughness;\n    float3 _4797 = _4392.sheen_color;\n    float _4798 = _4392.sheen_roughness;\n    float _4799 = _4392.anisotropy;\n    float _4800 = _4392.anisotropy_rotation;\n    float _4801 = _4392.specular;\n    float _4802 = _4392.ior;\n    float3 _4803 = _4392.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4749, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4384, short(gl_FrontFacing) };\n    Surface param_3 = _4392;\n    surface(param_2, param_3);\n    _4788 = param_3.albedo;\n    _4789 = param_3.alpha;\n    _4790 = param_3.normal;\n    _4791 = param_3.metallic;\n    _4792 = param_3.roughness;\n    _4793 = param_3.occlusion;\n    _4794 = param_3.emission;\n    _4795 = param_3.clearcoat;\n    _4796 = param_3.clearcoat_roughness;\n    _4797 = param_3.sheen_color;\n    _4798 = param_3.sheen_roughness;\n    _4799 = param_3.anisotropy;\n    _4800 = param_3.anisotropy_rotation;\n    _4801 = param_3.specular;\n    _4802 = param_3.ior;\n    _4803 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4749;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _365, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4788 = param_6;\n    _4790 = param_7;\n    float3 result;\n    if (_365.fa_emissive.w > 0.5)\n    {\n        result = _4788;\n    }\n    else\n    {\n        float3 _4430 = _4790;\n        float3 _4431 = fast::normalize(_4430);\n        _4790 = _4431;\n        float3 param_8 = _4431;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _4749, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4384, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _4788, _4789, _4790, _4791, _4792, _4793, _4794, _4795, _4796, _4797, _4798, _4799, _4800, _4801, _4802, _4803 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _365, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11, _365, fa_env_smp, fa_env_tex);\n        int _4450 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4450; ln++)\n        {\n            int param_12 = ln;\n            int _4463 = fa_cl_light(param_12, _365, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            bool _4466 = in.fa_lm.z > 0.5;\n            bool _4472;\n            if (_4466)\n            {\n                int param_13 = _4463;\n                _4472 = fa_light_baked(param_13, _365, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _4472 = _4466;\n            }\n            if (_4472)\n            {\n                continue;\n            }\n            int param_14 = _4463;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _4749;\n            LightSample _4484 = fa_light_shadowed(param_14, param_15, param_16, _365, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2072, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _4749, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4384, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _4788, _4789, _4790, _4791, _4792, _4793, _4794, _4795, _4796, _4797, _4798, _4799, _4800, _4801, _4802, _4803 };\n            LightSample param_19 = _4484;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4499 = result;\n    float3 _4500 = _4499 + _4794;\n    result = _4500;\n    float3 param_20 = _4500;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _2072);\n    bool _4509 = _365.fa_fog.w > 0.0;\n    bool _4516;\n    if (!_4509)\n    {\n        _4516 = _365.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4516 = _4509;\n    }\n    if (_4516)\n    {\n        float3 _4525 = in.fa_world_pos - _365.fa_camera_pos.xyz;\n        float _4531 = dot(_4525, _365.fa_fog_c.xyz);\n        bool _4535 = _365.fa_fog_c.w > 0.5;\n        float _4536;\n        if (_4535)\n        {\n            _4536 = _4531;\n        }\n        else\n        {\n            _4536 = length(_4525);\n        }\n        float _4548 = _4536 - _365.fa_fog_b.x;\n        if (_4548 > 0.0)\n        {\n            float _4557 = _365.fa_fog.w * _4548;\n            float tau = _4557 * _4557;\n            if (_365.fa_fog_b.y > 0.0)\n            {\n                float _4573;\n                if (_4535)\n                {\n                    _4573 = in.fa_world_pos.y - (_365.fa_fog_c.y * _4531);\n                }\n                else\n                {\n                    _4573 = _365.fa_camera_pos.y;\n                }\n                float _4594 = mix(_4573, in.fa_world_pos.y, fast::clamp(_365.fa_fog_b.x / _4536, 0.0, 1.0));\n                float _4598 = in.fa_world_pos.y - _4594;\n                float _4603 = _4594 - _365.fa_fog_b.z;\n                float _4608 = in.fa_world_pos.y - _365.fa_fog_b.z;\n                bool _4611 = _4603 <= 0.0;\n                bool _4612 = !_4611;\n                bool _4618;\n                if (_4612)\n                {\n                    _4618 = _365.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4618 = _4611;\n                }\n                float _4619;\n                if (_4618)\n                {\n                    _4619 = _365.fa_fog_b.y;\n                }\n                else\n                {\n                    _4619 = _365.fa_fog_b.y * exp(-fast::min(_365.fa_fog_b.w * _4603, 80.0));\n                }\n                bool _4646;\n                if (_4612)\n                {\n                    _4646 = _365.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4646 = _4611;\n                }\n                float _4647;\n                if (_4646)\n                {\n                    _4647 = _365.fa_fog_b.y * _4603;\n                }\n                else\n                {\n                    _4647 = (_365.fa_fog_b.y * (1.0 - exp(-fast::min(_365.fa_fog_b.w * _4603, 80.0)))) / _365.fa_fog_b.w;\n                }\n                bool _4672 = _4608 <= 0.0;\n                bool _4679;\n                if (!_4672)\n                {\n                    _4679 = _365.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4679 = _4672;\n                }\n                float _4680;\n                if (_4679)\n                {\n                    _4680 = _365.fa_fog_b.y * _4608;\n                }\n                else\n                {\n                    _4680 = (_365.fa_fog_b.y * (1.0 - exp(-fast::min(_365.fa_fog_b.w * _4608, 80.0)))) / _365.fa_fog_b.w;\n                }\n                float _4707;\n                if (abs(_4598) < 0.001000000047497451305389404296875)\n                {\n                    _4707 = _4619;\n                }\n                else\n                {\n                    _4707 = (_4680 - _4647) / _4598;\n                }\n                tau += (_4548 * fast::max(_4707, 0.0));\n            }\n            result = mix(result, _365.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4789);\n    return out;\n}\n\n",
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
            "inst_name": "_365",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2072",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "msl_texture_n": 7
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
              "msl_texture_n": 8
            }
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 9
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
              "msl_texture_n": 10
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
              "msl_texture_n": 11
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 11,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _785 = base_t;\n    _785.x = _225.x;\n    _785.y = _225.y;\n    _785.z = _225.z;\n    base_t = _785;\n    float4 _241 = (_785 * _213.fa_base_color) * i.vertex_color;\n    float3 _748 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _793 = _279;\n        _793.x = _284.x;\n        _793.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _796 = mrt;\n    _796.x = _313.x;\n    _796.y = _313.y;\n    _796.z = _313.z;\n    mrt = _796;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _753 = _213.fa_layers_a.x;\n    float _754 = _213.fa_layers_a.y;\n    float _757 = _213.fa_layers_a.z;\n    float _756 = _213.fa_layers_b.w;\n    float _759 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _753 *= _355.y;\n            _754 *= _355.z;\n            _756 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _748, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _753, _754, _213.fa_layers_b.xyz, _756, _757, _213.fa_layers_a.w, _759, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _659 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _659, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _659, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _785 = base_t;\n    _785.x = _225.x;\n    _785.y = _225.y;\n    _785.z = _225.z;\n    base_t = _785;\n    float4 _241 = (_785 * _213.fa_base_color) * i.vertex_color;\n    float3 _748 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _793 = _279;\n        _793.x = _284.x;\n        _793.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _796 = mrt;\n    _796.x = _313.x;\n    _796.y = _313.y;\n    _796.z = _313.z;\n    mrt = _796;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _753 = _213.fa_layers_a.x;\n    float _754 = _213.fa_layers_a.y;\n    float _757 = _213.fa_layers_a.z;\n    float _756 = _213.fa_layers_b.w;\n    float _759 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _753 *= _355.y;\n            _754 *= _355.z;\n            _756 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _748, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _753, _754, _213.fa_layers_b.xyz, _756, _757, _213.fa_layers_a.w, _759, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _659 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _659, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _659, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
