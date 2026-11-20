{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5c278b25d8ce4341984c8bf2a53e1ca7890b6a924713889b53c089df056597d0",
  "slang": "metal_macos",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_270, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float skyAmount;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nconstant spvUnsafeArray<float, 63> _2520 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492)\n{\n    bool _497 = _492.fa_cl_info.x < 0.0;\n    bool _504;\n    if (!_497)\n    {\n        _504 = _492.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _504 = _497;\n    }\n    bool _512;\n    if (!_504)\n    {\n        _512 = _492.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _512 = _504;\n    }\n    bool _519;\n    if (!_512)\n    {\n        _519 = _492.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _519 = _512;\n    }\n    bool _526;\n    if (!_519)\n    {\n        _526 = _492.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _526 = _519;\n    }\n    if (_526)\n    {\n        return float4(0.0);\n    }\n    float4 _536 = float4(world_pos, 1.0);\n    float _543 = dot(_492.fa_cl_vpw, _536);\n    if (!(_543 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _565 = float2(dot(_492.fa_cl_vpx, _536), dot(_492.fa_cl_vpy, _536)) / float2(_543);\n    int _569 = int(_492.fa_cl_grid.x);\n    int _573 = int(_492.fa_cl_grid.y);\n    int param = (int(_492.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_492.fa_cl_fwd.xyz, world_pos) + _492.fa_cl_fwd.w, _492.fa_cl_grid.w) / _492.fa_cl_grid.w) * _492.fa_cl_grid.z)), 0, int(_492.fa_cl_info.y) - 1) * _573) + clamp(int(floor(((_565.y * 0.5) + 0.5) * _492.fa_cl_grid.y)), 0, _573 - 1)) * _569)) + clamp(int(floor(((_565.x * 0.5) + 0.5) * _492.fa_cl_grid.x)), 0, _569 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492)\n{\n    float3 param = world_pos;\n    float4 _649 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _492);\n    return int2(int(_649.x), int(_649.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_492.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3067 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _492);\n    fa_cl_slot = _3067.x;\n    fa_cl_local = _3067.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3374 = fa_linear_to_srgb(param);\n        c = _3374;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3382 = fa_srgb_to_linear(param_1);\n            c = _3382;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _255;\n    if (bool(i.front_facing))\n    {\n        _255 = i.world_normal;\n    }\n    else\n    {\n        _255 = -i.world_normal;\n    }\n    float3 _279 = fast::normalize(i.world_tangent.xyz - (_255 * dot(_255, i.world_tangent.xyz)));\n    float3 _307 = fast::normalize(((_279 * m.x) + ((cross(_255, _279) * i.world_tangent.w) * m.y)) + (_255 * m.z));\n    float3 _310;\n    if (bool(i.front_facing))\n    {\n        _310 = _307;\n    }\n    else\n    {\n        _310 = -_307;\n    }\n    return _310;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _492, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _492.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3413 = fa_tex_fix(param_2, param_3);\n    float4 _4422 = base_t;\n    _4422.x = _3413.x;\n    _4422.y = _3413.y;\n    _4422.z = _3413.z;\n    base_t = _4422;\n    float4 _3427 = (_4422 * _492.fa_base_color) * i.vertex_color;\n    float3 _4289 = i.world_normal;\n    if (_492.fa_maps.z > 0.5)\n    {\n        float param_4 = _492.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3459 = fa_tex_fix(param_6, param_7);\n        float3 _3462 = (_3459 * 2.0) - float3(1.0);\n        float2 _3467 = _3462.xy * _492.fa_maps.x;\n        float3 _4430 = _3462;\n        _4430.x = _3467.x;\n        _4430.y = _3467.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4430;\n        _4289 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _492.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3496 = fa_tex_fix(param_12, param_13);\n    float4 _4433 = mrt;\n    _4433.x = _3496.x;\n    _4433.y = _3496.y;\n    _4433.z = _3496.z;\n    mrt = _4433;\n    float4 _3524 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _492.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3524.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3536 = fa_tex_fix(param_16, param_17);\n    float param_18 = _492.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3566 = fa_tex_fix(param_20, param_21);\n    float _4294 = _492.fa_layers_a.x;\n    float _4295 = _492.fa_layers_a.y;\n    float _4298 = _492.fa_layers_a.z;\n    float _4297 = _492.fa_layers_b.w;\n    float _4300 = _492.fa_layers_c.x;\n    if (_492.fa_layers_c.z > 0.5)\n    {\n        if (mod(_492.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4294 *= _3536.y;\n            _4295 *= _3536.z;\n            _4297 *= _3524.w;\n        }\n        if (_492.fa_layers_c.z > 1.5)\n        {\n            _4298 *= mrt.x;\n            _4300 *= mrt.w;\n        }\n    }\n    return Surface{ _3427.xyz, _3427.w, _4289, fast::clamp(_492.fa_pbr.x * _3496.z, 0.0, 1.0), fast::clamp(_492.fa_pbr.y * _3496.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_492.fa_maps.y * (_3536.x - 1.0)), _492.fa_emissive.xyz + (_492.fa_model_emissive.xyz * _3566), _4294, _4295, _492.fa_layers_b.xyz, _4297, _4298, _492.fa_layers_a.w, _4300, _492.fa_layers_c.y, _492.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _730 = rect.zw - rect.xy;\n    float2 _734 = _730 * atlas;\n    float2 _738 = ddx * _734;\n    float2 _742 = ddy * _734;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _730)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_738, _738), dot(_742, _742)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _777 = _492.fa_counts.y < 0.5;\n    bool _784;\n    if (!_777)\n    {\n        _784 = _492.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _784 = _777;\n    }\n    if (_784)\n    {\n        return;\n    }\n    float3 _790 = dfdx(world_pos);\n    float3 _793 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _797 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _492);\n    int _801 = int(_797.w);\n    if (_801 < 1)\n    {\n        return;\n    }\n    int _811 = int(_492.fa_counts.y + 0.5);\n    int param_1 = _811;\n    float4 _815 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _818 = _815.yz;\n    int _822 = int(_815.w);\n    int param_2 = _811 + 1;\n    float4 _827 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _828 = _827.x;\n    int _834 = int(_492.fa_counts.w + 0.5) - 1;\n    int _838 = int(_797.z);\n    float3 _1104;\n    for (int k = 0; k < _801; k++)\n    {\n        int _851 = _838 + k;\n        int param_3 = _822 + (_851 >> 2);\n        int _869 = (_811 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_851 & 3]) * 7);\n        int param_4 = _869 + 6;\n        float4 _874 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_874.w + 0.5) >> _834) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _869;\n        float4 _889 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _869 + 1;\n        float4 _894 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _869 + 2;\n        float4 _899 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _902 = _889.xyz;\n        float _907 = dot(_902, world_pos) + _889.w;\n        float3 _909 = _894.xyz;\n        float _914 = dot(_909, world_pos) + _894.w;\n        float3 _916 = _899.xyz;\n        float _921 = dot(_916, world_pos) + _899.w;\n        bool _926 = abs(_907) > 0.5;\n        bool _934;\n        if (!_926)\n        {\n            _934 = abs(_914) > 0.5;\n        }\n        else\n        {\n            _934 = _926;\n        }\n        bool _942;\n        if (!_934)\n        {\n            _942 = abs(_921) > 0.5;\n        }\n        else\n        {\n            _942 = _934;\n        }\n        if (_942)\n        {\n            continue;\n        }\n        float _957 = fast::clamp(dot(geo_normal, fast::normalize(_916)) * _874.z, 0.0, 1.0);\n        if (_957 <= 0.0)\n        {\n            continue;\n        }\n        float _977 = (fast::clamp((0.5 - abs(_921)) * 10.0, 0.0, 1.0) * _957) * _874.x;\n        float2 _985 = float2(_907 + 0.5, 0.5 - _914);\n        float2 _995 = float2(dot(_902, _790), dot(_909, _790));\n        float2 _1005 = float2(dot(_902, _793), dot(_909, _793));\n        int param_8 = _869 + 5;\n        float4 _1010 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _869 + 3;\n        float4 _1015 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _869 + 4;\n        float4 _1020 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1010.xyz;\n        bool _1030 = _1015.z > _1015.x;\n        if (_1030)\n        {\n            float4 param_11 = _1015;\n            float2 param_12 = _985;\n            float2 param_13 = _818;\n            float2 param_14 = _995;\n            float2 param_15 = _1005;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_828 > 0.5) && (_828 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1056 = fa_dc_to_linear(param_16);\n                float4 _4345 = tx;\n                _4345.x = _1056.x;\n                _4345.y = _1056.y;\n                _4345.z = _1056.z;\n                tx = _4345;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_977 * tex_a) * _1010.w, 0.0, 1.0)));\n        if (_1020.z > _1020.x)\n        {\n            float4 param_17 = _1020;\n            float2 param_18 = _985;\n            float2 param_19 = _818;\n            float2 param_20 = _995;\n            float2 param_21 = _1005;\n            float4 _1100 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_828 > 1.5)\n            {\n                float3 param_22 = _1100.xyz;\n                float3 _1110 = fa_dc_to_srgb(param_22);\n                _1104 = _1110;\n            }\n            else\n            {\n                _1104 = _1100.xyz;\n            }\n            float3 _1120 = (_1104 * 2.0) - float3(1.0);\n            float2 _1125 = _1120.xy * _874.y;\n            float3 _1147 = (fast::normalize(_902) * _1125.x) + (fast::normalize(_909) * _1125.y);\n            float3 _1150 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1150, fast::normalize((_1150 * fast::max(_1120.z, 0.0500000007450580596923828125)) + (_1147 - (_1150 * dot(_1150, _1147)))), float3(fast::clamp(_977 * (_1030 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(thread int& fa_cl_ndir, thread int& fa_cl_local)\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_no_light()\n{\n    return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, 0 };\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492)\n{\n    int param = (int(_492.fa_cl_info.x) + int(_492.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _492);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _366 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _372 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _375 = _372.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _381 = _375 < 0.5;\n    float3 l;\n    if (_381)\n    {\n        l = fast::normalize(_366.xyz);\n    }\n    else\n    {\n        float3 _393 = _366.xyz - world_pos;\n        float _395 = length(_393);\n        dist = _395;\n        l = _393 / float3(fast::max(_395, 9.9999997473787516355514526367188e-05));\n        float _410 = _395 / fast::max(_366.w, 0.001000000047497451305389404296875);\n        float _416 = fast::clamp(1.0 - (_410 * _410), 0.0, 1.0);\n        atten = _416 * _416;\n        if (_375 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _430 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _440 = _430.w;\n            int param_3 = (li * 4) + 3;\n            float4 _446 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _447 = _446.x;\n            float cos_inner = _447;\n            if (_447 > 1.5)\n            {\n                cos_inner = mix(_440, 1.0, 0.25);\n            }\n            atten *= smoothstep(_440, cos_inner, dot(-l, fast::normalize(_430.xyz)));\n        }\n    }\n    int _478;\n    if (_381)\n    {\n        _478 = 0;\n    }\n    else\n    {\n        _478 = (_375 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _372.xyz * atten, atten, 1.0, dist, _478 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_unshadowed(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, thread float3& fa_lm)\n{\n    bool _3208 = n < 0;\n    bool _3215;\n    if (!_3208)\n    {\n        _3215 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _3215 = _3208;\n    }\n    if (_3215)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _3223 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _492, fa_cl_ndir, fa_cl_slot);\n    bool _3226 = fa_lm.z > 0.5;\n    bool _3232;\n    if (_3226)\n    {\n        int param_1 = _3223;\n        _3232 = fa_light_baked(param_1, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3232 = _3226;\n    }\n    if (_3232)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _3223;\n    float3 param_3 = i.world_pos;\n    return fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1232)\n{\n    float _1222;\n    if (i == 0)\n    {\n        _1222 = _1232.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1238;\n        if (i == 1)\n        {\n            _1238 = _1232.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1246;\n            if (i == 2)\n            {\n                _1246 = _1232.fa_shadow_split.z;\n            }\n            else\n            {\n                _1246 = _1232.fa_shadow_split.w;\n            }\n            _1238 = _1246;\n        }\n        _1222 = _1238;\n    }\n    return _1222;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1279 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1283;\n    if (conv.x < 0.5)\n    {\n        _1283 = _1279;\n    }\n    else\n    {\n        _1283 = (conv.y * conv.z) / (conv.z - (_1279 * (conv.z - conv.y)));\n    }\n    return _1283;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1210 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1210), sin(_1210)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1232, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1329 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1343 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1329;\n            float2 _1362 = fa_shadow_vogel(param_3, param_4, param_5) * _1343;\n            float2 param_6 = uv + (_1362 * _1232.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1374 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1374 < (zr - (length(_1362) * plane)))\n            {\n                sum += _1374;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1418 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1418; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1418;\n        float param_11 = _1329;\n        float2 _1437 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1437 * _1232.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1437) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1418);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1232, texture2d<float> fa_shadow_tex)\n{\n    float _1479 = fast::max(_1232.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1484 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1490 = sqrt(1.0 - (_1484 * _1484));\n    float _1497 = fast::min(_1490 / fast::max(_1484, 0.20000000298023223876953125), 4.0);\n    float _1502;\n    if (_1232.fa_shadow_bias.y > 0.0)\n    {\n        _1502 = _1232.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1502 = 1.5 * _1232.fa_shadow_info[ci].x;\n    }\n    float4 _1527 = _1232.fa_shadow_mat[ci] * float4(world + (n * (_1502 * _1490)), 1.0);\n    float _1534 = _1527.x;\n    bool _1537 = _1534 < _1232.fa_shadow_rect[ci].x;\n    bool _1546;\n    if (!_1537)\n    {\n        _1546 = _1534 > _1232.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1546 = _1537;\n    }\n    bool _1555;\n    if (!_1546)\n    {\n        _1555 = _1527.y < _1232.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1555 = _1546;\n    }\n    bool _1564;\n    if (!_1555)\n    {\n        _1564 = _1527.y > _1232.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1564 = _1555;\n    }\n    bool _1571;\n    if (!_1564)\n    {\n        _1571 = _1527.z > 1.0;\n    }\n    else\n    {\n        _1571 = _1564;\n    }\n    if (_1571)\n    {\n        return -1.0;\n    }\n    float _1580;\n    if (_1232.fa_shadow_bias.x > 0.0)\n    {\n        _1580 = _1232.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1580 = 1.5 * _1232.fa_shadow_info[ci].x;\n    }\n    float2 param = _1527.xy;\n    float4 param_1 = _1232.fa_shadow_rect[ci];\n    float param_2 = _1527.z - ((_1580 * (1.0 + (0.5 * _1497))) / _1479);\n    float param_3 = _1232.fa_shadow_info[ci].x;\n    float param_4 = _1479;\n    float param_5 = _1479 * 0.25;\n    float param_6 = ((_1232.fa_shadow_info[ci].x * fast::min(_1497, 3.0)) * 0.5) / _1479;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1232.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1232.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1232, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492, thread float4& gl_FragCoord, constant fa_shadows& _1232, texture2d<float> fa_shadow_tex)\n{\n    if (_492.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2007 = int(_1232.fa_shadow_cfg.x + 0.5);\n    if (_2007 < 1)\n    {\n        return 1.0;\n    }\n    float _2022 = dot(world - _1232.fa_shadow_eye.xyz, _1232.fa_shadow_fwd.xyz);\n    int param = _2007 - 1;\n    if (_2022 > fa_shadow_split_at(param, _1232))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2034 = _2007 > 1;\n    bool _2041;\n    if (_2034)\n    {\n        _2041 = _2022 > _1232.fa_shadow_split.x;\n    }\n    else\n    {\n        _2041 = _2034;\n    }\n    if (_2041)\n    {\n        ci = 1;\n    }\n    bool _2045 = _2007 > 2;\n    bool _2052;\n    if (_2045)\n    {\n        _2052 = _2022 > _1232.fa_shadow_split.y;\n    }\n    else\n    {\n        _2052 = _2045;\n    }\n    if (_2052)\n    {\n        ci = 2;\n    }\n    bool _2056 = _2007 > 3;\n    bool _2063;\n    if (_2056)\n    {\n        _2063 = _2022 > _1232.fa_shadow_split.z;\n    }\n    else\n    {\n        _2063 = _2056;\n    }\n    if (_2063)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2007)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2089 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1232, fa_shadow_tex);\n        s = _2089;\n        if (_2089 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1232.fa_shadow_cfg.y > 0.0)\n    {\n        float _2114;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2114 = fa_shadow_split_at(param_5, _1232);\n        }\n        else\n        {\n            _2114 = _1232.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2133 = _1232.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1232) - _2114, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2144 = fast::clamp((_2022 - (fa_shadow_split_at(param_7, _1232) - _2133)) / _2133, 0.0, 1.0);\n        if (_2144 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2007)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2165 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1232, fa_shadow_tex);\n                s2 = _2165;\n                if (_2165 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2144);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492, thread float4& gl_FragCoord, constant fa_shadows& _1232, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _492, gl_FragCoord, _1232, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492, thread float4& gl_FragCoord, constant fa_shadows& _1232, texture2d<float> fa_shadow_tex)\n{\n    bool _1638 = _492.fa_pbr.z < 0.5;\n    bool _1646;\n    if (!_1638)\n    {\n        _1646 = _1232.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1646 = _1638;\n    }\n    if (_1646)\n    {\n        return 1.0;\n    }\n    int param = (int(_1232.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1659 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1660 = _1659.x;\n    if (_1660 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1669 = int(_1660 + 0.5);\n    int param_1 = _1669;\n    float4 _1673 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1669 + 1;\n    float4 _1678 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1681 = _1673.y;\n    if (_1681 > 0.0)\n    {\n        float _1698 = 1.0 - smoothstep(0.75 * _1681, _1681, length(world - _1232.fa_shadow_eye.xyz));\n        fade = _1698;\n        if (_1698 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1673.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1717 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1720 = abs(_1717);\n        float _1722 = _1720.x;\n        float _1724 = _1720.y;\n        bool _1725 = _1722 >= _1724;\n        bool _1733;\n        if (_1725)\n        {\n            _1733 = _1722 >= _1720.z;\n        }\n        else\n        {\n            _1733 = _1725;\n        }\n        int _1734;\n        if (_1733)\n        {\n            _1734 = (_1717.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1747;\n            if (_1724 >= _1720.z)\n            {\n                _1747 = (_1717.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1747 = (_1717.z > 0.0) ? 4 : 5;\n            }\n            _1734 = _1747;\n        }\n        face = _1734;\n    }\n    int _1766 = (_1669 + 2) + (face * 6);\n    int param_4 = _1766;\n    int param_5 = _1766 + 1;\n    int param_6 = _1766 + 3;\n    float4 _1780 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1766 + 4;\n    float4 _1785 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1766 + 5;\n    float4 _1790 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1802 = _1790.x * fast::max(dot(_1780, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1807 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1830 = fast::clamp(dot(n, _1780.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1853 = fast::min(sqrt(1.0 - (_1830 * _1830)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1780, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1856 = _1678.y;\n    float _1858;\n    if (_1856 > 0.0)\n    {\n        _1858 = _1856;\n    }\n    else\n    {\n        _1858 = 1.5 * _1802;\n    }\n    float4 _1878 = float4(world + (n * (_1858 * sqrt(1.0 - (_1807 * _1807)))), 1.0);\n    float _1882 = dot(_1780, _1878);\n    float _1885 = _1790.y;\n    if (_1882 < _1885)\n    {\n        return 1.0;\n    }\n    float2 _1900 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1878), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1878)) / float2(_1882);\n    float _1902 = _1900.x;\n    bool _1905 = _1902 < _1785.x;\n    bool _1914;\n    if (!_1905)\n    {\n        _1914 = _1902 > _1785.z;\n    }\n    else\n    {\n        _1914 = _1905;\n    }\n    bool _1923;\n    if (!_1914)\n    {\n        _1923 = _1900.y < _1785.y;\n    }\n    else\n    {\n        _1923 = _1914;\n    }\n    bool _1932;\n    if (!_1923)\n    {\n        _1932 = _1900.y > _1785.w;\n    }\n    else\n    {\n        _1932 = _1923;\n    }\n    if (_1932)\n    {\n        return 1.0;\n    }\n    float _1938 = _1678.x;\n    float _1940;\n    if (_1938 > 0.0)\n    {\n        _1940 = _1938;\n    }\n    else\n    {\n        _1940 = 1.5 * _1802;\n    }\n    float2 param_10 = _1900;\n    float4 param_11 = _1785;\n    float param_12 = _1882 - (_1940 * (1.0 + (0.5 * _1853)));\n    float param_13 = _1802;\n    float param_14 = 1.0;\n    float param_15 = _1790.z * 0.25;\n    float param_16 = (_1802 * fast::min(_1853, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1885, _1790.z);\n    int param_18 = int(_1673.z + 0.5);\n    float param_19 = _1673.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1232, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492, thread float4& gl_FragCoord, constant fa_shadows& _1232, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3094 = fa_lm.z > 0.5;\n    bool _3100;\n    if (_3094)\n    {\n        int param = li;\n        _3100 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3100 = _3094;\n    }\n    if (_3100)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3122 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _4265 = _3122.direction;\n    float3 _4260 = _3122.color;\n    float _4267 = _3122.attenuation;\n    float _4262 = _3122.shadow;\n    int _4270 = _3122.type;\n    if ((_4270 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4265;\n        float _3136 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _492, gl_FragCoord, _1232, fa_shadow_tex, fa_world_pos);\n        _4262 = _3136;\n        _4260 *= _3136;\n    }\n    else\n    {\n        bool _3147 = _4270 != 0;\n        bool _3153;\n        if (_3147)\n        {\n            _3153 = _4267 > 0.0;\n        }\n        else\n        {\n            _3153 = _3147;\n        }\n        if (_3153)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4265;\n            float _3165 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _492, gl_FragCoord, _1232, fa_shadow_tex);\n            _4262 = _3165;\n            _4260 *= _3165;\n        }\n    }\n    return LightSample{ _4265, _4260, _4267, _4262, _3122._distance, _4270 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492, thread float4& gl_FragCoord, constant fa_shadows& _1232, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, thread float3& fa_lm)\n{\n    bool _3182 = n < 0;\n    bool _3189;\n    if (!_3182)\n    {\n        _3189 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _3189 = _3182;\n    }\n    if (_3189)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _492, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3, fa_light_tex, fa_shadow_smp, _492, gl_FragCoord, _1232, fa_shadow_tex, fa_world_pos, fa_lm);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _2445 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2453 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2456 = int(_2445);\n    int _2459 = int(_2453);\n    float _2469 = _2453 - float(_2459);\n    int _2525 = (_2456 * 9) + _2459;\n    int _2545 = ((_2456 + 1) * 9) + _2459;\n    return mix(mix(_2520[_2525], _2520[_2525 + 1], _2469), mix(_2520[_2545], _2520[_2545 + 1], _2469), _2445 - float(_2456));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4126 = false;\n    float _4127 = 1.0;\n    float _4128 = 1.0;\n    float _4129 = 1.0;\n    float _4130 = 0.0;\n    float _4131 = 0.0;\n    float _4132 = 0.0;\n    float _4133 = 0.0;\n    float _4135 = 1.0;\n    bool _4136 = false;\n    float3 _4137 = float3(0.0);\n    float _4138 = 1.0;\n    float _4139 = 1.0;\n    float _4140 = 1.0;\n    float _4141 = 0.0;\n    float _4142 = 0.0;\n    float3 _4143 = float3(1.0, 0.0, 0.0);\n    float3 _4144 = float3(0.0, 0.0, 1.0);\n    float _4145 = 1.0;\n    float _4146 = 1.0;\n    float _2598 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2602 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2607 = (_2598 != 1.0) || (_2602 != 1.5);\n    bool _2617;\n    if (!_2607)\n    {\n        _2617 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2617 = _2607;\n    }\n    if (_2617)\n    {\n        float _2625 = (_2602 - 1.0) / (_2602 + 1.0);\n        f0 = mix(fast::min(float3(_2625 * _2625) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2598, s.albedo, float3(metallic));\n        _4127 = mix(_2598, 1.0, metallic);\n        _4126 = true;\n    }\n    float _2653 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2653 > 0.0)\n    {\n        float _2661 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4130 = _2653;\n        _4131 = _2661;\n        float _2668 = _2661 * _2661;\n        _4132 = _2668;\n        _4133 = _2668 * _2668;\n        float _2680 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4135 = _2680;\n        _4128 = 1.0 - (_2653 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2680, 0.0, 1.0), 5.0))));\n        _4126 = true;\n    }\n    float3 _2700 = fast::max(s.sheen_color, float3(0.0));\n    float _2709 = fast::max(_2700.x, fast::max(_2700.y, _2700.z));\n    if (_2709 > 0.0)\n    {\n        float _2717 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4136 = true;\n        _4137 = _2700;\n        _4138 = _2717;\n        _4139 = _2717 * _2717;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2717;\n        float _2734 = fa_sheen_albedo(param, param_1);\n        _4141 = _2734;\n        _4140 = 1.0 - fast::min(_2709 * _2734, 1.0);\n        _4126 = true;\n    }\n    _4129 = _4128 * _4140;\n    float _2753 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2753 != 0.0)\n    {\n        float3 _2768 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2768;\n        if (dot(_2768, _2768) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2785 = t;\n        float3 _2786 = fast::normalize(_2785);\n        t = _2786;\n        float3 _2811 = fast::normalize((_2786 * cos(s.anisotropy_rotation)) + ((cross(n, _2786) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4143 = _2811;\n        _4144 = cross(n, _2811);\n        float _2821 = roughness * roughness;\n        float _2827 = mix(_2821, 1.0, _2753 * _2753);\n        bool _2829 = _2753 > 0.0;\n        _4145 = _2829 ? _2827 : _2821;\n        _4146 = _2829 ? _2821 : _2827;\n        _4142 = _2753;\n        _4126 = true;\n    }\n    return FaLayers{ short(_4126), _4127, _4128, _4129, _4130, _4131, _4132, _4133, i.world_normal, _4135, short(_4136), _4137, _4138, _4139, _4140, _4141, _4142, _4143, _4144, _4145, _4146 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _2377 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2380 = _2377.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_2380 * _2380, exp2((-9.27999973297119140625) * ndv)) * _2380) + _2377.y)) + _2377.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _492, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_492.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _492.fa_env_horizon.w)).xyz;\n    }\n    float _2301 = rough * rough;\n    float _2331 = 0.60000002384185791015625 * _2301;\n    return mix(mix(_492.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_492.fa_env_horizon.xyz, _492.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _2301)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _2331, 0.0500000007450580596923828125 + _2331, d.y))), ((_492.fa_env_sky.xyz + _492.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_2301 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _492, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2862;\n        if (L.aniso >= 0.0)\n        {\n            _2862 = L.b;\n        }\n        else\n        {\n            _2862 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2862, v), _2862), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2895 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _492, fa_env_smp, fa_env_tex) * ((f0 * _2895.x) + (float3(L.f90) * _2895.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _492, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2950 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _492, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _2950.x) + _2950.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _492, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2419 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _492, fa_env_smp, fa_env_tex) * ((f0 * _2419.x) + float3(_2419.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _492, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float _2989 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _2993 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _3000 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_2989));\n    float3 f0 = _3000;\n    float3 _3004 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3004;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2989;\n    float param_5 = _2993;\n    float3 param_6 = _3000;\n    FaLayers _3021 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3021.on)\n    {\n        FaLayers param_7 = _3021;\n        float3 param_8 = _3004;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2993;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _492, fa_env_smp, fa_env_tex) * s.occlusion;\n    }\n    float3 param_12 = _3004;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2993;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _492, fa_env_smp, fa_env_tex) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lighting(thread const SurfaceInput& i, thread const Surface& s, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492, sampler fa_env_smp, thread float4& gl_FragCoord, constant fa_shadows& _1232, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texturecube<float> fa_env_tex, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, thread float3& fa_lm, constant fa_material& _3313)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(fa_cl_ndir, fa_cl_local); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _3270 = dot(fa_light_unshadowed(param, param_1, fa_light_tex, fa_shadow_smp, _492, fa_cl_ndir, fa_cl_slot, fa_cl_local, fa_lm).color, float3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_3270 > bestPower)\n        {\n            bestPower = _3270;\n            best = n;\n        }\n    }\n    float3 lit = (_492.fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _3299 = fa_light(param_2, param_3, fa_light_tex, fa_shadow_smp, _492, gl_FragCoord, _1232, fa_shadow_tex, fa_world_pos, fa_cl_ndir, fa_cl_slot, fa_cl_local, fa_lm);\n        float _3307;\n        if (dot(s.normal, _3299.direction) > 0.5)\n        {\n            _3307 = 1.0;\n        }\n        else\n        {\n            _3307 = _3313.dark;\n        }\n        lit += ((s.albedo * _3299.color) * _3307);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5, _492, fa_env_smp, fa_env_tex) * _3313.skyAmount);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1232)\n{\n    if (_1232.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2189 = int(_1232.fa_shadow_cfg.x + 0.5);\n    float _2199 = dot(world - _1232.fa_shadow_eye.xyz, _1232.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2204 = _2189 > 0;\n    bool _2213;\n    if (_2204)\n    {\n        int param = _2189 - 1;\n        _2213 = _2199 <= fa_shadow_split_at(param, _1232);\n    }\n    else\n    {\n        _2213 = _2204;\n    }\n    if (_2213)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2220 = _2189 > 1;\n        bool _2227;\n        if (_2220)\n        {\n            _2227 = _2199 > _1232.fa_shadow_split.x;\n        }\n        else\n        {\n            _2227 = _2220;\n        }\n        if (_2227)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2233 = _2189 > 2;\n        bool _2240;\n        if (_2233)\n        {\n            _2240 = _2199 > _1232.fa_shadow_split.y;\n        }\n        else\n        {\n            _2240 = _2233;\n        }\n        if (_2240)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2246 = _2189 > 3;\n        bool _2253;\n        if (_2246)\n        {\n            _2253 = _2199 > _1232.fa_shadow_split.z;\n        }\n        else\n        {\n            _2253 = _2246;\n        }\n        if (_2253)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _492 [[buffer(1)]], constant fa_material& _3313 [[buffer(5)]], constant fa_shadows& _1232 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_decal_tex [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4000 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4000 = -_4000;\n    }\n    float3 _3687 = fast::normalize(_492.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _492, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4000, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3687, short(gl_FrontFacing) };\n    Surface _3695 = fa_standard_surface(param_1, _492, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4031 = _3695.albedo;\n    float _4032 = _3695.alpha;\n    float3 _4033 = _3695.normal;\n    float _4034 = _3695.metallic;\n    float _4035 = _3695.roughness;\n    float _4036 = _3695.occlusion;\n    float3 _4037 = _3695.emission;\n    float _4038 = _3695.clearcoat;\n    float _4039 = _3695.clearcoat_roughness;\n    float3 _4040 = _3695.sheen_color;\n    float _4041 = _3695.sheen_roughness;\n    float _4042 = _3695.anisotropy;\n    float _4043 = _3695.anisotropy_rotation;\n    float _4044 = _3695.specular;\n    float _4045 = _3695.ior;\n    float3 _4046 = _3695.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4000, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3687, short(gl_FrontFacing) };\n    Surface param_3 = _3695;\n    surface(param_2, param_3);\n    _4031 = param_3.albedo;\n    _4032 = param_3.alpha;\n    _4033 = param_3.normal;\n    _4034 = param_3.metallic;\n    _4035 = param_3.roughness;\n    _4036 = param_3.occlusion;\n    _4037 = param_3.emission;\n    _4038 = param_3.clearcoat;\n    _4039 = param_3.clearcoat_roughness;\n    _4040 = param_3.sheen_color;\n    _4041 = param_3.sheen_roughness;\n    _4042 = param_3.anisotropy;\n    _4043 = param_3.anisotropy_rotation;\n    _4044 = param_3.specular;\n    _4045 = param_3.ior;\n    _4046 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4000;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _492, fa_decal_tex, fa_env_smp);\n    _4031 = param_6;\n    _4033 = param_7;\n    float3 result;\n    if (_492.fa_emissive.w > 0.5)\n    {\n        result = _4031;\n    }\n    else\n    {\n        float3 _3733 = _4033;\n        float3 _3734 = fast::normalize(_3733);\n        _4033 = _3734;\n        SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _4000, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3687, short(gl_FrontFacing) };\n        Surface param_9 = Surface{ _4031, _4032, _3734, _4034, _4035, _4036, _4037, _4038, _4039, _4040, _4041, _4042, _4043, _4044, _4045, _4046 };\n        result = lighting(param_8, param_9, fa_light_tex, fa_shadow_smp, _492, fa_env_smp, gl_FragCoord, _1232, fa_shadow_tex, in.fa_world_pos, fa_env_tex, fa_cl_ndir, fa_cl_slot, fa_cl_local, in.fa_lm, _3313);\n    }\n    float3 _3749 = result;\n    float3 _3750 = _3749 + _4037;\n    result = _3750;\n    float3 param_10 = _3750;\n    float3 param_11 = in.fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11, _1232);\n    bool _3759 = _492.fa_fog.w > 0.0;\n    bool _3766;\n    if (!_3759)\n    {\n        _3766 = _492.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3766 = _3759;\n    }\n    if (_3766)\n    {\n        float3 _3775 = in.fa_world_pos - _492.fa_camera_pos.xyz;\n        float _3781 = dot(_3775, _492.fa_fog_c.xyz);\n        bool _3785 = _492.fa_fog_c.w > 0.5;\n        float _3786;\n        if (_3785)\n        {\n            _3786 = _3781;\n        }\n        else\n        {\n            _3786 = length(_3775);\n        }\n        float _3798 = _3786 - _492.fa_fog_b.x;\n        if (_3798 > 0.0)\n        {\n            float _3807 = _492.fa_fog.w * _3798;\n            float tau = _3807 * _3807;\n            if (_492.fa_fog_b.y > 0.0)\n            {\n                float _3823;\n                if (_3785)\n                {\n                    _3823 = in.fa_world_pos.y - (_492.fa_fog_c.y * _3781);\n                }\n                else\n                {\n                    _3823 = _492.fa_camera_pos.y;\n                }\n                float _3844 = mix(_3823, in.fa_world_pos.y, fast::clamp(_492.fa_fog_b.x / _3786, 0.0, 1.0));\n                float _3848 = in.fa_world_pos.y - _3844;\n                float _3853 = _3844 - _492.fa_fog_b.z;\n                float _3858 = in.fa_world_pos.y - _492.fa_fog_b.z;\n                bool _3861 = _3853 <= 0.0;\n                bool _3862 = !_3861;\n                bool _3868;\n                if (_3862)\n                {\n                    _3868 = _492.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3868 = _3861;\n                }\n                float _3869;\n                if (_3868)\n                {\n                    _3869 = _492.fa_fog_b.y;\n                }\n                else\n                {\n                    _3869 = _492.fa_fog_b.y * exp(-fast::min(_492.fa_fog_b.w * _3853, 80.0));\n                }\n                bool _3896;\n                if (_3862)\n                {\n                    _3896 = _492.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3896 = _3861;\n                }\n                float _3897;\n                if (_3896)\n                {\n                    _3897 = _492.fa_fog_b.y * _3853;\n                }\n                else\n                {\n                    _3897 = (_492.fa_fog_b.y * (1.0 - exp(-fast::min(_492.fa_fog_b.w * _3853, 80.0)))) / _492.fa_fog_b.w;\n                }\n                bool _3922 = _3858 <= 0.0;\n                bool _3929;\n                if (!_3922)\n                {\n                    _3929 = _492.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3929 = _3922;\n                }\n                float _3930;\n                if (_3929)\n                {\n                    _3930 = _492.fa_fog_b.y * _3858;\n                }\n                else\n                {\n                    _3930 = (_492.fa_fog_b.y * (1.0 - exp(-fast::min(_492.fa_fog_b.w * _3858, 80.0)))) / _492.fa_fog_b.w;\n                }\n                float _3957;\n                if (abs(_3848) < 0.001000000047497451305389404296875)\n                {\n                    _3957 = _3869;\n                }\n                else\n                {\n                    _3957 = (_3930 - _3897) / _3848;\n                }\n                tau += (_3798 * fast::max(_3957, 0.0));\n            }\n            result = mix(result, _492.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4032);\n    return out;\n}\n\n",
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
            "inst_name": "_492",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1232",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_3313",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 8,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_391, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float skyAmount;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nconstant spvUnsafeArray<float, 63> _2520 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492)\n{\n    bool _497 = _492.fa_cl_info.x < 0.0;\n    bool _504;\n    if (!_497)\n    {\n        _504 = _492.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _504 = _497;\n    }\n    bool _512;\n    if (!_504)\n    {\n        _512 = _492.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _512 = _504;\n    }\n    bool _519;\n    if (!_512)\n    {\n        _519 = _492.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _519 = _512;\n    }\n    bool _526;\n    if (!_519)\n    {\n        _526 = _492.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _526 = _519;\n    }\n    if (_526)\n    {\n        return float4(0.0);\n    }\n    float4 _536 = float4(world_pos, 1.0);\n    float _543 = dot(_492.fa_cl_vpw, _536);\n    if (!(_543 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _565 = float2(dot(_492.fa_cl_vpx, _536), dot(_492.fa_cl_vpy, _536)) / float2(_543);\n    int _569 = int(_492.fa_cl_grid.x);\n    int _573 = int(_492.fa_cl_grid.y);\n    int param = (int(_492.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_492.fa_cl_fwd.xyz, world_pos) + _492.fa_cl_fwd.w, _492.fa_cl_grid.w) / _492.fa_cl_grid.w) * _492.fa_cl_grid.z)), 0, int(_492.fa_cl_info.y) - 1) * _573) + clamp(int(floor(((_565.y * 0.5) + 0.5) * _492.fa_cl_grid.y)), 0, _573 - 1)) * _569)) + clamp(int(floor(((_565.x * 0.5) + 0.5) * _492.fa_cl_grid.x)), 0, _569 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492)\n{\n    float3 param = world_pos;\n    float4 _649 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _492);\n    return int2(int(_649.x), int(_649.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_492.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3067 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _492);\n    fa_cl_slot = _3067.x;\n    fa_cl_local = _3067.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3374 = fa_linear_to_srgb(param);\n        c = _3374;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3382 = fa_srgb_to_linear(param_1);\n            c = _3382;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _255;\n    if (bool(i.front_facing))\n    {\n        _255 = i.world_normal;\n    }\n    else\n    {\n        _255 = -i.world_normal;\n    }\n    float3 _279 = fast::normalize(i.world_tangent.xyz - (_255 * dot(_255, i.world_tangent.xyz)));\n    float3 _307 = fast::normalize(((_279 * m.x) + ((cross(_255, _279) * i.world_tangent.w) * m.y)) + (_255 * m.z));\n    float3 _310;\n    if (bool(i.front_facing))\n    {\n        _310 = _307;\n    }\n    else\n    {\n        _310 = -_307;\n    }\n    return _310;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _492, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _492.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3413 = fa_tex_fix(param_2, param_3);\n    float4 _4422 = base_t;\n    _4422.x = _3413.x;\n    _4422.y = _3413.y;\n    _4422.z = _3413.z;\n    base_t = _4422;\n    float4 _3427 = (_4422 * _492.fa_base_color) * i.vertex_color;\n    float3 _4289 = i.world_normal;\n    if (_492.fa_maps.z > 0.5)\n    {\n        float param_4 = _492.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3459 = fa_tex_fix(param_6, param_7);\n        float3 _3462 = (_3459 * 2.0) - float3(1.0);\n        float2 _3467 = _3462.xy * _492.fa_maps.x;\n        float3 _4430 = _3462;\n        _4430.x = _3467.x;\n        _4430.y = _3467.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4430;\n        _4289 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _492.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3496 = fa_tex_fix(param_12, param_13);\n    float4 _4433 = mrt;\n    _4433.x = _3496.x;\n    _4433.y = _3496.y;\n    _4433.z = _3496.z;\n    mrt = _4433;\n    float4 _3524 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _492.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3524.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3536 = fa_tex_fix(param_16, param_17);\n    float param_18 = _492.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3566 = fa_tex_fix(param_20, param_21);\n    float _4294 = _492.fa_layers_a.x;\n    float _4295 = _492.fa_layers_a.y;\n    float _4298 = _492.fa_layers_a.z;\n    float _4297 = _492.fa_layers_b.w;\n    float _4300 = _492.fa_layers_c.x;\n    if (_492.fa_layers_c.z > 0.5)\n    {\n        if (mod(_492.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4294 *= _3536.y;\n            _4295 *= _3536.z;\n            _4297 *= _3524.w;\n        }\n        if (_492.fa_layers_c.z > 1.5)\n        {\n            _4298 *= mrt.x;\n            _4300 *= mrt.w;\n        }\n    }\n    return Surface{ _3427.xyz, _3427.w, _4289, fast::clamp(_492.fa_pbr.x * _3496.z, 0.0, 1.0), fast::clamp(_492.fa_pbr.y * _3496.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_492.fa_maps.y * (_3536.x - 1.0)), _492.fa_emissive.xyz + (_492.fa_model_emissive.xyz * _3566), _4294, _4295, _492.fa_layers_b.xyz, _4297, _4298, _492.fa_layers_a.w, _4300, _492.fa_layers_c.y, _492.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _730 = rect.zw - rect.xy;\n    float2 _734 = _730 * atlas;\n    float2 _738 = ddx * _734;\n    float2 _742 = ddy * _734;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _730)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_738, _738), dot(_742, _742)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _777 = _492.fa_counts.y < 0.5;\n    bool _784;\n    if (!_777)\n    {\n        _784 = _492.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _784 = _777;\n    }\n    if (_784)\n    {\n        return;\n    }\n    float3 _790 = dfdx(world_pos);\n    float3 _793 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _797 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _492);\n    int _801 = int(_797.w);\n    if (_801 < 1)\n    {\n        return;\n    }\n    int _811 = int(_492.fa_counts.y + 0.5);\n    int param_1 = _811;\n    float4 _815 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _818 = _815.yz;\n    int _822 = int(_815.w);\n    int param_2 = _811 + 1;\n    float4 _827 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _828 = _827.x;\n    int _834 = int(_492.fa_counts.w + 0.5) - 1;\n    int _838 = int(_797.z);\n    float3 _1104;\n    for (int k = 0; k < _801; k++)\n    {\n        int _851 = _838 + k;\n        int param_3 = _822 + (_851 >> 2);\n        int _869 = (_811 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_851 & 3]) * 7);\n        int param_4 = _869 + 6;\n        float4 _874 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_874.w + 0.5) >> _834) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _869;\n        float4 _889 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _869 + 1;\n        float4 _894 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _869 + 2;\n        float4 _899 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _902 = _889.xyz;\n        float _907 = dot(_902, world_pos) + _889.w;\n        float3 _909 = _894.xyz;\n        float _914 = dot(_909, world_pos) + _894.w;\n        float3 _916 = _899.xyz;\n        float _921 = dot(_916, world_pos) + _899.w;\n        bool _926 = abs(_907) > 0.5;\n        bool _934;\n        if (!_926)\n        {\n            _934 = abs(_914) > 0.5;\n        }\n        else\n        {\n            _934 = _926;\n        }\n        bool _942;\n        if (!_934)\n        {\n            _942 = abs(_921) > 0.5;\n        }\n        else\n        {\n            _942 = _934;\n        }\n        if (_942)\n        {\n            continue;\n        }\n        float _957 = fast::clamp(dot(geo_normal, fast::normalize(_916)) * _874.z, 0.0, 1.0);\n        if (_957 <= 0.0)\n        {\n            continue;\n        }\n        float _977 = (fast::clamp((0.5 - abs(_921)) * 10.0, 0.0, 1.0) * _957) * _874.x;\n        float2 _985 = float2(_907 + 0.5, 0.5 - _914);\n        float2 _995 = float2(dot(_902, _790), dot(_909, _790));\n        float2 _1005 = float2(dot(_902, _793), dot(_909, _793));\n        int param_8 = _869 + 5;\n        float4 _1010 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _869 + 3;\n        float4 _1015 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _869 + 4;\n        float4 _1020 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1010.xyz;\n        bool _1030 = _1015.z > _1015.x;\n        if (_1030)\n        {\n            float4 param_11 = _1015;\n            float2 param_12 = _985;\n            float2 param_13 = _818;\n            float2 param_14 = _995;\n            float2 param_15 = _1005;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_828 > 0.5) && (_828 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1056 = fa_dc_to_linear(param_16);\n                float4 _4345 = tx;\n                _4345.x = _1056.x;\n                _4345.y = _1056.y;\n                _4345.z = _1056.z;\n                tx = _4345;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_977 * tex_a) * _1010.w, 0.0, 1.0)));\n        if (_1020.z > _1020.x)\n        {\n            float4 param_17 = _1020;\n            float2 param_18 = _985;\n            float2 param_19 = _818;\n            float2 param_20 = _995;\n            float2 param_21 = _1005;\n            float4 _1100 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_828 > 1.5)\n            {\n                float3 param_22 = _1100.xyz;\n                float3 _1110 = fa_dc_to_srgb(param_22);\n                _1104 = _1110;\n            }\n            else\n            {\n                _1104 = _1100.xyz;\n            }\n            float3 _1120 = (_1104 * 2.0) - float3(1.0);\n            float2 _1125 = _1120.xy * _874.y;\n            float3 _1147 = (fast::normalize(_902) * _1125.x) + (fast::normalize(_909) * _1125.y);\n            float3 _1150 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1150, fast::normalize((_1150 * fast::max(_1120.z, 0.0500000007450580596923828125)) + (_1147 - (_1150 * dot(_1150, _1147)))), float3(fast::clamp(_977 * (_1030 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(thread int& fa_cl_ndir, thread int& fa_cl_local)\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_no_light()\n{\n    return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, 0 };\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492)\n{\n    int param = (int(_492.fa_cl_info.x) + int(_492.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _492);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _366 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _372 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _375 = _372.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _381 = _375 < 0.5;\n    float3 l;\n    if (_381)\n    {\n        l = fast::normalize(_366.xyz);\n    }\n    else\n    {\n        float3 _393 = _366.xyz - world_pos;\n        float _395 = length(_393);\n        dist = _395;\n        l = _393 / float3(fast::max(_395, 9.9999997473787516355514526367188e-05));\n        float _410 = _395 / fast::max(_366.w, 0.001000000047497451305389404296875);\n        float _416 = fast::clamp(1.0 - (_410 * _410), 0.0, 1.0);\n        atten = _416 * _416;\n        if (_375 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _430 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _440 = _430.w;\n            int param_3 = (li * 4) + 3;\n            float4 _446 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _447 = _446.x;\n            float cos_inner = _447;\n            if (_447 > 1.5)\n            {\n                cos_inner = mix(_440, 1.0, 0.25);\n            }\n            atten *= smoothstep(_440, cos_inner, dot(-l, fast::normalize(_430.xyz)));\n        }\n    }\n    int _478;\n    if (_381)\n    {\n        _478 = 0;\n    }\n    else\n    {\n        _478 = (_375 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _372.xyz * atten, atten, 1.0, dist, _478 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_unshadowed(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, thread float3& fa_lm)\n{\n    bool _3208 = n < 0;\n    bool _3215;\n    if (!_3208)\n    {\n        _3215 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _3215 = _3208;\n    }\n    if (_3215)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _3223 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _492, fa_cl_ndir, fa_cl_slot);\n    bool _3226 = fa_lm.z > 0.5;\n    bool _3232;\n    if (_3226)\n    {\n        int param_1 = _3223;\n        _3232 = fa_light_baked(param_1, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3232 = _3226;\n    }\n    if (_3232)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _3223;\n    float3 param_3 = i.world_pos;\n    return fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1232)\n{\n    float _1222;\n    if (i == 0)\n    {\n        _1222 = _1232.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1238;\n        if (i == 1)\n        {\n            _1238 = _1232.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1246;\n            if (i == 2)\n            {\n                _1246 = _1232.fa_shadow_split.z;\n            }\n            else\n            {\n                _1246 = _1232.fa_shadow_split.w;\n            }\n            _1238 = _1246;\n        }\n        _1222 = _1238;\n    }\n    return _1222;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1279 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1283;\n    if (conv.x < 0.5)\n    {\n        _1283 = _1279;\n    }\n    else\n    {\n        _1283 = (conv.y * conv.z) / (conv.z - (_1279 * (conv.z - conv.y)));\n    }\n    return _1283;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1210 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1210), sin(_1210)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1232, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1329 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1343 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1329;\n            float2 _1362 = fa_shadow_vogel(param_3, param_4, param_5) * _1343;\n            float2 param_6 = uv + (_1362 * _1232.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1374 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1374 < (zr - (length(_1362) * plane)))\n            {\n                sum += _1374;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1418 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1418; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1418;\n        float param_11 = _1329;\n        float2 _1437 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1437 * _1232.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1437) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1418);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1232, texture2d<float> fa_shadow_tex)\n{\n    float _1479 = fast::max(_1232.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1484 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1490 = sqrt(1.0 - (_1484 * _1484));\n    float _1497 = fast::min(_1490 / fast::max(_1484, 0.20000000298023223876953125), 4.0);\n    float _1502;\n    if (_1232.fa_shadow_bias.y > 0.0)\n    {\n        _1502 = _1232.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1502 = 1.5 * _1232.fa_shadow_info[ci].x;\n    }\n    float4 _1527 = _1232.fa_shadow_mat[ci] * float4(world + (n * (_1502 * _1490)), 1.0);\n    float _1534 = _1527.x;\n    bool _1537 = _1534 < _1232.fa_shadow_rect[ci].x;\n    bool _1546;\n    if (!_1537)\n    {\n        _1546 = _1534 > _1232.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1546 = _1537;\n    }\n    bool _1555;\n    if (!_1546)\n    {\n        _1555 = _1527.y < _1232.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1555 = _1546;\n    }\n    bool _1564;\n    if (!_1555)\n    {\n        _1564 = _1527.y > _1232.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1564 = _1555;\n    }\n    bool _1571;\n    if (!_1564)\n    {\n        _1571 = _1527.z > 1.0;\n    }\n    else\n    {\n        _1571 = _1564;\n    }\n    if (_1571)\n    {\n        return -1.0;\n    }\n    float _1580;\n    if (_1232.fa_shadow_bias.x > 0.0)\n    {\n        _1580 = _1232.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1580 = 1.5 * _1232.fa_shadow_info[ci].x;\n    }\n    float2 param = _1527.xy;\n    float4 param_1 = _1232.fa_shadow_rect[ci];\n    float param_2 = _1527.z - ((_1580 * (1.0 + (0.5 * _1497))) / _1479);\n    float param_3 = _1232.fa_shadow_info[ci].x;\n    float param_4 = _1479;\n    float param_5 = _1479 * 0.25;\n    float param_6 = ((_1232.fa_shadow_info[ci].x * fast::min(_1497, 3.0)) * 0.5) / _1479;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1232.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1232.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1232, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492, thread float4& gl_FragCoord, constant fa_shadows& _1232, texture2d<float> fa_shadow_tex)\n{\n    if (_492.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2007 = int(_1232.fa_shadow_cfg.x + 0.5);\n    if (_2007 < 1)\n    {\n        return 1.0;\n    }\n    float _2022 = dot(world - _1232.fa_shadow_eye.xyz, _1232.fa_shadow_fwd.xyz);\n    int param = _2007 - 1;\n    if (_2022 > fa_shadow_split_at(param, _1232))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2034 = _2007 > 1;\n    bool _2041;\n    if (_2034)\n    {\n        _2041 = _2022 > _1232.fa_shadow_split.x;\n    }\n    else\n    {\n        _2041 = _2034;\n    }\n    if (_2041)\n    {\n        ci = 1;\n    }\n    bool _2045 = _2007 > 2;\n    bool _2052;\n    if (_2045)\n    {\n        _2052 = _2022 > _1232.fa_shadow_split.y;\n    }\n    else\n    {\n        _2052 = _2045;\n    }\n    if (_2052)\n    {\n        ci = 2;\n    }\n    bool _2056 = _2007 > 3;\n    bool _2063;\n    if (_2056)\n    {\n        _2063 = _2022 > _1232.fa_shadow_split.z;\n    }\n    else\n    {\n        _2063 = _2056;\n    }\n    if (_2063)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2007)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2089 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1232, fa_shadow_tex);\n        s = _2089;\n        if (_2089 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1232.fa_shadow_cfg.y > 0.0)\n    {\n        float _2114;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2114 = fa_shadow_split_at(param_5, _1232);\n        }\n        else\n        {\n            _2114 = _1232.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2133 = _1232.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1232) - _2114, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2144 = fast::clamp((_2022 - (fa_shadow_split_at(param_7, _1232) - _2133)) / _2133, 0.0, 1.0);\n        if (_2144 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2007)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2165 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1232, fa_shadow_tex);\n                s2 = _2165;\n                if (_2165 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2144);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492, thread float4& gl_FragCoord, constant fa_shadows& _1232, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _492, gl_FragCoord, _1232, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492, thread float4& gl_FragCoord, constant fa_shadows& _1232, texture2d<float> fa_shadow_tex)\n{\n    bool _1638 = _492.fa_pbr.z < 0.5;\n    bool _1646;\n    if (!_1638)\n    {\n        _1646 = _1232.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1646 = _1638;\n    }\n    if (_1646)\n    {\n        return 1.0;\n    }\n    int param = (int(_1232.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1659 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1660 = _1659.x;\n    if (_1660 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1669 = int(_1660 + 0.5);\n    int param_1 = _1669;\n    float4 _1673 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1669 + 1;\n    float4 _1678 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1681 = _1673.y;\n    if (_1681 > 0.0)\n    {\n        float _1698 = 1.0 - smoothstep(0.75 * _1681, _1681, length(world - _1232.fa_shadow_eye.xyz));\n        fade = _1698;\n        if (_1698 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1673.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1717 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1720 = abs(_1717);\n        float _1722 = _1720.x;\n        float _1724 = _1720.y;\n        bool _1725 = _1722 >= _1724;\n        bool _1733;\n        if (_1725)\n        {\n            _1733 = _1722 >= _1720.z;\n        }\n        else\n        {\n            _1733 = _1725;\n        }\n        int _1734;\n        if (_1733)\n        {\n            _1734 = (_1717.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1747;\n            if (_1724 >= _1720.z)\n            {\n                _1747 = (_1717.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1747 = (_1717.z > 0.0) ? 4 : 5;\n            }\n            _1734 = _1747;\n        }\n        face = _1734;\n    }\n    int _1766 = (_1669 + 2) + (face * 6);\n    int param_4 = _1766;\n    int param_5 = _1766 + 1;\n    int param_6 = _1766 + 3;\n    float4 _1780 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1766 + 4;\n    float4 _1785 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1766 + 5;\n    float4 _1790 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1802 = _1790.x * fast::max(dot(_1780, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1807 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1830 = fast::clamp(dot(n, _1780.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1853 = fast::min(sqrt(1.0 - (_1830 * _1830)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1780, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1856 = _1678.y;\n    float _1858;\n    if (_1856 > 0.0)\n    {\n        _1858 = _1856;\n    }\n    else\n    {\n        _1858 = 1.5 * _1802;\n    }\n    float4 _1878 = float4(world + (n * (_1858 * sqrt(1.0 - (_1807 * _1807)))), 1.0);\n    float _1882 = dot(_1780, _1878);\n    float _1885 = _1790.y;\n    if (_1882 < _1885)\n    {\n        return 1.0;\n    }\n    float2 _1900 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1878), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1878)) / float2(_1882);\n    float _1902 = _1900.x;\n    bool _1905 = _1902 < _1785.x;\n    bool _1914;\n    if (!_1905)\n    {\n        _1914 = _1902 > _1785.z;\n    }\n    else\n    {\n        _1914 = _1905;\n    }\n    bool _1923;\n    if (!_1914)\n    {\n        _1923 = _1900.y < _1785.y;\n    }\n    else\n    {\n        _1923 = _1914;\n    }\n    bool _1932;\n    if (!_1923)\n    {\n        _1932 = _1900.y > _1785.w;\n    }\n    else\n    {\n        _1932 = _1923;\n    }\n    if (_1932)\n    {\n        return 1.0;\n    }\n    float _1938 = _1678.x;\n    float _1940;\n    if (_1938 > 0.0)\n    {\n        _1940 = _1938;\n    }\n    else\n    {\n        _1940 = 1.5 * _1802;\n    }\n    float2 param_10 = _1900;\n    float4 param_11 = _1785;\n    float param_12 = _1882 - (_1940 * (1.0 + (0.5 * _1853)));\n    float param_13 = _1802;\n    float param_14 = 1.0;\n    float param_15 = _1790.z * 0.25;\n    float param_16 = (_1802 * fast::min(_1853, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1885, _1790.z);\n    int param_18 = int(_1673.z + 0.5);\n    float param_19 = _1673.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1232, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492, thread float4& gl_FragCoord, constant fa_shadows& _1232, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3094 = fa_lm.z > 0.5;\n    bool _3100;\n    if (_3094)\n    {\n        int param = li;\n        _3100 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3100 = _3094;\n    }\n    if (_3100)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3122 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _4265 = _3122.direction;\n    float3 _4260 = _3122.color;\n    float _4267 = _3122.attenuation;\n    float _4262 = _3122.shadow;\n    int _4270 = _3122.type;\n    if ((_4270 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4265;\n        float _3136 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _492, gl_FragCoord, _1232, fa_shadow_tex, fa_world_pos);\n        _4262 = _3136;\n        _4260 *= _3136;\n    }\n    else\n    {\n        bool _3147 = _4270 != 0;\n        bool _3153;\n        if (_3147)\n        {\n            _3153 = _4267 > 0.0;\n        }\n        else\n        {\n            _3153 = _3147;\n        }\n        if (_3153)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4265;\n            float _3165 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _492, gl_FragCoord, _1232, fa_shadow_tex);\n            _4262 = _3165;\n            _4260 *= _3165;\n        }\n    }\n    return LightSample{ _4265, _4260, _4267, _4262, _3122._distance, _4270 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492, thread float4& gl_FragCoord, constant fa_shadows& _1232, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, thread float3& fa_lm)\n{\n    bool _3182 = n < 0;\n    bool _3189;\n    if (!_3182)\n    {\n        _3189 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _3189 = _3182;\n    }\n    if (_3189)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _492, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3, fa_light_tex, fa_shadow_smp, _492, gl_FragCoord, _1232, fa_shadow_tex, fa_world_pos, fa_lm);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _2445 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2453 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2456 = int(_2445);\n    int _2459 = int(_2453);\n    float _2469 = _2453 - float(_2459);\n    int _2525 = (_2456 * 9) + _2459;\n    int _2545 = ((_2456 + 1) * 9) + _2459;\n    return mix(mix(_2520[_2525], _2520[_2525 + 1], _2469), mix(_2520[_2545], _2520[_2545 + 1], _2469), _2445 - float(_2456));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4126 = false;\n    float _4127 = 1.0;\n    float _4128 = 1.0;\n    float _4129 = 1.0;\n    float _4130 = 0.0;\n    float _4131 = 0.0;\n    float _4132 = 0.0;\n    float _4133 = 0.0;\n    float _4135 = 1.0;\n    bool _4136 = false;\n    float3 _4137 = float3(0.0);\n    float _4138 = 1.0;\n    float _4139 = 1.0;\n    float _4140 = 1.0;\n    float _4141 = 0.0;\n    float _4142 = 0.0;\n    float3 _4143 = float3(1.0, 0.0, 0.0);\n    float3 _4144 = float3(0.0, 0.0, 1.0);\n    float _4145 = 1.0;\n    float _4146 = 1.0;\n    float _2598 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2602 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2607 = (_2598 != 1.0) || (_2602 != 1.5);\n    bool _2617;\n    if (!_2607)\n    {\n        _2617 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2617 = _2607;\n    }\n    if (_2617)\n    {\n        float _2625 = (_2602 - 1.0) / (_2602 + 1.0);\n        f0 = mix(fast::min(float3(_2625 * _2625) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2598, s.albedo, float3(metallic));\n        _4127 = mix(_2598, 1.0, metallic);\n        _4126 = true;\n    }\n    float _2653 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2653 > 0.0)\n    {\n        float _2661 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4130 = _2653;\n        _4131 = _2661;\n        float _2668 = _2661 * _2661;\n        _4132 = _2668;\n        _4133 = _2668 * _2668;\n        float _2680 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4135 = _2680;\n        _4128 = 1.0 - (_2653 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2680, 0.0, 1.0), 5.0))));\n        _4126 = true;\n    }\n    float3 _2700 = fast::max(s.sheen_color, float3(0.0));\n    float _2709 = fast::max(_2700.x, fast::max(_2700.y, _2700.z));\n    if (_2709 > 0.0)\n    {\n        float _2717 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4136 = true;\n        _4137 = _2700;\n        _4138 = _2717;\n        _4139 = _2717 * _2717;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2717;\n        float _2734 = fa_sheen_albedo(param, param_1);\n        _4141 = _2734;\n        _4140 = 1.0 - fast::min(_2709 * _2734, 1.0);\n        _4126 = true;\n    }\n    _4129 = _4128 * _4140;\n    float _2753 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2753 != 0.0)\n    {\n        float3 _2768 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2768;\n        if (dot(_2768, _2768) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2785 = t;\n        float3 _2786 = fast::normalize(_2785);\n        t = _2786;\n        float3 _2811 = fast::normalize((_2786 * cos(s.anisotropy_rotation)) + ((cross(n, _2786) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4143 = _2811;\n        _4144 = cross(n, _2811);\n        float _2821 = roughness * roughness;\n        float _2827 = mix(_2821, 1.0, _2753 * _2753);\n        bool _2829 = _2753 > 0.0;\n        _4145 = _2829 ? _2827 : _2821;\n        _4146 = _2829 ? _2821 : _2827;\n        _4142 = _2753;\n        _4126 = true;\n    }\n    return FaLayers{ short(_4126), _4127, _4128, _4129, _4130, _4131, _4132, _4133, i.world_normal, _4135, short(_4136), _4137, _4138, _4139, _4140, _4141, _4142, _4143, _4144, _4145, _4146 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _2377 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2380 = _2377.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_2380 * _2380, exp2((-9.27999973297119140625) * ndv)) * _2380) + _2377.y)) + _2377.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _492, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_492.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _492.fa_env_horizon.w)).xyz;\n    }\n    float _2301 = rough * rough;\n    float _2331 = 0.60000002384185791015625 * _2301;\n    return mix(mix(_492.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_492.fa_env_horizon.xyz, _492.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _2301)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _2331, 0.0500000007450580596923828125 + _2331, d.y))), ((_492.fa_env_sky.xyz + _492.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_2301 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _492, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2862;\n        if (L.aniso >= 0.0)\n        {\n            _2862 = L.b;\n        }\n        else\n        {\n            _2862 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2862, v), _2862), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2895 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _492, fa_env_smp, fa_env_tex) * ((f0 * _2895.x) + (float3(L.f90) * _2895.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _492, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2950 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _492, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _2950.x) + _2950.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _492, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2419 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _492, fa_env_smp, fa_env_tex) * ((f0 * _2419.x) + float3(_2419.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _492, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float _2989 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _2993 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _3000 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_2989));\n    float3 f0 = _3000;\n    float3 _3004 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3004;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2989;\n    float param_5 = _2993;\n    float3 param_6 = _3000;\n    FaLayers _3021 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3021.on)\n    {\n        FaLayers param_7 = _3021;\n        float3 param_8 = _3004;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2993;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _492, fa_env_smp, fa_env_tex) * s.occlusion;\n    }\n    float3 param_12 = _3004;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2993;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _492, fa_env_smp, fa_env_tex) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lighting(thread const SurfaceInput& i, thread const Surface& s, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _492, sampler fa_env_smp, thread float4& gl_FragCoord, constant fa_shadows& _1232, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texturecube<float> fa_env_tex, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, thread float3& fa_lm, constant fa_material& _3313)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(fa_cl_ndir, fa_cl_local); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _3270 = dot(fa_light_unshadowed(param, param_1, fa_light_tex, fa_shadow_smp, _492, fa_cl_ndir, fa_cl_slot, fa_cl_local, fa_lm).color, float3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_3270 > bestPower)\n        {\n            bestPower = _3270;\n            best = n;\n        }\n    }\n    float3 lit = (_492.fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _3299 = fa_light(param_2, param_3, fa_light_tex, fa_shadow_smp, _492, gl_FragCoord, _1232, fa_shadow_tex, fa_world_pos, fa_cl_ndir, fa_cl_slot, fa_cl_local, fa_lm);\n        float _3307;\n        if (dot(s.normal, _3299.direction) > 0.5)\n        {\n            _3307 = 1.0;\n        }\n        else\n        {\n            _3307 = _3313.dark;\n        }\n        lit += ((s.albedo * _3299.color) * _3307);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5, _492, fa_env_smp, fa_env_tex) * _3313.skyAmount);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1232)\n{\n    if (_1232.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2189 = int(_1232.fa_shadow_cfg.x + 0.5);\n    float _2199 = dot(world - _1232.fa_shadow_eye.xyz, _1232.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2204 = _2189 > 0;\n    bool _2213;\n    if (_2204)\n    {\n        int param = _2189 - 1;\n        _2213 = _2199 <= fa_shadow_split_at(param, _1232);\n    }\n    else\n    {\n        _2213 = _2204;\n    }\n    if (_2213)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2220 = _2189 > 1;\n        bool _2227;\n        if (_2220)\n        {\n            _2227 = _2199 > _1232.fa_shadow_split.x;\n        }\n        else\n        {\n            _2227 = _2220;\n        }\n        if (_2227)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2233 = _2189 > 2;\n        bool _2240;\n        if (_2233)\n        {\n            _2240 = _2199 > _1232.fa_shadow_split.y;\n        }\n        else\n        {\n            _2240 = _2233;\n        }\n        if (_2240)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2246 = _2189 > 3;\n        bool _2253;\n        if (_2246)\n        {\n            _2253 = _2199 > _1232.fa_shadow_split.z;\n        }\n        else\n        {\n            _2253 = _2246;\n        }\n        if (_2253)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _492 [[buffer(1)]], constant fa_material& _3313 [[buffer(5)]], constant fa_shadows& _1232 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_decal_tex [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4000 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4000 = -_4000;\n    }\n    float3 _3687 = fast::normalize(_492.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _492, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4000, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3687, short(gl_FrontFacing) };\n    Surface _3695 = fa_standard_surface(param_1, _492, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4031 = _3695.albedo;\n    float _4032 = _3695.alpha;\n    float3 _4033 = _3695.normal;\n    float _4034 = _3695.metallic;\n    float _4035 = _3695.roughness;\n    float _4036 = _3695.occlusion;\n    float3 _4037 = _3695.emission;\n    float _4038 = _3695.clearcoat;\n    float _4039 = _3695.clearcoat_roughness;\n    float3 _4040 = _3695.sheen_color;\n    float _4041 = _3695.sheen_roughness;\n    float _4042 = _3695.anisotropy;\n    float _4043 = _3695.anisotropy_rotation;\n    float _4044 = _3695.specular;\n    float _4045 = _3695.ior;\n    float3 _4046 = _3695.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4000, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3687, short(gl_FrontFacing) };\n    Surface param_3 = _3695;\n    surface(param_2, param_3);\n    _4031 = param_3.albedo;\n    _4032 = param_3.alpha;\n    _4033 = param_3.normal;\n    _4034 = param_3.metallic;\n    _4035 = param_3.roughness;\n    _4036 = param_3.occlusion;\n    _4037 = param_3.emission;\n    _4038 = param_3.clearcoat;\n    _4039 = param_3.clearcoat_roughness;\n    _4040 = param_3.sheen_color;\n    _4041 = param_3.sheen_roughness;\n    _4042 = param_3.anisotropy;\n    _4043 = param_3.anisotropy_rotation;\n    _4044 = param_3.specular;\n    _4045 = param_3.ior;\n    _4046 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4000;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _492, fa_decal_tex, fa_env_smp);\n    _4031 = param_6;\n    _4033 = param_7;\n    float3 result;\n    if (_492.fa_emissive.w > 0.5)\n    {\n        result = _4031;\n    }\n    else\n    {\n        float3 _3733 = _4033;\n        float3 _3734 = fast::normalize(_3733);\n        _4033 = _3734;\n        SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _4000, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3687, short(gl_FrontFacing) };\n        Surface param_9 = Surface{ _4031, _4032, _3734, _4034, _4035, _4036, _4037, _4038, _4039, _4040, _4041, _4042, _4043, _4044, _4045, _4046 };\n        result = lighting(param_8, param_9, fa_light_tex, fa_shadow_smp, _492, fa_env_smp, gl_FragCoord, _1232, fa_shadow_tex, in.fa_world_pos, fa_env_tex, fa_cl_ndir, fa_cl_slot, fa_cl_local, in.fa_lm, _3313);\n    }\n    float3 _3749 = result;\n    float3 _3750 = _3749 + _4037;\n    result = _3750;\n    float3 param_10 = _3750;\n    float3 param_11 = in.fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11, _1232);\n    bool _3759 = _492.fa_fog.w > 0.0;\n    bool _3766;\n    if (!_3759)\n    {\n        _3766 = _492.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3766 = _3759;\n    }\n    if (_3766)\n    {\n        float3 _3775 = in.fa_world_pos - _492.fa_camera_pos.xyz;\n        float _3781 = dot(_3775, _492.fa_fog_c.xyz);\n        bool _3785 = _492.fa_fog_c.w > 0.5;\n        float _3786;\n        if (_3785)\n        {\n            _3786 = _3781;\n        }\n        else\n        {\n            _3786 = length(_3775);\n        }\n        float _3798 = _3786 - _492.fa_fog_b.x;\n        if (_3798 > 0.0)\n        {\n            float _3807 = _492.fa_fog.w * _3798;\n            float tau = _3807 * _3807;\n            if (_492.fa_fog_b.y > 0.0)\n            {\n                float _3823;\n                if (_3785)\n                {\n                    _3823 = in.fa_world_pos.y - (_492.fa_fog_c.y * _3781);\n                }\n                else\n                {\n                    _3823 = _492.fa_camera_pos.y;\n                }\n                float _3844 = mix(_3823, in.fa_world_pos.y, fast::clamp(_492.fa_fog_b.x / _3786, 0.0, 1.0));\n                float _3848 = in.fa_world_pos.y - _3844;\n                float _3853 = _3844 - _492.fa_fog_b.z;\n                float _3858 = in.fa_world_pos.y - _492.fa_fog_b.z;\n                bool _3861 = _3853 <= 0.0;\n                bool _3862 = !_3861;\n                bool _3868;\n                if (_3862)\n                {\n                    _3868 = _492.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3868 = _3861;\n                }\n                float _3869;\n                if (_3868)\n                {\n                    _3869 = _492.fa_fog_b.y;\n                }\n                else\n                {\n                    _3869 = _492.fa_fog_b.y * exp(-fast::min(_492.fa_fog_b.w * _3853, 80.0));\n                }\n                bool _3896;\n                if (_3862)\n                {\n                    _3896 = _492.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3896 = _3861;\n                }\n                float _3897;\n                if (_3896)\n                {\n                    _3897 = _492.fa_fog_b.y * _3853;\n                }\n                else\n                {\n                    _3897 = (_492.fa_fog_b.y * (1.0 - exp(-fast::min(_492.fa_fog_b.w * _3853, 80.0)))) / _492.fa_fog_b.w;\n                }\n                bool _3922 = _3858 <= 0.0;\n                bool _3929;\n                if (!_3922)\n                {\n                    _3929 = _492.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3929 = _3922;\n                }\n                float _3930;\n                if (_3929)\n                {\n                    _3930 = _492.fa_fog_b.y * _3858;\n                }\n                else\n                {\n                    _3930 = (_492.fa_fog_b.y * (1.0 - exp(-fast::min(_492.fa_fog_b.w * _3858, 80.0)))) / _492.fa_fog_b.w;\n                }\n                float _3957;\n                if (abs(_3848) < 0.001000000047497451305389404296875)\n                {\n                    _3957 = _3869;\n                }\n                else\n                {\n                    _3957 = (_3930 - _3897) / _3848;\n                }\n                tau += (_3798 * fast::max(_3957, 0.0));\n            }\n            result = mix(result, _492.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4032);\n    return out;\n}\n\n",
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
            "inst_name": "_492",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1232",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_3313",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 8,
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
