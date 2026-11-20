{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "194db57da3c2e45b061059a5d5aaa1ec99bea4d520978217d5e137fe8b76e503",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_267, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nconstant spvUnsafeArray<float, 63> _1571 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _441)\n{\n    bool _446 = _441.fa_cl_info.x < 0.0;\n    bool _453;\n    if (!_446)\n    {\n        _453 = _441.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _453 = _446;\n    }\n    bool _461;\n    if (!_453)\n    {\n        _461 = _441.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _461 = _453;\n    }\n    bool _468;\n    if (!_461)\n    {\n        _468 = _441.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _468 = _461;\n    }\n    bool _475;\n    if (!_468)\n    {\n        _475 = _441.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _475 = _468;\n    }\n    if (_475)\n    {\n        return int2(0);\n    }\n    float4 _485 = float4(world_pos, 1.0);\n    float _492 = dot(_441.fa_cl_vpw, _485);\n    if (!(_492 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _514 = float2(dot(_441.fa_cl_vpx, _485), dot(_441.fa_cl_vpy, _485)) / float2(_492);\n    int _518 = int(_441.fa_cl_grid.x);\n    int _522 = int(_441.fa_cl_grid.y);\n    int param = (int(_441.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_441.fa_cl_fwd.xyz, world_pos) + _441.fa_cl_fwd.w, _441.fa_cl_grid.w) / _441.fa_cl_grid.w) * _441.fa_cl_grid.z)), 0, int(_441.fa_cl_info.y) - 1) * _522) + clamp(int(floor(((_514.y * 0.5) + 0.5) * _441.fa_cl_grid.y)), 0, _522 - 1)) * _518)) + clamp(int(floor(((_514.x * 0.5) + 0.5) * _441.fa_cl_grid.x)), 0, _518 - 1);\n    float4 _593 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_593.x), int(_593.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _441, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_441.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2111 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _441);\n    fa_cl_slot = _2111.x;\n    fa_cl_local = _2111.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2247 = fa_linear_to_srgb(param);\n        c = _2247;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2255 = fa_srgb_to_linear(param_1);\n            c = _2255;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _205;\n    if (bool(i.front_facing))\n    {\n        _205 = i.world_normal;\n    }\n    else\n    {\n        _205 = -i.world_normal;\n    }\n    float3 _229 = fast::normalize(i.world_tangent.xyz - (_205 * dot(_205, i.world_tangent.xyz)));\n    float3 _257 = fast::normalize(((_229 * m.x) + ((cross(_205, _229) * i.world_tangent.w) * m.y)) + (_205 * m.z));\n    float3 _260;\n    if (bool(i.front_facing))\n    {\n        _260 = _257;\n    }\n    else\n    {\n        _260 = -_257;\n    }\n    return _260;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _441, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _441.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2286 = fa_tex_fix(param_2, param_3);\n    float4 _3305 = base_t;\n    _3305.x = _2286.x;\n    _3305.y = _2286.y;\n    _3305.z = _2286.z;\n    base_t = _3305;\n    float4 _2300 = (_3305 * _441.fa_base_color) * i.vertex_color;\n    float3 _3239 = i.world_normal;\n    if (_441.fa_maps.z > 0.5)\n    {\n        float param_4 = _441.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2332 = fa_tex_fix(param_6, param_7);\n        float3 _2336 = (_2332 * 2.0) - float3(1.0);\n        float2 _2341 = _2336.xy * _441.fa_maps.x;\n        float3 _3313 = _2336;\n        _3313.x = _2341.x;\n        _3313.y = _2341.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3313;\n        _3239 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _441.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2370 = fa_tex_fix(param_12, param_13);\n    float4 _3316 = mrt;\n    _3316.x = _2370.x;\n    _3316.y = _2370.y;\n    _3316.z = _2370.z;\n    mrt = _3316;\n    float4 _2398 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _441.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2398.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2410 = fa_tex_fix(param_16, param_17);\n    float param_18 = _441.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2440 = fa_tex_fix(param_20, param_21);\n    float _3244 = _441.fa_layers_a.x;\n    float _3245 = _441.fa_layers_a.y;\n    float _3248 = _441.fa_layers_a.z;\n    float _3247 = _441.fa_layers_b.w;\n    float _3250 = _441.fa_layers_c.x;\n    if (_441.fa_layers_c.z > 0.5)\n    {\n        if (mod(_441.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3244 *= _2410.y;\n            _3245 *= _2410.z;\n            _3247 *= _2398.w;\n        }\n        if (_441.fa_layers_c.z > 1.5)\n        {\n            _3248 *= mrt.x;\n            _3250 *= mrt.w;\n        }\n    }\n    return Surface{ _2300.xyz, _2300.w, _3239, fast::clamp(_441.fa_pbr.x * _2370.z, 0.0, 1.0), fast::clamp(_441.fa_pbr.y * _2370.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_441.fa_maps.y * (_2410.x - 1.0)), _441.fa_emissive.xyz + (_441.fa_model_emissive.xyz * _2440), _3244, _3245, _441.fa_layers_b.xyz, _3247, _3248, _441.fa_layers_a.w, _3250, _441.fa_layers_c.y, _441.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _441, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_441.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _441.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _441, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _441, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1496 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1504 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1507 = int(_1496);\n    int _1510 = int(_1504);\n    float _1520 = _1504 - float(_1510);\n    int _1576 = (_1507 * 9) + _1510;\n    int _1596 = ((_1507 + 1) * 9) + _1510;\n    return mix(mix(_1571[_1576], _1571[_1576 + 1], _1520), mix(_1571[_1596], _1571[_1596 + 1], _1520), _1496 - float(_1507));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _3098 = false;\n    float _3099 = 1.0;\n    float _3100 = 1.0;\n    float _3101 = 1.0;\n    float _3102 = 0.0;\n    float _3103 = 0.0;\n    float _3104 = 0.0;\n    float _3105 = 0.0;\n    float _3107 = 1.0;\n    bool _3108 = false;\n    float3 _3109 = float3(0.0);\n    float _3110 = 1.0;\n    float _3111 = 1.0;\n    float _3112 = 1.0;\n    float _3113 = 0.0;\n    float _3114 = 0.0;\n    float3 _3115 = float3(1.0, 0.0, 0.0);\n    float3 _3116 = float3(0.0, 0.0, 1.0);\n    float _3117 = 1.0;\n    float _3118 = 1.0;\n    float _1651 = fast::clamp(s.specular, 0.0, 1.0);\n    float _1655 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _1660 = (_1651 != 1.0) || (_1655 != 1.5);\n    bool _1670;\n    if (!_1660)\n    {\n        _1670 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _1670 = _1660;\n    }\n    if (_1670)\n    {\n        float _1678 = (_1655 - 1.0) / (_1655 + 1.0);\n        f0 = mix(fast::min(float3(_1678 * _1678) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _1651, s.albedo, float3(metallic));\n        _3099 = mix(_1651, 1.0, metallic);\n        _3098 = true;\n    }\n    float _1706 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_1706 > 0.0)\n    {\n        float _1714 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3102 = _1706;\n        _3103 = _1714;\n        float _1721 = _1714 * _1714;\n        _3104 = _1721;\n        _3105 = _1721 * _1721;\n        float _1733 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3107 = _1733;\n        _3100 = 1.0 - (_1706 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _1733, 0.0, 1.0), 5.0))));\n        _3098 = true;\n    }\n    float3 _1753 = fast::max(s.sheen_color, float3(0.0));\n    float _1762 = fast::max(_1753.x, fast::max(_1753.y, _1753.z));\n    if (_1762 > 0.0)\n    {\n        float _1770 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3108 = true;\n        _3109 = _1753;\n        _3110 = _1770;\n        _3111 = _1770 * _1770;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1770;\n        float _1787 = fa_sheen_albedo(param, param_1);\n        _3113 = _1787;\n        _3112 = 1.0 - fast::min(_1762 * _1787, 1.0);\n        _3098 = true;\n    }\n    _3101 = _3100 * _3112;\n    float _1806 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_1806 != 0.0)\n    {\n        float3 _1821 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1821;\n        if (dot(_1821, _1821) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _1839 = t;\n        float3 _1840 = fast::normalize(_1839);\n        t = _1840;\n        float3 _1865 = fast::normalize((_1840 * cos(s.anisotropy_rotation)) + ((cross(n, _1840) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3115 = _1865;\n        _3116 = cross(n, _1865);\n        float _1875 = roughness * roughness;\n        float _1881 = mix(_1875, 1.0, _1806 * _1806);\n        bool _1883 = _1806 > 0.0;\n        _3117 = _1883 ? _1881 : _1875;\n        _3118 = _1883 ? _1875 : _1881;\n        _3114 = _1806;\n        _3098 = true;\n    }\n    return FaLayers{ short(_3098), _3099, _3100, _3101, _3102, _3103, _3104, _3105, i.world_normal, _3107, short(_3108), _3109, _3110, _3111, _3112, _3113, _3114, _3115, _3116, _3117, _3118 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1428 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1431 = _1428.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1431 * _1431, exp2((-9.27999973297119140625) * ndv)) * _1431) + _1428.y)) + _1428.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _441, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_441.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _441.fa_env_horizon.w)).xyz;\n    }\n    float _1333 = rough * rough;\n    float _1363 = 0.60000002384185791015625 * _1333;\n    return mix(mix(_441.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_441.fa_env_horizon.xyz, _441.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1333)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1363, 0.0500000007450580596923828125 + _1363, d.y))), ((_441.fa_env_sky.xyz + _441.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1333 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _441, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _1916;\n        if (L.aniso >= 0.0)\n        {\n            _1916 = L.b;\n        }\n        else\n        {\n            _1916 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_1916, v), _1916), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1949 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _441, fa_env_tex, fa_env_smp) * ((f0 * _1949.x) + (float3(L.f90) * _1949.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _441, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2004 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _441, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _2004.x) + _2004.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _441, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1470 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _441, fa_env_tex, fa_env_smp) * ((f0 * _1470.x) + float3(_1470.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _441, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float _2033 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _2037 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _2044 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_2033));\n    float3 f0 = _2044;\n    float3 _2048 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2048;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2033;\n    float param_5 = _2037;\n    float3 param_6 = _2044;\n    FaLayers _2065 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2065.on)\n    {\n        FaLayers param_7 = _2065;\n        float3 param_8 = _2048;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2037;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _441, fa_env_tex, fa_env_smp) * s.occlusion;\n    }\n    float3 param_12 = _2048;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2037;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _441, fa_env_tex, fa_env_smp) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor, constant fa_mesh_fs_params& _441, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1, _441, fa_env_tex, fa_env_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _441)\n{\n    int param = (int(_441.fa_cl_info.x) + int(_441.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _441, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _441);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _316 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _322 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _325 = _322.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _331 = _325 < 0.5;\n    float3 l;\n    if (_331)\n    {\n        l = fast::normalize(_316.xyz);\n    }\n    else\n    {\n        float3 _343 = _316.xyz - world_pos;\n        float _345 = length(_343);\n        dist = _345;\n        l = _343 / float3(fast::max(_345, 9.9999997473787516355514526367188e-05));\n        float _360 = _345 / fast::max(_316.w, 0.001000000047497451305389404296875);\n        float _366 = fast::clamp(1.0 - (_360 * _360), 0.0, 1.0);\n        atten = _366 * _366;\n        if (_325 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _380 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _390 = _380.w;\n            int param_3 = (li * 4) + 3;\n            float4 _396 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _397 = _396.x;\n            float cos_inner = _397;\n            if (_397 > 1.5)\n            {\n                cos_inner = mix(_390, 1.0, 0.25);\n            }\n            atten *= smoothstep(_390, cos_inner, dot(-l, fast::normalize(_380.xyz)));\n        }\n    }\n    int _427;\n    if (_331)\n    {\n        _427 = 0;\n    }\n    else\n    {\n        _427 = (_325 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _322.xyz * atten, atten, 1.0, dist, _427 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _677)\n{\n    float _667;\n    if (i == 0)\n    {\n        _667 = _677.fa_shadow_split.x;\n    }\n    else\n    {\n        float _683;\n        if (i == 1)\n        {\n            _683 = _677.fa_shadow_split.y;\n        }\n        else\n        {\n            float _691;\n            if (i == 2)\n            {\n                _691 = _677.fa_shadow_split.z;\n            }\n            else\n            {\n                _691 = _677.fa_shadow_split.w;\n            }\n            _683 = _691;\n        }\n        _667 = _683;\n    }\n    return _667;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _655 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_655), sin(_655)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _677, texture2d<float> fa_shadow_tex)\n{\n    float _729 = fast::max(_677.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _734 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _740 = sqrt(1.0 - (_734 * _734));\n    float _748 = fast::min(_740 / fast::max(_734, 0.20000000298023223876953125), 4.0);\n    float _753;\n    if (_677.fa_shadow_bias.y > 0.0)\n    {\n        _753 = _677.fa_shadow_bias.y;\n    }\n    else\n    {\n        _753 = 1.5 * _677.fa_shadow_info[ci].x;\n    }\n    float4 _778 = _677.fa_shadow_mat[ci] * float4(world + (n * (_753 * _740)), 1.0);\n    float _785 = _778.x;\n    bool _788 = _785 < _677.fa_shadow_rect[ci].x;\n    bool _797;\n    if (!_788)\n    {\n        _797 = _785 > _677.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _797 = _788;\n    }\n    bool _806;\n    if (!_797)\n    {\n        _806 = _778.y < _677.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _806 = _797;\n    }\n    bool _815;\n    if (!_806)\n    {\n        _815 = _778.y > _677.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _815 = _806;\n    }\n    bool _822;\n    if (!_815)\n    {\n        _822 = _778.z > 1.0;\n    }\n    else\n    {\n        _822 = _815;\n    }\n    if (_822)\n    {\n        return -1.0;\n    }\n    float _831;\n    if (_677.fa_shadow_bias.x > 0.0)\n    {\n        _831 = _677.fa_shadow_bias.x;\n    }\n    else\n    {\n        _831 = 1.5 * _677.fa_shadow_info[ci].x;\n    }\n    float _850 = _778.z - ((_831 * (1.0 + (0.5 * _748))) / _729);\n    float _859 = ((_677.fa_shadow_info[ci].x * fast::min(_748, 3.0)) * 0.5) / _729;\n    int _868 = int(_677.fa_shadow_cfg.z + 0.5);\n    if (_868 == 1)\n    {\n        float2 param = _778.xy;\n        float4 param_1 = _677.fa_shadow_rect[ci];\n        float _879 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_850 <= _879);\n    }\n    float _886 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _889 = _868 == 2;\n    if (_889)\n    {\n        float _903 = fast::clamp(((_677.fa_shadow_cfg.w * _729) * 0.25) / _677.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _886;\n            float2 _922 = fa_shadow_vogel(param_2, param_3, param_4) * _903;\n            float2 param_5 = _778.xy + (_922 * _677.fa_shadow_bias.zw);\n            float4 param_6 = _677.fa_shadow_rect[ci];\n            float _933 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_933 < (_850 - (length(_922) * _859)))\n            {\n                sum += _933;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_850 - (sum / cnt), 0.0) * _729) * _677.fa_shadow_cfg.w) / _677.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _977 = _889 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _977; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _977;\n        float param_9 = _886;\n        float2 _996 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _778.xy + (_996 * _677.fa_shadow_bias.zw);\n        float4 param_11 = _677.fa_shadow_rect[ci];\n        float _1007 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_850 - (length(_996) * _859)) <= _1007);\n    }\n    return lit / float(_977);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _441, thread float4& gl_FragCoord, constant fa_shadows& _677, texture2d<float> fa_shadow_tex)\n{\n    if (_441.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1037 = int(_677.fa_shadow_cfg.x + 0.5);\n    if (_1037 < 1)\n    {\n        return 1.0;\n    }\n    float _1053 = dot(world - _677.fa_shadow_eye.xyz, _677.fa_shadow_fwd.xyz);\n    int param = _1037 - 1;\n    if (_1053 > fa_shadow_split_at(param, _677))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1065 = _1037 > 1;\n    bool _1072;\n    if (_1065)\n    {\n        _1072 = _1053 > _677.fa_shadow_split.x;\n    }\n    else\n    {\n        _1072 = _1065;\n    }\n    if (_1072)\n    {\n        ci = 1;\n    }\n    bool _1076 = _1037 > 2;\n    bool _1083;\n    if (_1076)\n    {\n        _1083 = _1053 > _677.fa_shadow_split.y;\n    }\n    else\n    {\n        _1083 = _1076;\n    }\n    if (_1083)\n    {\n        ci = 2;\n    }\n    bool _1087 = _1037 > 3;\n    bool _1094;\n    if (_1087)\n    {\n        _1094 = _1053 > _677.fa_shadow_split.z;\n    }\n    else\n    {\n        _1094 = _1087;\n    }\n    if (_1094)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1037)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1120 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _677, fa_shadow_tex);\n        s = _1120;\n        if (_1120 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_677.fa_shadow_cfg.y > 0.0)\n    {\n        float _1145;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1145 = fa_shadow_split_at(param_5, _677);\n        }\n        else\n        {\n            _1145 = _677.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1164 = _677.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _677) - _1145, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1175 = fast::clamp((_1053 - (fa_shadow_split_at(param_7, _677) - _1164)) / _1164, 0.0, 1.0);\n        if (_1175 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1037)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1196 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _677, fa_shadow_tex);\n                s2 = _1196;\n                if (_1196 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1175);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _441, thread float4& gl_FragCoord, constant fa_shadows& _677, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _441, gl_FragCoord, _677, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _441, thread float4& gl_FragCoord, constant fa_shadows& _677, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _2138 = fa_lm.z > 0.5;\n    bool _2144;\n    if (_2138)\n    {\n        int param = li;\n        _2144 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2144 = _2138;\n    }\n    if (_2144)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2166 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _3224 = _2166.direction;\n    float3 _3219 = _2166.color;\n    float _3221 = _2166.shadow;\n    int _3229 = _2166.type;\n    if ((_3229 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3224;\n        float _2180 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _441, gl_FragCoord, _677, fa_shadow_tex, fa_world_pos);\n        _3221 = _2180;\n        _3219 *= _2180;\n    }\n    return LightSample{ _3224, _3219, _2166.attenuation, _3221, _2166._distance, _3229 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _677)\n{\n    if (_677.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1220 = int(_677.fa_shadow_cfg.x + 0.5);\n    float _1230 = dot(world - _677.fa_shadow_eye.xyz, _677.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1235 = _1220 > 0;\n    bool _1244;\n    if (_1235)\n    {\n        int param = _1220 - 1;\n        _1244 = _1230 <= fa_shadow_split_at(param, _677);\n    }\n    else\n    {\n        _1244 = _1235;\n    }\n    if (_1244)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1251 = _1220 > 1;\n        bool _1258;\n        if (_1251)\n        {\n            _1258 = _1230 > _677.fa_shadow_split.x;\n        }\n        else\n        {\n            _1258 = _1251;\n        }\n        if (_1258)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1264 = _1220 > 2;\n        bool _1271;\n        if (_1264)\n        {\n            _1271 = _1230 > _677.fa_shadow_split.y;\n        }\n        else\n        {\n            _1271 = _1264;\n        }\n        if (_1271)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1277 = _1220 > 3;\n        bool _1284;\n        if (_1277)\n        {\n            _1284 = _1230 > _677.fa_shadow_split.z;\n        }\n        else\n        {\n            _1284 = _1277;\n        }\n        if (_1284)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _441 [[buffer(1)]], constant fa_shadows& _677 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2928 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2928 = -_2928;\n    }\n    float3 _2580 = fast::normalize(_441.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _441, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2928, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2580, short(gl_FrontFacing) };\n    Surface _2588 = fa_standard_surface(param_1, _441, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2967 = _2588.albedo;\n    float _2968 = _2588.alpha;\n    float3 _2969 = _2588.normal;\n    float _2970 = _2588.metallic;\n    float _2971 = _2588.roughness;\n    float _2972 = _2588.occlusion;\n    float3 _2973 = _2588.emission;\n    float _2974 = _2588.clearcoat;\n    float _2975 = _2588.clearcoat_roughness;\n    float3 _2976 = _2588.sheen_color;\n    float _2977 = _2588.sheen_roughness;\n    float _2978 = _2588.anisotropy;\n    float _2979 = _2588.anisotropy_rotation;\n    float _2980 = _2588.specular;\n    float _2981 = _2588.ior;\n    float3 _2982 = _2588.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2928, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2580, short(gl_FrontFacing) };\n    Surface param_3 = _2588;\n    surface(param_2, param_3);\n    _2967 = param_3.albedo;\n    _2968 = param_3.alpha;\n    _2969 = param_3.normal;\n    _2970 = param_3.metallic;\n    _2971 = param_3.roughness;\n    _2972 = param_3.occlusion;\n    _2973 = param_3.emission;\n    _2974 = param_3.clearcoat;\n    _2975 = param_3.clearcoat_roughness;\n    _2976 = param_3.sheen_color;\n    _2977 = param_3.sheen_roughness;\n    _2978 = param_3.anisotropy;\n    _2979 = param_3.anisotropy_rotation;\n    _2980 = param_3.specular;\n    _2981 = param_3.ior;\n    _2982 = param_3.specular_color;\n    float3 result;\n    if (_441.fa_emissive.w > 0.5)\n    {\n        result = _2967;\n    }\n    else\n    {\n        float3 _2609 = _2969;\n        float3 _2610 = fast::normalize(_2609);\n        _2969 = _2610;\n        float3 param_4 = _2610;\n        SurfaceInput param_5 = SurfaceInput{ in.fa_world_pos, _2928, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2580, short(gl_FrontFacing) };\n        Surface param_6 = Surface{ _2967, _2968, _2969, _2970, _2971, _2972, _2973, _2974, _2975, _2976, _2977, _2978, _2979, _2980, _2981, _2982 };\n        float3 param_7 = fa_indirect_diffuse(param_4, _441, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_5, param_6, param_7, _441, fa_env_tex, fa_env_smp);\n        int _2629 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2629; ln++)\n        {\n            int param_8 = ln;\n            int _2642 = fa_cl_light(param_8, fa_light_tex, fa_shadow_smp, _441, fa_cl_ndir, fa_cl_slot);\n            bool _2645 = in.fa_lm.z > 0.5;\n            bool _2651;\n            if (_2645)\n            {\n                int param_9 = _2642;\n                _2651 = fa_light_baked(param_9, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _2651 = _2645;\n            }\n            if (_2651)\n            {\n                continue;\n            }\n            int param_10 = _2642;\n            float3 param_11 = in.fa_world_pos;\n            float3 param_12 = _2928;\n            SurfaceInput param_13 = SurfaceInput{ in.fa_world_pos, _2928, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2580, short(gl_FrontFacing) };\n            Surface param_14 = Surface{ _2967, _2968, _2969, _2970, _2971, _2972, _2973, _2974, _2975, _2976, _2977, _2978, _2979, _2980, _2981, _2982 };\n            LightSample param_15 = fa_light_shadowed(param_10, param_11, param_12, fa_light_tex, fa_shadow_smp, _441, gl_FragCoord, _677, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            lit += light(param_13, param_14, param_15);\n        }\n        result = lit;\n    }\n    float3 _2678 = result;\n    float3 _2679 = _2678 + _2973;\n    result = _2679;\n    float3 param_16 = _2679;\n    float3 param_17 = in.fa_world_pos;\n    result = fa_shadow_debug(param_16, param_17, _677);\n    bool _2688 = _441.fa_fog.w > 0.0;\n    bool _2695;\n    if (!_2688)\n    {\n        _2695 = _441.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2695 = _2688;\n    }\n    if (_2695)\n    {\n        float3 _2704 = in.fa_world_pos - _441.fa_camera_pos.xyz;\n        float _2710 = dot(_2704, _441.fa_fog_c.xyz);\n        bool _2714 = _441.fa_fog_c.w > 0.5;\n        float _2715;\n        if (_2714)\n        {\n            _2715 = _2710;\n        }\n        else\n        {\n            _2715 = length(_2704);\n        }\n        float _2727 = _2715 - _441.fa_fog_b.x;\n        if (_2727 > 0.0)\n        {\n            float _2736 = _441.fa_fog.w * _2727;\n            float tau = _2736 * _2736;\n            if (_441.fa_fog_b.y > 0.0)\n            {\n                float _2752;\n                if (_2714)\n                {\n                    _2752 = in.fa_world_pos.y - (_441.fa_fog_c.y * _2710);\n                }\n                else\n                {\n                    _2752 = _441.fa_camera_pos.y;\n                }\n                float _2773 = mix(_2752, in.fa_world_pos.y, fast::clamp(_441.fa_fog_b.x / _2715, 0.0, 1.0));\n                float _2777 = in.fa_world_pos.y - _2773;\n                float _2782 = _2773 - _441.fa_fog_b.z;\n                float _2787 = in.fa_world_pos.y - _441.fa_fog_b.z;\n                bool _2790 = _2782 <= 0.0;\n                bool _2791 = !_2790;\n                bool _2797;\n                if (_2791)\n                {\n                    _2797 = _441.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2797 = _2790;\n                }\n                float _2798;\n                if (_2797)\n                {\n                    _2798 = _441.fa_fog_b.y;\n                }\n                else\n                {\n                    _2798 = _441.fa_fog_b.y * exp(-fast::min(_441.fa_fog_b.w * _2782, 80.0));\n                }\n                bool _2825;\n                if (_2791)\n                {\n                    _2825 = _441.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2825 = _2790;\n                }\n                float _2826;\n                if (_2825)\n                {\n                    _2826 = _441.fa_fog_b.y * _2782;\n                }\n                else\n                {\n                    _2826 = (_441.fa_fog_b.y * (1.0 - exp(-fast::min(_441.fa_fog_b.w * _2782, 80.0)))) / _441.fa_fog_b.w;\n                }\n                bool _2851 = _2787 <= 0.0;\n                bool _2858;\n                if (!_2851)\n                {\n                    _2858 = _441.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2858 = _2851;\n                }\n                float _2859;\n                if (_2858)\n                {\n                    _2859 = _441.fa_fog_b.y * _2787;\n                }\n                else\n                {\n                    _2859 = (_441.fa_fog_b.y * (1.0 - exp(-fast::min(_441.fa_fog_b.w * _2787, 80.0)))) / _441.fa_fog_b.w;\n                }\n                float _2886;\n                if (abs(_2777) < 0.001000000047497451305389404296875)\n                {\n                    _2886 = _2798;\n                }\n                else\n                {\n                    _2886 = (_2859 - _2826) / _2777;\n                }\n                tau += (_2727 * fast::max(_2886, 0.0));\n            }\n            result = mix(result, _441.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2968);\n    return out;\n}\n\n",
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
            "inst_name": "_441",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_677",
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
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nconstant spvUnsafeArray<float, 63> _1571 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _441)\n{\n    bool _446 = _441.fa_cl_info.x < 0.0;\n    bool _453;\n    if (!_446)\n    {\n        _453 = _441.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _453 = _446;\n    }\n    bool _461;\n    if (!_453)\n    {\n        _461 = _441.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _461 = _453;\n    }\n    bool _468;\n    if (!_461)\n    {\n        _468 = _441.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _468 = _461;\n    }\n    bool _475;\n    if (!_468)\n    {\n        _475 = _441.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _475 = _468;\n    }\n    if (_475)\n    {\n        return int2(0);\n    }\n    float4 _485 = float4(world_pos, 1.0);\n    float _492 = dot(_441.fa_cl_vpw, _485);\n    if (!(_492 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _514 = float2(dot(_441.fa_cl_vpx, _485), dot(_441.fa_cl_vpy, _485)) / float2(_492);\n    int _518 = int(_441.fa_cl_grid.x);\n    int _522 = int(_441.fa_cl_grid.y);\n    int param = (int(_441.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_441.fa_cl_fwd.xyz, world_pos) + _441.fa_cl_fwd.w, _441.fa_cl_grid.w) / _441.fa_cl_grid.w) * _441.fa_cl_grid.z)), 0, int(_441.fa_cl_info.y) - 1) * _522) + clamp(int(floor(((_514.y * 0.5) + 0.5) * _441.fa_cl_grid.y)), 0, _522 - 1)) * _518)) + clamp(int(floor(((_514.x * 0.5) + 0.5) * _441.fa_cl_grid.x)), 0, _518 - 1);\n    float4 _593 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_593.x), int(_593.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _441, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_441.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2111 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _441);\n    fa_cl_slot = _2111.x;\n    fa_cl_local = _2111.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2247 = fa_linear_to_srgb(param);\n        c = _2247;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2255 = fa_srgb_to_linear(param_1);\n            c = _2255;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _205;\n    if (bool(i.front_facing))\n    {\n        _205 = i.world_normal;\n    }\n    else\n    {\n        _205 = -i.world_normal;\n    }\n    float3 _229 = fast::normalize(i.world_tangent.xyz - (_205 * dot(_205, i.world_tangent.xyz)));\n    float3 _257 = fast::normalize(((_229 * m.x) + ((cross(_205, _229) * i.world_tangent.w) * m.y)) + (_205 * m.z));\n    float3 _260;\n    if (bool(i.front_facing))\n    {\n        _260 = _257;\n    }\n    else\n    {\n        _260 = -_257;\n    }\n    return _260;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _441, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _441.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2286 = fa_tex_fix(param_2, param_3);\n    float4 _3305 = base_t;\n    _3305.x = _2286.x;\n    _3305.y = _2286.y;\n    _3305.z = _2286.z;\n    base_t = _3305;\n    float4 _2300 = (_3305 * _441.fa_base_color) * i.vertex_color;\n    float3 _3239 = i.world_normal;\n    if (_441.fa_maps.z > 0.5)\n    {\n        float param_4 = _441.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2332 = fa_tex_fix(param_6, param_7);\n        float3 _2336 = (_2332 * 2.0) - float3(1.0);\n        float2 _2341 = _2336.xy * _441.fa_maps.x;\n        float3 _3313 = _2336;\n        _3313.x = _2341.x;\n        _3313.y = _2341.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3313;\n        _3239 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _441.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2370 = fa_tex_fix(param_12, param_13);\n    float4 _3316 = mrt;\n    _3316.x = _2370.x;\n    _3316.y = _2370.y;\n    _3316.z = _2370.z;\n    mrt = _3316;\n    float4 _2398 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _441.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2398.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2410 = fa_tex_fix(param_16, param_17);\n    float param_18 = _441.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2440 = fa_tex_fix(param_20, param_21);\n    float _3244 = _441.fa_layers_a.x;\n    float _3245 = _441.fa_layers_a.y;\n    float _3248 = _441.fa_layers_a.z;\n    float _3247 = _441.fa_layers_b.w;\n    float _3250 = _441.fa_layers_c.x;\n    if (_441.fa_layers_c.z > 0.5)\n    {\n        if (mod(_441.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3244 *= _2410.y;\n            _3245 *= _2410.z;\n            _3247 *= _2398.w;\n        }\n        if (_441.fa_layers_c.z > 1.5)\n        {\n            _3248 *= mrt.x;\n            _3250 *= mrt.w;\n        }\n    }\n    return Surface{ _2300.xyz, _2300.w, _3239, fast::clamp(_441.fa_pbr.x * _2370.z, 0.0, 1.0), fast::clamp(_441.fa_pbr.y * _2370.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_441.fa_maps.y * (_2410.x - 1.0)), _441.fa_emissive.xyz + (_441.fa_model_emissive.xyz * _2440), _3244, _3245, _441.fa_layers_b.xyz, _3247, _3248, _441.fa_layers_a.w, _3250, _441.fa_layers_c.y, _441.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _441, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_441.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _441.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _441, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _441, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1496 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1504 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1507 = int(_1496);\n    int _1510 = int(_1504);\n    float _1520 = _1504 - float(_1510);\n    int _1576 = (_1507 * 9) + _1510;\n    int _1596 = ((_1507 + 1) * 9) + _1510;\n    return mix(mix(_1571[_1576], _1571[_1576 + 1], _1520), mix(_1571[_1596], _1571[_1596 + 1], _1520), _1496 - float(_1507));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _3098 = false;\n    float _3099 = 1.0;\n    float _3100 = 1.0;\n    float _3101 = 1.0;\n    float _3102 = 0.0;\n    float _3103 = 0.0;\n    float _3104 = 0.0;\n    float _3105 = 0.0;\n    float _3107 = 1.0;\n    bool _3108 = false;\n    float3 _3109 = float3(0.0);\n    float _3110 = 1.0;\n    float _3111 = 1.0;\n    float _3112 = 1.0;\n    float _3113 = 0.0;\n    float _3114 = 0.0;\n    float3 _3115 = float3(1.0, 0.0, 0.0);\n    float3 _3116 = float3(0.0, 0.0, 1.0);\n    float _3117 = 1.0;\n    float _3118 = 1.0;\n    float _1651 = fast::clamp(s.specular, 0.0, 1.0);\n    float _1655 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _1660 = (_1651 != 1.0) || (_1655 != 1.5);\n    bool _1670;\n    if (!_1660)\n    {\n        _1670 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _1670 = _1660;\n    }\n    if (_1670)\n    {\n        float _1678 = (_1655 - 1.0) / (_1655 + 1.0);\n        f0 = mix(fast::min(float3(_1678 * _1678) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _1651, s.albedo, float3(metallic));\n        _3099 = mix(_1651, 1.0, metallic);\n        _3098 = true;\n    }\n    float _1706 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_1706 > 0.0)\n    {\n        float _1714 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3102 = _1706;\n        _3103 = _1714;\n        float _1721 = _1714 * _1714;\n        _3104 = _1721;\n        _3105 = _1721 * _1721;\n        float _1733 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3107 = _1733;\n        _3100 = 1.0 - (_1706 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _1733, 0.0, 1.0), 5.0))));\n        _3098 = true;\n    }\n    float3 _1753 = fast::max(s.sheen_color, float3(0.0));\n    float _1762 = fast::max(_1753.x, fast::max(_1753.y, _1753.z));\n    if (_1762 > 0.0)\n    {\n        float _1770 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3108 = true;\n        _3109 = _1753;\n        _3110 = _1770;\n        _3111 = _1770 * _1770;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1770;\n        float _1787 = fa_sheen_albedo(param, param_1);\n        _3113 = _1787;\n        _3112 = 1.0 - fast::min(_1762 * _1787, 1.0);\n        _3098 = true;\n    }\n    _3101 = _3100 * _3112;\n    float _1806 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_1806 != 0.0)\n    {\n        float3 _1821 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1821;\n        if (dot(_1821, _1821) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _1839 = t;\n        float3 _1840 = fast::normalize(_1839);\n        t = _1840;\n        float3 _1865 = fast::normalize((_1840 * cos(s.anisotropy_rotation)) + ((cross(n, _1840) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3115 = _1865;\n        _3116 = cross(n, _1865);\n        float _1875 = roughness * roughness;\n        float _1881 = mix(_1875, 1.0, _1806 * _1806);\n        bool _1883 = _1806 > 0.0;\n        _3117 = _1883 ? _1881 : _1875;\n        _3118 = _1883 ? _1875 : _1881;\n        _3114 = _1806;\n        _3098 = true;\n    }\n    return FaLayers{ short(_3098), _3099, _3100, _3101, _3102, _3103, _3104, _3105, i.world_normal, _3107, short(_3108), _3109, _3110, _3111, _3112, _3113, _3114, _3115, _3116, _3117, _3118 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1428 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1431 = _1428.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1431 * _1431, exp2((-9.27999973297119140625) * ndv)) * _1431) + _1428.y)) + _1428.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _441, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_441.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _441.fa_env_horizon.w)).xyz;\n    }\n    float _1333 = rough * rough;\n    float _1363 = 0.60000002384185791015625 * _1333;\n    return mix(mix(_441.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_441.fa_env_horizon.xyz, _441.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1333)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1363, 0.0500000007450580596923828125 + _1363, d.y))), ((_441.fa_env_sky.xyz + _441.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1333 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _441, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _1916;\n        if (L.aniso >= 0.0)\n        {\n            _1916 = L.b;\n        }\n        else\n        {\n            _1916 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_1916, v), _1916), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1949 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _441, fa_env_tex, fa_env_smp) * ((f0 * _1949.x) + (float3(L.f90) * _1949.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _441, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2004 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _441, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _2004.x) + _2004.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _441, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1470 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _441, fa_env_tex, fa_env_smp) * ((f0 * _1470.x) + float3(_1470.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _441, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float _2033 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _2037 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _2044 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_2033));\n    float3 f0 = _2044;\n    float3 _2048 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2048;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2033;\n    float param_5 = _2037;\n    float3 param_6 = _2044;\n    FaLayers _2065 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2065.on)\n    {\n        FaLayers param_7 = _2065;\n        float3 param_8 = _2048;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2037;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _441, fa_env_tex, fa_env_smp) * s.occlusion;\n    }\n    float3 param_12 = _2048;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2037;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _441, fa_env_tex, fa_env_smp) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor, constant fa_mesh_fs_params& _441, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1, _441, fa_env_tex, fa_env_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _441)\n{\n    int param = (int(_441.fa_cl_info.x) + int(_441.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _441, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _441);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _316 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _322 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _325 = _322.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _331 = _325 < 0.5;\n    float3 l;\n    if (_331)\n    {\n        l = fast::normalize(_316.xyz);\n    }\n    else\n    {\n        float3 _343 = _316.xyz - world_pos;\n        float _345 = length(_343);\n        dist = _345;\n        l = _343 / float3(fast::max(_345, 9.9999997473787516355514526367188e-05));\n        float _360 = _345 / fast::max(_316.w, 0.001000000047497451305389404296875);\n        float _366 = fast::clamp(1.0 - (_360 * _360), 0.0, 1.0);\n        atten = _366 * _366;\n        if (_325 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _380 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _390 = _380.w;\n            int param_3 = (li * 4) + 3;\n            float4 _396 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _397 = _396.x;\n            float cos_inner = _397;\n            if (_397 > 1.5)\n            {\n                cos_inner = mix(_390, 1.0, 0.25);\n            }\n            atten *= smoothstep(_390, cos_inner, dot(-l, fast::normalize(_380.xyz)));\n        }\n    }\n    int _427;\n    if (_331)\n    {\n        _427 = 0;\n    }\n    else\n    {\n        _427 = (_325 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _322.xyz * atten, atten, 1.0, dist, _427 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _677)\n{\n    float _667;\n    if (i == 0)\n    {\n        _667 = _677.fa_shadow_split.x;\n    }\n    else\n    {\n        float _683;\n        if (i == 1)\n        {\n            _683 = _677.fa_shadow_split.y;\n        }\n        else\n        {\n            float _691;\n            if (i == 2)\n            {\n                _691 = _677.fa_shadow_split.z;\n            }\n            else\n            {\n                _691 = _677.fa_shadow_split.w;\n            }\n            _683 = _691;\n        }\n        _667 = _683;\n    }\n    return _667;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _655 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_655), sin(_655)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _677, texture2d<float> fa_shadow_tex)\n{\n    float _729 = fast::max(_677.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _734 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _740 = sqrt(1.0 - (_734 * _734));\n    float _748 = fast::min(_740 / fast::max(_734, 0.20000000298023223876953125), 4.0);\n    float _753;\n    if (_677.fa_shadow_bias.y > 0.0)\n    {\n        _753 = _677.fa_shadow_bias.y;\n    }\n    else\n    {\n        _753 = 1.5 * _677.fa_shadow_info[ci].x;\n    }\n    float4 _778 = _677.fa_shadow_mat[ci] * float4(world + (n * (_753 * _740)), 1.0);\n    float _785 = _778.x;\n    bool _788 = _785 < _677.fa_shadow_rect[ci].x;\n    bool _797;\n    if (!_788)\n    {\n        _797 = _785 > _677.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _797 = _788;\n    }\n    bool _806;\n    if (!_797)\n    {\n        _806 = _778.y < _677.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _806 = _797;\n    }\n    bool _815;\n    if (!_806)\n    {\n        _815 = _778.y > _677.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _815 = _806;\n    }\n    bool _822;\n    if (!_815)\n    {\n        _822 = _778.z > 1.0;\n    }\n    else\n    {\n        _822 = _815;\n    }\n    if (_822)\n    {\n        return -1.0;\n    }\n    float _831;\n    if (_677.fa_shadow_bias.x > 0.0)\n    {\n        _831 = _677.fa_shadow_bias.x;\n    }\n    else\n    {\n        _831 = 1.5 * _677.fa_shadow_info[ci].x;\n    }\n    float _850 = _778.z - ((_831 * (1.0 + (0.5 * _748))) / _729);\n    float _859 = ((_677.fa_shadow_info[ci].x * fast::min(_748, 3.0)) * 0.5) / _729;\n    int _868 = int(_677.fa_shadow_cfg.z + 0.5);\n    if (_868 == 1)\n    {\n        float2 param = _778.xy;\n        float4 param_1 = _677.fa_shadow_rect[ci];\n        float _879 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_850 <= _879);\n    }\n    float _886 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _889 = _868 == 2;\n    if (_889)\n    {\n        float _903 = fast::clamp(((_677.fa_shadow_cfg.w * _729) * 0.25) / _677.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _886;\n            float2 _922 = fa_shadow_vogel(param_2, param_3, param_4) * _903;\n            float2 param_5 = _778.xy + (_922 * _677.fa_shadow_bias.zw);\n            float4 param_6 = _677.fa_shadow_rect[ci];\n            float _933 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_933 < (_850 - (length(_922) * _859)))\n            {\n                sum += _933;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_850 - (sum / cnt), 0.0) * _729) * _677.fa_shadow_cfg.w) / _677.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _977 = _889 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _977; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _977;\n        float param_9 = _886;\n        float2 _996 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _778.xy + (_996 * _677.fa_shadow_bias.zw);\n        float4 param_11 = _677.fa_shadow_rect[ci];\n        float _1007 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_850 - (length(_996) * _859)) <= _1007);\n    }\n    return lit / float(_977);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _441, thread float4& gl_FragCoord, constant fa_shadows& _677, texture2d<float> fa_shadow_tex)\n{\n    if (_441.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1037 = int(_677.fa_shadow_cfg.x + 0.5);\n    if (_1037 < 1)\n    {\n        return 1.0;\n    }\n    float _1053 = dot(world - _677.fa_shadow_eye.xyz, _677.fa_shadow_fwd.xyz);\n    int param = _1037 - 1;\n    if (_1053 > fa_shadow_split_at(param, _677))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1065 = _1037 > 1;\n    bool _1072;\n    if (_1065)\n    {\n        _1072 = _1053 > _677.fa_shadow_split.x;\n    }\n    else\n    {\n        _1072 = _1065;\n    }\n    if (_1072)\n    {\n        ci = 1;\n    }\n    bool _1076 = _1037 > 2;\n    bool _1083;\n    if (_1076)\n    {\n        _1083 = _1053 > _677.fa_shadow_split.y;\n    }\n    else\n    {\n        _1083 = _1076;\n    }\n    if (_1083)\n    {\n        ci = 2;\n    }\n    bool _1087 = _1037 > 3;\n    bool _1094;\n    if (_1087)\n    {\n        _1094 = _1053 > _677.fa_shadow_split.z;\n    }\n    else\n    {\n        _1094 = _1087;\n    }\n    if (_1094)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1037)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1120 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _677, fa_shadow_tex);\n        s = _1120;\n        if (_1120 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_677.fa_shadow_cfg.y > 0.0)\n    {\n        float _1145;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1145 = fa_shadow_split_at(param_5, _677);\n        }\n        else\n        {\n            _1145 = _677.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1164 = _677.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _677) - _1145, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1175 = fast::clamp((_1053 - (fa_shadow_split_at(param_7, _677) - _1164)) / _1164, 0.0, 1.0);\n        if (_1175 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1037)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1196 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _677, fa_shadow_tex);\n                s2 = _1196;\n                if (_1196 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1175);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _441, thread float4& gl_FragCoord, constant fa_shadows& _677, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _441, gl_FragCoord, _677, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _441, thread float4& gl_FragCoord, constant fa_shadows& _677, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _2138 = fa_lm.z > 0.5;\n    bool _2144;\n    if (_2138)\n    {\n        int param = li;\n        _2144 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2144 = _2138;\n    }\n    if (_2144)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2166 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _3224 = _2166.direction;\n    float3 _3219 = _2166.color;\n    float _3221 = _2166.shadow;\n    int _3229 = _2166.type;\n    if ((_3229 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3224;\n        float _2180 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _441, gl_FragCoord, _677, fa_shadow_tex, fa_world_pos);\n        _3221 = _2180;\n        _3219 *= _2180;\n    }\n    return LightSample{ _3224, _3219, _2166.attenuation, _3221, _2166._distance, _3229 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _677)\n{\n    if (_677.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1220 = int(_677.fa_shadow_cfg.x + 0.5);\n    float _1230 = dot(world - _677.fa_shadow_eye.xyz, _677.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1235 = _1220 > 0;\n    bool _1244;\n    if (_1235)\n    {\n        int param = _1220 - 1;\n        _1244 = _1230 <= fa_shadow_split_at(param, _677);\n    }\n    else\n    {\n        _1244 = _1235;\n    }\n    if (_1244)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1251 = _1220 > 1;\n        bool _1258;\n        if (_1251)\n        {\n            _1258 = _1230 > _677.fa_shadow_split.x;\n        }\n        else\n        {\n            _1258 = _1251;\n        }\n        if (_1258)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1264 = _1220 > 2;\n        bool _1271;\n        if (_1264)\n        {\n            _1271 = _1230 > _677.fa_shadow_split.y;\n        }\n        else\n        {\n            _1271 = _1264;\n        }\n        if (_1271)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1277 = _1220 > 3;\n        bool _1284;\n        if (_1277)\n        {\n            _1284 = _1230 > _677.fa_shadow_split.z;\n        }\n        else\n        {\n            _1284 = _1277;\n        }\n        if (_1284)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _441 [[buffer(1)]], constant fa_shadows& _677 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2928 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2928 = -_2928;\n    }\n    float3 _2580 = fast::normalize(_441.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _441, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2928, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2580, short(gl_FrontFacing) };\n    Surface _2588 = fa_standard_surface(param_1, _441, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2967 = _2588.albedo;\n    float _2968 = _2588.alpha;\n    float3 _2969 = _2588.normal;\n    float _2970 = _2588.metallic;\n    float _2971 = _2588.roughness;\n    float _2972 = _2588.occlusion;\n    float3 _2973 = _2588.emission;\n    float _2974 = _2588.clearcoat;\n    float _2975 = _2588.clearcoat_roughness;\n    float3 _2976 = _2588.sheen_color;\n    float _2977 = _2588.sheen_roughness;\n    float _2978 = _2588.anisotropy;\n    float _2979 = _2588.anisotropy_rotation;\n    float _2980 = _2588.specular;\n    float _2981 = _2588.ior;\n    float3 _2982 = _2588.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2928, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2580, short(gl_FrontFacing) };\n    Surface param_3 = _2588;\n    surface(param_2, param_3);\n    _2967 = param_3.albedo;\n    _2968 = param_3.alpha;\n    _2969 = param_3.normal;\n    _2970 = param_3.metallic;\n    _2971 = param_3.roughness;\n    _2972 = param_3.occlusion;\n    _2973 = param_3.emission;\n    _2974 = param_3.clearcoat;\n    _2975 = param_3.clearcoat_roughness;\n    _2976 = param_3.sheen_color;\n    _2977 = param_3.sheen_roughness;\n    _2978 = param_3.anisotropy;\n    _2979 = param_3.anisotropy_rotation;\n    _2980 = param_3.specular;\n    _2981 = param_3.ior;\n    _2982 = param_3.specular_color;\n    float3 result;\n    if (_441.fa_emissive.w > 0.5)\n    {\n        result = _2967;\n    }\n    else\n    {\n        float3 _2609 = _2969;\n        float3 _2610 = fast::normalize(_2609);\n        _2969 = _2610;\n        float3 param_4 = _2610;\n        SurfaceInput param_5 = SurfaceInput{ in.fa_world_pos, _2928, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2580, short(gl_FrontFacing) };\n        Surface param_6 = Surface{ _2967, _2968, _2969, _2970, _2971, _2972, _2973, _2974, _2975, _2976, _2977, _2978, _2979, _2980, _2981, _2982 };\n        float3 param_7 = fa_indirect_diffuse(param_4, _441, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_5, param_6, param_7, _441, fa_env_tex, fa_env_smp);\n        int _2629 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2629; ln++)\n        {\n            int param_8 = ln;\n            int _2642 = fa_cl_light(param_8, fa_light_tex, fa_shadow_smp, _441, fa_cl_ndir, fa_cl_slot);\n            bool _2645 = in.fa_lm.z > 0.5;\n            bool _2651;\n            if (_2645)\n            {\n                int param_9 = _2642;\n                _2651 = fa_light_baked(param_9, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _2651 = _2645;\n            }\n            if (_2651)\n            {\n                continue;\n            }\n            int param_10 = _2642;\n            float3 param_11 = in.fa_world_pos;\n            float3 param_12 = _2928;\n            SurfaceInput param_13 = SurfaceInput{ in.fa_world_pos, _2928, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2580, short(gl_FrontFacing) };\n            Surface param_14 = Surface{ _2967, _2968, _2969, _2970, _2971, _2972, _2973, _2974, _2975, _2976, _2977, _2978, _2979, _2980, _2981, _2982 };\n            LightSample param_15 = fa_light_shadowed(param_10, param_11, param_12, fa_light_tex, fa_shadow_smp, _441, gl_FragCoord, _677, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            lit += light(param_13, param_14, param_15);\n        }\n        result = lit;\n    }\n    float3 _2678 = result;\n    float3 _2679 = _2678 + _2973;\n    result = _2679;\n    float3 param_16 = _2679;\n    float3 param_17 = in.fa_world_pos;\n    result = fa_shadow_debug(param_16, param_17, _677);\n    bool _2688 = _441.fa_fog.w > 0.0;\n    bool _2695;\n    if (!_2688)\n    {\n        _2695 = _441.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2695 = _2688;\n    }\n    if (_2695)\n    {\n        float3 _2704 = in.fa_world_pos - _441.fa_camera_pos.xyz;\n        float _2710 = dot(_2704, _441.fa_fog_c.xyz);\n        bool _2714 = _441.fa_fog_c.w > 0.5;\n        float _2715;\n        if (_2714)\n        {\n            _2715 = _2710;\n        }\n        else\n        {\n            _2715 = length(_2704);\n        }\n        float _2727 = _2715 - _441.fa_fog_b.x;\n        if (_2727 > 0.0)\n        {\n            float _2736 = _441.fa_fog.w * _2727;\n            float tau = _2736 * _2736;\n            if (_441.fa_fog_b.y > 0.0)\n            {\n                float _2752;\n                if (_2714)\n                {\n                    _2752 = in.fa_world_pos.y - (_441.fa_fog_c.y * _2710);\n                }\n                else\n                {\n                    _2752 = _441.fa_camera_pos.y;\n                }\n                float _2773 = mix(_2752, in.fa_world_pos.y, fast::clamp(_441.fa_fog_b.x / _2715, 0.0, 1.0));\n                float _2777 = in.fa_world_pos.y - _2773;\n                float _2782 = _2773 - _441.fa_fog_b.z;\n                float _2787 = in.fa_world_pos.y - _441.fa_fog_b.z;\n                bool _2790 = _2782 <= 0.0;\n                bool _2791 = !_2790;\n                bool _2797;\n                if (_2791)\n                {\n                    _2797 = _441.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2797 = _2790;\n                }\n                float _2798;\n                if (_2797)\n                {\n                    _2798 = _441.fa_fog_b.y;\n                }\n                else\n                {\n                    _2798 = _441.fa_fog_b.y * exp(-fast::min(_441.fa_fog_b.w * _2782, 80.0));\n                }\n                bool _2825;\n                if (_2791)\n                {\n                    _2825 = _441.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2825 = _2790;\n                }\n                float _2826;\n                if (_2825)\n                {\n                    _2826 = _441.fa_fog_b.y * _2782;\n                }\n                else\n                {\n                    _2826 = (_441.fa_fog_b.y * (1.0 - exp(-fast::min(_441.fa_fog_b.w * _2782, 80.0)))) / _441.fa_fog_b.w;\n                }\n                bool _2851 = _2787 <= 0.0;\n                bool _2858;\n                if (!_2851)\n                {\n                    _2858 = _441.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2858 = _2851;\n                }\n                float _2859;\n                if (_2858)\n                {\n                    _2859 = _441.fa_fog_b.y * _2787;\n                }\n                else\n                {\n                    _2859 = (_441.fa_fog_b.y * (1.0 - exp(-fast::min(_441.fa_fog_b.w * _2787, 80.0)))) / _441.fa_fog_b.w;\n                }\n                float _2886;\n                if (abs(_2777) < 0.001000000047497451305389404296875)\n                {\n                    _2886 = _2798;\n                }\n                else\n                {\n                    _2886 = (_2859 - _2826) / _2777;\n                }\n                tau += (_2727 * fast::max(_2886, 0.0));\n            }\n            result = mix(result, _441.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2968);\n    return out;\n}\n\n",
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
            "inst_name": "_441",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_677",
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
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
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
