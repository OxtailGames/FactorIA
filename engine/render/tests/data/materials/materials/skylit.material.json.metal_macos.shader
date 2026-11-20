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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nconstant spvUnsafeArray<float, 63> _1952 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _439)\n{\n    bool _444 = _439.fa_cl_info.x < 0.0;\n    bool _451;\n    if (!_444)\n    {\n        _451 = _439.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _451 = _444;\n    }\n    bool _459;\n    if (!_451)\n    {\n        _459 = _439.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _459 = _451;\n    }\n    bool _466;\n    if (!_459)\n    {\n        _466 = _439.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _466 = _459;\n    }\n    bool _473;\n    if (!_466)\n    {\n        _473 = _439.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _473 = _466;\n    }\n    if (_473)\n    {\n        return int2(0);\n    }\n    float4 _483 = float4(world_pos, 1.0);\n    float _490 = dot(_439.fa_cl_vpw, _483);\n    if (!(_490 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _512 = float2(dot(_439.fa_cl_vpx, _483), dot(_439.fa_cl_vpy, _483)) / float2(_490);\n    int _516 = int(_439.fa_cl_grid.x);\n    int _520 = int(_439.fa_cl_grid.y);\n    int param = (int(_439.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_439.fa_cl_fwd.xyz, world_pos) + _439.fa_cl_fwd.w, _439.fa_cl_grid.w) / _439.fa_cl_grid.w) * _439.fa_cl_grid.z)), 0, int(_439.fa_cl_info.y) - 1) * _520) + clamp(int(floor(((_512.y * 0.5) + 0.5) * _439.fa_cl_grid.y)), 0, _520 - 1)) * _516)) + clamp(int(floor(((_512.x * 0.5) + 0.5) * _439.fa_cl_grid.x)), 0, _516 - 1);\n    float4 _591 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_591.x), int(_591.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _439, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_439.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2490 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _439);\n    fa_cl_slot = _2490.x;\n    fa_cl_local = _2490.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2628 = fa_linear_to_srgb(param);\n        c = _2628;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2636 = fa_srgb_to_linear(param_1);\n            c = _2636;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _220;\n    if (bool(i.front_facing))\n    {\n        _220 = i.world_normal;\n    }\n    else\n    {\n        _220 = -i.world_normal;\n    }\n    float3 _244 = fast::normalize(i.world_tangent.xyz - (_220 * dot(_220, i.world_tangent.xyz)));\n    float3 _272 = fast::normalize(((_244 * m.x) + ((cross(_220, _244) * i.world_tangent.w) * m.y)) + (_220 * m.z));\n    float3 _275;\n    if (bool(i.front_facing))\n    {\n        _275 = _272;\n    }\n    else\n    {\n        _275 = -_272;\n    }\n    return _275;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _439, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _439.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2667 = fa_tex_fix(param_2, param_3);\n    float4 _3674 = base_t;\n    _3674.x = _2667.x;\n    _3674.y = _2667.y;\n    _3674.z = _2667.z;\n    base_t = _3674;\n    float4 _2681 = (_3674 * _439.fa_base_color) * i.vertex_color;\n    float3 _3576 = i.world_normal;\n    if (_439.fa_maps.z > 0.5)\n    {\n        float param_4 = _439.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2713 = fa_tex_fix(param_6, param_7);\n        float3 _2717 = (_2713 * 2.0) - float3(1.0);\n        float2 _2722 = _2717.xy * _439.fa_maps.x;\n        float3 _3682 = _2717;\n        _3682.x = _2722.x;\n        _3682.y = _2722.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3682;\n        _3576 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _439.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2751 = fa_tex_fix(param_12, param_13);\n    float4 _3685 = mrt;\n    _3685.x = _2751.x;\n    _3685.y = _2751.y;\n    _3685.z = _2751.z;\n    mrt = _3685;\n    float4 _2779 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _439.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2779.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2791 = fa_tex_fix(param_16, param_17);\n    float param_18 = _439.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2821 = fa_tex_fix(param_20, param_21);\n    float _3581 = _439.fa_layers_a.x;\n    float _3582 = _439.fa_layers_a.y;\n    float _3585 = _439.fa_layers_a.z;\n    float _3584 = _439.fa_layers_b.w;\n    float _3587 = _439.fa_layers_c.x;\n    if (_439.fa_layers_c.z > 0.5)\n    {\n        if (mod(_439.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3581 *= _2791.y;\n            _3582 *= _2791.z;\n            _3584 *= _2779.w;\n        }\n        if (_439.fa_layers_c.z > 1.5)\n        {\n            _3585 *= mrt.x;\n            _3587 *= mrt.w;\n        }\n    }\n    return Surface{ _2681.xyz, _2681.w, _3576, fast::clamp(_439.fa_pbr.x * _2751.z, 0.0, 1.0), fast::clamp(_439.fa_pbr.y * _2751.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_439.fa_maps.y * (_2791.x - 1.0)), _439.fa_emissive.xyz + (_439.fa_model_emissive.xyz * _2821), _3581, _3582, _439.fa_layers_b.xyz, _3584, _3585, _439.fa_layers_a.w, _3587, _439.fa_layers_c.y, _439.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _439, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_439.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _439.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1877 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1885 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1888 = int(_1877);\n    int _1891 = int(_1885);\n    float _1901 = _1885 - float(_1891);\n    int _1957 = (_1888 * 9) + _1891;\n    int _1977 = ((_1888 + 1) * 9) + _1891;\n    return mix(mix(_1952[_1957], _1952[_1957 + 1], _1901), mix(_1952[_1977], _1952[_1977 + 1], _1901), _1877 - float(_1888));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _3448 = false;\n    float _3449 = 1.0;\n    float _3450 = 1.0;\n    float _3451 = 1.0;\n    float _3452 = 0.0;\n    float _3453 = 0.0;\n    float _3454 = 0.0;\n    float _3455 = 0.0;\n    float _3457 = 1.0;\n    bool _3458 = false;\n    float3 _3459 = float3(0.0);\n    float _3460 = 1.0;\n    float _3461 = 1.0;\n    float _3462 = 1.0;\n    float _3463 = 0.0;\n    float _3464 = 0.0;\n    float3 _3465 = float3(1.0, 0.0, 0.0);\n    float3 _3466 = float3(0.0, 0.0, 1.0);\n    float _3467 = 1.0;\n    float _3468 = 1.0;\n    float _2030 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2034 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2039 = (_2030 != 1.0) || (_2034 != 1.5);\n    bool _2049;\n    if (!_2039)\n    {\n        _2049 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2049 = _2039;\n    }\n    if (_2049)\n    {\n        float _2057 = (_2034 - 1.0) / (_2034 + 1.0);\n        f0 = mix(fast::min(float3(_2057 * _2057) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2030, s.albedo, float3(metallic));\n        _3449 = mix(_2030, 1.0, metallic);\n        _3448 = true;\n    }\n    float _2085 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2085 > 0.0)\n    {\n        float _2093 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3452 = _2085;\n        _3453 = _2093;\n        float _2100 = _2093 * _2093;\n        _3454 = _2100;\n        _3455 = _2100 * _2100;\n        float _2112 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3457 = _2112;\n        _3450 = 1.0 - (_2085 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2112, 0.0, 1.0), 5.0))));\n        _3448 = true;\n    }\n    float3 _2132 = fast::max(s.sheen_color, float3(0.0));\n    float _2141 = fast::max(_2132.x, fast::max(_2132.y, _2132.z));\n    if (_2141 > 0.0)\n    {\n        float _2149 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3458 = true;\n        _3459 = _2132;\n        _3460 = _2149;\n        _3461 = _2149 * _2149;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2149;\n        float _2166 = fa_sheen_albedo(param, param_1);\n        _3463 = _2166;\n        _3462 = 1.0 - fast::min(_2141 * _2166, 1.0);\n        _3448 = true;\n    }\n    _3451 = _3450 * _3462;\n    float _2185 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2185 != 0.0)\n    {\n        float3 _2200 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2200;\n        if (dot(_2200, _2200) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2218 = t;\n        float3 _2219 = fast::normalize(_2218);\n        t = _2219;\n        float3 _2244 = fast::normalize((_2219 * cos(s.anisotropy_rotation)) + ((cross(n, _2219) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3465 = _2244;\n        _3466 = cross(n, _2244);\n        float _2254 = roughness * roughness;\n        float _2260 = mix(_2254, 1.0, _2185 * _2185);\n        bool _2262 = _2185 > 0.0;\n        _3467 = _2262 ? _2260 : _2254;\n        _3468 = _2262 ? _2254 : _2260;\n        _3464 = _2185;\n        _3448 = true;\n    }\n    return FaLayers{ short(_3448), _3449, _3450, _3451, _3452, _3453, _3454, _3455, i.world_normal, _3457, short(_3458), _3459, _3460, _3461, _3462, _3463, _3464, _3465, _3466, _3467, _3468 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1809 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1812 = _1809.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1812 * _1812, exp2((-9.27999973297119140625) * ndv)) * _1812) + _1809.y)) + _1809.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _439, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_439.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _439.fa_env_horizon.w)).xyz;\n    }\n    float _1714 = rough * rough;\n    float _1744 = 0.60000002384185791015625 * _1714;\n    return mix(mix(_439.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_439.fa_env_horizon.xyz, _439.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1714)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1744, 0.0500000007450580596923828125 + _1744, d.y))), ((_439.fa_env_sky.xyz + _439.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1714 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _439, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2295;\n        if (L.aniso >= 0.0)\n        {\n            _2295 = L.b;\n        }\n        else\n        {\n            _2295 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2295, v), _2295), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2328 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _439, fa_env_tex, fa_env_smp) * ((f0 * _2328.x) + (float3(L.f90) * _2328.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _439, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2383 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _439, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _2383.x) + _2383.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _439, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1851 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _439, fa_env_tex, fa_env_smp) * ((f0 * _1851.x) + float3(_1851.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _439, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float _2412 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _2416 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _2423 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_2412));\n    float3 f0 = _2423;\n    float3 _2427 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2427;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2412;\n    float param_5 = _2416;\n    float3 param_6 = _2423;\n    FaLayers _2444 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2444.on)\n    {\n        FaLayers param_7 = _2444;\n        float3 param_8 = _2427;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2416;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _439, fa_env_tex, fa_env_smp) * s.occlusion;\n    }\n    float3 param_12 = _2427;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2416;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _439, fa_env_tex, fa_env_smp) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor, constant fa_mesh_fs_params& _439, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1, _439, fa_env_tex, fa_env_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _439)\n{\n    int param = (int(_439.fa_cl_info.x) + int(_439.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _439, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _439);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _312 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _318 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _321 = _318.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _328 = _321 < 0.5;\n    float3 l;\n    if (_328)\n    {\n        l = fast::normalize(_312.xyz);\n    }\n    else\n    {\n        float3 _340 = _312.xyz - world_pos;\n        float _342 = length(_340);\n        dist = _342;\n        l = _340 / float3(fast::max(_342, 9.9999997473787516355514526367188e-05));\n        float _357 = _342 / fast::max(_312.w, 0.001000000047497451305389404296875);\n        float _363 = fast::clamp(1.0 - (_357 * _357), 0.0, 1.0);\n        atten = _363 * _363;\n        if (_321 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _377 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _387 = _377.w;\n            int param_3 = (li * 4) + 3;\n            float4 _394 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _395 = _394.x;\n            float cos_inner = _395;\n            if (_395 > 1.5)\n            {\n                cos_inner = mix(_387, 1.0, 0.25);\n            }\n            atten *= smoothstep(_387, cos_inner, dot(-l, fast::normalize(_377.xyz)));\n        }\n    }\n    int _425;\n    if (_328)\n    {\n        _425 = 0;\n    }\n    else\n    {\n        _425 = (_321 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _318.xyz * atten, atten, 1.0, dist, _425 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _675)\n{\n    float _665;\n    if (i == 0)\n    {\n        _665 = _675.fa_shadow_split.x;\n    }\n    else\n    {\n        float _681;\n        if (i == 1)\n        {\n            _681 = _675.fa_shadow_split.y;\n        }\n        else\n        {\n            float _689;\n            if (i == 2)\n            {\n                _689 = _675.fa_shadow_split.z;\n            }\n            else\n            {\n                _689 = _675.fa_shadow_split.w;\n            }\n            _681 = _689;\n        }\n        _665 = _681;\n    }\n    return _665;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _722 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _726;\n    if (conv.x < 0.5)\n    {\n        _726 = _722;\n    }\n    else\n    {\n        _726 = (conv.y * conv.z) / (conv.z - (_722 * (conv.z - conv.y)));\n    }\n    return _726;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _653 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_653), sin(_653)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _675, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _772 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _786 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _772;\n            float2 _805 = fa_shadow_vogel(param_3, param_4, param_5) * _786;\n            float2 param_6 = uv + (_805 * _675.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _817 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_817 < (zr - (length(_805) * plane)))\n            {\n                sum += _817;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _861 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _861; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _861;\n        float param_11 = _772;\n        float2 _880 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_880 * _675.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_880) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_861);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _675, texture2d<float> fa_shadow_tex)\n{\n    float _922 = fast::max(_675.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _927 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _933 = sqrt(1.0 - (_927 * _927));\n    float _941 = fast::min(_933 / fast::max(_927, 0.20000000298023223876953125), 4.0);\n    float _946;\n    if (_675.fa_shadow_bias.y > 0.0)\n    {\n        _946 = _675.fa_shadow_bias.y;\n    }\n    else\n    {\n        _946 = 1.5 * _675.fa_shadow_info[ci].x;\n    }\n    float4 _971 = _675.fa_shadow_mat[ci] * float4(world + (n * (_946 * _933)), 1.0);\n    float _978 = _971.x;\n    bool _981 = _978 < _675.fa_shadow_rect[ci].x;\n    bool _990;\n    if (!_981)\n    {\n        _990 = _978 > _675.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _990 = _981;\n    }\n    bool _999;\n    if (!_990)\n    {\n        _999 = _971.y < _675.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _999 = _990;\n    }\n    bool _1008;\n    if (!_999)\n    {\n        _1008 = _971.y > _675.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1008 = _999;\n    }\n    bool _1015;\n    if (!_1008)\n    {\n        _1015 = _971.z > 1.0;\n    }\n    else\n    {\n        _1015 = _1008;\n    }\n    if (_1015)\n    {\n        return -1.0;\n    }\n    float _1024;\n    if (_675.fa_shadow_bias.x > 0.0)\n    {\n        _1024 = _675.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1024 = 1.5 * _675.fa_shadow_info[ci].x;\n    }\n    float2 param = _971.xy;\n    float4 param_1 = _675.fa_shadow_rect[ci];\n    float param_2 = _971.z - ((_1024 * (1.0 + (0.5 * _941))) / _922);\n    float param_3 = _675.fa_shadow_info[ci].x;\n    float param_4 = _922;\n    float param_5 = _922 * 0.25;\n    float param_6 = ((_675.fa_shadow_info[ci].x * fast::min(_941, 3.0)) * 0.5) / _922;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_675.fa_shadow_cfg.z + 0.5);\n    float param_9 = _675.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _675, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _439, thread float4& gl_FragCoord, constant fa_shadows& _675, texture2d<float> fa_shadow_tex)\n{\n    if (_439.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1418 = int(_675.fa_shadow_cfg.x + 0.5);\n    if (_1418 < 1)\n    {\n        return 1.0;\n    }\n    float _1434 = dot(world - _675.fa_shadow_eye.xyz, _675.fa_shadow_fwd.xyz);\n    int param = _1418 - 1;\n    if (_1434 > fa_shadow_split_at(param, _675))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1446 = _1418 > 1;\n    bool _1453;\n    if (_1446)\n    {\n        _1453 = _1434 > _675.fa_shadow_split.x;\n    }\n    else\n    {\n        _1453 = _1446;\n    }\n    if (_1453)\n    {\n        ci = 1;\n    }\n    bool _1457 = _1418 > 2;\n    bool _1464;\n    if (_1457)\n    {\n        _1464 = _1434 > _675.fa_shadow_split.y;\n    }\n    else\n    {\n        _1464 = _1457;\n    }\n    if (_1464)\n    {\n        ci = 2;\n    }\n    bool _1468 = _1418 > 3;\n    bool _1475;\n    if (_1468)\n    {\n        _1475 = _1434 > _675.fa_shadow_split.z;\n    }\n    else\n    {\n        _1475 = _1468;\n    }\n    if (_1475)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1418)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1501 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _675, fa_shadow_tex);\n        s = _1501;\n        if (_1501 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_675.fa_shadow_cfg.y > 0.0)\n    {\n        float _1526;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1526 = fa_shadow_split_at(param_5, _675);\n        }\n        else\n        {\n            _1526 = _675.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1545 = _675.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _675) - _1526, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1556 = fast::clamp((_1434 - (fa_shadow_split_at(param_7, _675) - _1545)) / _1545, 0.0, 1.0);\n        if (_1556 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1418)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1577 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _675, fa_shadow_tex);\n                s2 = _1577;\n                if (_1577 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1556);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _439, thread float4& gl_FragCoord, constant fa_shadows& _675, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _439, gl_FragCoord, _675, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _439, thread float4& gl_FragCoord, constant fa_shadows& _675, texture2d<float> fa_shadow_tex)\n{\n    bool _1083 = _439.fa_pbr.z < 0.5;\n    bool _1091;\n    if (!_1083)\n    {\n        _1091 = _675.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1091 = _1083;\n    }\n    if (_1091)\n    {\n        return 1.0;\n    }\n    int param = (int(_675.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1104 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1105 = _1104.x;\n    if (_1105 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1114 = int(_1105 + 0.5);\n    int param_1 = _1114;\n    float4 _1118 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1114 + 1;\n    float4 _1123 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1126 = _1118.y;\n    if (_1126 > 0.0)\n    {\n        float _1143 = 1.0 - smoothstep(0.75 * _1126, _1126, length(world - _675.fa_shadow_eye.xyz));\n        fade = _1143;\n        if (_1143 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1118.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1162 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1165 = abs(_1162);\n        float _1167 = _1165.x;\n        float _1169 = _1165.y;\n        bool _1170 = _1167 >= _1169;\n        bool _1178;\n        if (_1170)\n        {\n            _1178 = _1167 >= _1165.z;\n        }\n        else\n        {\n            _1178 = _1170;\n        }\n        int _1179;\n        if (_1178)\n        {\n            _1179 = (_1162.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1192;\n            if (_1169 >= _1165.z)\n            {\n                _1192 = (_1162.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1192 = (_1162.z > 0.0) ? 4 : 5;\n            }\n            _1179 = _1192;\n        }\n        face = _1179;\n    }\n    int _1211 = (_1114 + 2) + (face * 6);\n    int param_4 = _1211;\n    int param_5 = _1211 + 1;\n    int param_6 = _1211 + 3;\n    float4 _1225 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1211 + 4;\n    float4 _1230 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1211 + 5;\n    float4 _1235 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1247 = _1235.x * fast::max(dot(_1225, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1252 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1258 = sqrt(1.0 - (_1252 * _1252));\n    float _1264 = fast::min(_1258 / fast::max(_1252, 0.20000000298023223876953125), 4.0);\n    float _1267 = _1123.y;\n    float _1269;\n    if (_1267 > 0.0)\n    {\n        _1269 = _1267;\n    }\n    else\n    {\n        _1269 = 1.5 * _1247;\n    }\n    float4 _1289 = float4(world + (n * (_1269 * _1258)), 1.0);\n    float _1293 = dot(_1225, _1289);\n    float _1296 = _1235.y;\n    if (_1293 < _1296)\n    {\n        return 1.0;\n    }\n    float2 _1311 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1289), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1289)) / float2(_1293);\n    float _1313 = _1311.x;\n    bool _1316 = _1313 < _1230.x;\n    bool _1325;\n    if (!_1316)\n    {\n        _1325 = _1313 > _1230.z;\n    }\n    else\n    {\n        _1325 = _1316;\n    }\n    bool _1334;\n    if (!_1325)\n    {\n        _1334 = _1311.y < _1230.y;\n    }\n    else\n    {\n        _1334 = _1325;\n    }\n    bool _1343;\n    if (!_1334)\n    {\n        _1343 = _1311.y > _1230.w;\n    }\n    else\n    {\n        _1343 = _1334;\n    }\n    if (_1343)\n    {\n        return 1.0;\n    }\n    float _1349 = _1123.x;\n    float _1351;\n    if (_1349 > 0.0)\n    {\n        _1351 = _1349;\n    }\n    else\n    {\n        _1351 = 1.5 * _1247;\n    }\n    float2 param_9 = _1311;\n    float4 param_10 = _1230;\n    float param_11 = _1293 - (_1351 * (1.0 + (0.5 * _1264)));\n    float param_12 = _1247;\n    float param_13 = 1.0;\n    float param_14 = _1235.z * 0.25;\n    float param_15 = (_1247 * fast::min(_1264, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _1296, _1235.z);\n    int param_17 = int(_1118.z + 0.5);\n    float param_18 = _1118.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _675, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _439, thread float4& gl_FragCoord, constant fa_shadows& _675, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2518 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _3561 = _2518.direction;\n    float3 _3556 = _2518.color;\n    float _3563 = _2518.attenuation;\n    float _3558 = _2518.shadow;\n    int _3566 = _2518.type;\n    if ((_3566 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _3561;\n        float _2532 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _439, gl_FragCoord, _675, fa_shadow_tex, fa_world_pos);\n        _3558 = _2532;\n        _3556 *= _2532;\n    }\n    else\n    {\n        bool _2543 = _3566 != 0;\n        bool _2549;\n        if (_2543)\n        {\n            _2549 = _3563 > 0.0;\n        }\n        else\n        {\n            _2549 = _2543;\n        }\n        if (_2549)\n        {\n            int param_4 = li;\n            float3 param_5 = world_pos;\n            float3 param_6 = gn;\n            float3 param_7 = _3561;\n            float _2561 = fa_shadow_local(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _439, gl_FragCoord, _675, fa_shadow_tex);\n            _3558 = _2561;\n            _3556 *= _2561;\n        }\n    }\n    return LightSample{ _3561, _3556, _3563, _3558, _2518._distance, _3566 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _675)\n{\n    if (_675.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1601 = int(_675.fa_shadow_cfg.x + 0.5);\n    float _1611 = dot(world - _675.fa_shadow_eye.xyz, _675.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1616 = _1601 > 0;\n    bool _1625;\n    if (_1616)\n    {\n        int param = _1601 - 1;\n        _1625 = _1611 <= fa_shadow_split_at(param, _675);\n    }\n    else\n    {\n        _1625 = _1616;\n    }\n    if (_1625)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1632 = _1601 > 1;\n        bool _1639;\n        if (_1632)\n        {\n            _1639 = _1611 > _675.fa_shadow_split.x;\n        }\n        else\n        {\n            _1639 = _1632;\n        }\n        if (_1639)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1645 = _1601 > 2;\n        bool _1652;\n        if (_1645)\n        {\n            _1652 = _1611 > _675.fa_shadow_split.y;\n        }\n        else\n        {\n            _1652 = _1645;\n        }\n        if (_1652)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1658 = _1601 > 3;\n        bool _1665;\n        if (_1658)\n        {\n            _1665 = _1611 > _675.fa_shadow_split.z;\n        }\n        else\n        {\n            _1665 = _1658;\n        }\n        if (_1665)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _439 [[buffer(1)]], constant fa_shadows& _675 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3278 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3278 = -_3278;\n    }\n    float3 _2942 = fast::normalize(_439.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _439, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3278, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2942, short(gl_FrontFacing) };\n    Surface _2950 = fa_standard_surface(param_1, _439, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3317 = _2950.albedo;\n    float _3318 = _2950.alpha;\n    float3 _3319 = _2950.normal;\n    float _3320 = _2950.metallic;\n    float _3321 = _2950.roughness;\n    float _3322 = _2950.occlusion;\n    float3 _3323 = _2950.emission;\n    float _3324 = _2950.clearcoat;\n    float _3325 = _2950.clearcoat_roughness;\n    float3 _3326 = _2950.sheen_color;\n    float _3327 = _2950.sheen_roughness;\n    float _3328 = _2950.anisotropy;\n    float _3329 = _2950.anisotropy_rotation;\n    float _3330 = _2950.specular;\n    float _3331 = _2950.ior;\n    float3 _3332 = _2950.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3278, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2942, short(gl_FrontFacing) };\n    Surface param_3 = _2950;\n    surface(param_2, param_3);\n    _3317 = param_3.albedo;\n    _3318 = param_3.alpha;\n    _3319 = param_3.normal;\n    _3320 = param_3.metallic;\n    _3321 = param_3.roughness;\n    _3322 = param_3.occlusion;\n    _3323 = param_3.emission;\n    _3324 = param_3.clearcoat;\n    _3325 = param_3.clearcoat_roughness;\n    _3326 = param_3.sheen_color;\n    _3327 = param_3.sheen_roughness;\n    _3328 = param_3.anisotropy;\n    _3329 = param_3.anisotropy_rotation;\n    _3330 = param_3.specular;\n    _3331 = param_3.ior;\n    _3332 = param_3.specular_color;\n    float3 result;\n    if (_439.fa_emissive.w > 0.5)\n    {\n        result = _3317;\n    }\n    else\n    {\n        float3 _2971 = _3319;\n        float3 _2972 = fast::normalize(_2971);\n        _3319 = _2972;\n        float3 param_4 = _2972;\n        SurfaceInput param_5 = SurfaceInput{ in.fa_world_pos, _3278, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2942, short(gl_FrontFacing) };\n        Surface param_6 = Surface{ _3317, _3318, _3319, _3320, _3321, _3322, _3323, _3324, _3325, _3326, _3327, _3328, _3329, _3330, _3331, _3332 };\n        float3 param_7 = fa_ambient_light(param_4, _439, fa_env_smp, fa_irr_tex);\n        float3 lit = ambient(param_5, param_6, param_7, _439, fa_env_tex, fa_env_smp);\n        int _2991 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2991; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8, fa_light_tex, fa_shadow_smp, _439, fa_cl_ndir, fa_cl_slot);\n            float3 param_10 = in.fa_world_pos;\n            float3 param_11 = _3278;\n            SurfaceInput param_12 = SurfaceInput{ in.fa_world_pos, _3278, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2942, short(gl_FrontFacing) };\n            Surface param_13 = Surface{ _3317, _3318, _3319, _3320, _3321, _3322, _3323, _3324, _3325, _3326, _3327, _3328, _3329, _3330, _3331, _3332 };\n            LightSample param_14 = fa_light_shadowed(param_9, param_10, param_11, fa_light_tex, fa_shadow_smp, _439, gl_FragCoord, _675, fa_shadow_tex, in.fa_world_pos);\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    float3 _3028 = result;\n    float3 _3029 = _3028 + _3323;\n    result = _3029;\n    float3 param_15 = _3029;\n    float3 param_16 = in.fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16, _675);\n    bool _3038 = _439.fa_fog.w > 0.0;\n    bool _3045;\n    if (!_3038)\n    {\n        _3045 = _439.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3045 = _3038;\n    }\n    if (_3045)\n    {\n        float3 _3054 = in.fa_world_pos - _439.fa_camera_pos.xyz;\n        float _3060 = dot(_3054, _439.fa_fog_c.xyz);\n        bool _3064 = _439.fa_fog_c.w > 0.5;\n        float _3065;\n        if (_3064)\n        {\n            _3065 = _3060;\n        }\n        else\n        {\n            _3065 = length(_3054);\n        }\n        float _3077 = _3065 - _439.fa_fog_b.x;\n        if (_3077 > 0.0)\n        {\n            float _3086 = _439.fa_fog.w * _3077;\n            float tau = _3086 * _3086;\n            if (_439.fa_fog_b.y > 0.0)\n            {\n                float _3102;\n                if (_3064)\n                {\n                    _3102 = in.fa_world_pos.y - (_439.fa_fog_c.y * _3060);\n                }\n                else\n                {\n                    _3102 = _439.fa_camera_pos.y;\n                }\n                float _3123 = mix(_3102, in.fa_world_pos.y, fast::clamp(_439.fa_fog_b.x / _3065, 0.0, 1.0));\n                float _3127 = in.fa_world_pos.y - _3123;\n                float _3132 = _3123 - _439.fa_fog_b.z;\n                float _3137 = in.fa_world_pos.y - _439.fa_fog_b.z;\n                bool _3140 = _3132 <= 0.0;\n                bool _3141 = !_3140;\n                bool _3147;\n                if (_3141)\n                {\n                    _3147 = _439.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3147 = _3140;\n                }\n                float _3148;\n                if (_3147)\n                {\n                    _3148 = _439.fa_fog_b.y;\n                }\n                else\n                {\n                    _3148 = _439.fa_fog_b.y * exp(-fast::min(_439.fa_fog_b.w * _3132, 80.0));\n                }\n                bool _3175;\n                if (_3141)\n                {\n                    _3175 = _439.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3175 = _3140;\n                }\n                float _3176;\n                if (_3175)\n                {\n                    _3176 = _439.fa_fog_b.y * _3132;\n                }\n                else\n                {\n                    _3176 = (_439.fa_fog_b.y * (1.0 - exp(-fast::min(_439.fa_fog_b.w * _3132, 80.0)))) / _439.fa_fog_b.w;\n                }\n                bool _3201 = _3137 <= 0.0;\n                bool _3208;\n                if (!_3201)\n                {\n                    _3208 = _439.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3208 = _3201;\n                }\n                float _3209;\n                if (_3208)\n                {\n                    _3209 = _439.fa_fog_b.y * _3137;\n                }\n                else\n                {\n                    _3209 = (_439.fa_fog_b.y * (1.0 - exp(-fast::min(_439.fa_fog_b.w * _3137, 80.0)))) / _439.fa_fog_b.w;\n                }\n                float _3236;\n                if (abs(_3127) < 0.001000000047497451305389404296875)\n                {\n                    _3236 = _3148;\n                }\n                else\n                {\n                    _3236 = (_3209 - _3176) / _3127;\n                }\n                tau += (_3077 * fast::max(_3236, 0.0));\n            }\n            result = mix(result, _439.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3318);\n    return out;\n}\n\n",
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
            "inst_name": "_439",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_675",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nconstant spvUnsafeArray<float, 63> _1952 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _439)\n{\n    bool _444 = _439.fa_cl_info.x < 0.0;\n    bool _451;\n    if (!_444)\n    {\n        _451 = _439.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _451 = _444;\n    }\n    bool _459;\n    if (!_451)\n    {\n        _459 = _439.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _459 = _451;\n    }\n    bool _466;\n    if (!_459)\n    {\n        _466 = _439.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _466 = _459;\n    }\n    bool _473;\n    if (!_466)\n    {\n        _473 = _439.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _473 = _466;\n    }\n    if (_473)\n    {\n        return int2(0);\n    }\n    float4 _483 = float4(world_pos, 1.0);\n    float _490 = dot(_439.fa_cl_vpw, _483);\n    if (!(_490 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _512 = float2(dot(_439.fa_cl_vpx, _483), dot(_439.fa_cl_vpy, _483)) / float2(_490);\n    int _516 = int(_439.fa_cl_grid.x);\n    int _520 = int(_439.fa_cl_grid.y);\n    int param = (int(_439.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_439.fa_cl_fwd.xyz, world_pos) + _439.fa_cl_fwd.w, _439.fa_cl_grid.w) / _439.fa_cl_grid.w) * _439.fa_cl_grid.z)), 0, int(_439.fa_cl_info.y) - 1) * _520) + clamp(int(floor(((_512.y * 0.5) + 0.5) * _439.fa_cl_grid.y)), 0, _520 - 1)) * _516)) + clamp(int(floor(((_512.x * 0.5) + 0.5) * _439.fa_cl_grid.x)), 0, _516 - 1);\n    float4 _591 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_591.x), int(_591.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _439, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_439.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2490 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _439);\n    fa_cl_slot = _2490.x;\n    fa_cl_local = _2490.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2628 = fa_linear_to_srgb(param);\n        c = _2628;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2636 = fa_srgb_to_linear(param_1);\n            c = _2636;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _220;\n    if (bool(i.front_facing))\n    {\n        _220 = i.world_normal;\n    }\n    else\n    {\n        _220 = -i.world_normal;\n    }\n    float3 _244 = fast::normalize(i.world_tangent.xyz - (_220 * dot(_220, i.world_tangent.xyz)));\n    float3 _272 = fast::normalize(((_244 * m.x) + ((cross(_220, _244) * i.world_tangent.w) * m.y)) + (_220 * m.z));\n    float3 _275;\n    if (bool(i.front_facing))\n    {\n        _275 = _272;\n    }\n    else\n    {\n        _275 = -_272;\n    }\n    return _275;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _439, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _439.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2667 = fa_tex_fix(param_2, param_3);\n    float4 _3674 = base_t;\n    _3674.x = _2667.x;\n    _3674.y = _2667.y;\n    _3674.z = _2667.z;\n    base_t = _3674;\n    float4 _2681 = (_3674 * _439.fa_base_color) * i.vertex_color;\n    float3 _3576 = i.world_normal;\n    if (_439.fa_maps.z > 0.5)\n    {\n        float param_4 = _439.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2713 = fa_tex_fix(param_6, param_7);\n        float3 _2717 = (_2713 * 2.0) - float3(1.0);\n        float2 _2722 = _2717.xy * _439.fa_maps.x;\n        float3 _3682 = _2717;\n        _3682.x = _2722.x;\n        _3682.y = _2722.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3682;\n        _3576 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _439.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2751 = fa_tex_fix(param_12, param_13);\n    float4 _3685 = mrt;\n    _3685.x = _2751.x;\n    _3685.y = _2751.y;\n    _3685.z = _2751.z;\n    mrt = _3685;\n    float4 _2779 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _439.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2779.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2791 = fa_tex_fix(param_16, param_17);\n    float param_18 = _439.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2821 = fa_tex_fix(param_20, param_21);\n    float _3581 = _439.fa_layers_a.x;\n    float _3582 = _439.fa_layers_a.y;\n    float _3585 = _439.fa_layers_a.z;\n    float _3584 = _439.fa_layers_b.w;\n    float _3587 = _439.fa_layers_c.x;\n    if (_439.fa_layers_c.z > 0.5)\n    {\n        if (mod(_439.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3581 *= _2791.y;\n            _3582 *= _2791.z;\n            _3584 *= _2779.w;\n        }\n        if (_439.fa_layers_c.z > 1.5)\n        {\n            _3585 *= mrt.x;\n            _3587 *= mrt.w;\n        }\n    }\n    return Surface{ _2681.xyz, _2681.w, _3576, fast::clamp(_439.fa_pbr.x * _2751.z, 0.0, 1.0), fast::clamp(_439.fa_pbr.y * _2751.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_439.fa_maps.y * (_2791.x - 1.0)), _439.fa_emissive.xyz + (_439.fa_model_emissive.xyz * _2821), _3581, _3582, _439.fa_layers_b.xyz, _3584, _3585, _439.fa_layers_a.w, _3587, _439.fa_layers_c.y, _439.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _439, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_439.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _439.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1877 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1885 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1888 = int(_1877);\n    int _1891 = int(_1885);\n    float _1901 = _1885 - float(_1891);\n    int _1957 = (_1888 * 9) + _1891;\n    int _1977 = ((_1888 + 1) * 9) + _1891;\n    return mix(mix(_1952[_1957], _1952[_1957 + 1], _1901), mix(_1952[_1977], _1952[_1977 + 1], _1901), _1877 - float(_1888));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _3448 = false;\n    float _3449 = 1.0;\n    float _3450 = 1.0;\n    float _3451 = 1.0;\n    float _3452 = 0.0;\n    float _3453 = 0.0;\n    float _3454 = 0.0;\n    float _3455 = 0.0;\n    float _3457 = 1.0;\n    bool _3458 = false;\n    float3 _3459 = float3(0.0);\n    float _3460 = 1.0;\n    float _3461 = 1.0;\n    float _3462 = 1.0;\n    float _3463 = 0.0;\n    float _3464 = 0.0;\n    float3 _3465 = float3(1.0, 0.0, 0.0);\n    float3 _3466 = float3(0.0, 0.0, 1.0);\n    float _3467 = 1.0;\n    float _3468 = 1.0;\n    float _2030 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2034 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2039 = (_2030 != 1.0) || (_2034 != 1.5);\n    bool _2049;\n    if (!_2039)\n    {\n        _2049 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2049 = _2039;\n    }\n    if (_2049)\n    {\n        float _2057 = (_2034 - 1.0) / (_2034 + 1.0);\n        f0 = mix(fast::min(float3(_2057 * _2057) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2030, s.albedo, float3(metallic));\n        _3449 = mix(_2030, 1.0, metallic);\n        _3448 = true;\n    }\n    float _2085 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2085 > 0.0)\n    {\n        float _2093 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3452 = _2085;\n        _3453 = _2093;\n        float _2100 = _2093 * _2093;\n        _3454 = _2100;\n        _3455 = _2100 * _2100;\n        float _2112 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3457 = _2112;\n        _3450 = 1.0 - (_2085 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2112, 0.0, 1.0), 5.0))));\n        _3448 = true;\n    }\n    float3 _2132 = fast::max(s.sheen_color, float3(0.0));\n    float _2141 = fast::max(_2132.x, fast::max(_2132.y, _2132.z));\n    if (_2141 > 0.0)\n    {\n        float _2149 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3458 = true;\n        _3459 = _2132;\n        _3460 = _2149;\n        _3461 = _2149 * _2149;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2149;\n        float _2166 = fa_sheen_albedo(param, param_1);\n        _3463 = _2166;\n        _3462 = 1.0 - fast::min(_2141 * _2166, 1.0);\n        _3448 = true;\n    }\n    _3451 = _3450 * _3462;\n    float _2185 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2185 != 0.0)\n    {\n        float3 _2200 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2200;\n        if (dot(_2200, _2200) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2218 = t;\n        float3 _2219 = fast::normalize(_2218);\n        t = _2219;\n        float3 _2244 = fast::normalize((_2219 * cos(s.anisotropy_rotation)) + ((cross(n, _2219) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3465 = _2244;\n        _3466 = cross(n, _2244);\n        float _2254 = roughness * roughness;\n        float _2260 = mix(_2254, 1.0, _2185 * _2185);\n        bool _2262 = _2185 > 0.0;\n        _3467 = _2262 ? _2260 : _2254;\n        _3468 = _2262 ? _2254 : _2260;\n        _3464 = _2185;\n        _3448 = true;\n    }\n    return FaLayers{ short(_3448), _3449, _3450, _3451, _3452, _3453, _3454, _3455, i.world_normal, _3457, short(_3458), _3459, _3460, _3461, _3462, _3463, _3464, _3465, _3466, _3467, _3468 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1809 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1812 = _1809.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1812 * _1812, exp2((-9.27999973297119140625) * ndv)) * _1812) + _1809.y)) + _1809.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _439, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_439.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _439.fa_env_horizon.w)).xyz;\n    }\n    float _1714 = rough * rough;\n    float _1744 = 0.60000002384185791015625 * _1714;\n    return mix(mix(_439.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_439.fa_env_horizon.xyz, _439.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1714)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1744, 0.0500000007450580596923828125 + _1744, d.y))), ((_439.fa_env_sky.xyz + _439.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1714 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _439, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2295;\n        if (L.aniso >= 0.0)\n        {\n            _2295 = L.b;\n        }\n        else\n        {\n            _2295 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2295, v), _2295), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2328 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _439, fa_env_tex, fa_env_smp) * ((f0 * _2328.x) + (float3(L.f90) * _2328.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _439, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2383 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _439, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _2383.x) + _2383.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _439, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1851 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _439, fa_env_tex, fa_env_smp) * ((f0 * _1851.x) + float3(_1851.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _439, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float _2412 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _2416 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _2423 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_2412));\n    float3 f0 = _2423;\n    float3 _2427 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2427;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2412;\n    float param_5 = _2416;\n    float3 param_6 = _2423;\n    FaLayers _2444 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2444.on)\n    {\n        FaLayers param_7 = _2444;\n        float3 param_8 = _2427;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2416;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _439, fa_env_tex, fa_env_smp) * s.occlusion;\n    }\n    float3 param_12 = _2427;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2416;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _439, fa_env_tex, fa_env_smp) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor, constant fa_mesh_fs_params& _439, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1, _439, fa_env_tex, fa_env_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _439)\n{\n    int param = (int(_439.fa_cl_info.x) + int(_439.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _439, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _439);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _312 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _318 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _321 = _318.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _328 = _321 < 0.5;\n    float3 l;\n    if (_328)\n    {\n        l = fast::normalize(_312.xyz);\n    }\n    else\n    {\n        float3 _340 = _312.xyz - world_pos;\n        float _342 = length(_340);\n        dist = _342;\n        l = _340 / float3(fast::max(_342, 9.9999997473787516355514526367188e-05));\n        float _357 = _342 / fast::max(_312.w, 0.001000000047497451305389404296875);\n        float _363 = fast::clamp(1.0 - (_357 * _357), 0.0, 1.0);\n        atten = _363 * _363;\n        if (_321 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _377 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _387 = _377.w;\n            int param_3 = (li * 4) + 3;\n            float4 _394 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _395 = _394.x;\n            float cos_inner = _395;\n            if (_395 > 1.5)\n            {\n                cos_inner = mix(_387, 1.0, 0.25);\n            }\n            atten *= smoothstep(_387, cos_inner, dot(-l, fast::normalize(_377.xyz)));\n        }\n    }\n    int _425;\n    if (_328)\n    {\n        _425 = 0;\n    }\n    else\n    {\n        _425 = (_321 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _318.xyz * atten, atten, 1.0, dist, _425 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _675)\n{\n    float _665;\n    if (i == 0)\n    {\n        _665 = _675.fa_shadow_split.x;\n    }\n    else\n    {\n        float _681;\n        if (i == 1)\n        {\n            _681 = _675.fa_shadow_split.y;\n        }\n        else\n        {\n            float _689;\n            if (i == 2)\n            {\n                _689 = _675.fa_shadow_split.z;\n            }\n            else\n            {\n                _689 = _675.fa_shadow_split.w;\n            }\n            _681 = _689;\n        }\n        _665 = _681;\n    }\n    return _665;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _722 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _726;\n    if (conv.x < 0.5)\n    {\n        _726 = _722;\n    }\n    else\n    {\n        _726 = (conv.y * conv.z) / (conv.z - (_722 * (conv.z - conv.y)));\n    }\n    return _726;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _653 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_653), sin(_653)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _675, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _772 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _786 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _772;\n            float2 _805 = fa_shadow_vogel(param_3, param_4, param_5) * _786;\n            float2 param_6 = uv + (_805 * _675.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _817 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_817 < (zr - (length(_805) * plane)))\n            {\n                sum += _817;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _861 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _861; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _861;\n        float param_11 = _772;\n        float2 _880 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_880 * _675.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_880) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_861);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _675, texture2d<float> fa_shadow_tex)\n{\n    float _922 = fast::max(_675.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _927 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _933 = sqrt(1.0 - (_927 * _927));\n    float _941 = fast::min(_933 / fast::max(_927, 0.20000000298023223876953125), 4.0);\n    float _946;\n    if (_675.fa_shadow_bias.y > 0.0)\n    {\n        _946 = _675.fa_shadow_bias.y;\n    }\n    else\n    {\n        _946 = 1.5 * _675.fa_shadow_info[ci].x;\n    }\n    float4 _971 = _675.fa_shadow_mat[ci] * float4(world + (n * (_946 * _933)), 1.0);\n    float _978 = _971.x;\n    bool _981 = _978 < _675.fa_shadow_rect[ci].x;\n    bool _990;\n    if (!_981)\n    {\n        _990 = _978 > _675.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _990 = _981;\n    }\n    bool _999;\n    if (!_990)\n    {\n        _999 = _971.y < _675.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _999 = _990;\n    }\n    bool _1008;\n    if (!_999)\n    {\n        _1008 = _971.y > _675.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1008 = _999;\n    }\n    bool _1015;\n    if (!_1008)\n    {\n        _1015 = _971.z > 1.0;\n    }\n    else\n    {\n        _1015 = _1008;\n    }\n    if (_1015)\n    {\n        return -1.0;\n    }\n    float _1024;\n    if (_675.fa_shadow_bias.x > 0.0)\n    {\n        _1024 = _675.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1024 = 1.5 * _675.fa_shadow_info[ci].x;\n    }\n    float2 param = _971.xy;\n    float4 param_1 = _675.fa_shadow_rect[ci];\n    float param_2 = _971.z - ((_1024 * (1.0 + (0.5 * _941))) / _922);\n    float param_3 = _675.fa_shadow_info[ci].x;\n    float param_4 = _922;\n    float param_5 = _922 * 0.25;\n    float param_6 = ((_675.fa_shadow_info[ci].x * fast::min(_941, 3.0)) * 0.5) / _922;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_675.fa_shadow_cfg.z + 0.5);\n    float param_9 = _675.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _675, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _439, thread float4& gl_FragCoord, constant fa_shadows& _675, texture2d<float> fa_shadow_tex)\n{\n    if (_439.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1418 = int(_675.fa_shadow_cfg.x + 0.5);\n    if (_1418 < 1)\n    {\n        return 1.0;\n    }\n    float _1434 = dot(world - _675.fa_shadow_eye.xyz, _675.fa_shadow_fwd.xyz);\n    int param = _1418 - 1;\n    if (_1434 > fa_shadow_split_at(param, _675))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1446 = _1418 > 1;\n    bool _1453;\n    if (_1446)\n    {\n        _1453 = _1434 > _675.fa_shadow_split.x;\n    }\n    else\n    {\n        _1453 = _1446;\n    }\n    if (_1453)\n    {\n        ci = 1;\n    }\n    bool _1457 = _1418 > 2;\n    bool _1464;\n    if (_1457)\n    {\n        _1464 = _1434 > _675.fa_shadow_split.y;\n    }\n    else\n    {\n        _1464 = _1457;\n    }\n    if (_1464)\n    {\n        ci = 2;\n    }\n    bool _1468 = _1418 > 3;\n    bool _1475;\n    if (_1468)\n    {\n        _1475 = _1434 > _675.fa_shadow_split.z;\n    }\n    else\n    {\n        _1475 = _1468;\n    }\n    if (_1475)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1418)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1501 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _675, fa_shadow_tex);\n        s = _1501;\n        if (_1501 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_675.fa_shadow_cfg.y > 0.0)\n    {\n        float _1526;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1526 = fa_shadow_split_at(param_5, _675);\n        }\n        else\n        {\n            _1526 = _675.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1545 = _675.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _675) - _1526, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1556 = fast::clamp((_1434 - (fa_shadow_split_at(param_7, _675) - _1545)) / _1545, 0.0, 1.0);\n        if (_1556 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1418)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1577 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _675, fa_shadow_tex);\n                s2 = _1577;\n                if (_1577 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1556);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _439, thread float4& gl_FragCoord, constant fa_shadows& _675, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _439, gl_FragCoord, _675, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _439, thread float4& gl_FragCoord, constant fa_shadows& _675, texture2d<float> fa_shadow_tex)\n{\n    bool _1083 = _439.fa_pbr.z < 0.5;\n    bool _1091;\n    if (!_1083)\n    {\n        _1091 = _675.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1091 = _1083;\n    }\n    if (_1091)\n    {\n        return 1.0;\n    }\n    int param = (int(_675.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1104 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1105 = _1104.x;\n    if (_1105 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1114 = int(_1105 + 0.5);\n    int param_1 = _1114;\n    float4 _1118 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1114 + 1;\n    float4 _1123 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1126 = _1118.y;\n    if (_1126 > 0.0)\n    {\n        float _1143 = 1.0 - smoothstep(0.75 * _1126, _1126, length(world - _675.fa_shadow_eye.xyz));\n        fade = _1143;\n        if (_1143 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1118.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1162 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1165 = abs(_1162);\n        float _1167 = _1165.x;\n        float _1169 = _1165.y;\n        bool _1170 = _1167 >= _1169;\n        bool _1178;\n        if (_1170)\n        {\n            _1178 = _1167 >= _1165.z;\n        }\n        else\n        {\n            _1178 = _1170;\n        }\n        int _1179;\n        if (_1178)\n        {\n            _1179 = (_1162.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1192;\n            if (_1169 >= _1165.z)\n            {\n                _1192 = (_1162.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1192 = (_1162.z > 0.0) ? 4 : 5;\n            }\n            _1179 = _1192;\n        }\n        face = _1179;\n    }\n    int _1211 = (_1114 + 2) + (face * 6);\n    int param_4 = _1211;\n    int param_5 = _1211 + 1;\n    int param_6 = _1211 + 3;\n    float4 _1225 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1211 + 4;\n    float4 _1230 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1211 + 5;\n    float4 _1235 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1247 = _1235.x * fast::max(dot(_1225, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1252 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1258 = sqrt(1.0 - (_1252 * _1252));\n    float _1264 = fast::min(_1258 / fast::max(_1252, 0.20000000298023223876953125), 4.0);\n    float _1267 = _1123.y;\n    float _1269;\n    if (_1267 > 0.0)\n    {\n        _1269 = _1267;\n    }\n    else\n    {\n        _1269 = 1.5 * _1247;\n    }\n    float4 _1289 = float4(world + (n * (_1269 * _1258)), 1.0);\n    float _1293 = dot(_1225, _1289);\n    float _1296 = _1235.y;\n    if (_1293 < _1296)\n    {\n        return 1.0;\n    }\n    float2 _1311 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1289), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1289)) / float2(_1293);\n    float _1313 = _1311.x;\n    bool _1316 = _1313 < _1230.x;\n    bool _1325;\n    if (!_1316)\n    {\n        _1325 = _1313 > _1230.z;\n    }\n    else\n    {\n        _1325 = _1316;\n    }\n    bool _1334;\n    if (!_1325)\n    {\n        _1334 = _1311.y < _1230.y;\n    }\n    else\n    {\n        _1334 = _1325;\n    }\n    bool _1343;\n    if (!_1334)\n    {\n        _1343 = _1311.y > _1230.w;\n    }\n    else\n    {\n        _1343 = _1334;\n    }\n    if (_1343)\n    {\n        return 1.0;\n    }\n    float _1349 = _1123.x;\n    float _1351;\n    if (_1349 > 0.0)\n    {\n        _1351 = _1349;\n    }\n    else\n    {\n        _1351 = 1.5 * _1247;\n    }\n    float2 param_9 = _1311;\n    float4 param_10 = _1230;\n    float param_11 = _1293 - (_1351 * (1.0 + (0.5 * _1264)));\n    float param_12 = _1247;\n    float param_13 = 1.0;\n    float param_14 = _1235.z * 0.25;\n    float param_15 = (_1247 * fast::min(_1264, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _1296, _1235.z);\n    int param_17 = int(_1118.z + 0.5);\n    float param_18 = _1118.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _675, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _439, thread float4& gl_FragCoord, constant fa_shadows& _675, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2518 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _3561 = _2518.direction;\n    float3 _3556 = _2518.color;\n    float _3563 = _2518.attenuation;\n    float _3558 = _2518.shadow;\n    int _3566 = _2518.type;\n    if ((_3566 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _3561;\n        float _2532 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _439, gl_FragCoord, _675, fa_shadow_tex, fa_world_pos);\n        _3558 = _2532;\n        _3556 *= _2532;\n    }\n    else\n    {\n        bool _2543 = _3566 != 0;\n        bool _2549;\n        if (_2543)\n        {\n            _2549 = _3563 > 0.0;\n        }\n        else\n        {\n            _2549 = _2543;\n        }\n        if (_2549)\n        {\n            int param_4 = li;\n            float3 param_5 = world_pos;\n            float3 param_6 = gn;\n            float3 param_7 = _3561;\n            float _2561 = fa_shadow_local(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _439, gl_FragCoord, _675, fa_shadow_tex);\n            _3558 = _2561;\n            _3556 *= _2561;\n        }\n    }\n    return LightSample{ _3561, _3556, _3563, _3558, _2518._distance, _3566 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _675)\n{\n    if (_675.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1601 = int(_675.fa_shadow_cfg.x + 0.5);\n    float _1611 = dot(world - _675.fa_shadow_eye.xyz, _675.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1616 = _1601 > 0;\n    bool _1625;\n    if (_1616)\n    {\n        int param = _1601 - 1;\n        _1625 = _1611 <= fa_shadow_split_at(param, _675);\n    }\n    else\n    {\n        _1625 = _1616;\n    }\n    if (_1625)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1632 = _1601 > 1;\n        bool _1639;\n        if (_1632)\n        {\n            _1639 = _1611 > _675.fa_shadow_split.x;\n        }\n        else\n        {\n            _1639 = _1632;\n        }\n        if (_1639)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1645 = _1601 > 2;\n        bool _1652;\n        if (_1645)\n        {\n            _1652 = _1611 > _675.fa_shadow_split.y;\n        }\n        else\n        {\n            _1652 = _1645;\n        }\n        if (_1652)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1658 = _1601 > 3;\n        bool _1665;\n        if (_1658)\n        {\n            _1665 = _1611 > _675.fa_shadow_split.z;\n        }\n        else\n        {\n            _1665 = _1658;\n        }\n        if (_1665)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _439 [[buffer(1)]], constant fa_shadows& _675 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3278 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3278 = -_3278;\n    }\n    float3 _2942 = fast::normalize(_439.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _439, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3278, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2942, short(gl_FrontFacing) };\n    Surface _2950 = fa_standard_surface(param_1, _439, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3317 = _2950.albedo;\n    float _3318 = _2950.alpha;\n    float3 _3319 = _2950.normal;\n    float _3320 = _2950.metallic;\n    float _3321 = _2950.roughness;\n    float _3322 = _2950.occlusion;\n    float3 _3323 = _2950.emission;\n    float _3324 = _2950.clearcoat;\n    float _3325 = _2950.clearcoat_roughness;\n    float3 _3326 = _2950.sheen_color;\n    float _3327 = _2950.sheen_roughness;\n    float _3328 = _2950.anisotropy;\n    float _3329 = _2950.anisotropy_rotation;\n    float _3330 = _2950.specular;\n    float _3331 = _2950.ior;\n    float3 _3332 = _2950.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3278, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2942, short(gl_FrontFacing) };\n    Surface param_3 = _2950;\n    surface(param_2, param_3);\n    _3317 = param_3.albedo;\n    _3318 = param_3.alpha;\n    _3319 = param_3.normal;\n    _3320 = param_3.metallic;\n    _3321 = param_3.roughness;\n    _3322 = param_3.occlusion;\n    _3323 = param_3.emission;\n    _3324 = param_3.clearcoat;\n    _3325 = param_3.clearcoat_roughness;\n    _3326 = param_3.sheen_color;\n    _3327 = param_3.sheen_roughness;\n    _3328 = param_3.anisotropy;\n    _3329 = param_3.anisotropy_rotation;\n    _3330 = param_3.specular;\n    _3331 = param_3.ior;\n    _3332 = param_3.specular_color;\n    float3 result;\n    if (_439.fa_emissive.w > 0.5)\n    {\n        result = _3317;\n    }\n    else\n    {\n        float3 _2971 = _3319;\n        float3 _2972 = fast::normalize(_2971);\n        _3319 = _2972;\n        float3 param_4 = _2972;\n        SurfaceInput param_5 = SurfaceInput{ in.fa_world_pos, _3278, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2942, short(gl_FrontFacing) };\n        Surface param_6 = Surface{ _3317, _3318, _3319, _3320, _3321, _3322, _3323, _3324, _3325, _3326, _3327, _3328, _3329, _3330, _3331, _3332 };\n        float3 param_7 = fa_ambient_light(param_4, _439, fa_env_smp, fa_irr_tex);\n        float3 lit = ambient(param_5, param_6, param_7, _439, fa_env_tex, fa_env_smp);\n        int _2991 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2991; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8, fa_light_tex, fa_shadow_smp, _439, fa_cl_ndir, fa_cl_slot);\n            float3 param_10 = in.fa_world_pos;\n            float3 param_11 = _3278;\n            SurfaceInput param_12 = SurfaceInput{ in.fa_world_pos, _3278, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2942, short(gl_FrontFacing) };\n            Surface param_13 = Surface{ _3317, _3318, _3319, _3320, _3321, _3322, _3323, _3324, _3325, _3326, _3327, _3328, _3329, _3330, _3331, _3332 };\n            LightSample param_14 = fa_light_shadowed(param_9, param_10, param_11, fa_light_tex, fa_shadow_smp, _439, gl_FragCoord, _675, fa_shadow_tex, in.fa_world_pos);\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    float3 _3028 = result;\n    float3 _3029 = _3028 + _3323;\n    result = _3029;\n    float3 param_15 = _3029;\n    float3 param_16 = in.fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16, _675);\n    bool _3038 = _439.fa_fog.w > 0.0;\n    bool _3045;\n    if (!_3038)\n    {\n        _3045 = _439.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3045 = _3038;\n    }\n    if (_3045)\n    {\n        float3 _3054 = in.fa_world_pos - _439.fa_camera_pos.xyz;\n        float _3060 = dot(_3054, _439.fa_fog_c.xyz);\n        bool _3064 = _439.fa_fog_c.w > 0.5;\n        float _3065;\n        if (_3064)\n        {\n            _3065 = _3060;\n        }\n        else\n        {\n            _3065 = length(_3054);\n        }\n        float _3077 = _3065 - _439.fa_fog_b.x;\n        if (_3077 > 0.0)\n        {\n            float _3086 = _439.fa_fog.w * _3077;\n            float tau = _3086 * _3086;\n            if (_439.fa_fog_b.y > 0.0)\n            {\n                float _3102;\n                if (_3064)\n                {\n                    _3102 = in.fa_world_pos.y - (_439.fa_fog_c.y * _3060);\n                }\n                else\n                {\n                    _3102 = _439.fa_camera_pos.y;\n                }\n                float _3123 = mix(_3102, in.fa_world_pos.y, fast::clamp(_439.fa_fog_b.x / _3065, 0.0, 1.0));\n                float _3127 = in.fa_world_pos.y - _3123;\n                float _3132 = _3123 - _439.fa_fog_b.z;\n                float _3137 = in.fa_world_pos.y - _439.fa_fog_b.z;\n                bool _3140 = _3132 <= 0.0;\n                bool _3141 = !_3140;\n                bool _3147;\n                if (_3141)\n                {\n                    _3147 = _439.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3147 = _3140;\n                }\n                float _3148;\n                if (_3147)\n                {\n                    _3148 = _439.fa_fog_b.y;\n                }\n                else\n                {\n                    _3148 = _439.fa_fog_b.y * exp(-fast::min(_439.fa_fog_b.w * _3132, 80.0));\n                }\n                bool _3175;\n                if (_3141)\n                {\n                    _3175 = _439.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3175 = _3140;\n                }\n                float _3176;\n                if (_3175)\n                {\n                    _3176 = _439.fa_fog_b.y * _3132;\n                }\n                else\n                {\n                    _3176 = (_439.fa_fog_b.y * (1.0 - exp(-fast::min(_439.fa_fog_b.w * _3132, 80.0)))) / _439.fa_fog_b.w;\n                }\n                bool _3201 = _3137 <= 0.0;\n                bool _3208;\n                if (!_3201)\n                {\n                    _3208 = _439.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3208 = _3201;\n                }\n                float _3209;\n                if (_3208)\n                {\n                    _3209 = _439.fa_fog_b.y * _3137;\n                }\n                else\n                {\n                    _3209 = (_439.fa_fog_b.y * (1.0 - exp(-fast::min(_439.fa_fog_b.w * _3137, 80.0)))) / _439.fa_fog_b.w;\n                }\n                float _3236;\n                if (abs(_3127) < 0.001000000047497451305389404296875)\n                {\n                    _3236 = _3148;\n                }\n                else\n                {\n                    _3236 = (_3209 - _3176) / _3127;\n                }\n                tau += (_3077 * fast::max(_3236, 0.0));\n            }\n            result = mix(result, _439.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3318);\n    return out;\n}\n\n",
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
            "inst_name": "_439",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_675",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
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
