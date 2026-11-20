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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nconstant spvUnsafeArray<float, 63> _1616 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _486)\n{\n    bool _491 = _486.fa_cl_info.x < 0.0;\n    bool _498;\n    if (!_491)\n    {\n        _498 = _486.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _498 = _491;\n    }\n    bool _506;\n    if (!_498)\n    {\n        _506 = _486.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _506 = _498;\n    }\n    bool _513;\n    if (!_506)\n    {\n        _513 = _486.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _513 = _506;\n    }\n    bool _520;\n    if (!_513)\n    {\n        _520 = _486.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _520 = _513;\n    }\n    if (_520)\n    {\n        return int2(0);\n    }\n    float4 _530 = float4(world_pos, 1.0);\n    float _537 = dot(_486.fa_cl_vpw, _530);\n    if (!(_537 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _559 = float2(dot(_486.fa_cl_vpx, _530), dot(_486.fa_cl_vpy, _530)) / float2(_537);\n    int _563 = int(_486.fa_cl_grid.x);\n    int _567 = int(_486.fa_cl_grid.y);\n    int param = (int(_486.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_486.fa_cl_fwd.xyz, world_pos) + _486.fa_cl_fwd.w, _486.fa_cl_grid.w) / _486.fa_cl_grid.w) * _486.fa_cl_grid.z)), 0, int(_486.fa_cl_info.y) - 1) * _567) + clamp(int(floor(((_559.y * 0.5) + 0.5) * _486.fa_cl_grid.y)), 0, _567 - 1)) * _563)) + clamp(int(floor(((_559.x * 0.5) + 0.5) * _486.fa_cl_grid.x)), 0, _563 - 1);\n    float4 _638 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_638.x), int(_638.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _486, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_486.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2435 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _486);\n    fa_cl_slot = _2435.x;\n    fa_cl_local = _2435.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2562 = fa_linear_to_srgb(param);\n        c = _2562;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2570 = fa_srgb_to_linear(param_1);\n            c = _2570;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _241;\n    if (bool(i.front_facing))\n    {\n        _241 = i.world_normal;\n    }\n    else\n    {\n        _241 = -i.world_normal;\n    }\n    float3 _265 = fast::normalize(i.world_tangent.xyz - (_241 * dot(_241, i.world_tangent.xyz)));\n    float3 _293 = fast::normalize(((_265 * m.x) + ((cross(_241, _265) * i.world_tangent.w) * m.y)) + (_241 * m.z));\n    float3 _296;\n    if (bool(i.front_facing))\n    {\n        _296 = _293;\n    }\n    else\n    {\n        _296 = -_293;\n    }\n    return _296;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _486, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _486.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2601 = fa_tex_fix(param_2, param_3);\n    float4 _3816 = base_t;\n    _3816.x = _2601.x;\n    _3816.y = _2601.y;\n    _3816.z = _2601.z;\n    base_t = _3816;\n    float4 _2615 = (_3816 * _486.fa_base_color) * i.vertex_color;\n    float3 _3750 = i.world_normal;\n    if (_486.fa_maps.z > 0.5)\n    {\n        float param_4 = _486.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2647 = fa_tex_fix(param_6, param_7);\n        float3 _2650 = (_2647 * 2.0) - float3(1.0);\n        float2 _2655 = _2650.xy * _486.fa_maps.x;\n        float3 _3824 = _2650;\n        _3824.x = _2655.x;\n        _3824.y = _2655.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3824;\n        _3750 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _486.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2684 = fa_tex_fix(param_12, param_13);\n    float4 _3827 = mrt;\n    _3827.x = _2684.x;\n    _3827.y = _2684.y;\n    _3827.z = _2684.z;\n    mrt = _3827;\n    float4 _2712 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _486.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2712.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2724 = fa_tex_fix(param_16, param_17);\n    float param_18 = _486.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2754 = fa_tex_fix(param_20, param_21);\n    float _3755 = _486.fa_layers_a.x;\n    float _3756 = _486.fa_layers_a.y;\n    float _3759 = _486.fa_layers_a.z;\n    float _3758 = _486.fa_layers_b.w;\n    float _3761 = _486.fa_layers_c.x;\n    if (_486.fa_layers_c.z > 0.5)\n    {\n        if (mod(_486.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3755 *= _2724.y;\n            _3756 *= _2724.z;\n            _3758 *= _2712.w;\n        }\n        if (_486.fa_layers_c.z > 1.5)\n        {\n            _3759 *= mrt.x;\n            _3761 *= mrt.w;\n        }\n    }\n    return Surface{ _2615.xyz, _2615.w, _3750, fast::clamp(_486.fa_pbr.x * _2684.z, 0.0, 1.0), fast::clamp(_486.fa_pbr.y * _2684.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_486.fa_maps.y * (_2724.x - 1.0)), _486.fa_emissive.xyz + (_486.fa_model_emissive.xyz * _2754), _3755, _3756, _486.fa_layers_b.xyz, _3758, _3759, _486.fa_layers_a.w, _3761, _486.fa_layers_c.y, _486.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1541 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1549 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1552 = int(_1541);\n    int _1555 = int(_1549);\n    float _1565 = _1549 - float(_1555);\n    int _1621 = (_1552 * 9) + _1555;\n    int _1641 = ((_1552 + 1) * 9) + _1555;\n    return mix(mix(_1616[_1621], _1616[_1621 + 1], _1565), mix(_1616[_1641], _1616[_1641 + 1], _1565), _1541 - float(_1552));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _3673 = false;\n    float _3674 = 1.0;\n    float _3675 = 1.0;\n    float _3676 = 1.0;\n    float _3677 = 0.0;\n    float _3678 = 0.0;\n    float _3679 = 0.0;\n    float _3680 = 0.0;\n    float _3682 = 1.0;\n    bool _3683 = false;\n    float3 _3684 = float3(0.0);\n    float _3685 = 1.0;\n    float _3686 = 1.0;\n    float _3687 = 1.0;\n    float _3688 = 0.0;\n    float _3689 = 0.0;\n    float3 _3690 = float3(1.0, 0.0, 0.0);\n    float3 _3691 = float3(0.0, 0.0, 1.0);\n    float _3692 = 1.0;\n    float _3693 = 1.0;\n    float _1696 = fast::clamp(s.specular, 0.0, 1.0);\n    float _1700 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _1705 = (_1696 != 1.0) || (_1700 != 1.5);\n    bool _1715;\n    if (!_1705)\n    {\n        _1715 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _1715 = _1705;\n    }\n    if (_1715)\n    {\n        float _1723 = (_1700 - 1.0) / (_1700 + 1.0);\n        f0 = mix(fast::min(float3(_1723 * _1723) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _1696, s.albedo, float3(metallic));\n        _3674 = mix(_1696, 1.0, metallic);\n        _3673 = true;\n    }\n    float _1751 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_1751 > 0.0)\n    {\n        float _1759 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3677 = _1751;\n        _3678 = _1759;\n        float _1766 = _1759 * _1759;\n        _3679 = _1766;\n        _3680 = _1766 * _1766;\n        float _1778 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3682 = _1778;\n        _3675 = 1.0 - (_1751 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _1778, 0.0, 1.0), 5.0))));\n        _3673 = true;\n    }\n    float3 _1798 = fast::max(s.sheen_color, float3(0.0));\n    float _1807 = fast::max(_1798.x, fast::max(_1798.y, _1798.z));\n    if (_1807 > 0.0)\n    {\n        float _1815 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3683 = true;\n        _3684 = _1798;\n        _3685 = _1815;\n        _3686 = _1815 * _1815;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1815;\n        float _1832 = fa_sheen_albedo(param, param_1);\n        _3688 = _1832;\n        _3687 = 1.0 - fast::min(_1807 * _1832, 1.0);\n        _3673 = true;\n    }\n    _3676 = _3675 * _3687;\n    float _1851 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_1851 != 0.0)\n    {\n        float3 _1866 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1866;\n        if (dot(_1866, _1866) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _1884 = t;\n        float3 _1885 = fast::normalize(_1884);\n        t = _1885;\n        float3 _1910 = fast::normalize((_1885 * cos(s.anisotropy_rotation)) + ((cross(n, _1885) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3690 = _1910;\n        _3691 = cross(n, _1910);\n        float _1920 = roughness * roughness;\n        float _1926 = mix(_1920, 1.0, _1851 * _1851);\n        bool _1928 = _1851 > 0.0;\n        _3692 = _1928 ? _1926 : _1920;\n        _3693 = _1928 ? _1920 : _1926;\n        _3689 = _1851;\n        _3673 = true;\n    }\n    return FaLayers{ short(_3673), _3674, _3675, _3676, _3677, _3678, _3679, _3680, i.world_normal, _3682, short(_3683), _3684, _3685, _3686, _3687, _3688, _3689, _3690, _3691, _3692, _3693 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _486, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_486.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _486.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _486, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _486, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _486)\n{\n    int param = (int(_486.fa_cl_info.x) + int(_486.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _486, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _486);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _360 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _366 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _369 = _366.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _375 = _369 < 0.5;\n    float3 l;\n    if (_375)\n    {\n        l = fast::normalize(_360.xyz);\n    }\n    else\n    {\n        float3 _387 = _360.xyz - world_pos;\n        float _389 = length(_387);\n        dist = _389;\n        l = _387 / float3(fast::max(_389, 9.9999997473787516355514526367188e-05));\n        float _404 = _389 / fast::max(_360.w, 0.001000000047497451305389404296875);\n        float _410 = fast::clamp(1.0 - (_404 * _404), 0.0, 1.0);\n        atten = _410 * _410;\n        if (_369 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _424 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _434 = _424.w;\n            int param_3 = (li * 4) + 3;\n            float4 _440 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _441 = _440.x;\n            float cos_inner = _441;\n            if (_441 > 1.5)\n            {\n                cos_inner = mix(_434, 1.0, 0.25);\n            }\n            atten *= smoothstep(_434, cos_inner, dot(-l, fast::normalize(_424.xyz)));\n        }\n    }\n    int _472;\n    if (_375)\n    {\n        _472 = 0;\n    }\n    else\n    {\n        _472 = (_369 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _366.xyz * atten, atten, 1.0, dist, _472 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _722)\n{\n    float _712;\n    if (i == 0)\n    {\n        _712 = _722.fa_shadow_split.x;\n    }\n    else\n    {\n        float _728;\n        if (i == 1)\n        {\n            _728 = _722.fa_shadow_split.y;\n        }\n        else\n        {\n            float _736;\n            if (i == 2)\n            {\n                _736 = _722.fa_shadow_split.z;\n            }\n            else\n            {\n                _736 = _722.fa_shadow_split.w;\n            }\n            _728 = _736;\n        }\n        _712 = _728;\n    }\n    return _712;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _700 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_700), sin(_700)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _722, texture2d<float> fa_shadow_tex)\n{\n    float _774 = fast::max(_722.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _779 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _785 = sqrt(1.0 - (_779 * _779));\n    float _793 = fast::min(_785 / fast::max(_779, 0.20000000298023223876953125), 4.0);\n    float _798;\n    if (_722.fa_shadow_bias.y > 0.0)\n    {\n        _798 = _722.fa_shadow_bias.y;\n    }\n    else\n    {\n        _798 = 1.5 * _722.fa_shadow_info[ci].x;\n    }\n    float4 _823 = _722.fa_shadow_mat[ci] * float4(world + (n * (_798 * _785)), 1.0);\n    float _830 = _823.x;\n    bool _833 = _830 < _722.fa_shadow_rect[ci].x;\n    bool _842;\n    if (!_833)\n    {\n        _842 = _830 > _722.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _842 = _833;\n    }\n    bool _851;\n    if (!_842)\n    {\n        _851 = _823.y < _722.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _851 = _842;\n    }\n    bool _860;\n    if (!_851)\n    {\n        _860 = _823.y > _722.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _860 = _851;\n    }\n    bool _867;\n    if (!_860)\n    {\n        _867 = _823.z > 1.0;\n    }\n    else\n    {\n        _867 = _860;\n    }\n    if (_867)\n    {\n        return -1.0;\n    }\n    float _876;\n    if (_722.fa_shadow_bias.x > 0.0)\n    {\n        _876 = _722.fa_shadow_bias.x;\n    }\n    else\n    {\n        _876 = 1.5 * _722.fa_shadow_info[ci].x;\n    }\n    float _895 = _823.z - ((_876 * (1.0 + (0.5 * _793))) / _774);\n    float _904 = ((_722.fa_shadow_info[ci].x * fast::min(_793, 3.0)) * 0.5) / _774;\n    int _913 = int(_722.fa_shadow_cfg.z + 0.5);\n    if (_913 == 1)\n    {\n        float2 param = _823.xy;\n        float4 param_1 = _722.fa_shadow_rect[ci];\n        float _924 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_895 <= _924);\n    }\n    float _931 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _934 = _913 == 2;\n    if (_934)\n    {\n        float _948 = fast::clamp(((_722.fa_shadow_cfg.w * _774) * 0.25) / _722.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _931;\n            float2 _967 = fa_shadow_vogel(param_2, param_3, param_4) * _948;\n            float2 param_5 = _823.xy + (_967 * _722.fa_shadow_bias.zw);\n            float4 param_6 = _722.fa_shadow_rect[ci];\n            float _978 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_978 < (_895 - (length(_967) * _904)))\n            {\n                sum += _978;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_895 - (sum / cnt), 0.0) * _774) * _722.fa_shadow_cfg.w) / _722.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1022 = _934 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1022; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1022;\n        float param_9 = _931;\n        float2 _1041 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _823.xy + (_1041 * _722.fa_shadow_bias.zw);\n        float4 param_11 = _722.fa_shadow_rect[ci];\n        float _1052 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_895 - (length(_1041) * _904)) <= _1052);\n    }\n    return lit / float(_1022);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _486, thread float4& gl_FragCoord, constant fa_shadows& _722, texture2d<float> fa_shadow_tex)\n{\n    if (_486.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1082 = int(_722.fa_shadow_cfg.x + 0.5);\n    if (_1082 < 1)\n    {\n        return 1.0;\n    }\n    float _1098 = dot(world - _722.fa_shadow_eye.xyz, _722.fa_shadow_fwd.xyz);\n    int param = _1082 - 1;\n    if (_1098 > fa_shadow_split_at(param, _722))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1110 = _1082 > 1;\n    bool _1117;\n    if (_1110)\n    {\n        _1117 = _1098 > _722.fa_shadow_split.x;\n    }\n    else\n    {\n        _1117 = _1110;\n    }\n    if (_1117)\n    {\n        ci = 1;\n    }\n    bool _1121 = _1082 > 2;\n    bool _1128;\n    if (_1121)\n    {\n        _1128 = _1098 > _722.fa_shadow_split.y;\n    }\n    else\n    {\n        _1128 = _1121;\n    }\n    if (_1128)\n    {\n        ci = 2;\n    }\n    bool _1132 = _1082 > 3;\n    bool _1139;\n    if (_1132)\n    {\n        _1139 = _1098 > _722.fa_shadow_split.z;\n    }\n    else\n    {\n        _1139 = _1132;\n    }\n    if (_1139)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1082)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1165 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _722, fa_shadow_tex);\n        s = _1165;\n        if (_1165 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_722.fa_shadow_cfg.y > 0.0)\n    {\n        float _1190;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1190 = fa_shadow_split_at(param_5, _722);\n        }\n        else\n        {\n            _1190 = _722.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1209 = _722.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _722) - _1190, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1220 = fast::clamp((_1098 - (fa_shadow_split_at(param_7, _722) - _1209)) / _1209, 0.0, 1.0);\n        if (_1220 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1082)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1241 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _722, fa_shadow_tex);\n                s2 = _1241;\n                if (_1241 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1220);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _486, thread float4& gl_FragCoord, constant fa_shadows& _722, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _486, gl_FragCoord, _722, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _486, thread float4& gl_FragCoord, constant fa_shadows& _722, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _2462 = fa_lm.z > 0.5;\n    bool _2468;\n    if (_2462)\n    {\n        int param = li;\n        _2468 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2468 = _2462;\n    }\n    if (_2468)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2490 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _3735 = _2490.direction;\n    float3 _3730 = _2490.color;\n    float _3732 = _2490.shadow;\n    int _3740 = _2490.type;\n    if ((_3740 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3735;\n        float _2504 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _486, gl_FragCoord, _722, fa_shadow_tex, fa_world_pos);\n        _3732 = _2504;\n        _3730 *= _2504;\n    }\n    return LightSample{ _3735, _3730, _2490.attenuation, _3732, _2490._distance, _3740 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _2078 = tdh / at;\n    float _2082 = bdh / ab;\n    float _2094 = ((_2078 * _2078) + (_2082 * _2082)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2094) * _2094);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _2175 = 1.0 / alpha;\n    return ((2.0 + _2175) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2175)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _2208 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2287 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2287) * _2287);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2208);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2208));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2360 = fast::max(dot(L.nc, l), 0.0);\n        float _2366 = fast::max(dot(L.nc, h), 0.0);\n        float _2375 = ((_2366 * _2366) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2375) * _2375)) * (0.5 / fast::max(mix((2.0 * _2360) * L.coat_ndv, _2360 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2360)) * _2360);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1473 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1476 = _1473.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1476 * _1476, exp2((-9.27999973297119140625) * ndv)) * _1476) + _1473.y)) + _1473.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _486, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_486.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _486.fa_env_horizon.w)).xyz;\n    }\n    float _1378 = rough * rough;\n    float _1408 = 0.60000002384185791015625 * _1378;\n    return mix(mix(_486.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_486.fa_env_horizon.xyz, _486.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1378)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1408, 0.0500000007450580596923828125 + _1408, d.y))), ((_486.fa_env_sky.xyz + _486.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1378 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _486, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _1961;\n        if (L.aniso >= 0.0)\n        {\n            _1961 = L.b;\n        }\n        else\n        {\n            _1961 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_1961, v), _1961), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1994 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _486, fa_env_tex, fa_env_smp) * ((f0 * _1994.x) + (float3(L.f90) * _1994.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _486, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2049 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _486, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _2049.x) + _2049.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _486, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1515 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _486, fa_env_tex, fa_env_smp) * ((f0 * _1515.x) + float3(_1515.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _722)\n{\n    if (_722.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1265 = int(_722.fa_shadow_cfg.x + 0.5);\n    float _1275 = dot(world - _722.fa_shadow_eye.xyz, _722.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1280 = _1265 > 0;\n    bool _1289;\n    if (_1280)\n    {\n        int param = _1265 - 1;\n        _1289 = _1275 <= fa_shadow_split_at(param, _722);\n    }\n    else\n    {\n        _1289 = _1280;\n    }\n    if (_1289)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1296 = _1265 > 1;\n        bool _1303;\n        if (_1296)\n        {\n            _1303 = _1275 > _722.fa_shadow_split.x;\n        }\n        else\n        {\n            _1303 = _1296;\n        }\n        if (_1303)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1309 = _1265 > 2;\n        bool _1316;\n        if (_1309)\n        {\n            _1316 = _1275 > _722.fa_shadow_split.y;\n        }\n        else\n        {\n            _1316 = _1309;\n        }\n        if (_1316)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1322 = _1265 > 3;\n        bool _1329;\n        if (_1322)\n        {\n            _1329 = _1275 > _722.fa_shadow_split.z;\n        }\n        else\n        {\n            _1329 = _1322;\n        }\n        if (_1329)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _486 [[buffer(1)]], constant fa_shadows& _722 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3452 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3452 = -_3452;\n    }\n    float3 _2894 = fast::normalize(_486.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _486, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3452, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2894, short(gl_FrontFacing) };\n    Surface _2902 = fa_standard_surface(param_1, _486, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3483 = _2902.albedo;\n    float _3484 = _2902.alpha;\n    float3 _3485 = _2902.normal;\n    float _3486 = _2902.metallic;\n    float _3487 = _2902.roughness;\n    float _3488 = _2902.occlusion;\n    float3 _3489 = _2902.emission;\n    float _3490 = _2902.clearcoat;\n    float _3491 = _2902.clearcoat_roughness;\n    float3 _3492 = _2902.sheen_color;\n    float _3493 = _2902.sheen_roughness;\n    float _3494 = _2902.anisotropy;\n    float _3495 = _2902.anisotropy_rotation;\n    float _3496 = _2902.specular;\n    float _3497 = _2902.ior;\n    float3 _3498 = _2902.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3452, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2894, short(gl_FrontFacing) };\n    Surface param_3 = _2902;\n    surface(param_2, param_3);\n    _3483 = param_3.albedo;\n    _3484 = param_3.alpha;\n    _3485 = param_3.normal;\n    _3486 = param_3.metallic;\n    _3487 = param_3.roughness;\n    _3488 = param_3.occlusion;\n    _3489 = param_3.emission;\n    _3490 = param_3.clearcoat;\n    _3491 = param_3.clearcoat_roughness;\n    _3492 = param_3.sheen_color;\n    _3493 = param_3.sheen_roughness;\n    _3494 = param_3.anisotropy;\n    _3495 = param_3.anisotropy_rotation;\n    _3496 = param_3.specular;\n    _3497 = param_3.ior;\n    _3498 = param_3.specular_color;\n    float3 result;\n    if (_486.fa_emissive.w > 0.5)\n    {\n        result = _3483;\n    }\n    else\n    {\n        float3 _2924 = fast::normalize(_3485);\n        float _2931 = fast::clamp(_3486, 0.0, 1.0);\n        float _2935 = fast::clamp(_3487, 0.0500000007450580596923828125, 1.0);\n        float _2939 = _2935 * _2935;\n        float _2943 = _2939 * _2939;\n        float _2948 = fast::max(dot(_2924, _2894), 9.9999997473787516355514526367188e-05);\n        float3 _2954 = _3483 * (1.0 - _2931);\n        float3 _2961 = mix(float3(0.039999999105930328369140625), _3483, float3(_2931));\n        float3 f0 = _2961;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _3452, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2894, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _3483, _3484, _3485, _3486, _3487, _3488, _3489, _3490, _3491, _3492, _3493, _3494, _3495, _3496, _3497, _3498 };\n        float3 param_6 = _2924;\n        float3 param_7 = _2894;\n        float param_8 = _2931;\n        float param_9 = _2935;\n        float3 param_10 = _2961;\n        FaLayers _2977 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _2924;\n        float3 lit = (fa_indirect_diffuse(param_11, _486, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap) * _2954) * _3488;\n        if (_2977.on)\n        {\n            lit *= _2977.base_scale;\n        }\n        int _2999 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2999; ln++)\n        {\n            int param_12 = ln;\n            int _3012 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _486, fa_cl_ndir, fa_cl_slot);\n            bool _3015 = in.fa_lm.z > 0.5;\n            bool _3021;\n            if (_3015)\n            {\n                int param_13 = _3012;\n                _3021 = fa_light_baked(param_13, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _3021 = _3015;\n            }\n            if (_3021)\n            {\n                continue;\n            }\n            int param_14 = _3012;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _3452;\n            LightSample _3033 = fa_light_shadowed(param_14, param_15, param_16, fa_light_tex, fa_shadow_smp, _486, gl_FragCoord, _722, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            float3 _3657 = _3033.direction;\n            float _3041 = fast::max(dot(_2924, _3657), 0.0);\n            float _3047 = _3033.attenuation * _3033.shadow;\n            float3 _3052 = fast::normalize(_3657 + _2894);\n            float _3057 = fast::max(dot(_2924, _3052), 0.0);\n            float _3062 = fast::max(dot(_2894, _3052), 0.0);\n            if (_2977.on)\n            {\n                FaLayers param_17 = _2977;\n                float3 param_18 = _2954;\n                float3 param_19 = f0;\n                float3 param_20 = _2924;\n                float3 param_21 = _2894;\n                float3 param_22 = _3657;\n                float3 param_23 = _3052;\n                float param_24 = _3041;\n                float param_25 = _2948;\n                float param_26 = _3057;\n                float param_27 = _3062;\n                float param_28 = _2939;\n                float param_29 = _2943;\n                int param_30 = _3012;\n                lit += (fa_layers_light(param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29) * (fa_light_rgb(param_30, fa_light_tex, fa_shadow_smp) * _3047));\n            }\n            else\n            {\n                float _3110 = ((_3057 * _3057) * (_2943 - 1.0)) + 1.0;\n                int param_31 = _3012;\n                lit += (((_2954 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _3062, 5.0))) * (((_2943 / ((3.1415927410125732421875 * _3110) * _3110)) * (0.5 / fast::max(mix((2.0 * _3041) * _2948, _3041 + _2948, _2939), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3041))) * fa_light_rgb(param_31, fa_light_tex, fa_shadow_smp)) * (_3041 * _3047));\n            }\n        }\n        if (_2977.on)\n        {\n            FaLayers param_32 = _2977;\n            float3 param_33 = _2924;\n            float3 param_34 = _2894;\n            float3 param_35 = f0;\n            float param_36 = _2935;\n            lit += (fa_layers_ibl(param_32, param_33, param_34, param_35, param_36, _486, fa_env_tex, fa_env_smp) * _3488);\n        }\n        else\n        {\n            float3 param_37 = _2924;\n            float3 param_38 = _2894;\n            float3 param_39 = f0;\n            float param_40 = _2935;\n            lit += (fa_sky_reflection(param_37, param_38, param_39, param_40, _486, fa_env_tex, fa_env_smp) * _3488);\n        }\n        result = lit;\n    }\n    float3 _3203 = result;\n    float3 _3204 = _3203 + _3489;\n    result = _3204;\n    float3 param_41 = _3204;\n    float3 param_42 = in.fa_world_pos;\n    result = fa_shadow_debug(param_41, param_42, _722);\n    bool _3213 = _486.fa_fog.w > 0.0;\n    bool _3220;\n    if (!_3213)\n    {\n        _3220 = _486.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3220 = _3213;\n    }\n    if (_3220)\n    {\n        float3 _3229 = in.fa_world_pos - _486.fa_camera_pos.xyz;\n        float _3235 = dot(_3229, _486.fa_fog_c.xyz);\n        bool _3239 = _486.fa_fog_c.w > 0.5;\n        float _3240;\n        if (_3239)\n        {\n            _3240 = _3235;\n        }\n        else\n        {\n            _3240 = length(_3229);\n        }\n        float _3252 = _3240 - _486.fa_fog_b.x;\n        if (_3252 > 0.0)\n        {\n            float _3261 = _486.fa_fog.w * _3252;\n            float tau = _3261 * _3261;\n            if (_486.fa_fog_b.y > 0.0)\n            {\n                float _3277;\n                if (_3239)\n                {\n                    _3277 = in.fa_world_pos.y - (_486.fa_fog_c.y * _3235);\n                }\n                else\n                {\n                    _3277 = _486.fa_camera_pos.y;\n                }\n                float _3298 = mix(_3277, in.fa_world_pos.y, fast::clamp(_486.fa_fog_b.x / _3240, 0.0, 1.0));\n                float _3302 = in.fa_world_pos.y - _3298;\n                float _3307 = _3298 - _486.fa_fog_b.z;\n                float _3312 = in.fa_world_pos.y - _486.fa_fog_b.z;\n                bool _3315 = _3307 <= 0.0;\n                bool _3316 = !_3315;\n                bool _3322;\n                if (_3316)\n                {\n                    _3322 = _486.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3322 = _3315;\n                }\n                float _3323;\n                if (_3322)\n                {\n                    _3323 = _486.fa_fog_b.y;\n                }\n                else\n                {\n                    _3323 = _486.fa_fog_b.y * exp(-fast::min(_486.fa_fog_b.w * _3307, 80.0));\n                }\n                bool _3350;\n                if (_3316)\n                {\n                    _3350 = _486.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3350 = _3315;\n                }\n                float _3351;\n                if (_3350)\n                {\n                    _3351 = _486.fa_fog_b.y * _3307;\n                }\n                else\n                {\n                    _3351 = (_486.fa_fog_b.y * (1.0 - exp(-fast::min(_486.fa_fog_b.w * _3307, 80.0)))) / _486.fa_fog_b.w;\n                }\n                bool _3376 = _3312 <= 0.0;\n                bool _3383;\n                if (!_3376)\n                {\n                    _3383 = _486.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3383 = _3376;\n                }\n                float _3384;\n                if (_3383)\n                {\n                    _3384 = _486.fa_fog_b.y * _3312;\n                }\n                else\n                {\n                    _3384 = (_486.fa_fog_b.y * (1.0 - exp(-fast::min(_486.fa_fog_b.w * _3312, 80.0)))) / _486.fa_fog_b.w;\n                }\n                float _3411;\n                if (abs(_3302) < 0.001000000047497451305389404296875)\n                {\n                    _3411 = _3323;\n                }\n                else\n                {\n                    _3411 = (_3384 - _3351) / _3302;\n                }\n                tau += (_3252 * fast::max(_3411, 0.0));\n            }\n            result = mix(result, _486.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3484);\n    return out;\n}\n\n",
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
            "inst_name": "_486",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_722",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_388, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nconstant spvUnsafeArray<float, 63> _1616 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _486)\n{\n    bool _491 = _486.fa_cl_info.x < 0.0;\n    bool _498;\n    if (!_491)\n    {\n        _498 = _486.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _498 = _491;\n    }\n    bool _506;\n    if (!_498)\n    {\n        _506 = _486.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _506 = _498;\n    }\n    bool _513;\n    if (!_506)\n    {\n        _513 = _486.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _513 = _506;\n    }\n    bool _520;\n    if (!_513)\n    {\n        _520 = _486.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _520 = _513;\n    }\n    if (_520)\n    {\n        return int2(0);\n    }\n    float4 _530 = float4(world_pos, 1.0);\n    float _537 = dot(_486.fa_cl_vpw, _530);\n    if (!(_537 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _559 = float2(dot(_486.fa_cl_vpx, _530), dot(_486.fa_cl_vpy, _530)) / float2(_537);\n    int _563 = int(_486.fa_cl_grid.x);\n    int _567 = int(_486.fa_cl_grid.y);\n    int param = (int(_486.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_486.fa_cl_fwd.xyz, world_pos) + _486.fa_cl_fwd.w, _486.fa_cl_grid.w) / _486.fa_cl_grid.w) * _486.fa_cl_grid.z)), 0, int(_486.fa_cl_info.y) - 1) * _567) + clamp(int(floor(((_559.y * 0.5) + 0.5) * _486.fa_cl_grid.y)), 0, _567 - 1)) * _563)) + clamp(int(floor(((_559.x * 0.5) + 0.5) * _486.fa_cl_grid.x)), 0, _563 - 1);\n    float4 _638 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_638.x), int(_638.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _486, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_486.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2435 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _486);\n    fa_cl_slot = _2435.x;\n    fa_cl_local = _2435.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2562 = fa_linear_to_srgb(param);\n        c = _2562;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2570 = fa_srgb_to_linear(param_1);\n            c = _2570;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _241;\n    if (bool(i.front_facing))\n    {\n        _241 = i.world_normal;\n    }\n    else\n    {\n        _241 = -i.world_normal;\n    }\n    float3 _265 = fast::normalize(i.world_tangent.xyz - (_241 * dot(_241, i.world_tangent.xyz)));\n    float3 _293 = fast::normalize(((_265 * m.x) + ((cross(_241, _265) * i.world_tangent.w) * m.y)) + (_241 * m.z));\n    float3 _296;\n    if (bool(i.front_facing))\n    {\n        _296 = _293;\n    }\n    else\n    {\n        _296 = -_293;\n    }\n    return _296;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _486, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _486.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2601 = fa_tex_fix(param_2, param_3);\n    float4 _3816 = base_t;\n    _3816.x = _2601.x;\n    _3816.y = _2601.y;\n    _3816.z = _2601.z;\n    base_t = _3816;\n    float4 _2615 = (_3816 * _486.fa_base_color) * i.vertex_color;\n    float3 _3750 = i.world_normal;\n    if (_486.fa_maps.z > 0.5)\n    {\n        float param_4 = _486.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2647 = fa_tex_fix(param_6, param_7);\n        float3 _2650 = (_2647 * 2.0) - float3(1.0);\n        float2 _2655 = _2650.xy * _486.fa_maps.x;\n        float3 _3824 = _2650;\n        _3824.x = _2655.x;\n        _3824.y = _2655.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3824;\n        _3750 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _486.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2684 = fa_tex_fix(param_12, param_13);\n    float4 _3827 = mrt;\n    _3827.x = _2684.x;\n    _3827.y = _2684.y;\n    _3827.z = _2684.z;\n    mrt = _3827;\n    float4 _2712 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _486.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2712.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2724 = fa_tex_fix(param_16, param_17);\n    float param_18 = _486.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2754 = fa_tex_fix(param_20, param_21);\n    float _3755 = _486.fa_layers_a.x;\n    float _3756 = _486.fa_layers_a.y;\n    float _3759 = _486.fa_layers_a.z;\n    float _3758 = _486.fa_layers_b.w;\n    float _3761 = _486.fa_layers_c.x;\n    if (_486.fa_layers_c.z > 0.5)\n    {\n        if (mod(_486.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3755 *= _2724.y;\n            _3756 *= _2724.z;\n            _3758 *= _2712.w;\n        }\n        if (_486.fa_layers_c.z > 1.5)\n        {\n            _3759 *= mrt.x;\n            _3761 *= mrt.w;\n        }\n    }\n    return Surface{ _2615.xyz, _2615.w, _3750, fast::clamp(_486.fa_pbr.x * _2684.z, 0.0, 1.0), fast::clamp(_486.fa_pbr.y * _2684.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_486.fa_maps.y * (_2724.x - 1.0)), _486.fa_emissive.xyz + (_486.fa_model_emissive.xyz * _2754), _3755, _3756, _486.fa_layers_b.xyz, _3758, _3759, _486.fa_layers_a.w, _3761, _486.fa_layers_c.y, _486.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1541 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1549 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1552 = int(_1541);\n    int _1555 = int(_1549);\n    float _1565 = _1549 - float(_1555);\n    int _1621 = (_1552 * 9) + _1555;\n    int _1641 = ((_1552 + 1) * 9) + _1555;\n    return mix(mix(_1616[_1621], _1616[_1621 + 1], _1565), mix(_1616[_1641], _1616[_1641 + 1], _1565), _1541 - float(_1552));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _3673 = false;\n    float _3674 = 1.0;\n    float _3675 = 1.0;\n    float _3676 = 1.0;\n    float _3677 = 0.0;\n    float _3678 = 0.0;\n    float _3679 = 0.0;\n    float _3680 = 0.0;\n    float _3682 = 1.0;\n    bool _3683 = false;\n    float3 _3684 = float3(0.0);\n    float _3685 = 1.0;\n    float _3686 = 1.0;\n    float _3687 = 1.0;\n    float _3688 = 0.0;\n    float _3689 = 0.0;\n    float3 _3690 = float3(1.0, 0.0, 0.0);\n    float3 _3691 = float3(0.0, 0.0, 1.0);\n    float _3692 = 1.0;\n    float _3693 = 1.0;\n    float _1696 = fast::clamp(s.specular, 0.0, 1.0);\n    float _1700 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _1705 = (_1696 != 1.0) || (_1700 != 1.5);\n    bool _1715;\n    if (!_1705)\n    {\n        _1715 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _1715 = _1705;\n    }\n    if (_1715)\n    {\n        float _1723 = (_1700 - 1.0) / (_1700 + 1.0);\n        f0 = mix(fast::min(float3(_1723 * _1723) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _1696, s.albedo, float3(metallic));\n        _3674 = mix(_1696, 1.0, metallic);\n        _3673 = true;\n    }\n    float _1751 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_1751 > 0.0)\n    {\n        float _1759 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3677 = _1751;\n        _3678 = _1759;\n        float _1766 = _1759 * _1759;\n        _3679 = _1766;\n        _3680 = _1766 * _1766;\n        float _1778 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3682 = _1778;\n        _3675 = 1.0 - (_1751 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _1778, 0.0, 1.0), 5.0))));\n        _3673 = true;\n    }\n    float3 _1798 = fast::max(s.sheen_color, float3(0.0));\n    float _1807 = fast::max(_1798.x, fast::max(_1798.y, _1798.z));\n    if (_1807 > 0.0)\n    {\n        float _1815 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3683 = true;\n        _3684 = _1798;\n        _3685 = _1815;\n        _3686 = _1815 * _1815;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1815;\n        float _1832 = fa_sheen_albedo(param, param_1);\n        _3688 = _1832;\n        _3687 = 1.0 - fast::min(_1807 * _1832, 1.0);\n        _3673 = true;\n    }\n    _3676 = _3675 * _3687;\n    float _1851 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_1851 != 0.0)\n    {\n        float3 _1866 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1866;\n        if (dot(_1866, _1866) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _1884 = t;\n        float3 _1885 = fast::normalize(_1884);\n        t = _1885;\n        float3 _1910 = fast::normalize((_1885 * cos(s.anisotropy_rotation)) + ((cross(n, _1885) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3690 = _1910;\n        _3691 = cross(n, _1910);\n        float _1920 = roughness * roughness;\n        float _1926 = mix(_1920, 1.0, _1851 * _1851);\n        bool _1928 = _1851 > 0.0;\n        _3692 = _1928 ? _1926 : _1920;\n        _3693 = _1928 ? _1920 : _1926;\n        _3689 = _1851;\n        _3673 = true;\n    }\n    return FaLayers{ short(_3673), _3674, _3675, _3676, _3677, _3678, _3679, _3680, i.world_normal, _3682, short(_3683), _3684, _3685, _3686, _3687, _3688, _3689, _3690, _3691, _3692, _3693 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _486, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_486.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _486.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _486, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _486, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _486)\n{\n    int param = (int(_486.fa_cl_info.x) + int(_486.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _486, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _486);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _360 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _366 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _369 = _366.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _375 = _369 < 0.5;\n    float3 l;\n    if (_375)\n    {\n        l = fast::normalize(_360.xyz);\n    }\n    else\n    {\n        float3 _387 = _360.xyz - world_pos;\n        float _389 = length(_387);\n        dist = _389;\n        l = _387 / float3(fast::max(_389, 9.9999997473787516355514526367188e-05));\n        float _404 = _389 / fast::max(_360.w, 0.001000000047497451305389404296875);\n        float _410 = fast::clamp(1.0 - (_404 * _404), 0.0, 1.0);\n        atten = _410 * _410;\n        if (_369 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _424 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _434 = _424.w;\n            int param_3 = (li * 4) + 3;\n            float4 _440 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _441 = _440.x;\n            float cos_inner = _441;\n            if (_441 > 1.5)\n            {\n                cos_inner = mix(_434, 1.0, 0.25);\n            }\n            atten *= smoothstep(_434, cos_inner, dot(-l, fast::normalize(_424.xyz)));\n        }\n    }\n    int _472;\n    if (_375)\n    {\n        _472 = 0;\n    }\n    else\n    {\n        _472 = (_369 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _366.xyz * atten, atten, 1.0, dist, _472 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _722)\n{\n    float _712;\n    if (i == 0)\n    {\n        _712 = _722.fa_shadow_split.x;\n    }\n    else\n    {\n        float _728;\n        if (i == 1)\n        {\n            _728 = _722.fa_shadow_split.y;\n        }\n        else\n        {\n            float _736;\n            if (i == 2)\n            {\n                _736 = _722.fa_shadow_split.z;\n            }\n            else\n            {\n                _736 = _722.fa_shadow_split.w;\n            }\n            _728 = _736;\n        }\n        _712 = _728;\n    }\n    return _712;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _700 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_700), sin(_700)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _722, texture2d<float> fa_shadow_tex)\n{\n    float _774 = fast::max(_722.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _779 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _785 = sqrt(1.0 - (_779 * _779));\n    float _793 = fast::min(_785 / fast::max(_779, 0.20000000298023223876953125), 4.0);\n    float _798;\n    if (_722.fa_shadow_bias.y > 0.0)\n    {\n        _798 = _722.fa_shadow_bias.y;\n    }\n    else\n    {\n        _798 = 1.5 * _722.fa_shadow_info[ci].x;\n    }\n    float4 _823 = _722.fa_shadow_mat[ci] * float4(world + (n * (_798 * _785)), 1.0);\n    float _830 = _823.x;\n    bool _833 = _830 < _722.fa_shadow_rect[ci].x;\n    bool _842;\n    if (!_833)\n    {\n        _842 = _830 > _722.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _842 = _833;\n    }\n    bool _851;\n    if (!_842)\n    {\n        _851 = _823.y < _722.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _851 = _842;\n    }\n    bool _860;\n    if (!_851)\n    {\n        _860 = _823.y > _722.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _860 = _851;\n    }\n    bool _867;\n    if (!_860)\n    {\n        _867 = _823.z > 1.0;\n    }\n    else\n    {\n        _867 = _860;\n    }\n    if (_867)\n    {\n        return -1.0;\n    }\n    float _876;\n    if (_722.fa_shadow_bias.x > 0.0)\n    {\n        _876 = _722.fa_shadow_bias.x;\n    }\n    else\n    {\n        _876 = 1.5 * _722.fa_shadow_info[ci].x;\n    }\n    float _895 = _823.z - ((_876 * (1.0 + (0.5 * _793))) / _774);\n    float _904 = ((_722.fa_shadow_info[ci].x * fast::min(_793, 3.0)) * 0.5) / _774;\n    int _913 = int(_722.fa_shadow_cfg.z + 0.5);\n    if (_913 == 1)\n    {\n        float2 param = _823.xy;\n        float4 param_1 = _722.fa_shadow_rect[ci];\n        float _924 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_895 <= _924);\n    }\n    float _931 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _934 = _913 == 2;\n    if (_934)\n    {\n        float _948 = fast::clamp(((_722.fa_shadow_cfg.w * _774) * 0.25) / _722.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _931;\n            float2 _967 = fa_shadow_vogel(param_2, param_3, param_4) * _948;\n            float2 param_5 = _823.xy + (_967 * _722.fa_shadow_bias.zw);\n            float4 param_6 = _722.fa_shadow_rect[ci];\n            float _978 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_978 < (_895 - (length(_967) * _904)))\n            {\n                sum += _978;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_895 - (sum / cnt), 0.0) * _774) * _722.fa_shadow_cfg.w) / _722.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1022 = _934 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1022; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1022;\n        float param_9 = _931;\n        float2 _1041 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _823.xy + (_1041 * _722.fa_shadow_bias.zw);\n        float4 param_11 = _722.fa_shadow_rect[ci];\n        float _1052 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_895 - (length(_1041) * _904)) <= _1052);\n    }\n    return lit / float(_1022);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _486, thread float4& gl_FragCoord, constant fa_shadows& _722, texture2d<float> fa_shadow_tex)\n{\n    if (_486.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1082 = int(_722.fa_shadow_cfg.x + 0.5);\n    if (_1082 < 1)\n    {\n        return 1.0;\n    }\n    float _1098 = dot(world - _722.fa_shadow_eye.xyz, _722.fa_shadow_fwd.xyz);\n    int param = _1082 - 1;\n    if (_1098 > fa_shadow_split_at(param, _722))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1110 = _1082 > 1;\n    bool _1117;\n    if (_1110)\n    {\n        _1117 = _1098 > _722.fa_shadow_split.x;\n    }\n    else\n    {\n        _1117 = _1110;\n    }\n    if (_1117)\n    {\n        ci = 1;\n    }\n    bool _1121 = _1082 > 2;\n    bool _1128;\n    if (_1121)\n    {\n        _1128 = _1098 > _722.fa_shadow_split.y;\n    }\n    else\n    {\n        _1128 = _1121;\n    }\n    if (_1128)\n    {\n        ci = 2;\n    }\n    bool _1132 = _1082 > 3;\n    bool _1139;\n    if (_1132)\n    {\n        _1139 = _1098 > _722.fa_shadow_split.z;\n    }\n    else\n    {\n        _1139 = _1132;\n    }\n    if (_1139)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1082)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1165 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _722, fa_shadow_tex);\n        s = _1165;\n        if (_1165 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_722.fa_shadow_cfg.y > 0.0)\n    {\n        float _1190;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1190 = fa_shadow_split_at(param_5, _722);\n        }\n        else\n        {\n            _1190 = _722.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1209 = _722.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _722) - _1190, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1220 = fast::clamp((_1098 - (fa_shadow_split_at(param_7, _722) - _1209)) / _1209, 0.0, 1.0);\n        if (_1220 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1082)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1241 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _722, fa_shadow_tex);\n                s2 = _1241;\n                if (_1241 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1220);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _486, thread float4& gl_FragCoord, constant fa_shadows& _722, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _486, gl_FragCoord, _722, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _486, thread float4& gl_FragCoord, constant fa_shadows& _722, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _2462 = fa_lm.z > 0.5;\n    bool _2468;\n    if (_2462)\n    {\n        int param = li;\n        _2468 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2468 = _2462;\n    }\n    if (_2468)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2490 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _3735 = _2490.direction;\n    float3 _3730 = _2490.color;\n    float _3732 = _2490.shadow;\n    int _3740 = _2490.type;\n    if ((_3740 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3735;\n        float _2504 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _486, gl_FragCoord, _722, fa_shadow_tex, fa_world_pos);\n        _3732 = _2504;\n        _3730 *= _2504;\n    }\n    return LightSample{ _3735, _3730, _2490.attenuation, _3732, _2490._distance, _3740 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _2078 = tdh / at;\n    float _2082 = bdh / ab;\n    float _2094 = ((_2078 * _2078) + (_2082 * _2082)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2094) * _2094);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _2175 = 1.0 / alpha;\n    return ((2.0 + _2175) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2175)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _2208 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2287 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2287) * _2287);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2208);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2208));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2360 = fast::max(dot(L.nc, l), 0.0);\n        float _2366 = fast::max(dot(L.nc, h), 0.0);\n        float _2375 = ((_2366 * _2366) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2375) * _2375)) * (0.5 / fast::max(mix((2.0 * _2360) * L.coat_ndv, _2360 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2360)) * _2360);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1473 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1476 = _1473.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1476 * _1476, exp2((-9.27999973297119140625) * ndv)) * _1476) + _1473.y)) + _1473.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _486, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_486.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _486.fa_env_horizon.w)).xyz;\n    }\n    float _1378 = rough * rough;\n    float _1408 = 0.60000002384185791015625 * _1378;\n    return mix(mix(_486.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_486.fa_env_horizon.xyz, _486.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1378)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1408, 0.0500000007450580596923828125 + _1408, d.y))), ((_486.fa_env_sky.xyz + _486.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1378 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _486, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _1961;\n        if (L.aniso >= 0.0)\n        {\n            _1961 = L.b;\n        }\n        else\n        {\n            _1961 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_1961, v), _1961), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1994 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _486, fa_env_tex, fa_env_smp) * ((f0 * _1994.x) + (float3(L.f90) * _1994.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _486, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2049 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _486, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _2049.x) + _2049.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _486, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1515 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _486, fa_env_tex, fa_env_smp) * ((f0 * _1515.x) + float3(_1515.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _722)\n{\n    if (_722.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1265 = int(_722.fa_shadow_cfg.x + 0.5);\n    float _1275 = dot(world - _722.fa_shadow_eye.xyz, _722.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1280 = _1265 > 0;\n    bool _1289;\n    if (_1280)\n    {\n        int param = _1265 - 1;\n        _1289 = _1275 <= fa_shadow_split_at(param, _722);\n    }\n    else\n    {\n        _1289 = _1280;\n    }\n    if (_1289)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1296 = _1265 > 1;\n        bool _1303;\n        if (_1296)\n        {\n            _1303 = _1275 > _722.fa_shadow_split.x;\n        }\n        else\n        {\n            _1303 = _1296;\n        }\n        if (_1303)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1309 = _1265 > 2;\n        bool _1316;\n        if (_1309)\n        {\n            _1316 = _1275 > _722.fa_shadow_split.y;\n        }\n        else\n        {\n            _1316 = _1309;\n        }\n        if (_1316)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1322 = _1265 > 3;\n        bool _1329;\n        if (_1322)\n        {\n            _1329 = _1275 > _722.fa_shadow_split.z;\n        }\n        else\n        {\n            _1329 = _1322;\n        }\n        if (_1329)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _486 [[buffer(1)]], constant fa_shadows& _722 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3452 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3452 = -_3452;\n    }\n    float3 _2894 = fast::normalize(_486.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _486, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3452, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2894, short(gl_FrontFacing) };\n    Surface _2902 = fa_standard_surface(param_1, _486, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3483 = _2902.albedo;\n    float _3484 = _2902.alpha;\n    float3 _3485 = _2902.normal;\n    float _3486 = _2902.metallic;\n    float _3487 = _2902.roughness;\n    float _3488 = _2902.occlusion;\n    float3 _3489 = _2902.emission;\n    float _3490 = _2902.clearcoat;\n    float _3491 = _2902.clearcoat_roughness;\n    float3 _3492 = _2902.sheen_color;\n    float _3493 = _2902.sheen_roughness;\n    float _3494 = _2902.anisotropy;\n    float _3495 = _2902.anisotropy_rotation;\n    float _3496 = _2902.specular;\n    float _3497 = _2902.ior;\n    float3 _3498 = _2902.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3452, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2894, short(gl_FrontFacing) };\n    Surface param_3 = _2902;\n    surface(param_2, param_3);\n    _3483 = param_3.albedo;\n    _3484 = param_3.alpha;\n    _3485 = param_3.normal;\n    _3486 = param_3.metallic;\n    _3487 = param_3.roughness;\n    _3488 = param_3.occlusion;\n    _3489 = param_3.emission;\n    _3490 = param_3.clearcoat;\n    _3491 = param_3.clearcoat_roughness;\n    _3492 = param_3.sheen_color;\n    _3493 = param_3.sheen_roughness;\n    _3494 = param_3.anisotropy;\n    _3495 = param_3.anisotropy_rotation;\n    _3496 = param_3.specular;\n    _3497 = param_3.ior;\n    _3498 = param_3.specular_color;\n    float3 result;\n    if (_486.fa_emissive.w > 0.5)\n    {\n        result = _3483;\n    }\n    else\n    {\n        float3 _2924 = fast::normalize(_3485);\n        float _2931 = fast::clamp(_3486, 0.0, 1.0);\n        float _2935 = fast::clamp(_3487, 0.0500000007450580596923828125, 1.0);\n        float _2939 = _2935 * _2935;\n        float _2943 = _2939 * _2939;\n        float _2948 = fast::max(dot(_2924, _2894), 9.9999997473787516355514526367188e-05);\n        float3 _2954 = _3483 * (1.0 - _2931);\n        float3 _2961 = mix(float3(0.039999999105930328369140625), _3483, float3(_2931));\n        float3 f0 = _2961;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _3452, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2894, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _3483, _3484, _3485, _3486, _3487, _3488, _3489, _3490, _3491, _3492, _3493, _3494, _3495, _3496, _3497, _3498 };\n        float3 param_6 = _2924;\n        float3 param_7 = _2894;\n        float param_8 = _2931;\n        float param_9 = _2935;\n        float3 param_10 = _2961;\n        FaLayers _2977 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _2924;\n        float3 lit = (fa_indirect_diffuse(param_11, _486, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap) * _2954) * _3488;\n        if (_2977.on)\n        {\n            lit *= _2977.base_scale;\n        }\n        int _2999 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2999; ln++)\n        {\n            int param_12 = ln;\n            int _3012 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _486, fa_cl_ndir, fa_cl_slot);\n            bool _3015 = in.fa_lm.z > 0.5;\n            bool _3021;\n            if (_3015)\n            {\n                int param_13 = _3012;\n                _3021 = fa_light_baked(param_13, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _3021 = _3015;\n            }\n            if (_3021)\n            {\n                continue;\n            }\n            int param_14 = _3012;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _3452;\n            LightSample _3033 = fa_light_shadowed(param_14, param_15, param_16, fa_light_tex, fa_shadow_smp, _486, gl_FragCoord, _722, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            float3 _3657 = _3033.direction;\n            float _3041 = fast::max(dot(_2924, _3657), 0.0);\n            float _3047 = _3033.attenuation * _3033.shadow;\n            float3 _3052 = fast::normalize(_3657 + _2894);\n            float _3057 = fast::max(dot(_2924, _3052), 0.0);\n            float _3062 = fast::max(dot(_2894, _3052), 0.0);\n            if (_2977.on)\n            {\n                FaLayers param_17 = _2977;\n                float3 param_18 = _2954;\n                float3 param_19 = f0;\n                float3 param_20 = _2924;\n                float3 param_21 = _2894;\n                float3 param_22 = _3657;\n                float3 param_23 = _3052;\n                float param_24 = _3041;\n                float param_25 = _2948;\n                float param_26 = _3057;\n                float param_27 = _3062;\n                float param_28 = _2939;\n                float param_29 = _2943;\n                int param_30 = _3012;\n                lit += (fa_layers_light(param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29) * (fa_light_rgb(param_30, fa_light_tex, fa_shadow_smp) * _3047));\n            }\n            else\n            {\n                float _3110 = ((_3057 * _3057) * (_2943 - 1.0)) + 1.0;\n                int param_31 = _3012;\n                lit += (((_2954 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _3062, 5.0))) * (((_2943 / ((3.1415927410125732421875 * _3110) * _3110)) * (0.5 / fast::max(mix((2.0 * _3041) * _2948, _3041 + _2948, _2939), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3041))) * fa_light_rgb(param_31, fa_light_tex, fa_shadow_smp)) * (_3041 * _3047));\n            }\n        }\n        if (_2977.on)\n        {\n            FaLayers param_32 = _2977;\n            float3 param_33 = _2924;\n            float3 param_34 = _2894;\n            float3 param_35 = f0;\n            float param_36 = _2935;\n            lit += (fa_layers_ibl(param_32, param_33, param_34, param_35, param_36, _486, fa_env_tex, fa_env_smp) * _3488);\n        }\n        else\n        {\n            float3 param_37 = _2924;\n            float3 param_38 = _2894;\n            float3 param_39 = f0;\n            float param_40 = _2935;\n            lit += (fa_sky_reflection(param_37, param_38, param_39, param_40, _486, fa_env_tex, fa_env_smp) * _3488);\n        }\n        result = lit;\n    }\n    float3 _3203 = result;\n    float3 _3204 = _3203 + _3489;\n    result = _3204;\n    float3 param_41 = _3204;\n    float3 param_42 = in.fa_world_pos;\n    result = fa_shadow_debug(param_41, param_42, _722);\n    bool _3213 = _486.fa_fog.w > 0.0;\n    bool _3220;\n    if (!_3213)\n    {\n        _3220 = _486.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3220 = _3213;\n    }\n    if (_3220)\n    {\n        float3 _3229 = in.fa_world_pos - _486.fa_camera_pos.xyz;\n        float _3235 = dot(_3229, _486.fa_fog_c.xyz);\n        bool _3239 = _486.fa_fog_c.w > 0.5;\n        float _3240;\n        if (_3239)\n        {\n            _3240 = _3235;\n        }\n        else\n        {\n            _3240 = length(_3229);\n        }\n        float _3252 = _3240 - _486.fa_fog_b.x;\n        if (_3252 > 0.0)\n        {\n            float _3261 = _486.fa_fog.w * _3252;\n            float tau = _3261 * _3261;\n            if (_486.fa_fog_b.y > 0.0)\n            {\n                float _3277;\n                if (_3239)\n                {\n                    _3277 = in.fa_world_pos.y - (_486.fa_fog_c.y * _3235);\n                }\n                else\n                {\n                    _3277 = _486.fa_camera_pos.y;\n                }\n                float _3298 = mix(_3277, in.fa_world_pos.y, fast::clamp(_486.fa_fog_b.x / _3240, 0.0, 1.0));\n                float _3302 = in.fa_world_pos.y - _3298;\n                float _3307 = _3298 - _486.fa_fog_b.z;\n                float _3312 = in.fa_world_pos.y - _486.fa_fog_b.z;\n                bool _3315 = _3307 <= 0.0;\n                bool _3316 = !_3315;\n                bool _3322;\n                if (_3316)\n                {\n                    _3322 = _486.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3322 = _3315;\n                }\n                float _3323;\n                if (_3322)\n                {\n                    _3323 = _486.fa_fog_b.y;\n                }\n                else\n                {\n                    _3323 = _486.fa_fog_b.y * exp(-fast::min(_486.fa_fog_b.w * _3307, 80.0));\n                }\n                bool _3350;\n                if (_3316)\n                {\n                    _3350 = _486.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3350 = _3315;\n                }\n                float _3351;\n                if (_3350)\n                {\n                    _3351 = _486.fa_fog_b.y * _3307;\n                }\n                else\n                {\n                    _3351 = (_486.fa_fog_b.y * (1.0 - exp(-fast::min(_486.fa_fog_b.w * _3307, 80.0)))) / _486.fa_fog_b.w;\n                }\n                bool _3376 = _3312 <= 0.0;\n                bool _3383;\n                if (!_3376)\n                {\n                    _3383 = _486.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3383 = _3376;\n                }\n                float _3384;\n                if (_3383)\n                {\n                    _3384 = _486.fa_fog_b.y * _3312;\n                }\n                else\n                {\n                    _3384 = (_486.fa_fog_b.y * (1.0 - exp(-fast::min(_486.fa_fog_b.w * _3312, 80.0)))) / _486.fa_fog_b.w;\n                }\n                float _3411;\n                if (abs(_3302) < 0.001000000047497451305389404296875)\n                {\n                    _3411 = _3323;\n                }\n                else\n                {\n                    _3411 = (_3384 - _3351) / _3302;\n                }\n                tau += (_3252 * fast::max(_3411, 0.0));\n            }\n            result = mix(result, _486.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3484);\n    return out;\n}\n\n",
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
            "inst_name": "_486",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_722",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    },
    "prepass": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _733 = base_t;\n    _733.x = _225.x;\n    _733.y = _225.y;\n    _733.z = _225.z;\n    base_t = _733;\n    float4 _241 = (_733 * _213.fa_base_color) * i.vertex_color;\n    float3 _696 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _741 = _279;\n        _741.x = _284.x;\n        _741.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _741;\n        _696 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _744 = mrt;\n    _744.x = _313.x;\n    _744.y = _313.y;\n    _744.z = _313.z;\n    mrt = _744;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _701 = _213.fa_layers_a.x;\n    float _702 = _213.fa_layers_a.y;\n    float _705 = _213.fa_layers_a.z;\n    float _704 = _213.fa_layers_b.w;\n    float _707 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _701 *= _355.y;\n            _702 *= _355.z;\n            _704 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _705 *= mrt.x;\n            _707 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _696, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _701, _702, _213.fa_layers_b.xyz, _704, _705, _213.fa_layers_a.w, _707, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _607 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _607 = -_607;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _607, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _607, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _733 = base_t;\n    _733.x = _225.x;\n    _733.y = _225.y;\n    _733.z = _225.z;\n    base_t = _733;\n    float4 _241 = (_733 * _213.fa_base_color) * i.vertex_color;\n    float3 _696 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _741 = _279;\n        _741.x = _284.x;\n        _741.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _741;\n        _696 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _744 = mrt;\n    _744.x = _313.x;\n    _744.y = _313.y;\n    _744.z = _313.z;\n    mrt = _744;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _701 = _213.fa_layers_a.x;\n    float _702 = _213.fa_layers_a.y;\n    float _705 = _213.fa_layers_a.z;\n    float _704 = _213.fa_layers_b.w;\n    float _707 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _701 *= _355.y;\n            _702 *= _355.z;\n            _704 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _705 *= mrt.x;\n            _707 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _696, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _701, _702, _213.fa_layers_b.xyz, _704, _705, _213.fa_layers_a.w, _707, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _607 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _607 = -_607;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _607, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _607, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
