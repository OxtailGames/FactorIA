{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "cdeb0668828214c74f0c30d588a05ff792b9d23c1a6a8d04f213c29c73527515",
  "slang": "metal_macos",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_270, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float skyAmount;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nconstant spvUnsafeArray<float, 63> _2528 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500)\n{\n    bool _505 = _500.fa_cl_info.x < 0.0;\n    bool _512;\n    if (!_505)\n    {\n        _512 = _500.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _512 = _505;\n    }\n    bool _520;\n    if (!_512)\n    {\n        _520 = _500.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _520 = _512;\n    }\n    bool _527;\n    if (!_520)\n    {\n        _527 = _500.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _527 = _520;\n    }\n    bool _534;\n    if (!_527)\n    {\n        _534 = _500.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _534 = _527;\n    }\n    if (_534)\n    {\n        return float4(0.0);\n    }\n    float4 _544 = float4(world_pos, 1.0);\n    float _551 = dot(_500.fa_cl_vpw, _544);\n    if (!(_551 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _573 = float2(dot(_500.fa_cl_vpx, _544), dot(_500.fa_cl_vpy, _544)) / float2(_551);\n    int _577 = int(_500.fa_cl_grid.x);\n    int _581 = int(_500.fa_cl_grid.y);\n    int param = (int(_500.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_500.fa_cl_fwd.xyz, world_pos) + _500.fa_cl_fwd.w, _500.fa_cl_grid.w) / _500.fa_cl_grid.w) * _500.fa_cl_grid.z)), 0, int(_500.fa_cl_info.y) - 1) * _581) + clamp(int(floor(((_573.y * 0.5) + 0.5) * _500.fa_cl_grid.y)), 0, _581 - 1)) * _577)) + clamp(int(floor(((_573.x * 0.5) + 0.5) * _500.fa_cl_grid.x)), 0, _577 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500)\n{\n    float3 param = world_pos;\n    float4 _657 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _500);\n    return int2(int(_657.x), int(_657.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_500.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3326 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _500);\n    fa_cl_slot = _3326.x;\n    fa_cl_local = _3326.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3677 = fa_linear_to_srgb(param);\n        c = _3677;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3685 = fa_srgb_to_linear(param_1);\n            c = _3685;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _263;\n    if (bool(i.front_facing))\n    {\n        _263 = i.world_normal;\n    }\n    else\n    {\n        _263 = -i.world_normal;\n    }\n    float3 _287 = fast::normalize(i.world_tangent.xyz - (_263 * dot(_263, i.world_tangent.xyz)));\n    float3 _315 = fast::normalize(((_287 * m.x) + ((cross(_263, _287) * i.world_tangent.w) * m.y)) + (_263 * m.z));\n    float3 _318;\n    if (bool(i.front_facing))\n    {\n        _318 = _315;\n    }\n    else\n    {\n        _318 = -_315;\n    }\n    return _318;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _500, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _500.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3716 = fa_tex_fix(param_2, param_3);\n    float4 _4738 = base_t;\n    _4738.x = _3716.x;\n    _4738.y = _3716.y;\n    _4738.z = _3716.z;\n    base_t = _4738;\n    float4 _3730 = (_4738 * _500.fa_base_color) * i.vertex_color;\n    float3 _4592 = i.world_normal;\n    if (_500.fa_maps.z > 0.5)\n    {\n        float param_4 = _500.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3762 = fa_tex_fix(param_6, param_7);\n        float3 _3765 = (_3762 * 2.0) - float3(1.0);\n        float2 _3770 = _3765.xy * _500.fa_maps.x;\n        float3 _4746 = _3765;\n        _4746.x = _3770.x;\n        _4746.y = _3770.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4746;\n        _4592 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _500.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3799 = fa_tex_fix(param_12, param_13);\n    float4 _4749 = mrt;\n    _4749.x = _3799.x;\n    _4749.y = _3799.y;\n    _4749.z = _3799.z;\n    mrt = _4749;\n    float4 _3827 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _500.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3827.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3839 = fa_tex_fix(param_16, param_17);\n    float param_18 = _500.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3869 = fa_tex_fix(param_20, param_21);\n    float _4597 = _500.fa_layers_a.x;\n    float _4598 = _500.fa_layers_a.y;\n    float _4601 = _500.fa_layers_a.z;\n    float _4600 = _500.fa_layers_b.w;\n    float _4603 = _500.fa_layers_c.x;\n    if (_500.fa_layers_c.z > 0.5)\n    {\n        if (mod(_500.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4597 *= _3839.y;\n            _4598 *= _3839.z;\n            _4600 *= _3827.w;\n        }\n        if (_500.fa_layers_c.z > 1.5)\n        {\n            _4601 *= mrt.x;\n            _4603 *= mrt.w;\n        }\n    }\n    return Surface{ _3730.xyz, _3730.w, _4592, fast::clamp(_500.fa_pbr.x * _3799.z, 0.0, 1.0), fast::clamp(_500.fa_pbr.y * _3799.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_500.fa_maps.y * (_3839.x - 1.0)), _500.fa_emissive.xyz + (_500.fa_model_emissive.xyz * _3869), _4597, _4598, _500.fa_layers_b.xyz, _4600, _4601, _500.fa_layers_a.w, _4603, _500.fa_layers_c.y, _500.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _738 = rect.zw - rect.xy;\n    float2 _742 = _738 * atlas;\n    float2 _746 = ddx * _742;\n    float2 _750 = ddy * _742;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _738)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_746, _746), dot(_750, _750)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _785 = _500.fa_counts.y < 0.5;\n    bool _792;\n    if (!_785)\n    {\n        _792 = _500.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _792 = _785;\n    }\n    if (_792)\n    {\n        return;\n    }\n    float3 _798 = dfdx(world_pos);\n    float3 _801 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _805 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _500);\n    int _809 = int(_805.w);\n    if (_809 < 1)\n    {\n        return;\n    }\n    int _819 = int(_500.fa_counts.y + 0.5);\n    int param_1 = _819;\n    float4 _823 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _826 = _823.yz;\n    int _830 = int(_823.w);\n    int param_2 = _819 + 1;\n    float4 _835 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _836 = _835.x;\n    int _842 = int(_500.fa_counts.w + 0.5) - 1;\n    int _846 = int(_805.z);\n    float3 _1112;\n    for (int k = 0; k < _809; k++)\n    {\n        int _859 = _846 + k;\n        int param_3 = _830 + (_859 >> 2);\n        int _877 = (_819 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_859 & 3]) * 7);\n        int param_4 = _877 + 6;\n        float4 _882 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_882.w + 0.5) >> _842) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _877;\n        float4 _897 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _877 + 1;\n        float4 _902 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _877 + 2;\n        float4 _907 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _910 = _897.xyz;\n        float _915 = dot(_910, world_pos) + _897.w;\n        float3 _917 = _902.xyz;\n        float _922 = dot(_917, world_pos) + _902.w;\n        float3 _924 = _907.xyz;\n        float _929 = dot(_924, world_pos) + _907.w;\n        bool _934 = abs(_915) > 0.5;\n        bool _942;\n        if (!_934)\n        {\n            _942 = abs(_922) > 0.5;\n        }\n        else\n        {\n            _942 = _934;\n        }\n        bool _950;\n        if (!_942)\n        {\n            _950 = abs(_929) > 0.5;\n        }\n        else\n        {\n            _950 = _942;\n        }\n        if (_950)\n        {\n            continue;\n        }\n        float _965 = fast::clamp(dot(geo_normal, fast::normalize(_924)) * _882.z, 0.0, 1.0);\n        if (_965 <= 0.0)\n        {\n            continue;\n        }\n        float _985 = (fast::clamp((0.5 - abs(_929)) * 10.0, 0.0, 1.0) * _965) * _882.x;\n        float2 _993 = float2(_915 + 0.5, 0.5 - _922);\n        float2 _1003 = float2(dot(_910, _798), dot(_917, _798));\n        float2 _1013 = float2(dot(_910, _801), dot(_917, _801));\n        int param_8 = _877 + 5;\n        float4 _1018 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _877 + 3;\n        float4 _1023 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _877 + 4;\n        float4 _1028 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1018.xyz;\n        bool _1038 = _1023.z > _1023.x;\n        if (_1038)\n        {\n            float4 param_11 = _1023;\n            float2 param_12 = _993;\n            float2 param_13 = _826;\n            float2 param_14 = _1003;\n            float2 param_15 = _1013;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_836 > 0.5) && (_836 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1064 = fa_dc_to_linear(param_16);\n                float4 _4648 = tx;\n                _4648.x = _1064.x;\n                _4648.y = _1064.y;\n                _4648.z = _1064.z;\n                tx = _4648;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_985 * tex_a) * _1018.w, 0.0, 1.0)));\n        if (_1028.z > _1028.x)\n        {\n            float4 param_17 = _1028;\n            float2 param_18 = _993;\n            float2 param_19 = _826;\n            float2 param_20 = _1003;\n            float2 param_21 = _1013;\n            float4 _1108 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_836 > 1.5)\n            {\n                float3 param_22 = _1108.xyz;\n                float3 _1118 = fa_dc_to_srgb(param_22);\n                _1112 = _1118;\n            }\n            else\n            {\n                _1112 = _1108.xyz;\n            }\n            float3 _1128 = (_1112 * 2.0) - float3(1.0);\n            float2 _1133 = _1128.xy * _882.y;\n            float3 _1155 = (fast::normalize(_910) * _1133.x) + (fast::normalize(_917) * _1133.y);\n            float3 _1158 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1158, fast::normalize((_1158 * fast::max(_1128.z, 0.0500000007450580596923828125)) + (_1155 - (_1158 * dot(_1158, _1155)))), float3(fast::clamp(_985 * (_1038 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(thread int& fa_cl_ndir, thread int& fa_cl_local)\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_no_light()\n{\n    return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, 0 };\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500)\n{\n    int param = (int(_500.fa_cl_info.x) + int(_500.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _500);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _374 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _380 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _383 = _380.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _389 = _383 < 0.5;\n    float3 l;\n    if (_389)\n    {\n        l = fast::normalize(_374.xyz);\n    }\n    else\n    {\n        float3 _401 = _374.xyz - world_pos;\n        float _403 = length(_401);\n        dist = _403;\n        l = _401 / float3(fast::max(_403, 9.9999997473787516355514526367188e-05));\n        float _418 = _403 / fast::max(_374.w, 0.001000000047497451305389404296875);\n        float _424 = fast::clamp(1.0 - (_418 * _418), 0.0, 1.0);\n        atten = _424 * _424;\n        if (_383 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _438 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _448 = _438.w;\n            int param_3 = (li * 4) + 3;\n            float4 _454 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _455 = _454.x;\n            float cos_inner = _455;\n            if (_455 > 1.5)\n            {\n                cos_inner = mix(_448, 1.0, 0.25);\n            }\n            atten *= smoothstep(_448, cos_inner, dot(-l, fast::normalize(_438.xyz)));\n        }\n    }\n    int _486;\n    if (_389)\n    {\n        _486 = 0;\n    }\n    else\n    {\n        _486 = (_383 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _380.xyz * atten, atten, 1.0, dist, _486 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_unshadowed(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, thread float3& fa_lm)\n{\n    bool _3511 = n < 0;\n    bool _3518;\n    if (!_3511)\n    {\n        _3518 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _3518 = _3511;\n    }\n    if (_3518)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _3526 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _500, fa_cl_ndir, fa_cl_slot);\n    bool _3529 = fa_lm.z > 0.5;\n    bool _3535;\n    if (_3529)\n    {\n        int param_1 = _3526;\n        _3535 = fa_light_baked(param_1, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3535 = _3529;\n    }\n    if (_3535)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _3526;\n    float3 param_3 = i.world_pos;\n    return fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1240)\n{\n    float _1230;\n    if (i == 0)\n    {\n        _1230 = _1240.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1246;\n        if (i == 1)\n        {\n            _1246 = _1240.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1254;\n            if (i == 2)\n            {\n                _1254 = _1240.fa_shadow_split.z;\n            }\n            else\n            {\n                _1254 = _1240.fa_shadow_split.w;\n            }\n            _1246 = _1254;\n        }\n        _1230 = _1246;\n    }\n    return _1230;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1287 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1291;\n    if (conv.x < 0.5)\n    {\n        _1291 = _1287;\n    }\n    else\n    {\n        _1291 = (conv.y * conv.z) / (conv.z - (_1287 * (conv.z - conv.y)));\n    }\n    return _1291;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1218 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1218), sin(_1218)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1240, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1337 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1351 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1337;\n            float2 _1370 = fa_shadow_vogel(param_3, param_4, param_5) * _1351;\n            float2 param_6 = uv + (_1370 * _1240.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1382 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1382 < (zr - (length(_1370) * plane)))\n            {\n                sum += _1382;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1426 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1426; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1426;\n        float param_11 = _1337;\n        float2 _1445 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1445 * _1240.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1445) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1426);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1240, texture2d<float> fa_shadow_tex)\n{\n    float _1487 = fast::max(_1240.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1492 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1498 = sqrt(1.0 - (_1492 * _1492));\n    float _1505 = fast::min(_1498 / fast::max(_1492, 0.20000000298023223876953125), 4.0);\n    float _1510;\n    if (_1240.fa_shadow_bias.y > 0.0)\n    {\n        _1510 = _1240.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1510 = 1.5 * _1240.fa_shadow_info[ci].x;\n    }\n    float4 _1535 = _1240.fa_shadow_mat[ci] * float4(world + (n * (_1510 * _1498)), 1.0);\n    float _1542 = _1535.x;\n    bool _1545 = _1542 < _1240.fa_shadow_rect[ci].x;\n    bool _1554;\n    if (!_1545)\n    {\n        _1554 = _1542 > _1240.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1554 = _1545;\n    }\n    bool _1563;\n    if (!_1554)\n    {\n        _1563 = _1535.y < _1240.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1563 = _1554;\n    }\n    bool _1572;\n    if (!_1563)\n    {\n        _1572 = _1535.y > _1240.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1572 = _1563;\n    }\n    bool _1579;\n    if (!_1572)\n    {\n        _1579 = _1535.z > 1.0;\n    }\n    else\n    {\n        _1579 = _1572;\n    }\n    if (_1579)\n    {\n        return -1.0;\n    }\n    float _1588;\n    if (_1240.fa_shadow_bias.x > 0.0)\n    {\n        _1588 = _1240.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1588 = 1.5 * _1240.fa_shadow_info[ci].x;\n    }\n    float2 param = _1535.xy;\n    float4 param_1 = _1240.fa_shadow_rect[ci];\n    float param_2 = _1535.z - ((_1588 * (1.0 + (0.5 * _1505))) / _1487);\n    float param_3 = _1240.fa_shadow_info[ci].x;\n    float param_4 = _1487;\n    float param_5 = _1487 * 0.25;\n    float param_6 = ((_1240.fa_shadow_info[ci].x * fast::min(_1505, 3.0)) * 0.5) / _1487;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1240.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1240.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1240, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, thread float4& gl_FragCoord, constant fa_shadows& _1240, texture2d<float> fa_shadow_tex)\n{\n    if (_500.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2015 = int(_1240.fa_shadow_cfg.x + 0.5);\n    if (_2015 < 1)\n    {\n        return 1.0;\n    }\n    float _2030 = dot(world - _1240.fa_shadow_eye.xyz, _1240.fa_shadow_fwd.xyz);\n    int param = _2015 - 1;\n    if (_2030 > fa_shadow_split_at(param, _1240))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2042 = _2015 > 1;\n    bool _2049;\n    if (_2042)\n    {\n        _2049 = _2030 > _1240.fa_shadow_split.x;\n    }\n    else\n    {\n        _2049 = _2042;\n    }\n    if (_2049)\n    {\n        ci = 1;\n    }\n    bool _2053 = _2015 > 2;\n    bool _2060;\n    if (_2053)\n    {\n        _2060 = _2030 > _1240.fa_shadow_split.y;\n    }\n    else\n    {\n        _2060 = _2053;\n    }\n    if (_2060)\n    {\n        ci = 2;\n    }\n    bool _2064 = _2015 > 3;\n    bool _2071;\n    if (_2064)\n    {\n        _2071 = _2030 > _1240.fa_shadow_split.z;\n    }\n    else\n    {\n        _2071 = _2064;\n    }\n    if (_2071)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2015)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2097 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1240, fa_shadow_tex);\n        s = _2097;\n        if (_2097 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1240.fa_shadow_cfg.y > 0.0)\n    {\n        float _2122;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2122 = fa_shadow_split_at(param_5, _1240);\n        }\n        else\n        {\n            _2122 = _1240.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2141 = _1240.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1240) - _2122, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2152 = fast::clamp((_2030 - (fa_shadow_split_at(param_7, _1240) - _2141)) / _2141, 0.0, 1.0);\n        if (_2152 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2015)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2173 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1240, fa_shadow_tex);\n                s2 = _2173;\n                if (_2173 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2152);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, thread float4& gl_FragCoord, constant fa_shadows& _1240, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _500, gl_FragCoord, _1240, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, thread float4& gl_FragCoord, constant fa_shadows& _1240, texture2d<float> fa_shadow_tex)\n{\n    bool _1646 = _500.fa_pbr.z < 0.5;\n    bool _1654;\n    if (!_1646)\n    {\n        _1654 = _1240.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1654 = _1646;\n    }\n    if (_1654)\n    {\n        return 1.0;\n    }\n    int param = (int(_1240.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1667 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1668 = _1667.x;\n    if (_1668 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1677 = int(_1668 + 0.5);\n    int param_1 = _1677;\n    float4 _1681 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1677 + 1;\n    float4 _1686 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1689 = _1681.y;\n    if (_1689 > 0.0)\n    {\n        float _1706 = 1.0 - smoothstep(0.75 * _1689, _1689, length(world - _1240.fa_shadow_eye.xyz));\n        fade = _1706;\n        if (_1706 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1681.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1725 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1728 = abs(_1725);\n        float _1730 = _1728.x;\n        float _1732 = _1728.y;\n        bool _1733 = _1730 >= _1732;\n        bool _1741;\n        if (_1733)\n        {\n            _1741 = _1730 >= _1728.z;\n        }\n        else\n        {\n            _1741 = _1733;\n        }\n        int _1742;\n        if (_1741)\n        {\n            _1742 = (_1725.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1755;\n            if (_1732 >= _1728.z)\n            {\n                _1755 = (_1725.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1755 = (_1725.z > 0.0) ? 4 : 5;\n            }\n            _1742 = _1755;\n        }\n        face = _1742;\n    }\n    int _1774 = (_1677 + 2) + (face * 6);\n    int param_4 = _1774;\n    int param_5 = _1774 + 1;\n    int param_6 = _1774 + 3;\n    float4 _1788 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1774 + 4;\n    float4 _1793 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1774 + 5;\n    float4 _1798 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1810 = _1798.x * fast::max(dot(_1788, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1815 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1838 = fast::clamp(dot(n, _1788.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1861 = fast::min(sqrt(1.0 - (_1838 * _1838)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1788, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1864 = _1686.y;\n    float _1866;\n    if (_1864 > 0.0)\n    {\n        _1866 = _1864;\n    }\n    else\n    {\n        _1866 = 1.5 * _1810;\n    }\n    float4 _1886 = float4(world + (n * (_1866 * sqrt(1.0 - (_1815 * _1815)))), 1.0);\n    float _1890 = dot(_1788, _1886);\n    float _1893 = _1798.y;\n    if (_1890 < _1893)\n    {\n        return 1.0;\n    }\n    float2 _1908 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1886), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1886)) / float2(_1890);\n    float _1910 = _1908.x;\n    bool _1913 = _1910 < _1793.x;\n    bool _1922;\n    if (!_1913)\n    {\n        _1922 = _1910 > _1793.z;\n    }\n    else\n    {\n        _1922 = _1913;\n    }\n    bool _1931;\n    if (!_1922)\n    {\n        _1931 = _1908.y < _1793.y;\n    }\n    else\n    {\n        _1931 = _1922;\n    }\n    bool _1940;\n    if (!_1931)\n    {\n        _1940 = _1908.y > _1793.w;\n    }\n    else\n    {\n        _1940 = _1931;\n    }\n    if (_1940)\n    {\n        return 1.0;\n    }\n    float _1946 = _1686.x;\n    float _1948;\n    if (_1946 > 0.0)\n    {\n        _1948 = _1946;\n    }\n    else\n    {\n        _1948 = 1.5 * _1810;\n    }\n    float2 param_10 = _1908;\n    float4 param_11 = _1793;\n    float param_12 = _1890 - (_1948 * (1.0 + (0.5 * _1861)));\n    float param_13 = _1810;\n    float param_14 = 1.0;\n    float param_15 = _1798.z * 0.25;\n    float param_16 = (_1810 * fast::min(_1861, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1893, _1798.z);\n    int param_18 = int(_1681.z + 0.5);\n    float param_19 = _1681.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1240, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_contact_shadow(thread const int& li, thread const float3& world, thread const float3& gn, thread const float3& l, thread const float& dist, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, thread float4& gl_FragCoord, constant fa_shadows& _1240, texture2d<float> fa_screen_tex)\n{\n    bool _3068 = _500.fa_ct_a.x < 0.5;\n    bool _3075;\n    if (!_3068)\n    {\n        _3075 = _1240.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _3075 = _3068;\n    }\n    if (_3075)\n    {\n        return 1.0;\n    }\n    int param = (int(_1240.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _3088 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _3089 = _3088.y;\n    float len = _3089;\n    if (_3089 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3101 = length(world - _500.fa_camera_pos.xyz);\n    float _3111 = 1.0 - smoothstep(0.5 * _500.fa_ct_b.x, _500.fa_ct_b.x, _3101);\n    if (_3111 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3117 = len;\n    float _3120 = fast::min(_3117, 0.89999997615814208984375 * dist);\n    len = _3120;\n    float _3125 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3101);\n    float _3130 = _3125 + (0.5 * _3120);\n    float3 _3136 = world + (gn * _3125);\n    float _3138 = fa_shadow_noise(gl_FragCoord);\n    float occ = 0.0;\n    float _3202;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3153 = (float(k) + _3138) * 0.083333335816860198974609375;\n        float3 _3161 = _3136 + (l * (_3153 * len));\n        float4 _3167 = float4(_3161, 1.0);\n        float _3173 = dot(_500.fa_ct_vpw, _3167);\n        if (_3173 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        float2 _3193 = float2(dot(_500.fa_ct_vpx, _3167), dot(_500.fa_ct_vpy, _3167)) / float2(_3173);\n        float _3197 = _3193.x * 0.5;\n        float _3198 = _3197 + 0.5;\n        if (_500.fa_ct_a.y > 0.5)\n        {\n            _3202 = (_3193.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3202 = 0.5 - (_3193.y * 0.5);\n        }\n        bool _3218 = _3198 < 0.0;\n        bool _3225;\n        if (!_3218)\n        {\n            _3225 = _3198 >= 1.0;\n        }\n        else\n        {\n            _3225 = _3218;\n        }\n        bool _3232;\n        if (!_3225)\n        {\n            _3232 = _3202 < 0.0;\n        }\n        else\n        {\n            _3232 = _3225;\n        }\n        bool _3239;\n        if (!_3232)\n        {\n            _3239 = _3202 >= 1.0;\n        }\n        else\n        {\n            _3239 = _3232;\n        }\n        if (_3239)\n        {\n            break;\n        }\n        float4 _3258 = fa_screen_tex.read(uint2(int2(float2(_3198, _3202) * _500.fa_ct_a.zw)), 0);\n        if (_3258.w < 0.5)\n        {\n            continue;\n        }\n        float _3277 = (dot(_500.fa_ct_fwd.xyz, _3161) + _500.fa_ct_fwd.w) - _3258.x;\n        if ((_3277 > _3125) && (_3277 < _3130))\n        {\n            occ = fast::max(occ, (1.0 - (_3153 * _3153)) * smoothstep(0.0, 0.0500000007450580596923828125, fast::min(fast::min(_3198, 0.5 - _3197), fast::min(_3202, 1.0 - _3202))));\n        }\n    }\n    return 1.0 - (occ * _3111);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, thread float4& gl_FragCoord, constant fa_shadows& _1240, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread float3& fa_lm)\n{\n    bool _3353 = fa_lm.z > 0.5;\n    bool _3359;\n    if (_3353)\n    {\n        int param = li;\n        _3359 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3359 = _3353;\n    }\n    if (_3359)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3381 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _4568 = _3381.direction;\n    float3 _4563 = _3381.color;\n    float _4570 = _3381.attenuation;\n    float _4565 = _3381.shadow;\n    float _4572 = _3381._distance;\n    int _4573 = _3381.type;\n    bool _3384 = _4573 == 0;\n    if (_3384 && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4568;\n        float _3395 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _500, gl_FragCoord, _1240, fa_shadow_tex, fa_world_pos);\n        _4565 = _3395;\n        _4563 *= _3395;\n    }\n    else\n    {\n        bool _3406 = _4573 != 0;\n        bool _3412;\n        if (_3406)\n        {\n            _3412 = _4570 > 0.0;\n        }\n        else\n        {\n            _3412 = _3406;\n        }\n        if (_3412)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4568;\n            float _3424 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _500, gl_FragCoord, _1240, fa_shadow_tex);\n            _4565 = _3424;\n            _4563 *= _3424;\n        }\n    }\n    bool _3434 = _500.fa_ct_a.x > 0.5;\n    bool _3440;\n    if (_3434)\n    {\n        _3440 = _4570 > 0.0;\n    }\n    else\n    {\n        _3440 = _3434;\n    }\n    if (_3440)\n    {\n        float _3447;\n        if (_3384)\n        {\n            _3447 = 1000000000.0;\n        }\n        else\n        {\n            _3447 = _4572;\n        }\n        int param_10 = li;\n        float3 param_11 = world_pos;\n        float3 param_12 = gn;\n        float3 param_13 = _4568;\n        float param_14 = _3447;\n        float _3465 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14, fa_light_tex, fa_shadow_smp, _500, gl_FragCoord, _1240, fa_screen_tex);\n        _4565 *= _3465;\n        _4563 *= _3465;\n    }\n    return LightSample{ _4568, _4563, _4570, _4565, _4572, _4573 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, thread float4& gl_FragCoord, constant fa_shadows& _1240, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, thread float3& fa_lm)\n{\n    bool _3485 = n < 0;\n    bool _3492;\n    if (!_3485)\n    {\n        _3492 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _3492 = _3485;\n    }\n    if (_3492)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _500, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3, fa_light_tex, fa_shadow_smp, _500, gl_FragCoord, _1240, fa_shadow_tex, fa_world_pos, fa_screen_tex, fa_lm);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _2453 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2461 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2464 = int(_2453);\n    int _2467 = int(_2461);\n    float _2477 = _2461 - float(_2467);\n    int _2533 = (_2464 * 9) + _2467;\n    int _2553 = ((_2464 + 1) * 9) + _2467;\n    return mix(mix(_2528[_2533], _2528[_2533 + 1], _2477), mix(_2528[_2553], _2528[_2553 + 1], _2477), _2453 - float(_2464));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4429 = false;\n    float _4430 = 1.0;\n    float _4431 = 1.0;\n    float _4432 = 1.0;\n    float _4433 = 0.0;\n    float _4434 = 0.0;\n    float _4435 = 0.0;\n    float _4436 = 0.0;\n    float _4438 = 1.0;\n    bool _4439 = false;\n    float3 _4440 = float3(0.0);\n    float _4441 = 1.0;\n    float _4442 = 1.0;\n    float _4443 = 1.0;\n    float _4444 = 0.0;\n    float _4445 = 0.0;\n    float3 _4446 = float3(1.0, 0.0, 0.0);\n    float3 _4447 = float3(0.0, 0.0, 1.0);\n    float _4448 = 1.0;\n    float _4449 = 1.0;\n    float _2606 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2610 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2615 = (_2606 != 1.0) || (_2610 != 1.5);\n    bool _2625;\n    if (!_2615)\n    {\n        _2625 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2625 = _2615;\n    }\n    if (_2625)\n    {\n        float _2633 = (_2610 - 1.0) / (_2610 + 1.0);\n        f0 = mix(fast::min(float3(_2633 * _2633) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2606, s.albedo, float3(metallic));\n        _4430 = mix(_2606, 1.0, metallic);\n        _4429 = true;\n    }\n    float _2661 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2661 > 0.0)\n    {\n        float _2669 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4433 = _2661;\n        _4434 = _2669;\n        float _2676 = _2669 * _2669;\n        _4435 = _2676;\n        _4436 = _2676 * _2676;\n        float _2688 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4438 = _2688;\n        _4431 = 1.0 - (_2661 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2688, 0.0, 1.0), 5.0))));\n        _4429 = true;\n    }\n    float3 _2708 = fast::max(s.sheen_color, float3(0.0));\n    float _2717 = fast::max(_2708.x, fast::max(_2708.y, _2708.z));\n    if (_2717 > 0.0)\n    {\n        float _2725 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4439 = true;\n        _4440 = _2708;\n        _4441 = _2725;\n        _4442 = _2725 * _2725;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2725;\n        float _2742 = fa_sheen_albedo(param, param_1);\n        _4444 = _2742;\n        _4443 = 1.0 - fast::min(_2717 * _2742, 1.0);\n        _4429 = true;\n    }\n    _4432 = _4431 * _4443;\n    float _2761 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2761 != 0.0)\n    {\n        float3 _2776 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2776;\n        if (dot(_2776, _2776) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2793 = t;\n        float3 _2794 = fast::normalize(_2793);\n        t = _2794;\n        float3 _2819 = fast::normalize((_2794 * cos(s.anisotropy_rotation)) + ((cross(n, _2794) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4446 = _2819;\n        _4447 = cross(n, _2819);\n        float _2829 = roughness * roughness;\n        float _2835 = mix(_2829, 1.0, _2761 * _2761);\n        bool _2837 = _2761 > 0.0;\n        _4448 = _2837 ? _2835 : _2829;\n        _4449 = _2837 ? _2829 : _2835;\n        _4445 = _2761;\n        _4429 = true;\n    }\n    return FaLayers{ short(_4429), _4430, _4431, _4432, _4433, _4434, _4435, _4436, i.world_normal, _4438, short(_4439), _4440, _4441, _4442, _4443, _4444, _4445, _4446, _4447, _4448, _4449 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _2385 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2388 = _2385.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_2388 * _2388, exp2((-9.27999973297119140625) * ndv)) * _2388) + _2385.y)) + _2385.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _500, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_500.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _500.fa_env_horizon.w)).xyz;\n    }\n    float _2309 = rough * rough;\n    float _2339 = 0.60000002384185791015625 * _2309;\n    return mix(mix(_500.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_500.fa_env_horizon.xyz, _500.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _2309)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _2339, 0.0500000007450580596923828125 + _2339, d.y))), ((_500.fa_env_sky.xyz + _500.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_2309 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _500, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2870;\n        if (L.aniso >= 0.0)\n        {\n            _2870 = L.b;\n        }\n        else\n        {\n            _2870 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2870, v), _2870), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2903 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _500, fa_env_smp, fa_env_tex) * ((f0 * _2903.x) + (float3(L.f90) * _2903.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _500, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2958 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _500, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _2958.x) + _2958.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _500, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2427 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _500, fa_env_smp, fa_env_tex) * ((f0 * _2427.x) + float3(_2427.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _500, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float _2997 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _3001 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _3008 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_2997));\n    float3 f0 = _3008;\n    float3 _3012 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3012;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2997;\n    float param_5 = _3001;\n    float3 param_6 = _3008;\n    FaLayers _3029 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3029.on)\n    {\n        FaLayers param_7 = _3029;\n        float3 param_8 = _3012;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3001;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _500, fa_env_smp, fa_env_tex) * s.occlusion;\n    }\n    float3 param_12 = _3012;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3001;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _500, fa_env_smp, fa_env_tex) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lighting(thread const SurfaceInput& i, thread const Surface& s, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, sampler fa_env_smp, thread float4& gl_FragCoord, constant fa_shadows& _1240, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texturecube<float> fa_env_tex, texture2d<float> fa_screen_tex, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, thread float3& fa_lm, constant fa_material& _3616)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(fa_cl_ndir, fa_cl_local); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _3573 = dot(fa_light_unshadowed(param, param_1, fa_light_tex, fa_shadow_smp, _500, fa_cl_ndir, fa_cl_slot, fa_cl_local, fa_lm).color, float3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_3573 > bestPower)\n        {\n            bestPower = _3573;\n            best = n;\n        }\n    }\n    float3 lit = (_500.fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _3602 = fa_light(param_2, param_3, fa_light_tex, fa_shadow_smp, _500, gl_FragCoord, _1240, fa_shadow_tex, fa_world_pos, fa_screen_tex, fa_cl_ndir, fa_cl_slot, fa_cl_local, fa_lm);\n        float _3610;\n        if (dot(s.normal, _3602.direction) > 0.5)\n        {\n            _3610 = 1.0;\n        }\n        else\n        {\n            _3610 = _3616.dark;\n        }\n        lit += ((s.albedo * _3602.color) * _3610);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5, _500, fa_env_smp, fa_env_tex) * _3616.skyAmount);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1240)\n{\n    if (_1240.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2197 = int(_1240.fa_shadow_cfg.x + 0.5);\n    float _2207 = dot(world - _1240.fa_shadow_eye.xyz, _1240.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2212 = _2197 > 0;\n    bool _2221;\n    if (_2212)\n    {\n        int param = _2197 - 1;\n        _2221 = _2207 <= fa_shadow_split_at(param, _1240);\n    }\n    else\n    {\n        _2221 = _2212;\n    }\n    if (_2221)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2228 = _2197 > 1;\n        bool _2235;\n        if (_2228)\n        {\n            _2235 = _2207 > _1240.fa_shadow_split.x;\n        }\n        else\n        {\n            _2235 = _2228;\n        }\n        if (_2235)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2241 = _2197 > 2;\n        bool _2248;\n        if (_2241)\n        {\n            _2248 = _2207 > _1240.fa_shadow_split.y;\n        }\n        else\n        {\n            _2248 = _2241;\n        }\n        if (_2248)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2254 = _2197 > 3;\n        bool _2261;\n        if (_2254)\n        {\n            _2261 = _2207 > _1240.fa_shadow_split.z;\n        }\n        else\n        {\n            _2261 = _2254;\n        }\n        if (_2261)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _500 [[buffer(1)]], constant fa_material& _3616 [[buffer(5)]], constant fa_shadows& _1240 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_decal_tex [[texture(8)]], texture2d<float> fa_screen_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4303 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4303 = -_4303;\n    }\n    float3 _3990 = fast::normalize(_500.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _500, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4303, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3990, short(gl_FrontFacing) };\n    Surface _3998 = fa_standard_surface(param_1, _500, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4334 = _3998.albedo;\n    float _4335 = _3998.alpha;\n    float3 _4336 = _3998.normal;\n    float _4337 = _3998.metallic;\n    float _4338 = _3998.roughness;\n    float _4339 = _3998.occlusion;\n    float3 _4340 = _3998.emission;\n    float _4341 = _3998.clearcoat;\n    float _4342 = _3998.clearcoat_roughness;\n    float3 _4343 = _3998.sheen_color;\n    float _4344 = _3998.sheen_roughness;\n    float _4345 = _3998.anisotropy;\n    float _4346 = _3998.anisotropy_rotation;\n    float _4347 = _3998.specular;\n    float _4348 = _3998.ior;\n    float3 _4349 = _3998.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4303, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3990, short(gl_FrontFacing) };\n    Surface param_3 = _3998;\n    surface(param_2, param_3);\n    _4334 = param_3.albedo;\n    _4335 = param_3.alpha;\n    _4336 = param_3.normal;\n    _4337 = param_3.metallic;\n    _4338 = param_3.roughness;\n    _4339 = param_3.occlusion;\n    _4340 = param_3.emission;\n    _4341 = param_3.clearcoat;\n    _4342 = param_3.clearcoat_roughness;\n    _4343 = param_3.sheen_color;\n    _4344 = param_3.sheen_roughness;\n    _4345 = param_3.anisotropy;\n    _4346 = param_3.anisotropy_rotation;\n    _4347 = param_3.specular;\n    _4348 = param_3.ior;\n    _4349 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4303;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _500, fa_decal_tex, fa_env_smp);\n    _4334 = param_6;\n    _4336 = param_7;\n    float3 result;\n    if (_500.fa_emissive.w > 0.5)\n    {\n        result = _4334;\n    }\n    else\n    {\n        float3 _4036 = _4336;\n        float3 _4037 = fast::normalize(_4036);\n        _4336 = _4037;\n        SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _4303, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3990, short(gl_FrontFacing) };\n        Surface param_9 = Surface{ _4334, _4335, _4037, _4337, _4338, _4339, _4340, _4341, _4342, _4343, _4344, _4345, _4346, _4347, _4348, _4349 };\n        result = lighting(param_8, param_9, fa_light_tex, fa_shadow_smp, _500, fa_env_smp, gl_FragCoord, _1240, fa_shadow_tex, in.fa_world_pos, fa_env_tex, fa_screen_tex, fa_cl_ndir, fa_cl_slot, fa_cl_local, in.fa_lm, _3616);\n    }\n    float3 _4052 = result;\n    float3 _4053 = _4052 + _4340;\n    result = _4053;\n    float3 param_10 = _4053;\n    float3 param_11 = in.fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11, _1240);\n    bool _4062 = _500.fa_fog.w > 0.0;\n    bool _4069;\n    if (!_4062)\n    {\n        _4069 = _500.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4069 = _4062;\n    }\n    if (_4069)\n    {\n        float3 _4078 = in.fa_world_pos - _500.fa_camera_pos.xyz;\n        float _4084 = dot(_4078, _500.fa_fog_c.xyz);\n        bool _4088 = _500.fa_fog_c.w > 0.5;\n        float _4089;\n        if (_4088)\n        {\n            _4089 = _4084;\n        }\n        else\n        {\n            _4089 = length(_4078);\n        }\n        float _4101 = _4089 - _500.fa_fog_b.x;\n        if (_4101 > 0.0)\n        {\n            float _4110 = _500.fa_fog.w * _4101;\n            float tau = _4110 * _4110;\n            if (_500.fa_fog_b.y > 0.0)\n            {\n                float _4126;\n                if (_4088)\n                {\n                    _4126 = in.fa_world_pos.y - (_500.fa_fog_c.y * _4084);\n                }\n                else\n                {\n                    _4126 = _500.fa_camera_pos.y;\n                }\n                float _4147 = mix(_4126, in.fa_world_pos.y, fast::clamp(_500.fa_fog_b.x / _4089, 0.0, 1.0));\n                float _4151 = in.fa_world_pos.y - _4147;\n                float _4156 = _4147 - _500.fa_fog_b.z;\n                float _4161 = in.fa_world_pos.y - _500.fa_fog_b.z;\n                bool _4164 = _4156 <= 0.0;\n                bool _4165 = !_4164;\n                bool _4171;\n                if (_4165)\n                {\n                    _4171 = _500.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4171 = _4164;\n                }\n                float _4172;\n                if (_4171)\n                {\n                    _4172 = _500.fa_fog_b.y;\n                }\n                else\n                {\n                    _4172 = _500.fa_fog_b.y * exp(-fast::min(_500.fa_fog_b.w * _4156, 80.0));\n                }\n                bool _4199;\n                if (_4165)\n                {\n                    _4199 = _500.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4199 = _4164;\n                }\n                float _4200;\n                if (_4199)\n                {\n                    _4200 = _500.fa_fog_b.y * _4156;\n                }\n                else\n                {\n                    _4200 = (_500.fa_fog_b.y * (1.0 - exp(-fast::min(_500.fa_fog_b.w * _4156, 80.0)))) / _500.fa_fog_b.w;\n                }\n                bool _4225 = _4161 <= 0.0;\n                bool _4232;\n                if (!_4225)\n                {\n                    _4232 = _500.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4232 = _4225;\n                }\n                float _4233;\n                if (_4232)\n                {\n                    _4233 = _500.fa_fog_b.y * _4161;\n                }\n                else\n                {\n                    _4233 = (_500.fa_fog_b.y * (1.0 - exp(-fast::min(_500.fa_fog_b.w * _4161, 80.0)))) / _500.fa_fog_b.w;\n                }\n                float _4260;\n                if (abs(_4151) < 0.001000000047497451305389404296875)\n                {\n                    _4260 = _4172;\n                }\n                else\n                {\n                    _4260 = (_4233 - _4200) / _4151;\n                }\n                tau += (_4101 * fast::max(_4260, 0.0));\n            }\n            result = mix(result, _500.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4335);\n    return out;\n}\n\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_500",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1240",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_3616",
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
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_391, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float skyAmount;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nconstant spvUnsafeArray<float, 63> _2528 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500)\n{\n    bool _505 = _500.fa_cl_info.x < 0.0;\n    bool _512;\n    if (!_505)\n    {\n        _512 = _500.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _512 = _505;\n    }\n    bool _520;\n    if (!_512)\n    {\n        _520 = _500.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _520 = _512;\n    }\n    bool _527;\n    if (!_520)\n    {\n        _527 = _500.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _527 = _520;\n    }\n    bool _534;\n    if (!_527)\n    {\n        _534 = _500.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _534 = _527;\n    }\n    if (_534)\n    {\n        return float4(0.0);\n    }\n    float4 _544 = float4(world_pos, 1.0);\n    float _551 = dot(_500.fa_cl_vpw, _544);\n    if (!(_551 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _573 = float2(dot(_500.fa_cl_vpx, _544), dot(_500.fa_cl_vpy, _544)) / float2(_551);\n    int _577 = int(_500.fa_cl_grid.x);\n    int _581 = int(_500.fa_cl_grid.y);\n    int param = (int(_500.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_500.fa_cl_fwd.xyz, world_pos) + _500.fa_cl_fwd.w, _500.fa_cl_grid.w) / _500.fa_cl_grid.w) * _500.fa_cl_grid.z)), 0, int(_500.fa_cl_info.y) - 1) * _581) + clamp(int(floor(((_573.y * 0.5) + 0.5) * _500.fa_cl_grid.y)), 0, _581 - 1)) * _577)) + clamp(int(floor(((_573.x * 0.5) + 0.5) * _500.fa_cl_grid.x)), 0, _577 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500)\n{\n    float3 param = world_pos;\n    float4 _657 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _500);\n    return int2(int(_657.x), int(_657.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_500.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3326 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _500);\n    fa_cl_slot = _3326.x;\n    fa_cl_local = _3326.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3677 = fa_linear_to_srgb(param);\n        c = _3677;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3685 = fa_srgb_to_linear(param_1);\n            c = _3685;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _263;\n    if (bool(i.front_facing))\n    {\n        _263 = i.world_normal;\n    }\n    else\n    {\n        _263 = -i.world_normal;\n    }\n    float3 _287 = fast::normalize(i.world_tangent.xyz - (_263 * dot(_263, i.world_tangent.xyz)));\n    float3 _315 = fast::normalize(((_287 * m.x) + ((cross(_263, _287) * i.world_tangent.w) * m.y)) + (_263 * m.z));\n    float3 _318;\n    if (bool(i.front_facing))\n    {\n        _318 = _315;\n    }\n    else\n    {\n        _318 = -_315;\n    }\n    return _318;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _500, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _500.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3716 = fa_tex_fix(param_2, param_3);\n    float4 _4738 = base_t;\n    _4738.x = _3716.x;\n    _4738.y = _3716.y;\n    _4738.z = _3716.z;\n    base_t = _4738;\n    float4 _3730 = (_4738 * _500.fa_base_color) * i.vertex_color;\n    float3 _4592 = i.world_normal;\n    if (_500.fa_maps.z > 0.5)\n    {\n        float param_4 = _500.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3762 = fa_tex_fix(param_6, param_7);\n        float3 _3765 = (_3762 * 2.0) - float3(1.0);\n        float2 _3770 = _3765.xy * _500.fa_maps.x;\n        float3 _4746 = _3765;\n        _4746.x = _3770.x;\n        _4746.y = _3770.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4746;\n        _4592 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _500.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3799 = fa_tex_fix(param_12, param_13);\n    float4 _4749 = mrt;\n    _4749.x = _3799.x;\n    _4749.y = _3799.y;\n    _4749.z = _3799.z;\n    mrt = _4749;\n    float4 _3827 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _500.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3827.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3839 = fa_tex_fix(param_16, param_17);\n    float param_18 = _500.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3869 = fa_tex_fix(param_20, param_21);\n    float _4597 = _500.fa_layers_a.x;\n    float _4598 = _500.fa_layers_a.y;\n    float _4601 = _500.fa_layers_a.z;\n    float _4600 = _500.fa_layers_b.w;\n    float _4603 = _500.fa_layers_c.x;\n    if (_500.fa_layers_c.z > 0.5)\n    {\n        if (mod(_500.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4597 *= _3839.y;\n            _4598 *= _3839.z;\n            _4600 *= _3827.w;\n        }\n        if (_500.fa_layers_c.z > 1.5)\n        {\n            _4601 *= mrt.x;\n            _4603 *= mrt.w;\n        }\n    }\n    return Surface{ _3730.xyz, _3730.w, _4592, fast::clamp(_500.fa_pbr.x * _3799.z, 0.0, 1.0), fast::clamp(_500.fa_pbr.y * _3799.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_500.fa_maps.y * (_3839.x - 1.0)), _500.fa_emissive.xyz + (_500.fa_model_emissive.xyz * _3869), _4597, _4598, _500.fa_layers_b.xyz, _4600, _4601, _500.fa_layers_a.w, _4603, _500.fa_layers_c.y, _500.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _738 = rect.zw - rect.xy;\n    float2 _742 = _738 * atlas;\n    float2 _746 = ddx * _742;\n    float2 _750 = ddy * _742;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _738)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_746, _746), dot(_750, _750)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _785 = _500.fa_counts.y < 0.5;\n    bool _792;\n    if (!_785)\n    {\n        _792 = _500.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _792 = _785;\n    }\n    if (_792)\n    {\n        return;\n    }\n    float3 _798 = dfdx(world_pos);\n    float3 _801 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _805 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _500);\n    int _809 = int(_805.w);\n    if (_809 < 1)\n    {\n        return;\n    }\n    int _819 = int(_500.fa_counts.y + 0.5);\n    int param_1 = _819;\n    float4 _823 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _826 = _823.yz;\n    int _830 = int(_823.w);\n    int param_2 = _819 + 1;\n    float4 _835 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _836 = _835.x;\n    int _842 = int(_500.fa_counts.w + 0.5) - 1;\n    int _846 = int(_805.z);\n    float3 _1112;\n    for (int k = 0; k < _809; k++)\n    {\n        int _859 = _846 + k;\n        int param_3 = _830 + (_859 >> 2);\n        int _877 = (_819 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_859 & 3]) * 7);\n        int param_4 = _877 + 6;\n        float4 _882 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_882.w + 0.5) >> _842) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _877;\n        float4 _897 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _877 + 1;\n        float4 _902 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _877 + 2;\n        float4 _907 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _910 = _897.xyz;\n        float _915 = dot(_910, world_pos) + _897.w;\n        float3 _917 = _902.xyz;\n        float _922 = dot(_917, world_pos) + _902.w;\n        float3 _924 = _907.xyz;\n        float _929 = dot(_924, world_pos) + _907.w;\n        bool _934 = abs(_915) > 0.5;\n        bool _942;\n        if (!_934)\n        {\n            _942 = abs(_922) > 0.5;\n        }\n        else\n        {\n            _942 = _934;\n        }\n        bool _950;\n        if (!_942)\n        {\n            _950 = abs(_929) > 0.5;\n        }\n        else\n        {\n            _950 = _942;\n        }\n        if (_950)\n        {\n            continue;\n        }\n        float _965 = fast::clamp(dot(geo_normal, fast::normalize(_924)) * _882.z, 0.0, 1.0);\n        if (_965 <= 0.0)\n        {\n            continue;\n        }\n        float _985 = (fast::clamp((0.5 - abs(_929)) * 10.0, 0.0, 1.0) * _965) * _882.x;\n        float2 _993 = float2(_915 + 0.5, 0.5 - _922);\n        float2 _1003 = float2(dot(_910, _798), dot(_917, _798));\n        float2 _1013 = float2(dot(_910, _801), dot(_917, _801));\n        int param_8 = _877 + 5;\n        float4 _1018 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _877 + 3;\n        float4 _1023 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _877 + 4;\n        float4 _1028 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1018.xyz;\n        bool _1038 = _1023.z > _1023.x;\n        if (_1038)\n        {\n            float4 param_11 = _1023;\n            float2 param_12 = _993;\n            float2 param_13 = _826;\n            float2 param_14 = _1003;\n            float2 param_15 = _1013;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_836 > 0.5) && (_836 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1064 = fa_dc_to_linear(param_16);\n                float4 _4648 = tx;\n                _4648.x = _1064.x;\n                _4648.y = _1064.y;\n                _4648.z = _1064.z;\n                tx = _4648;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_985 * tex_a) * _1018.w, 0.0, 1.0)));\n        if (_1028.z > _1028.x)\n        {\n            float4 param_17 = _1028;\n            float2 param_18 = _993;\n            float2 param_19 = _826;\n            float2 param_20 = _1003;\n            float2 param_21 = _1013;\n            float4 _1108 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_836 > 1.5)\n            {\n                float3 param_22 = _1108.xyz;\n                float3 _1118 = fa_dc_to_srgb(param_22);\n                _1112 = _1118;\n            }\n            else\n            {\n                _1112 = _1108.xyz;\n            }\n            float3 _1128 = (_1112 * 2.0) - float3(1.0);\n            float2 _1133 = _1128.xy * _882.y;\n            float3 _1155 = (fast::normalize(_910) * _1133.x) + (fast::normalize(_917) * _1133.y);\n            float3 _1158 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1158, fast::normalize((_1158 * fast::max(_1128.z, 0.0500000007450580596923828125)) + (_1155 - (_1158 * dot(_1158, _1155)))), float3(fast::clamp(_985 * (_1038 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(thread int& fa_cl_ndir, thread int& fa_cl_local)\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_no_light()\n{\n    return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, 0 };\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500)\n{\n    int param = (int(_500.fa_cl_info.x) + int(_500.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _500);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _374 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _380 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _383 = _380.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _389 = _383 < 0.5;\n    float3 l;\n    if (_389)\n    {\n        l = fast::normalize(_374.xyz);\n    }\n    else\n    {\n        float3 _401 = _374.xyz - world_pos;\n        float _403 = length(_401);\n        dist = _403;\n        l = _401 / float3(fast::max(_403, 9.9999997473787516355514526367188e-05));\n        float _418 = _403 / fast::max(_374.w, 0.001000000047497451305389404296875);\n        float _424 = fast::clamp(1.0 - (_418 * _418), 0.0, 1.0);\n        atten = _424 * _424;\n        if (_383 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _438 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _448 = _438.w;\n            int param_3 = (li * 4) + 3;\n            float4 _454 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _455 = _454.x;\n            float cos_inner = _455;\n            if (_455 > 1.5)\n            {\n                cos_inner = mix(_448, 1.0, 0.25);\n            }\n            atten *= smoothstep(_448, cos_inner, dot(-l, fast::normalize(_438.xyz)));\n        }\n    }\n    int _486;\n    if (_389)\n    {\n        _486 = 0;\n    }\n    else\n    {\n        _486 = (_383 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _380.xyz * atten, atten, 1.0, dist, _486 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_unshadowed(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, thread float3& fa_lm)\n{\n    bool _3511 = n < 0;\n    bool _3518;\n    if (!_3511)\n    {\n        _3518 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _3518 = _3511;\n    }\n    if (_3518)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _3526 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _500, fa_cl_ndir, fa_cl_slot);\n    bool _3529 = fa_lm.z > 0.5;\n    bool _3535;\n    if (_3529)\n    {\n        int param_1 = _3526;\n        _3535 = fa_light_baked(param_1, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3535 = _3529;\n    }\n    if (_3535)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _3526;\n    float3 param_3 = i.world_pos;\n    return fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1240)\n{\n    float _1230;\n    if (i == 0)\n    {\n        _1230 = _1240.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1246;\n        if (i == 1)\n        {\n            _1246 = _1240.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1254;\n            if (i == 2)\n            {\n                _1254 = _1240.fa_shadow_split.z;\n            }\n            else\n            {\n                _1254 = _1240.fa_shadow_split.w;\n            }\n            _1246 = _1254;\n        }\n        _1230 = _1246;\n    }\n    return _1230;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1287 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1291;\n    if (conv.x < 0.5)\n    {\n        _1291 = _1287;\n    }\n    else\n    {\n        _1291 = (conv.y * conv.z) / (conv.z - (_1287 * (conv.z - conv.y)));\n    }\n    return _1291;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1218 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1218), sin(_1218)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1240, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1337 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1351 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1337;\n            float2 _1370 = fa_shadow_vogel(param_3, param_4, param_5) * _1351;\n            float2 param_6 = uv + (_1370 * _1240.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1382 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1382 < (zr - (length(_1370) * plane)))\n            {\n                sum += _1382;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1426 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1426; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1426;\n        float param_11 = _1337;\n        float2 _1445 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1445 * _1240.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1445) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1426);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1240, texture2d<float> fa_shadow_tex)\n{\n    float _1487 = fast::max(_1240.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1492 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1498 = sqrt(1.0 - (_1492 * _1492));\n    float _1505 = fast::min(_1498 / fast::max(_1492, 0.20000000298023223876953125), 4.0);\n    float _1510;\n    if (_1240.fa_shadow_bias.y > 0.0)\n    {\n        _1510 = _1240.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1510 = 1.5 * _1240.fa_shadow_info[ci].x;\n    }\n    float4 _1535 = _1240.fa_shadow_mat[ci] * float4(world + (n * (_1510 * _1498)), 1.0);\n    float _1542 = _1535.x;\n    bool _1545 = _1542 < _1240.fa_shadow_rect[ci].x;\n    bool _1554;\n    if (!_1545)\n    {\n        _1554 = _1542 > _1240.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1554 = _1545;\n    }\n    bool _1563;\n    if (!_1554)\n    {\n        _1563 = _1535.y < _1240.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1563 = _1554;\n    }\n    bool _1572;\n    if (!_1563)\n    {\n        _1572 = _1535.y > _1240.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1572 = _1563;\n    }\n    bool _1579;\n    if (!_1572)\n    {\n        _1579 = _1535.z > 1.0;\n    }\n    else\n    {\n        _1579 = _1572;\n    }\n    if (_1579)\n    {\n        return -1.0;\n    }\n    float _1588;\n    if (_1240.fa_shadow_bias.x > 0.0)\n    {\n        _1588 = _1240.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1588 = 1.5 * _1240.fa_shadow_info[ci].x;\n    }\n    float2 param = _1535.xy;\n    float4 param_1 = _1240.fa_shadow_rect[ci];\n    float param_2 = _1535.z - ((_1588 * (1.0 + (0.5 * _1505))) / _1487);\n    float param_3 = _1240.fa_shadow_info[ci].x;\n    float param_4 = _1487;\n    float param_5 = _1487 * 0.25;\n    float param_6 = ((_1240.fa_shadow_info[ci].x * fast::min(_1505, 3.0)) * 0.5) / _1487;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1240.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1240.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1240, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, thread float4& gl_FragCoord, constant fa_shadows& _1240, texture2d<float> fa_shadow_tex)\n{\n    if (_500.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2015 = int(_1240.fa_shadow_cfg.x + 0.5);\n    if (_2015 < 1)\n    {\n        return 1.0;\n    }\n    float _2030 = dot(world - _1240.fa_shadow_eye.xyz, _1240.fa_shadow_fwd.xyz);\n    int param = _2015 - 1;\n    if (_2030 > fa_shadow_split_at(param, _1240))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2042 = _2015 > 1;\n    bool _2049;\n    if (_2042)\n    {\n        _2049 = _2030 > _1240.fa_shadow_split.x;\n    }\n    else\n    {\n        _2049 = _2042;\n    }\n    if (_2049)\n    {\n        ci = 1;\n    }\n    bool _2053 = _2015 > 2;\n    bool _2060;\n    if (_2053)\n    {\n        _2060 = _2030 > _1240.fa_shadow_split.y;\n    }\n    else\n    {\n        _2060 = _2053;\n    }\n    if (_2060)\n    {\n        ci = 2;\n    }\n    bool _2064 = _2015 > 3;\n    bool _2071;\n    if (_2064)\n    {\n        _2071 = _2030 > _1240.fa_shadow_split.z;\n    }\n    else\n    {\n        _2071 = _2064;\n    }\n    if (_2071)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2015)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2097 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1240, fa_shadow_tex);\n        s = _2097;\n        if (_2097 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1240.fa_shadow_cfg.y > 0.0)\n    {\n        float _2122;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2122 = fa_shadow_split_at(param_5, _1240);\n        }\n        else\n        {\n            _2122 = _1240.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2141 = _1240.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1240) - _2122, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2152 = fast::clamp((_2030 - (fa_shadow_split_at(param_7, _1240) - _2141)) / _2141, 0.0, 1.0);\n        if (_2152 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2015)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2173 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1240, fa_shadow_tex);\n                s2 = _2173;\n                if (_2173 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2152);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, thread float4& gl_FragCoord, constant fa_shadows& _1240, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _500, gl_FragCoord, _1240, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, thread float4& gl_FragCoord, constant fa_shadows& _1240, texture2d<float> fa_shadow_tex)\n{\n    bool _1646 = _500.fa_pbr.z < 0.5;\n    bool _1654;\n    if (!_1646)\n    {\n        _1654 = _1240.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1654 = _1646;\n    }\n    if (_1654)\n    {\n        return 1.0;\n    }\n    int param = (int(_1240.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1667 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1668 = _1667.x;\n    if (_1668 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1677 = int(_1668 + 0.5);\n    int param_1 = _1677;\n    float4 _1681 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1677 + 1;\n    float4 _1686 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1689 = _1681.y;\n    if (_1689 > 0.0)\n    {\n        float _1706 = 1.0 - smoothstep(0.75 * _1689, _1689, length(world - _1240.fa_shadow_eye.xyz));\n        fade = _1706;\n        if (_1706 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1681.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1725 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1728 = abs(_1725);\n        float _1730 = _1728.x;\n        float _1732 = _1728.y;\n        bool _1733 = _1730 >= _1732;\n        bool _1741;\n        if (_1733)\n        {\n            _1741 = _1730 >= _1728.z;\n        }\n        else\n        {\n            _1741 = _1733;\n        }\n        int _1742;\n        if (_1741)\n        {\n            _1742 = (_1725.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1755;\n            if (_1732 >= _1728.z)\n            {\n                _1755 = (_1725.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1755 = (_1725.z > 0.0) ? 4 : 5;\n            }\n            _1742 = _1755;\n        }\n        face = _1742;\n    }\n    int _1774 = (_1677 + 2) + (face * 6);\n    int param_4 = _1774;\n    int param_5 = _1774 + 1;\n    int param_6 = _1774 + 3;\n    float4 _1788 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1774 + 4;\n    float4 _1793 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1774 + 5;\n    float4 _1798 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1810 = _1798.x * fast::max(dot(_1788, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1815 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1838 = fast::clamp(dot(n, _1788.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1861 = fast::min(sqrt(1.0 - (_1838 * _1838)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1788, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1864 = _1686.y;\n    float _1866;\n    if (_1864 > 0.0)\n    {\n        _1866 = _1864;\n    }\n    else\n    {\n        _1866 = 1.5 * _1810;\n    }\n    float4 _1886 = float4(world + (n * (_1866 * sqrt(1.0 - (_1815 * _1815)))), 1.0);\n    float _1890 = dot(_1788, _1886);\n    float _1893 = _1798.y;\n    if (_1890 < _1893)\n    {\n        return 1.0;\n    }\n    float2 _1908 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1886), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1886)) / float2(_1890);\n    float _1910 = _1908.x;\n    bool _1913 = _1910 < _1793.x;\n    bool _1922;\n    if (!_1913)\n    {\n        _1922 = _1910 > _1793.z;\n    }\n    else\n    {\n        _1922 = _1913;\n    }\n    bool _1931;\n    if (!_1922)\n    {\n        _1931 = _1908.y < _1793.y;\n    }\n    else\n    {\n        _1931 = _1922;\n    }\n    bool _1940;\n    if (!_1931)\n    {\n        _1940 = _1908.y > _1793.w;\n    }\n    else\n    {\n        _1940 = _1931;\n    }\n    if (_1940)\n    {\n        return 1.0;\n    }\n    float _1946 = _1686.x;\n    float _1948;\n    if (_1946 > 0.0)\n    {\n        _1948 = _1946;\n    }\n    else\n    {\n        _1948 = 1.5 * _1810;\n    }\n    float2 param_10 = _1908;\n    float4 param_11 = _1793;\n    float param_12 = _1890 - (_1948 * (1.0 + (0.5 * _1861)));\n    float param_13 = _1810;\n    float param_14 = 1.0;\n    float param_15 = _1798.z * 0.25;\n    float param_16 = (_1810 * fast::min(_1861, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1893, _1798.z);\n    int param_18 = int(_1681.z + 0.5);\n    float param_19 = _1681.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1240, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_contact_shadow(thread const int& li, thread const float3& world, thread const float3& gn, thread const float3& l, thread const float& dist, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, thread float4& gl_FragCoord, constant fa_shadows& _1240, texture2d<float> fa_screen_tex)\n{\n    bool _3068 = _500.fa_ct_a.x < 0.5;\n    bool _3075;\n    if (!_3068)\n    {\n        _3075 = _1240.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _3075 = _3068;\n    }\n    if (_3075)\n    {\n        return 1.0;\n    }\n    int param = (int(_1240.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _3088 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _3089 = _3088.y;\n    float len = _3089;\n    if (_3089 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3101 = length(world - _500.fa_camera_pos.xyz);\n    float _3111 = 1.0 - smoothstep(0.5 * _500.fa_ct_b.x, _500.fa_ct_b.x, _3101);\n    if (_3111 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3117 = len;\n    float _3120 = fast::min(_3117, 0.89999997615814208984375 * dist);\n    len = _3120;\n    float _3125 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3101);\n    float _3130 = _3125 + (0.5 * _3120);\n    float3 _3136 = world + (gn * _3125);\n    float _3138 = fa_shadow_noise(gl_FragCoord);\n    float occ = 0.0;\n    float _3202;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3153 = (float(k) + _3138) * 0.083333335816860198974609375;\n        float3 _3161 = _3136 + (l * (_3153 * len));\n        float4 _3167 = float4(_3161, 1.0);\n        float _3173 = dot(_500.fa_ct_vpw, _3167);\n        if (_3173 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        float2 _3193 = float2(dot(_500.fa_ct_vpx, _3167), dot(_500.fa_ct_vpy, _3167)) / float2(_3173);\n        float _3197 = _3193.x * 0.5;\n        float _3198 = _3197 + 0.5;\n        if (_500.fa_ct_a.y > 0.5)\n        {\n            _3202 = (_3193.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3202 = 0.5 - (_3193.y * 0.5);\n        }\n        bool _3218 = _3198 < 0.0;\n        bool _3225;\n        if (!_3218)\n        {\n            _3225 = _3198 >= 1.0;\n        }\n        else\n        {\n            _3225 = _3218;\n        }\n        bool _3232;\n        if (!_3225)\n        {\n            _3232 = _3202 < 0.0;\n        }\n        else\n        {\n            _3232 = _3225;\n        }\n        bool _3239;\n        if (!_3232)\n        {\n            _3239 = _3202 >= 1.0;\n        }\n        else\n        {\n            _3239 = _3232;\n        }\n        if (_3239)\n        {\n            break;\n        }\n        float4 _3258 = fa_screen_tex.read(uint2(int2(float2(_3198, _3202) * _500.fa_ct_a.zw)), 0);\n        if (_3258.w < 0.5)\n        {\n            continue;\n        }\n        float _3277 = (dot(_500.fa_ct_fwd.xyz, _3161) + _500.fa_ct_fwd.w) - _3258.x;\n        if ((_3277 > _3125) && (_3277 < _3130))\n        {\n            occ = fast::max(occ, (1.0 - (_3153 * _3153)) * smoothstep(0.0, 0.0500000007450580596923828125, fast::min(fast::min(_3198, 0.5 - _3197), fast::min(_3202, 1.0 - _3202))));\n        }\n    }\n    return 1.0 - (occ * _3111);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, thread float4& gl_FragCoord, constant fa_shadows& _1240, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread float3& fa_lm)\n{\n    bool _3353 = fa_lm.z > 0.5;\n    bool _3359;\n    if (_3353)\n    {\n        int param = li;\n        _3359 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3359 = _3353;\n    }\n    if (_3359)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3381 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _4568 = _3381.direction;\n    float3 _4563 = _3381.color;\n    float _4570 = _3381.attenuation;\n    float _4565 = _3381.shadow;\n    float _4572 = _3381._distance;\n    int _4573 = _3381.type;\n    bool _3384 = _4573 == 0;\n    if (_3384 && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4568;\n        float _3395 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _500, gl_FragCoord, _1240, fa_shadow_tex, fa_world_pos);\n        _4565 = _3395;\n        _4563 *= _3395;\n    }\n    else\n    {\n        bool _3406 = _4573 != 0;\n        bool _3412;\n        if (_3406)\n        {\n            _3412 = _4570 > 0.0;\n        }\n        else\n        {\n            _3412 = _3406;\n        }\n        if (_3412)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4568;\n            float _3424 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _500, gl_FragCoord, _1240, fa_shadow_tex);\n            _4565 = _3424;\n            _4563 *= _3424;\n        }\n    }\n    bool _3434 = _500.fa_ct_a.x > 0.5;\n    bool _3440;\n    if (_3434)\n    {\n        _3440 = _4570 > 0.0;\n    }\n    else\n    {\n        _3440 = _3434;\n    }\n    if (_3440)\n    {\n        float _3447;\n        if (_3384)\n        {\n            _3447 = 1000000000.0;\n        }\n        else\n        {\n            _3447 = _4572;\n        }\n        int param_10 = li;\n        float3 param_11 = world_pos;\n        float3 param_12 = gn;\n        float3 param_13 = _4568;\n        float param_14 = _3447;\n        float _3465 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14, fa_light_tex, fa_shadow_smp, _500, gl_FragCoord, _1240, fa_screen_tex);\n        _4565 *= _3465;\n        _4563 *= _3465;\n    }\n    return LightSample{ _4568, _4563, _4570, _4565, _4572, _4573 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& n, thread const SurfaceInput& i, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, thread float4& gl_FragCoord, constant fa_shadows& _1240, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, thread float3& fa_lm)\n{\n    bool _3485 = n < 0;\n    bool _3492;\n    if (!_3485)\n    {\n        _3492 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _3492 = _3485;\n    }\n    if (_3492)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, fa_light_tex, fa_shadow_smp, _500, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3, fa_light_tex, fa_shadow_smp, _500, gl_FragCoord, _1240, fa_shadow_tex, fa_world_pos, fa_screen_tex, fa_lm);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _2453 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2461 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2464 = int(_2453);\n    int _2467 = int(_2461);\n    float _2477 = _2461 - float(_2467);\n    int _2533 = (_2464 * 9) + _2467;\n    int _2553 = ((_2464 + 1) * 9) + _2467;\n    return mix(mix(_2528[_2533], _2528[_2533 + 1], _2477), mix(_2528[_2553], _2528[_2553 + 1], _2477), _2453 - float(_2464));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4429 = false;\n    float _4430 = 1.0;\n    float _4431 = 1.0;\n    float _4432 = 1.0;\n    float _4433 = 0.0;\n    float _4434 = 0.0;\n    float _4435 = 0.0;\n    float _4436 = 0.0;\n    float _4438 = 1.0;\n    bool _4439 = false;\n    float3 _4440 = float3(0.0);\n    float _4441 = 1.0;\n    float _4442 = 1.0;\n    float _4443 = 1.0;\n    float _4444 = 0.0;\n    float _4445 = 0.0;\n    float3 _4446 = float3(1.0, 0.0, 0.0);\n    float3 _4447 = float3(0.0, 0.0, 1.0);\n    float _4448 = 1.0;\n    float _4449 = 1.0;\n    float _2606 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2610 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2615 = (_2606 != 1.0) || (_2610 != 1.5);\n    bool _2625;\n    if (!_2615)\n    {\n        _2625 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2625 = _2615;\n    }\n    if (_2625)\n    {\n        float _2633 = (_2610 - 1.0) / (_2610 + 1.0);\n        f0 = mix(fast::min(float3(_2633 * _2633) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2606, s.albedo, float3(metallic));\n        _4430 = mix(_2606, 1.0, metallic);\n        _4429 = true;\n    }\n    float _2661 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2661 > 0.0)\n    {\n        float _2669 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4433 = _2661;\n        _4434 = _2669;\n        float _2676 = _2669 * _2669;\n        _4435 = _2676;\n        _4436 = _2676 * _2676;\n        float _2688 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4438 = _2688;\n        _4431 = 1.0 - (_2661 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2688, 0.0, 1.0), 5.0))));\n        _4429 = true;\n    }\n    float3 _2708 = fast::max(s.sheen_color, float3(0.0));\n    float _2717 = fast::max(_2708.x, fast::max(_2708.y, _2708.z));\n    if (_2717 > 0.0)\n    {\n        float _2725 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4439 = true;\n        _4440 = _2708;\n        _4441 = _2725;\n        _4442 = _2725 * _2725;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2725;\n        float _2742 = fa_sheen_albedo(param, param_1);\n        _4444 = _2742;\n        _4443 = 1.0 - fast::min(_2717 * _2742, 1.0);\n        _4429 = true;\n    }\n    _4432 = _4431 * _4443;\n    float _2761 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2761 != 0.0)\n    {\n        float3 _2776 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2776;\n        if (dot(_2776, _2776) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2793 = t;\n        float3 _2794 = fast::normalize(_2793);\n        t = _2794;\n        float3 _2819 = fast::normalize((_2794 * cos(s.anisotropy_rotation)) + ((cross(n, _2794) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4446 = _2819;\n        _4447 = cross(n, _2819);\n        float _2829 = roughness * roughness;\n        float _2835 = mix(_2829, 1.0, _2761 * _2761);\n        bool _2837 = _2761 > 0.0;\n        _4448 = _2837 ? _2835 : _2829;\n        _4449 = _2837 ? _2829 : _2835;\n        _4445 = _2761;\n        _4429 = true;\n    }\n    return FaLayers{ short(_4429), _4430, _4431, _4432, _4433, _4434, _4435, _4436, i.world_normal, _4438, short(_4439), _4440, _4441, _4442, _4443, _4444, _4445, _4446, _4447, _4448, _4449 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _2385 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2388 = _2385.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_2388 * _2388, exp2((-9.27999973297119140625) * ndv)) * _2388) + _2385.y)) + _2385.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _500, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_500.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _500.fa_env_horizon.w)).xyz;\n    }\n    float _2309 = rough * rough;\n    float _2339 = 0.60000002384185791015625 * _2309;\n    return mix(mix(_500.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_500.fa_env_horizon.xyz, _500.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _2309)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _2339, 0.0500000007450580596923828125 + _2339, d.y))), ((_500.fa_env_sky.xyz + _500.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_2309 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _500, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2870;\n        if (L.aniso >= 0.0)\n        {\n            _2870 = L.b;\n        }\n        else\n        {\n            _2870 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2870, v), _2870), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2903 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _500, fa_env_smp, fa_env_tex) * ((f0 * _2903.x) + (float3(L.f90) * _2903.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _500, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2958 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _500, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _2958.x) + _2958.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _500, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2427 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _500, fa_env_smp, fa_env_tex) * ((f0 * _2427.x) + float3(_2427.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _500, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float _2997 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _3001 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _3008 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_2997));\n    float3 f0 = _3008;\n    float3 _3012 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3012;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2997;\n    float param_5 = _3001;\n    float3 param_6 = _3008;\n    FaLayers _3029 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3029.on)\n    {\n        FaLayers param_7 = _3029;\n        float3 param_8 = _3012;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3001;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _500, fa_env_smp, fa_env_tex) * s.occlusion;\n    }\n    float3 param_12 = _3012;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3001;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _500, fa_env_smp, fa_env_tex) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lighting(thread const SurfaceInput& i, thread const Surface& s, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _500, sampler fa_env_smp, thread float4& gl_FragCoord, constant fa_shadows& _1240, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texturecube<float> fa_env_tex, texture2d<float> fa_screen_tex, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, thread float3& fa_lm, constant fa_material& _3616)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(fa_cl_ndir, fa_cl_local); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _3573 = dot(fa_light_unshadowed(param, param_1, fa_light_tex, fa_shadow_smp, _500, fa_cl_ndir, fa_cl_slot, fa_cl_local, fa_lm).color, float3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_3573 > bestPower)\n        {\n            bestPower = _3573;\n            best = n;\n        }\n    }\n    float3 lit = (_500.fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _3602 = fa_light(param_2, param_3, fa_light_tex, fa_shadow_smp, _500, gl_FragCoord, _1240, fa_shadow_tex, fa_world_pos, fa_screen_tex, fa_cl_ndir, fa_cl_slot, fa_cl_local, fa_lm);\n        float _3610;\n        if (dot(s.normal, _3602.direction) > 0.5)\n        {\n            _3610 = 1.0;\n        }\n        else\n        {\n            _3610 = _3616.dark;\n        }\n        lit += ((s.albedo * _3602.color) * _3610);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5, _500, fa_env_smp, fa_env_tex) * _3616.skyAmount);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1240)\n{\n    if (_1240.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2197 = int(_1240.fa_shadow_cfg.x + 0.5);\n    float _2207 = dot(world - _1240.fa_shadow_eye.xyz, _1240.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2212 = _2197 > 0;\n    bool _2221;\n    if (_2212)\n    {\n        int param = _2197 - 1;\n        _2221 = _2207 <= fa_shadow_split_at(param, _1240);\n    }\n    else\n    {\n        _2221 = _2212;\n    }\n    if (_2221)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2228 = _2197 > 1;\n        bool _2235;\n        if (_2228)\n        {\n            _2235 = _2207 > _1240.fa_shadow_split.x;\n        }\n        else\n        {\n            _2235 = _2228;\n        }\n        if (_2235)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2241 = _2197 > 2;\n        bool _2248;\n        if (_2241)\n        {\n            _2248 = _2207 > _1240.fa_shadow_split.y;\n        }\n        else\n        {\n            _2248 = _2241;\n        }\n        if (_2248)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2254 = _2197 > 3;\n        bool _2261;\n        if (_2254)\n        {\n            _2261 = _2207 > _1240.fa_shadow_split.z;\n        }\n        else\n        {\n            _2261 = _2254;\n        }\n        if (_2261)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _500 [[buffer(1)]], constant fa_material& _3616 [[buffer(5)]], constant fa_shadows& _1240 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_decal_tex [[texture(8)]], texture2d<float> fa_screen_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4303 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4303 = -_4303;\n    }\n    float3 _3990 = fast::normalize(_500.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _500, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4303, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3990, short(gl_FrontFacing) };\n    Surface _3998 = fa_standard_surface(param_1, _500, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4334 = _3998.albedo;\n    float _4335 = _3998.alpha;\n    float3 _4336 = _3998.normal;\n    float _4337 = _3998.metallic;\n    float _4338 = _3998.roughness;\n    float _4339 = _3998.occlusion;\n    float3 _4340 = _3998.emission;\n    float _4341 = _3998.clearcoat;\n    float _4342 = _3998.clearcoat_roughness;\n    float3 _4343 = _3998.sheen_color;\n    float _4344 = _3998.sheen_roughness;\n    float _4345 = _3998.anisotropy;\n    float _4346 = _3998.anisotropy_rotation;\n    float _4347 = _3998.specular;\n    float _4348 = _3998.ior;\n    float3 _4349 = _3998.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4303, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3990, short(gl_FrontFacing) };\n    Surface param_3 = _3998;\n    surface(param_2, param_3);\n    _4334 = param_3.albedo;\n    _4335 = param_3.alpha;\n    _4336 = param_3.normal;\n    _4337 = param_3.metallic;\n    _4338 = param_3.roughness;\n    _4339 = param_3.occlusion;\n    _4340 = param_3.emission;\n    _4341 = param_3.clearcoat;\n    _4342 = param_3.clearcoat_roughness;\n    _4343 = param_3.sheen_color;\n    _4344 = param_3.sheen_roughness;\n    _4345 = param_3.anisotropy;\n    _4346 = param_3.anisotropy_rotation;\n    _4347 = param_3.specular;\n    _4348 = param_3.ior;\n    _4349 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4303;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _500, fa_decal_tex, fa_env_smp);\n    _4334 = param_6;\n    _4336 = param_7;\n    float3 result;\n    if (_500.fa_emissive.w > 0.5)\n    {\n        result = _4334;\n    }\n    else\n    {\n        float3 _4036 = _4336;\n        float3 _4037 = fast::normalize(_4036);\n        _4336 = _4037;\n        SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _4303, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3990, short(gl_FrontFacing) };\n        Surface param_9 = Surface{ _4334, _4335, _4037, _4337, _4338, _4339, _4340, _4341, _4342, _4343, _4344, _4345, _4346, _4347, _4348, _4349 };\n        result = lighting(param_8, param_9, fa_light_tex, fa_shadow_smp, _500, fa_env_smp, gl_FragCoord, _1240, fa_shadow_tex, in.fa_world_pos, fa_env_tex, fa_screen_tex, fa_cl_ndir, fa_cl_slot, fa_cl_local, in.fa_lm, _3616);\n    }\n    float3 _4052 = result;\n    float3 _4053 = _4052 + _4340;\n    result = _4053;\n    float3 param_10 = _4053;\n    float3 param_11 = in.fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11, _1240);\n    bool _4062 = _500.fa_fog.w > 0.0;\n    bool _4069;\n    if (!_4062)\n    {\n        _4069 = _500.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4069 = _4062;\n    }\n    if (_4069)\n    {\n        float3 _4078 = in.fa_world_pos - _500.fa_camera_pos.xyz;\n        float _4084 = dot(_4078, _500.fa_fog_c.xyz);\n        bool _4088 = _500.fa_fog_c.w > 0.5;\n        float _4089;\n        if (_4088)\n        {\n            _4089 = _4084;\n        }\n        else\n        {\n            _4089 = length(_4078);\n        }\n        float _4101 = _4089 - _500.fa_fog_b.x;\n        if (_4101 > 0.0)\n        {\n            float _4110 = _500.fa_fog.w * _4101;\n            float tau = _4110 * _4110;\n            if (_500.fa_fog_b.y > 0.0)\n            {\n                float _4126;\n                if (_4088)\n                {\n                    _4126 = in.fa_world_pos.y - (_500.fa_fog_c.y * _4084);\n                }\n                else\n                {\n                    _4126 = _500.fa_camera_pos.y;\n                }\n                float _4147 = mix(_4126, in.fa_world_pos.y, fast::clamp(_500.fa_fog_b.x / _4089, 0.0, 1.0));\n                float _4151 = in.fa_world_pos.y - _4147;\n                float _4156 = _4147 - _500.fa_fog_b.z;\n                float _4161 = in.fa_world_pos.y - _500.fa_fog_b.z;\n                bool _4164 = _4156 <= 0.0;\n                bool _4165 = !_4164;\n                bool _4171;\n                if (_4165)\n                {\n                    _4171 = _500.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4171 = _4164;\n                }\n                float _4172;\n                if (_4171)\n                {\n                    _4172 = _500.fa_fog_b.y;\n                }\n                else\n                {\n                    _4172 = _500.fa_fog_b.y * exp(-fast::min(_500.fa_fog_b.w * _4156, 80.0));\n                }\n                bool _4199;\n                if (_4165)\n                {\n                    _4199 = _500.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4199 = _4164;\n                }\n                float _4200;\n                if (_4199)\n                {\n                    _4200 = _500.fa_fog_b.y * _4156;\n                }\n                else\n                {\n                    _4200 = (_500.fa_fog_b.y * (1.0 - exp(-fast::min(_500.fa_fog_b.w * _4156, 80.0)))) / _500.fa_fog_b.w;\n                }\n                bool _4225 = _4161 <= 0.0;\n                bool _4232;\n                if (!_4225)\n                {\n                    _4232 = _500.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4232 = _4225;\n                }\n                float _4233;\n                if (_4232)\n                {\n                    _4233 = _500.fa_fog_b.y * _4161;\n                }\n                else\n                {\n                    _4233 = (_500.fa_fog_b.y * (1.0 - exp(-fast::min(_500.fa_fog_b.w * _4161, 80.0)))) / _500.fa_fog_b.w;\n                }\n                float _4260;\n                if (abs(_4151) < 0.001000000047497451305389404296875)\n                {\n                    _4260 = _4172;\n                }\n                else\n                {\n                    _4260 = (_4233 - _4200) / _4151;\n                }\n                tau += (_4101 * fast::max(_4260, 0.0));\n            }\n            result = mix(result, _500.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4335);\n    return out;\n}\n\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_500",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1240",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_3616",
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
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _787 = base_t;\n    _787.x = _225.x;\n    _787.y = _225.y;\n    _787.z = _225.z;\n    base_t = _787;\n    float4 _241 = (_787 * _213.fa_base_color) * i.vertex_color;\n    float3 _750 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _795 = _279;\n        _795.x = _284.x;\n        _795.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _798 = mrt;\n    _798.x = _313.x;\n    _798.y = _313.y;\n    _798.z = _313.z;\n    mrt = _798;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _755 = _213.fa_layers_a.x;\n    float _756 = _213.fa_layers_a.y;\n    float _759 = _213.fa_layers_a.z;\n    float _758 = _213.fa_layers_b.w;\n    float _761 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _755 *= _355.y;\n            _756 *= _355.z;\n            _758 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _750, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _755, _756, _213.fa_layers_b.xyz, _758, _759, _213.fa_layers_a.w, _761, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _661 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _661, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _661, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 480,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _787 = base_t;\n    _787.x = _225.x;\n    _787.y = _225.y;\n    _787.z = _225.z;\n    base_t = _787;\n    float4 _241 = (_787 * _213.fa_base_color) * i.vertex_color;\n    float3 _750 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _795 = _279;\n        _795.x = _284.x;\n        _795.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _798 = mrt;\n    _798.x = _313.x;\n    _798.y = _313.y;\n    _798.z = _313.z;\n    mrt = _798;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _755 = _213.fa_layers_a.x;\n    float _756 = _213.fa_layers_a.y;\n    float _759 = _213.fa_layers_a.z;\n    float _758 = _213.fa_layers_b.w;\n    float _761 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _755 *= _355.y;\n            _756 *= _355.z;\n            _758 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _750, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _755, _756, _213.fa_layers_b.xyz, _758, _759, _213.fa_layers_a.w, _761, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _661 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _661, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _661, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 480,
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
