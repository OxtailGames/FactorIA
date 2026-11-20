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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nconstant spvUnsafeArray<float, 63> _2537 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _491)\n{\n    bool _496 = _491.fa_cl_info.x < 0.0;\n    bool _503;\n    if (!_496)\n    {\n        _503 = _491.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _503 = _496;\n    }\n    bool _511;\n    if (!_503)\n    {\n        _511 = _491.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _511 = _503;\n    }\n    bool _518;\n    if (!_511)\n    {\n        _518 = _491.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _518 = _511;\n    }\n    bool _525;\n    if (!_518)\n    {\n        _525 = _491.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _525 = _518;\n    }\n    if (_525)\n    {\n        return float4(0.0);\n    }\n    float4 _535 = float4(world_pos, 1.0);\n    float _542 = dot(_491.fa_cl_vpw, _535);\n    if (!(_542 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _564 = float2(dot(_491.fa_cl_vpx, _535), dot(_491.fa_cl_vpy, _535)) / float2(_542);\n    int _568 = int(_491.fa_cl_grid.x);\n    int _572 = int(_491.fa_cl_grid.y);\n    int param = (int(_491.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_491.fa_cl_fwd.xyz, world_pos) + _491.fa_cl_fwd.w, _491.fa_cl_grid.w) / _491.fa_cl_grid.w) * _491.fa_cl_grid.z)), 0, int(_491.fa_cl_info.y) - 1) * _572) + clamp(int(floor(((_564.y * 0.5) + 0.5) * _491.fa_cl_grid.y)), 0, _572 - 1)) * _568)) + clamp(int(floor(((_564.x * 0.5) + 0.5) * _491.fa_cl_grid.x)), 0, _568 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _491)\n{\n    float3 param = world_pos;\n    float4 _648 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _491);\n    return int2(int(_648.x), int(_648.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _491, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_491.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3074 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _491);\n    fa_cl_slot = _3074.x;\n    fa_cl_local = _3074.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3228 = fa_linear_to_srgb(param);\n        c = _3228;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3236 = fa_srgb_to_linear(param_1);\n            c = _3236;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _255;\n    if (bool(i.front_facing))\n    {\n        _255 = i.world_normal;\n    }\n    else\n    {\n        _255 = -i.world_normal;\n    }\n    float3 _279 = fast::normalize(i.world_tangent.xyz - (_255 * dot(_255, i.world_tangent.xyz)));\n    float3 _307 = fast::normalize(((_279 * m.x) + ((cross(_255, _279) * i.world_tangent.w) * m.y)) + (_255 * m.z));\n    float3 _310;\n    if (bool(i.front_facing))\n    {\n        _310 = _307;\n    }\n    else\n    {\n        _310 = -_307;\n    }\n    return _310;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _491, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _491.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3267 = fa_tex_fix(param_2, param_3);\n    float4 _4369 = base_t;\n    _4369.x = _3267.x;\n    _4369.y = _3267.y;\n    _4369.z = _3267.z;\n    base_t = _4369;\n    float4 _3281 = (_4369 * _491.fa_base_color) * i.vertex_color;\n    float3 _4236 = i.world_normal;\n    if (_491.fa_maps.z > 0.5)\n    {\n        float param_4 = _491.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3313 = fa_tex_fix(param_6, param_7);\n        float3 _3316 = (_3313 * 2.0) - float3(1.0);\n        float2 _3321 = _3316.xy * _491.fa_maps.x;\n        float3 _4377 = _3316;\n        _4377.x = _3321.x;\n        _4377.y = _3321.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4377;\n        _4236 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _491.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3350 = fa_tex_fix(param_12, param_13);\n    float4 _4380 = mrt;\n    _4380.x = _3350.x;\n    _4380.y = _3350.y;\n    _4380.z = _3350.z;\n    mrt = _4380;\n    float4 _3378 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _491.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3378.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3390 = fa_tex_fix(param_16, param_17);\n    float param_18 = _491.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3420 = fa_tex_fix(param_20, param_21);\n    float _4241 = _491.fa_layers_a.x;\n    float _4242 = _491.fa_layers_a.y;\n    float _4245 = _491.fa_layers_a.z;\n    float _4244 = _491.fa_layers_b.w;\n    float _4247 = _491.fa_layers_c.x;\n    if (_491.fa_layers_c.z > 0.5)\n    {\n        if (mod(_491.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4241 *= _3390.y;\n            _4242 *= _3390.z;\n            _4244 *= _3378.w;\n        }\n        if (_491.fa_layers_c.z > 1.5)\n        {\n            _4245 *= mrt.x;\n            _4247 *= mrt.w;\n        }\n    }\n    return Surface{ _3281.xyz, _3281.w, _4236, fast::clamp(_491.fa_pbr.x * _3350.z, 0.0, 1.0), fast::clamp(_491.fa_pbr.y * _3350.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_491.fa_maps.y * (_3390.x - 1.0)), _491.fa_emissive.xyz + (_491.fa_model_emissive.xyz * _3420), _4241, _4242, _491.fa_layers_b.xyz, _4244, _4245, _491.fa_layers_a.w, _4247, _491.fa_layers_c.y, _491.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _729 = rect.zw - rect.xy;\n    float2 _733 = _729 * atlas;\n    float2 _737 = ddx * _733;\n    float2 _741 = ddy * _733;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _729)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_737, _737), dot(_741, _741)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _491, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _776 = _491.fa_counts.y < 0.5;\n    bool _783;\n    if (!_776)\n    {\n        _783 = _491.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _783 = _776;\n    }\n    if (_783)\n    {\n        return;\n    }\n    float3 _789 = dfdx(world_pos);\n    float3 _792 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _796 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _491);\n    int _800 = int(_796.w);\n    if (_800 < 1)\n    {\n        return;\n    }\n    int _810 = int(_491.fa_counts.y + 0.5);\n    int param_1 = _810;\n    float4 _814 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _817 = _814.yz;\n    int _821 = int(_814.w);\n    int param_2 = _810 + 1;\n    float4 _826 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _827 = _826.x;\n    int _833 = int(_491.fa_counts.w + 0.5) - 1;\n    int _837 = int(_796.z);\n    float3 _1103;\n    for (int k = 0; k < _800; k++)\n    {\n        int _850 = _837 + k;\n        int param_3 = _821 + (_850 >> 2);\n        int _868 = (_810 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_850 & 3]) * 7);\n        int param_4 = _868 + 6;\n        float4 _873 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_873.w + 0.5) >> _833) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _868;\n        float4 _888 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _868 + 1;\n        float4 _893 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _868 + 2;\n        float4 _898 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _901 = _888.xyz;\n        float _906 = dot(_901, world_pos) + _888.w;\n        float3 _908 = _893.xyz;\n        float _913 = dot(_908, world_pos) + _893.w;\n        float3 _915 = _898.xyz;\n        float _920 = dot(_915, world_pos) + _898.w;\n        bool _925 = abs(_906) > 0.5;\n        bool _933;\n        if (!_925)\n        {\n            _933 = abs(_913) > 0.5;\n        }\n        else\n        {\n            _933 = _925;\n        }\n        bool _941;\n        if (!_933)\n        {\n            _941 = abs(_920) > 0.5;\n        }\n        else\n        {\n            _941 = _933;\n        }\n        if (_941)\n        {\n            continue;\n        }\n        float _956 = fast::clamp(dot(geo_normal, fast::normalize(_915)) * _873.z, 0.0, 1.0);\n        if (_956 <= 0.0)\n        {\n            continue;\n        }\n        float _976 = (fast::clamp((0.5 - abs(_920)) * 10.0, 0.0, 1.0) * _956) * _873.x;\n        float2 _984 = float2(_906 + 0.5, 0.5 - _913);\n        float2 _994 = float2(dot(_901, _789), dot(_908, _789));\n        float2 _1004 = float2(dot(_901, _792), dot(_908, _792));\n        int param_8 = _868 + 5;\n        float4 _1009 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _868 + 3;\n        float4 _1014 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _868 + 4;\n        float4 _1019 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1009.xyz;\n        bool _1029 = _1014.z > _1014.x;\n        if (_1029)\n        {\n            float4 param_11 = _1014;\n            float2 param_12 = _984;\n            float2 param_13 = _817;\n            float2 param_14 = _994;\n            float2 param_15 = _1004;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_827 > 0.5) && (_827 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1055 = fa_dc_to_linear(param_16);\n                float4 _4292 = tx;\n                _4292.x = _1055.x;\n                _4292.y = _1055.y;\n                _4292.z = _1055.z;\n                tx = _4292;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_976 * tex_a) * _1009.w, 0.0, 1.0)));\n        if (_1019.z > _1019.x)\n        {\n            float4 param_17 = _1019;\n            float2 param_18 = _984;\n            float2 param_19 = _817;\n            float2 param_20 = _994;\n            float2 param_21 = _1004;\n            float4 _1099 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_827 > 1.5)\n            {\n                float3 param_22 = _1099.xyz;\n                float3 _1109 = fa_dc_to_srgb(param_22);\n                _1103 = _1109;\n            }\n            else\n            {\n                _1103 = _1099.xyz;\n            }\n            float3 _1119 = (_1103 * 2.0) - float3(1.0);\n            float2 _1124 = _1119.xy * _873.y;\n            float3 _1146 = (fast::normalize(_901) * _1124.x) + (fast::normalize(_908) * _1124.y);\n            float3 _1149 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1149, fast::normalize((_1149 * fast::max(_1119.z, 0.0500000007450580596923828125)) + (_1146 - (_1149 * dot(_1149, _1146)))), float3(fast::clamp(_976 * (_1029 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _491, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_491.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _491.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _491, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _491, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _2462 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2470 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2473 = int(_2462);\n    int _2476 = int(_2470);\n    float _2486 = _2470 - float(_2476);\n    int _2542 = (_2473 * 9) + _2476;\n    int _2562 = ((_2473 + 1) * 9) + _2476;\n    return mix(mix(_2537[_2542], _2537[_2542 + 1], _2486), mix(_2537[_2562], _2537[_2562 + 1], _2486), _2462 - float(_2473));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4095 = false;\n    float _4096 = 1.0;\n    float _4097 = 1.0;\n    float _4098 = 1.0;\n    float _4099 = 0.0;\n    float _4100 = 0.0;\n    float _4101 = 0.0;\n    float _4102 = 0.0;\n    float _4104 = 1.0;\n    bool _4105 = false;\n    float3 _4106 = float3(0.0);\n    float _4107 = 1.0;\n    float _4108 = 1.0;\n    float _4109 = 1.0;\n    float _4110 = 0.0;\n    float _4111 = 0.0;\n    float3 _4112 = float3(1.0, 0.0, 0.0);\n    float3 _4113 = float3(0.0, 0.0, 1.0);\n    float _4114 = 1.0;\n    float _4115 = 1.0;\n    float _2615 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2619 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2624 = (_2615 != 1.0) || (_2619 != 1.5);\n    bool _2634;\n    if (!_2624)\n    {\n        _2634 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2634 = _2624;\n    }\n    if (_2634)\n    {\n        float _2642 = (_2619 - 1.0) / (_2619 + 1.0);\n        f0 = mix(fast::min(float3(_2642 * _2642) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2615, s.albedo, float3(metallic));\n        _4096 = mix(_2615, 1.0, metallic);\n        _4095 = true;\n    }\n    float _2670 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2670 > 0.0)\n    {\n        float _2678 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4099 = _2670;\n        _4100 = _2678;\n        float _2685 = _2678 * _2678;\n        _4101 = _2685;\n        _4102 = _2685 * _2685;\n        float _2697 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4104 = _2697;\n        _4097 = 1.0 - (_2670 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2697, 0.0, 1.0), 5.0))));\n        _4095 = true;\n    }\n    float3 _2717 = fast::max(s.sheen_color, float3(0.0));\n    float _2726 = fast::max(_2717.x, fast::max(_2717.y, _2717.z));\n    if (_2726 > 0.0)\n    {\n        float _2734 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4105 = true;\n        _4106 = _2717;\n        _4107 = _2734;\n        _4108 = _2734 * _2734;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2734;\n        float _2751 = fa_sheen_albedo(param, param_1);\n        _4110 = _2751;\n        _4109 = 1.0 - fast::min(_2726 * _2751, 1.0);\n        _4095 = true;\n    }\n    _4098 = _4097 * _4109;\n    float _2770 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2770 != 0.0)\n    {\n        float3 _2785 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2785;\n        if (dot(_2785, _2785) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2802 = t;\n        float3 _2803 = fast::normalize(_2802);\n        t = _2803;\n        float3 _2828 = fast::normalize((_2803 * cos(s.anisotropy_rotation)) + ((cross(n, _2803) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4112 = _2828;\n        _4113 = cross(n, _2828);\n        float _2838 = roughness * roughness;\n        float _2844 = mix(_2838, 1.0, _2770 * _2770);\n        bool _2846 = _2770 > 0.0;\n        _4114 = _2846 ? _2844 : _2838;\n        _4115 = _2846 ? _2838 : _2844;\n        _4111 = _2770;\n        _4095 = true;\n    }\n    return FaLayers{ short(_4095), _4096, _4097, _4098, _4099, _4100, _4101, _4102, i.world_normal, _4104, short(_4105), _4106, _4107, _4108, _4109, _4110, _4111, _4112, _4113, _4114, _4115 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _2394 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2397 = _2394.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_2397 * _2397, exp2((-9.27999973297119140625) * ndv)) * _2397) + _2394.y)) + _2394.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _491, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_491.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _491.fa_env_horizon.w)).xyz;\n    }\n    float _2300 = rough * rough;\n    float _2330 = 0.60000002384185791015625 * _2300;\n    return mix(mix(_491.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_491.fa_env_horizon.xyz, _491.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _2300)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _2330, 0.0500000007450580596923828125 + _2330, d.y))), ((_491.fa_env_sky.xyz + _491.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_2300 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _491, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2879;\n        if (L.aniso >= 0.0)\n        {\n            _2879 = L.b;\n        }\n        else\n        {\n            _2879 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2879, v), _2879), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2912 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _491, fa_env_smp, fa_env_tex) * ((f0 * _2912.x) + (float3(L.f90) * _2912.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _491, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2967 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _491, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _2967.x) + _2967.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _491, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2436 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _491, fa_env_smp, fa_env_tex) * ((f0 * _2436.x) + float3(_2436.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _491, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float _2996 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _3000 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _3007 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_2996));\n    float3 f0 = _3007;\n    float3 _3011 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3011;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2996;\n    float param_5 = _3000;\n    float3 param_6 = _3007;\n    FaLayers _3028 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3028.on)\n    {\n        FaLayers param_7 = _3028;\n        float3 param_8 = _3011;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3000;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _491, fa_env_smp, fa_env_tex) * s.occlusion;\n    }\n    float3 param_12 = _3011;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3000;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _491, fa_env_smp, fa_env_tex) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor, constant fa_mesh_fs_params& _491, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1, _491, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _491)\n{\n    int param = (int(_491.fa_cl_info.x) + int(_491.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _491, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _491);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _366 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _372 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _375 = _372.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _381 = _375 < 0.5;\n    float3 l;\n    if (_381)\n    {\n        l = fast::normalize(_366.xyz);\n    }\n    else\n    {\n        float3 _393 = _366.xyz - world_pos;\n        float _395 = length(_393);\n        dist = _395;\n        l = _393 / float3(fast::max(_395, 9.9999997473787516355514526367188e-05));\n        float _410 = _395 / fast::max(_366.w, 0.001000000047497451305389404296875);\n        float _416 = fast::clamp(1.0 - (_410 * _410), 0.0, 1.0);\n        atten = _416 * _416;\n        if (_375 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _430 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _440 = _430.w;\n            int param_3 = (li * 4) + 3;\n            float4 _446 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _447 = _446.x;\n            float cos_inner = _447;\n            if (_447 > 1.5)\n            {\n                cos_inner = mix(_440, 1.0, 0.25);\n            }\n            atten *= smoothstep(_440, cos_inner, dot(-l, fast::normalize(_430.xyz)));\n        }\n    }\n    int _477;\n    if (_381)\n    {\n        _477 = 0;\n    }\n    else\n    {\n        _477 = (_375 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _372.xyz * atten, atten, 1.0, dist, _477 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1231)\n{\n    float _1221;\n    if (i == 0)\n    {\n        _1221 = _1231.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1237;\n        if (i == 1)\n        {\n            _1237 = _1231.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1245;\n            if (i == 2)\n            {\n                _1245 = _1231.fa_shadow_split.z;\n            }\n            else\n            {\n                _1245 = _1231.fa_shadow_split.w;\n            }\n            _1237 = _1245;\n        }\n        _1221 = _1237;\n    }\n    return _1221;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1278 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1282;\n    if (conv.x < 0.5)\n    {\n        _1282 = _1278;\n    }\n    else\n    {\n        _1282 = (conv.y * conv.z) / (conv.z - (_1278 * (conv.z - conv.y)));\n    }\n    return _1282;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1209 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1209), sin(_1209)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1231, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1328 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1342 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1328;\n            float2 _1361 = fa_shadow_vogel(param_3, param_4, param_5) * _1342;\n            float2 param_6 = uv + (_1361 * _1231.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1373 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1373 < (zr - (length(_1361) * plane)))\n            {\n                sum += _1373;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1417 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1417; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1417;\n        float param_11 = _1328;\n        float2 _1436 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1436 * _1231.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1436) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1417);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1231, texture2d<float> fa_shadow_tex)\n{\n    float _1478 = fast::max(_1231.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1483 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1489 = sqrt(1.0 - (_1483 * _1483));\n    float _1496 = fast::min(_1489 / fast::max(_1483, 0.20000000298023223876953125), 4.0);\n    float _1501;\n    if (_1231.fa_shadow_bias.y > 0.0)\n    {\n        _1501 = _1231.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1501 = 1.5 * _1231.fa_shadow_info[ci].x;\n    }\n    float4 _1526 = _1231.fa_shadow_mat[ci] * float4(world + (n * (_1501 * _1489)), 1.0);\n    float _1533 = _1526.x;\n    bool _1536 = _1533 < _1231.fa_shadow_rect[ci].x;\n    bool _1545;\n    if (!_1536)\n    {\n        _1545 = _1533 > _1231.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1545 = _1536;\n    }\n    bool _1554;\n    if (!_1545)\n    {\n        _1554 = _1526.y < _1231.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1554 = _1545;\n    }\n    bool _1563;\n    if (!_1554)\n    {\n        _1563 = _1526.y > _1231.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1563 = _1554;\n    }\n    bool _1570;\n    if (!_1563)\n    {\n        _1570 = _1526.z > 1.0;\n    }\n    else\n    {\n        _1570 = _1563;\n    }\n    if (_1570)\n    {\n        return -1.0;\n    }\n    float _1579;\n    if (_1231.fa_shadow_bias.x > 0.0)\n    {\n        _1579 = _1231.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1579 = 1.5 * _1231.fa_shadow_info[ci].x;\n    }\n    float2 param = _1526.xy;\n    float4 param_1 = _1231.fa_shadow_rect[ci];\n    float param_2 = _1526.z - ((_1579 * (1.0 + (0.5 * _1496))) / _1478);\n    float param_3 = _1231.fa_shadow_info[ci].x;\n    float param_4 = _1478;\n    float param_5 = _1478 * 0.25;\n    float param_6 = ((_1231.fa_shadow_info[ci].x * fast::min(_1496, 3.0)) * 0.5) / _1478;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1231.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1231.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1231, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _491, thread float4& gl_FragCoord, constant fa_shadows& _1231, texture2d<float> fa_shadow_tex)\n{\n    if (_491.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2006 = int(_1231.fa_shadow_cfg.x + 0.5);\n    if (_2006 < 1)\n    {\n        return 1.0;\n    }\n    float _2021 = dot(world - _1231.fa_shadow_eye.xyz, _1231.fa_shadow_fwd.xyz);\n    int param = _2006 - 1;\n    if (_2021 > fa_shadow_split_at(param, _1231))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2033 = _2006 > 1;\n    bool _2040;\n    if (_2033)\n    {\n        _2040 = _2021 > _1231.fa_shadow_split.x;\n    }\n    else\n    {\n        _2040 = _2033;\n    }\n    if (_2040)\n    {\n        ci = 1;\n    }\n    bool _2044 = _2006 > 2;\n    bool _2051;\n    if (_2044)\n    {\n        _2051 = _2021 > _1231.fa_shadow_split.y;\n    }\n    else\n    {\n        _2051 = _2044;\n    }\n    if (_2051)\n    {\n        ci = 2;\n    }\n    bool _2055 = _2006 > 3;\n    bool _2062;\n    if (_2055)\n    {\n        _2062 = _2021 > _1231.fa_shadow_split.z;\n    }\n    else\n    {\n        _2062 = _2055;\n    }\n    if (_2062)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2006)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2088 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1231, fa_shadow_tex);\n        s = _2088;\n        if (_2088 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1231.fa_shadow_cfg.y > 0.0)\n    {\n        float _2113;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2113 = fa_shadow_split_at(param_5, _1231);\n        }\n        else\n        {\n            _2113 = _1231.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2132 = _1231.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1231) - _2113, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2143 = fast::clamp((_2021 - (fa_shadow_split_at(param_7, _1231) - _2132)) / _2132, 0.0, 1.0);\n        if (_2143 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2006)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2164 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1231, fa_shadow_tex);\n                s2 = _2164;\n                if (_2164 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2143);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _491, thread float4& gl_FragCoord, constant fa_shadows& _1231, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _491, gl_FragCoord, _1231, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _491, thread float4& gl_FragCoord, constant fa_shadows& _1231, texture2d<float> fa_shadow_tex)\n{\n    bool _1637 = _491.fa_pbr.z < 0.5;\n    bool _1645;\n    if (!_1637)\n    {\n        _1645 = _1231.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1645 = _1637;\n    }\n    if (_1645)\n    {\n        return 1.0;\n    }\n    int param = (int(_1231.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1658 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1659 = _1658.x;\n    if (_1659 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1668 = int(_1659 + 0.5);\n    int param_1 = _1668;\n    float4 _1672 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1668 + 1;\n    float4 _1677 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1680 = _1672.y;\n    if (_1680 > 0.0)\n    {\n        float _1697 = 1.0 - smoothstep(0.75 * _1680, _1680, length(world - _1231.fa_shadow_eye.xyz));\n        fade = _1697;\n        if (_1697 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1672.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1716 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1719 = abs(_1716);\n        float _1721 = _1719.x;\n        float _1723 = _1719.y;\n        bool _1724 = _1721 >= _1723;\n        bool _1732;\n        if (_1724)\n        {\n            _1732 = _1721 >= _1719.z;\n        }\n        else\n        {\n            _1732 = _1724;\n        }\n        int _1733;\n        if (_1732)\n        {\n            _1733 = (_1716.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1746;\n            if (_1723 >= _1719.z)\n            {\n                _1746 = (_1716.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1746 = (_1716.z > 0.0) ? 4 : 5;\n            }\n            _1733 = _1746;\n        }\n        face = _1733;\n    }\n    int _1765 = (_1668 + 2) + (face * 6);\n    int param_4 = _1765;\n    int param_5 = _1765 + 1;\n    int param_6 = _1765 + 3;\n    float4 _1779 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1765 + 4;\n    float4 _1784 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1765 + 5;\n    float4 _1789 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1801 = _1789.x * fast::max(dot(_1779, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1806 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1829 = fast::clamp(dot(n, _1779.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1852 = fast::min(sqrt(1.0 - (_1829 * _1829)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1779, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1855 = _1677.y;\n    float _1857;\n    if (_1855 > 0.0)\n    {\n        _1857 = _1855;\n    }\n    else\n    {\n        _1857 = 1.5 * _1801;\n    }\n    float4 _1877 = float4(world + (n * (_1857 * sqrt(1.0 - (_1806 * _1806)))), 1.0);\n    float _1881 = dot(_1779, _1877);\n    float _1884 = _1789.y;\n    if (_1881 < _1884)\n    {\n        return 1.0;\n    }\n    float2 _1899 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1877), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1877)) / float2(_1881);\n    float _1901 = _1899.x;\n    bool _1904 = _1901 < _1784.x;\n    bool _1913;\n    if (!_1904)\n    {\n        _1913 = _1901 > _1784.z;\n    }\n    else\n    {\n        _1913 = _1904;\n    }\n    bool _1922;\n    if (!_1913)\n    {\n        _1922 = _1899.y < _1784.y;\n    }\n    else\n    {\n        _1922 = _1913;\n    }\n    bool _1931;\n    if (!_1922)\n    {\n        _1931 = _1899.y > _1784.w;\n    }\n    else\n    {\n        _1931 = _1922;\n    }\n    if (_1931)\n    {\n        return 1.0;\n    }\n    float _1937 = _1677.x;\n    float _1939;\n    if (_1937 > 0.0)\n    {\n        _1939 = _1937;\n    }\n    else\n    {\n        _1939 = 1.5 * _1801;\n    }\n    float2 param_10 = _1899;\n    float4 param_11 = _1784;\n    float param_12 = _1881 - (_1939 * (1.0 + (0.5 * _1852)));\n    float param_13 = _1801;\n    float param_14 = 1.0;\n    float param_15 = _1789.z * 0.25;\n    float param_16 = (_1801 * fast::min(_1852, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1884, _1789.z);\n    int param_18 = int(_1672.z + 0.5);\n    float param_19 = _1672.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1231, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _491, thread float4& gl_FragCoord, constant fa_shadows& _1231, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3101 = fa_lm.z > 0.5;\n    bool _3107;\n    if (_3101)\n    {\n        int param = li;\n        _3107 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3107 = _3101;\n    }\n    if (_3107)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3129 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _4221 = _3129.direction;\n    float3 _4216 = _3129.color;\n    float _4223 = _3129.attenuation;\n    float _4218 = _3129.shadow;\n    int _4226 = _3129.type;\n    if ((_4226 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4221;\n        float _3143 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _491, gl_FragCoord, _1231, fa_shadow_tex, fa_world_pos);\n        _4218 = _3143;\n        _4216 *= _3143;\n    }\n    else\n    {\n        bool _3154 = _4226 != 0;\n        bool _3160;\n        if (_3154)\n        {\n            _3160 = _4223 > 0.0;\n        }\n        else\n        {\n            _3160 = _3154;\n        }\n        if (_3160)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4221;\n            float _3172 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _491, gl_FragCoord, _1231, fa_shadow_tex);\n            _4218 = _3172;\n            _4216 *= _3172;\n        }\n    }\n    return LightSample{ _4221, _4216, _4223, _4218, _3129._distance, _4226 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1231)\n{\n    if (_1231.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2188 = int(_1231.fa_shadow_cfg.x + 0.5);\n    float _2198 = dot(world - _1231.fa_shadow_eye.xyz, _1231.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2203 = _2188 > 0;\n    bool _2212;\n    if (_2203)\n    {\n        int param = _2188 - 1;\n        _2212 = _2198 <= fa_shadow_split_at(param, _1231);\n    }\n    else\n    {\n        _2212 = _2203;\n    }\n    if (_2212)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2219 = _2188 > 1;\n        bool _2226;\n        if (_2219)\n        {\n            _2226 = _2198 > _1231.fa_shadow_split.x;\n        }\n        else\n        {\n            _2226 = _2219;\n        }\n        if (_2226)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2232 = _2188 > 2;\n        bool _2239;\n        if (_2232)\n        {\n            _2239 = _2198 > _1231.fa_shadow_split.y;\n        }\n        else\n        {\n            _2239 = _2232;\n        }\n        if (_2239)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2245 = _2188 > 3;\n        bool _2252;\n        if (_2245)\n        {\n            _2252 = _2198 > _1231.fa_shadow_split.z;\n        }\n        else\n        {\n            _2252 = _2245;\n        }\n        if (_2252)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _491 [[buffer(1)]], constant fa_shadows& _1231 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3925 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3925 = -_3925;\n    }\n    float3 _3560 = fast::normalize(_491.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _491, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3925, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3560, short(gl_FrontFacing) };\n    Surface _3568 = fa_standard_surface(param_1, _491, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3964 = _3568.albedo;\n    float _3965 = _3568.alpha;\n    float3 _3966 = _3568.normal;\n    float _3967 = _3568.metallic;\n    float _3968 = _3568.roughness;\n    float _3969 = _3568.occlusion;\n    float3 _3970 = _3568.emission;\n    float _3971 = _3568.clearcoat;\n    float _3972 = _3568.clearcoat_roughness;\n    float3 _3973 = _3568.sheen_color;\n    float _3974 = _3568.sheen_roughness;\n    float _3975 = _3568.anisotropy;\n    float _3976 = _3568.anisotropy_rotation;\n    float _3977 = _3568.specular;\n    float _3978 = _3568.ior;\n    float3 _3979 = _3568.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3925, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3560, short(gl_FrontFacing) };\n    Surface param_3 = _3568;\n    surface(param_2, param_3);\n    _3964 = param_3.albedo;\n    _3965 = param_3.alpha;\n    _3966 = param_3.normal;\n    _3967 = param_3.metallic;\n    _3968 = param_3.roughness;\n    _3969 = param_3.occlusion;\n    _3970 = param_3.emission;\n    _3971 = param_3.clearcoat;\n    _3972 = param_3.clearcoat_roughness;\n    _3973 = param_3.sheen_color;\n    _3974 = param_3.sheen_roughness;\n    _3975 = param_3.anisotropy;\n    _3976 = param_3.anisotropy_rotation;\n    _3977 = param_3.specular;\n    _3978 = param_3.ior;\n    _3979 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _3925;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _491, fa_decal_tex, fa_env_smp);\n    _3964 = param_6;\n    _3966 = param_7;\n    float3 result;\n    if (_491.fa_emissive.w > 0.5)\n    {\n        result = _3964;\n    }\n    else\n    {\n        float3 _3606 = _3966;\n        float3 _3607 = fast::normalize(_3606);\n        _3966 = _3607;\n        float3 param_8 = _3607;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _3925, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3560, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _3964, _3965, _3966, _3967, _3968, _3969, _3970, _3971, _3972, _3973, _3974, _3975, _3976, _3977, _3978, _3979 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _491, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11, _491, fa_env_smp, fa_env_tex);\n        int _3626 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3626; ln++)\n        {\n            int param_12 = ln;\n            int _3639 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _491, fa_cl_ndir, fa_cl_slot);\n            bool _3642 = in.fa_lm.z > 0.5;\n            bool _3648;\n            if (_3642)\n            {\n                int param_13 = _3639;\n                _3648 = fa_light_baked(param_13, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _3648 = _3642;\n            }\n            if (_3648)\n            {\n                continue;\n            }\n            int param_14 = _3639;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _3925;\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _3925, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3560, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _3964, _3965, _3966, _3967, _3968, _3969, _3970, _3971, _3972, _3973, _3974, _3975, _3976, _3977, _3978, _3979 };\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16, fa_light_tex, fa_shadow_smp, _491, gl_FragCoord, _1231, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _3675 = result;\n    float3 _3676 = _3675 + _3970;\n    result = _3676;\n    float3 param_20 = _3676;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _1231);\n    bool _3685 = _491.fa_fog.w > 0.0;\n    bool _3692;\n    if (!_3685)\n    {\n        _3692 = _491.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3692 = _3685;\n    }\n    if (_3692)\n    {\n        float3 _3701 = in.fa_world_pos - _491.fa_camera_pos.xyz;\n        float _3707 = dot(_3701, _491.fa_fog_c.xyz);\n        bool _3711 = _491.fa_fog_c.w > 0.5;\n        float _3712;\n        if (_3711)\n        {\n            _3712 = _3707;\n        }\n        else\n        {\n            _3712 = length(_3701);\n        }\n        float _3724 = _3712 - _491.fa_fog_b.x;\n        if (_3724 > 0.0)\n        {\n            float _3733 = _491.fa_fog.w * _3724;\n            float tau = _3733 * _3733;\n            if (_491.fa_fog_b.y > 0.0)\n            {\n                float _3749;\n                if (_3711)\n                {\n                    _3749 = in.fa_world_pos.y - (_491.fa_fog_c.y * _3707);\n                }\n                else\n                {\n                    _3749 = _491.fa_camera_pos.y;\n                }\n                float _3770 = mix(_3749, in.fa_world_pos.y, fast::clamp(_491.fa_fog_b.x / _3712, 0.0, 1.0));\n                float _3774 = in.fa_world_pos.y - _3770;\n                float _3779 = _3770 - _491.fa_fog_b.z;\n                float _3784 = in.fa_world_pos.y - _491.fa_fog_b.z;\n                bool _3787 = _3779 <= 0.0;\n                bool _3788 = !_3787;\n                bool _3794;\n                if (_3788)\n                {\n                    _3794 = _491.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3794 = _3787;\n                }\n                float _3795;\n                if (_3794)\n                {\n                    _3795 = _491.fa_fog_b.y;\n                }\n                else\n                {\n                    _3795 = _491.fa_fog_b.y * exp(-fast::min(_491.fa_fog_b.w * _3779, 80.0));\n                }\n                bool _3822;\n                if (_3788)\n                {\n                    _3822 = _491.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3822 = _3787;\n                }\n                float _3823;\n                if (_3822)\n                {\n                    _3823 = _491.fa_fog_b.y * _3779;\n                }\n                else\n                {\n                    _3823 = (_491.fa_fog_b.y * (1.0 - exp(-fast::min(_491.fa_fog_b.w * _3779, 80.0)))) / _491.fa_fog_b.w;\n                }\n                bool _3848 = _3784 <= 0.0;\n                bool _3855;\n                if (!_3848)\n                {\n                    _3855 = _491.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3855 = _3848;\n                }\n                float _3856;\n                if (_3855)\n                {\n                    _3856 = _491.fa_fog_b.y * _3784;\n                }\n                else\n                {\n                    _3856 = (_491.fa_fog_b.y * (1.0 - exp(-fast::min(_491.fa_fog_b.w * _3784, 80.0)))) / _491.fa_fog_b.w;\n                }\n                float _3883;\n                if (abs(_3774) < 0.001000000047497451305389404296875)\n                {\n                    _3883 = _3795;\n                }\n                else\n                {\n                    _3883 = (_3856 - _3823) / _3774;\n                }\n                tau += (_3724 * fast::max(_3883, 0.0));\n            }\n            result = mix(result, _491.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3965);\n    return out;\n}\n\n",
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
            "inst_name": "_491",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1231",
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
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 10
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nconstant spvUnsafeArray<float, 63> _2537 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _491)\n{\n    bool _496 = _491.fa_cl_info.x < 0.0;\n    bool _503;\n    if (!_496)\n    {\n        _503 = _491.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _503 = _496;\n    }\n    bool _511;\n    if (!_503)\n    {\n        _511 = _491.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _511 = _503;\n    }\n    bool _518;\n    if (!_511)\n    {\n        _518 = _491.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _518 = _511;\n    }\n    bool _525;\n    if (!_518)\n    {\n        _525 = _491.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _525 = _518;\n    }\n    if (_525)\n    {\n        return float4(0.0);\n    }\n    float4 _535 = float4(world_pos, 1.0);\n    float _542 = dot(_491.fa_cl_vpw, _535);\n    if (!(_542 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _564 = float2(dot(_491.fa_cl_vpx, _535), dot(_491.fa_cl_vpy, _535)) / float2(_542);\n    int _568 = int(_491.fa_cl_grid.x);\n    int _572 = int(_491.fa_cl_grid.y);\n    int param = (int(_491.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_491.fa_cl_fwd.xyz, world_pos) + _491.fa_cl_fwd.w, _491.fa_cl_grid.w) / _491.fa_cl_grid.w) * _491.fa_cl_grid.z)), 0, int(_491.fa_cl_info.y) - 1) * _572) + clamp(int(floor(((_564.y * 0.5) + 0.5) * _491.fa_cl_grid.y)), 0, _572 - 1)) * _568)) + clamp(int(floor(((_564.x * 0.5) + 0.5) * _491.fa_cl_grid.x)), 0, _568 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _491)\n{\n    float3 param = world_pos;\n    float4 _648 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _491);\n    return int2(int(_648.x), int(_648.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _491, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_491.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3074 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _491);\n    fa_cl_slot = _3074.x;\n    fa_cl_local = _3074.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3228 = fa_linear_to_srgb(param);\n        c = _3228;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3236 = fa_srgb_to_linear(param_1);\n            c = _3236;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _255;\n    if (bool(i.front_facing))\n    {\n        _255 = i.world_normal;\n    }\n    else\n    {\n        _255 = -i.world_normal;\n    }\n    float3 _279 = fast::normalize(i.world_tangent.xyz - (_255 * dot(_255, i.world_tangent.xyz)));\n    float3 _307 = fast::normalize(((_279 * m.x) + ((cross(_255, _279) * i.world_tangent.w) * m.y)) + (_255 * m.z));\n    float3 _310;\n    if (bool(i.front_facing))\n    {\n        _310 = _307;\n    }\n    else\n    {\n        _310 = -_307;\n    }\n    return _310;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _491, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _491.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3267 = fa_tex_fix(param_2, param_3);\n    float4 _4369 = base_t;\n    _4369.x = _3267.x;\n    _4369.y = _3267.y;\n    _4369.z = _3267.z;\n    base_t = _4369;\n    float4 _3281 = (_4369 * _491.fa_base_color) * i.vertex_color;\n    float3 _4236 = i.world_normal;\n    if (_491.fa_maps.z > 0.5)\n    {\n        float param_4 = _491.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3313 = fa_tex_fix(param_6, param_7);\n        float3 _3316 = (_3313 * 2.0) - float3(1.0);\n        float2 _3321 = _3316.xy * _491.fa_maps.x;\n        float3 _4377 = _3316;\n        _4377.x = _3321.x;\n        _4377.y = _3321.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4377;\n        _4236 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _491.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3350 = fa_tex_fix(param_12, param_13);\n    float4 _4380 = mrt;\n    _4380.x = _3350.x;\n    _4380.y = _3350.y;\n    _4380.z = _3350.z;\n    mrt = _4380;\n    float4 _3378 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _491.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3378.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3390 = fa_tex_fix(param_16, param_17);\n    float param_18 = _491.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3420 = fa_tex_fix(param_20, param_21);\n    float _4241 = _491.fa_layers_a.x;\n    float _4242 = _491.fa_layers_a.y;\n    float _4245 = _491.fa_layers_a.z;\n    float _4244 = _491.fa_layers_b.w;\n    float _4247 = _491.fa_layers_c.x;\n    if (_491.fa_layers_c.z > 0.5)\n    {\n        if (mod(_491.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4241 *= _3390.y;\n            _4242 *= _3390.z;\n            _4244 *= _3378.w;\n        }\n        if (_491.fa_layers_c.z > 1.5)\n        {\n            _4245 *= mrt.x;\n            _4247 *= mrt.w;\n        }\n    }\n    return Surface{ _3281.xyz, _3281.w, _4236, fast::clamp(_491.fa_pbr.x * _3350.z, 0.0, 1.0), fast::clamp(_491.fa_pbr.y * _3350.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_491.fa_maps.y * (_3390.x - 1.0)), _491.fa_emissive.xyz + (_491.fa_model_emissive.xyz * _3420), _4241, _4242, _491.fa_layers_b.xyz, _4244, _4245, _491.fa_layers_a.w, _4247, _491.fa_layers_c.y, _491.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _729 = rect.zw - rect.xy;\n    float2 _733 = _729 * atlas;\n    float2 _737 = ddx * _733;\n    float2 _741 = ddy * _733;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _729)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_737, _737), dot(_741, _741)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _491, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _776 = _491.fa_counts.y < 0.5;\n    bool _783;\n    if (!_776)\n    {\n        _783 = _491.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _783 = _776;\n    }\n    if (_783)\n    {\n        return;\n    }\n    float3 _789 = dfdx(world_pos);\n    float3 _792 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _796 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _491);\n    int _800 = int(_796.w);\n    if (_800 < 1)\n    {\n        return;\n    }\n    int _810 = int(_491.fa_counts.y + 0.5);\n    int param_1 = _810;\n    float4 _814 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _817 = _814.yz;\n    int _821 = int(_814.w);\n    int param_2 = _810 + 1;\n    float4 _826 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _827 = _826.x;\n    int _833 = int(_491.fa_counts.w + 0.5) - 1;\n    int _837 = int(_796.z);\n    float3 _1103;\n    for (int k = 0; k < _800; k++)\n    {\n        int _850 = _837 + k;\n        int param_3 = _821 + (_850 >> 2);\n        int _868 = (_810 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_850 & 3]) * 7);\n        int param_4 = _868 + 6;\n        float4 _873 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_873.w + 0.5) >> _833) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _868;\n        float4 _888 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _868 + 1;\n        float4 _893 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _868 + 2;\n        float4 _898 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _901 = _888.xyz;\n        float _906 = dot(_901, world_pos) + _888.w;\n        float3 _908 = _893.xyz;\n        float _913 = dot(_908, world_pos) + _893.w;\n        float3 _915 = _898.xyz;\n        float _920 = dot(_915, world_pos) + _898.w;\n        bool _925 = abs(_906) > 0.5;\n        bool _933;\n        if (!_925)\n        {\n            _933 = abs(_913) > 0.5;\n        }\n        else\n        {\n            _933 = _925;\n        }\n        bool _941;\n        if (!_933)\n        {\n            _941 = abs(_920) > 0.5;\n        }\n        else\n        {\n            _941 = _933;\n        }\n        if (_941)\n        {\n            continue;\n        }\n        float _956 = fast::clamp(dot(geo_normal, fast::normalize(_915)) * _873.z, 0.0, 1.0);\n        if (_956 <= 0.0)\n        {\n            continue;\n        }\n        float _976 = (fast::clamp((0.5 - abs(_920)) * 10.0, 0.0, 1.0) * _956) * _873.x;\n        float2 _984 = float2(_906 + 0.5, 0.5 - _913);\n        float2 _994 = float2(dot(_901, _789), dot(_908, _789));\n        float2 _1004 = float2(dot(_901, _792), dot(_908, _792));\n        int param_8 = _868 + 5;\n        float4 _1009 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _868 + 3;\n        float4 _1014 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _868 + 4;\n        float4 _1019 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1009.xyz;\n        bool _1029 = _1014.z > _1014.x;\n        if (_1029)\n        {\n            float4 param_11 = _1014;\n            float2 param_12 = _984;\n            float2 param_13 = _817;\n            float2 param_14 = _994;\n            float2 param_15 = _1004;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_827 > 0.5) && (_827 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1055 = fa_dc_to_linear(param_16);\n                float4 _4292 = tx;\n                _4292.x = _1055.x;\n                _4292.y = _1055.y;\n                _4292.z = _1055.z;\n                tx = _4292;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_976 * tex_a) * _1009.w, 0.0, 1.0)));\n        if (_1019.z > _1019.x)\n        {\n            float4 param_17 = _1019;\n            float2 param_18 = _984;\n            float2 param_19 = _817;\n            float2 param_20 = _994;\n            float2 param_21 = _1004;\n            float4 _1099 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_827 > 1.5)\n            {\n                float3 param_22 = _1099.xyz;\n                float3 _1109 = fa_dc_to_srgb(param_22);\n                _1103 = _1109;\n            }\n            else\n            {\n                _1103 = _1099.xyz;\n            }\n            float3 _1119 = (_1103 * 2.0) - float3(1.0);\n            float2 _1124 = _1119.xy * _873.y;\n            float3 _1146 = (fast::normalize(_901) * _1124.x) + (fast::normalize(_908) * _1124.y);\n            float3 _1149 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1149, fast::normalize((_1149 * fast::max(_1119.z, 0.0500000007450580596923828125)) + (_1146 - (_1149 * dot(_1149, _1146)))), float3(fast::clamp(_976 * (_1029 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _491, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_491.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _491.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _491, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _491, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _2462 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2470 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2473 = int(_2462);\n    int _2476 = int(_2470);\n    float _2486 = _2470 - float(_2476);\n    int _2542 = (_2473 * 9) + _2476;\n    int _2562 = ((_2473 + 1) * 9) + _2476;\n    return mix(mix(_2537[_2542], _2537[_2542 + 1], _2486), mix(_2537[_2562], _2537[_2562 + 1], _2486), _2462 - float(_2473));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4095 = false;\n    float _4096 = 1.0;\n    float _4097 = 1.0;\n    float _4098 = 1.0;\n    float _4099 = 0.0;\n    float _4100 = 0.0;\n    float _4101 = 0.0;\n    float _4102 = 0.0;\n    float _4104 = 1.0;\n    bool _4105 = false;\n    float3 _4106 = float3(0.0);\n    float _4107 = 1.0;\n    float _4108 = 1.0;\n    float _4109 = 1.0;\n    float _4110 = 0.0;\n    float _4111 = 0.0;\n    float3 _4112 = float3(1.0, 0.0, 0.0);\n    float3 _4113 = float3(0.0, 0.0, 1.0);\n    float _4114 = 1.0;\n    float _4115 = 1.0;\n    float _2615 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2619 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2624 = (_2615 != 1.0) || (_2619 != 1.5);\n    bool _2634;\n    if (!_2624)\n    {\n        _2634 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2634 = _2624;\n    }\n    if (_2634)\n    {\n        float _2642 = (_2619 - 1.0) / (_2619 + 1.0);\n        f0 = mix(fast::min(float3(_2642 * _2642) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2615, s.albedo, float3(metallic));\n        _4096 = mix(_2615, 1.0, metallic);\n        _4095 = true;\n    }\n    float _2670 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2670 > 0.0)\n    {\n        float _2678 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4099 = _2670;\n        _4100 = _2678;\n        float _2685 = _2678 * _2678;\n        _4101 = _2685;\n        _4102 = _2685 * _2685;\n        float _2697 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4104 = _2697;\n        _4097 = 1.0 - (_2670 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2697, 0.0, 1.0), 5.0))));\n        _4095 = true;\n    }\n    float3 _2717 = fast::max(s.sheen_color, float3(0.0));\n    float _2726 = fast::max(_2717.x, fast::max(_2717.y, _2717.z));\n    if (_2726 > 0.0)\n    {\n        float _2734 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4105 = true;\n        _4106 = _2717;\n        _4107 = _2734;\n        _4108 = _2734 * _2734;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2734;\n        float _2751 = fa_sheen_albedo(param, param_1);\n        _4110 = _2751;\n        _4109 = 1.0 - fast::min(_2726 * _2751, 1.0);\n        _4095 = true;\n    }\n    _4098 = _4097 * _4109;\n    float _2770 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2770 != 0.0)\n    {\n        float3 _2785 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2785;\n        if (dot(_2785, _2785) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2802 = t;\n        float3 _2803 = fast::normalize(_2802);\n        t = _2803;\n        float3 _2828 = fast::normalize((_2803 * cos(s.anisotropy_rotation)) + ((cross(n, _2803) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4112 = _2828;\n        _4113 = cross(n, _2828);\n        float _2838 = roughness * roughness;\n        float _2844 = mix(_2838, 1.0, _2770 * _2770);\n        bool _2846 = _2770 > 0.0;\n        _4114 = _2846 ? _2844 : _2838;\n        _4115 = _2846 ? _2838 : _2844;\n        _4111 = _2770;\n        _4095 = true;\n    }\n    return FaLayers{ short(_4095), _4096, _4097, _4098, _4099, _4100, _4101, _4102, i.world_normal, _4104, short(_4105), _4106, _4107, _4108, _4109, _4110, _4111, _4112, _4113, _4114, _4115 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _2394 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2397 = _2394.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_2397 * _2397, exp2((-9.27999973297119140625) * ndv)) * _2397) + _2394.y)) + _2394.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _491, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_491.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _491.fa_env_horizon.w)).xyz;\n    }\n    float _2300 = rough * rough;\n    float _2330 = 0.60000002384185791015625 * _2300;\n    return mix(mix(_491.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_491.fa_env_horizon.xyz, _491.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _2300)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _2330, 0.0500000007450580596923828125 + _2330, d.y))), ((_491.fa_env_sky.xyz + _491.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_2300 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _491, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2879;\n        if (L.aniso >= 0.0)\n        {\n            _2879 = L.b;\n        }\n        else\n        {\n            _2879 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2879, v), _2879), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2912 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _491, fa_env_smp, fa_env_tex) * ((f0 * _2912.x) + (float3(L.f90) * _2912.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _491, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2967 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _491, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _2967.x) + _2967.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _491, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2436 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _491, fa_env_smp, fa_env_tex) * ((f0 * _2436.x) + float3(_2436.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _491, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float _2996 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _3000 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _3007 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_2996));\n    float3 f0 = _3007;\n    float3 _3011 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3011;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2996;\n    float param_5 = _3000;\n    float3 param_6 = _3007;\n    FaLayers _3028 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3028.on)\n    {\n        FaLayers param_7 = _3028;\n        float3 param_8 = _3011;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3000;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _491, fa_env_smp, fa_env_tex) * s.occlusion;\n    }\n    float3 param_12 = _3011;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3000;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _491, fa_env_smp, fa_env_tex) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor, constant fa_mesh_fs_params& _491, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1, _491, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _491)\n{\n    int param = (int(_491.fa_cl_info.x) + int(_491.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _491, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _491);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _366 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _372 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _375 = _372.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _381 = _375 < 0.5;\n    float3 l;\n    if (_381)\n    {\n        l = fast::normalize(_366.xyz);\n    }\n    else\n    {\n        float3 _393 = _366.xyz - world_pos;\n        float _395 = length(_393);\n        dist = _395;\n        l = _393 / float3(fast::max(_395, 9.9999997473787516355514526367188e-05));\n        float _410 = _395 / fast::max(_366.w, 0.001000000047497451305389404296875);\n        float _416 = fast::clamp(1.0 - (_410 * _410), 0.0, 1.0);\n        atten = _416 * _416;\n        if (_375 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _430 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _440 = _430.w;\n            int param_3 = (li * 4) + 3;\n            float4 _446 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _447 = _446.x;\n            float cos_inner = _447;\n            if (_447 > 1.5)\n            {\n                cos_inner = mix(_440, 1.0, 0.25);\n            }\n            atten *= smoothstep(_440, cos_inner, dot(-l, fast::normalize(_430.xyz)));\n        }\n    }\n    int _477;\n    if (_381)\n    {\n        _477 = 0;\n    }\n    else\n    {\n        _477 = (_375 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _372.xyz * atten, atten, 1.0, dist, _477 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1231)\n{\n    float _1221;\n    if (i == 0)\n    {\n        _1221 = _1231.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1237;\n        if (i == 1)\n        {\n            _1237 = _1231.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1245;\n            if (i == 2)\n            {\n                _1245 = _1231.fa_shadow_split.z;\n            }\n            else\n            {\n                _1245 = _1231.fa_shadow_split.w;\n            }\n            _1237 = _1245;\n        }\n        _1221 = _1237;\n    }\n    return _1221;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1278 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1282;\n    if (conv.x < 0.5)\n    {\n        _1282 = _1278;\n    }\n    else\n    {\n        _1282 = (conv.y * conv.z) / (conv.z - (_1278 * (conv.z - conv.y)));\n    }\n    return _1282;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1209 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1209), sin(_1209)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1231, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1328 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1342 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1328;\n            float2 _1361 = fa_shadow_vogel(param_3, param_4, param_5) * _1342;\n            float2 param_6 = uv + (_1361 * _1231.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1373 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1373 < (zr - (length(_1361) * plane)))\n            {\n                sum += _1373;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1417 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1417; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1417;\n        float param_11 = _1328;\n        float2 _1436 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1436 * _1231.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1436) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1417);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1231, texture2d<float> fa_shadow_tex)\n{\n    float _1478 = fast::max(_1231.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1483 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1489 = sqrt(1.0 - (_1483 * _1483));\n    float _1496 = fast::min(_1489 / fast::max(_1483, 0.20000000298023223876953125), 4.0);\n    float _1501;\n    if (_1231.fa_shadow_bias.y > 0.0)\n    {\n        _1501 = _1231.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1501 = 1.5 * _1231.fa_shadow_info[ci].x;\n    }\n    float4 _1526 = _1231.fa_shadow_mat[ci] * float4(world + (n * (_1501 * _1489)), 1.0);\n    float _1533 = _1526.x;\n    bool _1536 = _1533 < _1231.fa_shadow_rect[ci].x;\n    bool _1545;\n    if (!_1536)\n    {\n        _1545 = _1533 > _1231.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1545 = _1536;\n    }\n    bool _1554;\n    if (!_1545)\n    {\n        _1554 = _1526.y < _1231.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1554 = _1545;\n    }\n    bool _1563;\n    if (!_1554)\n    {\n        _1563 = _1526.y > _1231.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1563 = _1554;\n    }\n    bool _1570;\n    if (!_1563)\n    {\n        _1570 = _1526.z > 1.0;\n    }\n    else\n    {\n        _1570 = _1563;\n    }\n    if (_1570)\n    {\n        return -1.0;\n    }\n    float _1579;\n    if (_1231.fa_shadow_bias.x > 0.0)\n    {\n        _1579 = _1231.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1579 = 1.5 * _1231.fa_shadow_info[ci].x;\n    }\n    float2 param = _1526.xy;\n    float4 param_1 = _1231.fa_shadow_rect[ci];\n    float param_2 = _1526.z - ((_1579 * (1.0 + (0.5 * _1496))) / _1478);\n    float param_3 = _1231.fa_shadow_info[ci].x;\n    float param_4 = _1478;\n    float param_5 = _1478 * 0.25;\n    float param_6 = ((_1231.fa_shadow_info[ci].x * fast::min(_1496, 3.0)) * 0.5) / _1478;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1231.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1231.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1231, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _491, thread float4& gl_FragCoord, constant fa_shadows& _1231, texture2d<float> fa_shadow_tex)\n{\n    if (_491.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2006 = int(_1231.fa_shadow_cfg.x + 0.5);\n    if (_2006 < 1)\n    {\n        return 1.0;\n    }\n    float _2021 = dot(world - _1231.fa_shadow_eye.xyz, _1231.fa_shadow_fwd.xyz);\n    int param = _2006 - 1;\n    if (_2021 > fa_shadow_split_at(param, _1231))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2033 = _2006 > 1;\n    bool _2040;\n    if (_2033)\n    {\n        _2040 = _2021 > _1231.fa_shadow_split.x;\n    }\n    else\n    {\n        _2040 = _2033;\n    }\n    if (_2040)\n    {\n        ci = 1;\n    }\n    bool _2044 = _2006 > 2;\n    bool _2051;\n    if (_2044)\n    {\n        _2051 = _2021 > _1231.fa_shadow_split.y;\n    }\n    else\n    {\n        _2051 = _2044;\n    }\n    if (_2051)\n    {\n        ci = 2;\n    }\n    bool _2055 = _2006 > 3;\n    bool _2062;\n    if (_2055)\n    {\n        _2062 = _2021 > _1231.fa_shadow_split.z;\n    }\n    else\n    {\n        _2062 = _2055;\n    }\n    if (_2062)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2006)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2088 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1231, fa_shadow_tex);\n        s = _2088;\n        if (_2088 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1231.fa_shadow_cfg.y > 0.0)\n    {\n        float _2113;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2113 = fa_shadow_split_at(param_5, _1231);\n        }\n        else\n        {\n            _2113 = _1231.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2132 = _1231.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1231) - _2113, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2143 = fast::clamp((_2021 - (fa_shadow_split_at(param_7, _1231) - _2132)) / _2132, 0.0, 1.0);\n        if (_2143 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2006)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2164 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1231, fa_shadow_tex);\n                s2 = _2164;\n                if (_2164 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2143);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _491, thread float4& gl_FragCoord, constant fa_shadows& _1231, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _491, gl_FragCoord, _1231, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _491, thread float4& gl_FragCoord, constant fa_shadows& _1231, texture2d<float> fa_shadow_tex)\n{\n    bool _1637 = _491.fa_pbr.z < 0.5;\n    bool _1645;\n    if (!_1637)\n    {\n        _1645 = _1231.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1645 = _1637;\n    }\n    if (_1645)\n    {\n        return 1.0;\n    }\n    int param = (int(_1231.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1658 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1659 = _1658.x;\n    if (_1659 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1668 = int(_1659 + 0.5);\n    int param_1 = _1668;\n    float4 _1672 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1668 + 1;\n    float4 _1677 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1680 = _1672.y;\n    if (_1680 > 0.0)\n    {\n        float _1697 = 1.0 - smoothstep(0.75 * _1680, _1680, length(world - _1231.fa_shadow_eye.xyz));\n        fade = _1697;\n        if (_1697 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1672.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1716 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1719 = abs(_1716);\n        float _1721 = _1719.x;\n        float _1723 = _1719.y;\n        bool _1724 = _1721 >= _1723;\n        bool _1732;\n        if (_1724)\n        {\n            _1732 = _1721 >= _1719.z;\n        }\n        else\n        {\n            _1732 = _1724;\n        }\n        int _1733;\n        if (_1732)\n        {\n            _1733 = (_1716.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1746;\n            if (_1723 >= _1719.z)\n            {\n                _1746 = (_1716.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1746 = (_1716.z > 0.0) ? 4 : 5;\n            }\n            _1733 = _1746;\n        }\n        face = _1733;\n    }\n    int _1765 = (_1668 + 2) + (face * 6);\n    int param_4 = _1765;\n    int param_5 = _1765 + 1;\n    int param_6 = _1765 + 3;\n    float4 _1779 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1765 + 4;\n    float4 _1784 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1765 + 5;\n    float4 _1789 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1801 = _1789.x * fast::max(dot(_1779, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1806 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1829 = fast::clamp(dot(n, _1779.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1852 = fast::min(sqrt(1.0 - (_1829 * _1829)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1779, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1855 = _1677.y;\n    float _1857;\n    if (_1855 > 0.0)\n    {\n        _1857 = _1855;\n    }\n    else\n    {\n        _1857 = 1.5 * _1801;\n    }\n    float4 _1877 = float4(world + (n * (_1857 * sqrt(1.0 - (_1806 * _1806)))), 1.0);\n    float _1881 = dot(_1779, _1877);\n    float _1884 = _1789.y;\n    if (_1881 < _1884)\n    {\n        return 1.0;\n    }\n    float2 _1899 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1877), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1877)) / float2(_1881);\n    float _1901 = _1899.x;\n    bool _1904 = _1901 < _1784.x;\n    bool _1913;\n    if (!_1904)\n    {\n        _1913 = _1901 > _1784.z;\n    }\n    else\n    {\n        _1913 = _1904;\n    }\n    bool _1922;\n    if (!_1913)\n    {\n        _1922 = _1899.y < _1784.y;\n    }\n    else\n    {\n        _1922 = _1913;\n    }\n    bool _1931;\n    if (!_1922)\n    {\n        _1931 = _1899.y > _1784.w;\n    }\n    else\n    {\n        _1931 = _1922;\n    }\n    if (_1931)\n    {\n        return 1.0;\n    }\n    float _1937 = _1677.x;\n    float _1939;\n    if (_1937 > 0.0)\n    {\n        _1939 = _1937;\n    }\n    else\n    {\n        _1939 = 1.5 * _1801;\n    }\n    float2 param_10 = _1899;\n    float4 param_11 = _1784;\n    float param_12 = _1881 - (_1939 * (1.0 + (0.5 * _1852)));\n    float param_13 = _1801;\n    float param_14 = 1.0;\n    float param_15 = _1789.z * 0.25;\n    float param_16 = (_1801 * fast::min(_1852, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1884, _1789.z);\n    int param_18 = int(_1672.z + 0.5);\n    float param_19 = _1672.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1231, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _491, thread float4& gl_FragCoord, constant fa_shadows& _1231, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3101 = fa_lm.z > 0.5;\n    bool _3107;\n    if (_3101)\n    {\n        int param = li;\n        _3107 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3107 = _3101;\n    }\n    if (_3107)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3129 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _4221 = _3129.direction;\n    float3 _4216 = _3129.color;\n    float _4223 = _3129.attenuation;\n    float _4218 = _3129.shadow;\n    int _4226 = _3129.type;\n    if ((_4226 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4221;\n        float _3143 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _491, gl_FragCoord, _1231, fa_shadow_tex, fa_world_pos);\n        _4218 = _3143;\n        _4216 *= _3143;\n    }\n    else\n    {\n        bool _3154 = _4226 != 0;\n        bool _3160;\n        if (_3154)\n        {\n            _3160 = _4223 > 0.0;\n        }\n        else\n        {\n            _3160 = _3154;\n        }\n        if (_3160)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4221;\n            float _3172 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _491, gl_FragCoord, _1231, fa_shadow_tex);\n            _4218 = _3172;\n            _4216 *= _3172;\n        }\n    }\n    return LightSample{ _4221, _4216, _4223, _4218, _3129._distance, _4226 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1231)\n{\n    if (_1231.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2188 = int(_1231.fa_shadow_cfg.x + 0.5);\n    float _2198 = dot(world - _1231.fa_shadow_eye.xyz, _1231.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2203 = _2188 > 0;\n    bool _2212;\n    if (_2203)\n    {\n        int param = _2188 - 1;\n        _2212 = _2198 <= fa_shadow_split_at(param, _1231);\n    }\n    else\n    {\n        _2212 = _2203;\n    }\n    if (_2212)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2219 = _2188 > 1;\n        bool _2226;\n        if (_2219)\n        {\n            _2226 = _2198 > _1231.fa_shadow_split.x;\n        }\n        else\n        {\n            _2226 = _2219;\n        }\n        if (_2226)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2232 = _2188 > 2;\n        bool _2239;\n        if (_2232)\n        {\n            _2239 = _2198 > _1231.fa_shadow_split.y;\n        }\n        else\n        {\n            _2239 = _2232;\n        }\n        if (_2239)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2245 = _2188 > 3;\n        bool _2252;\n        if (_2245)\n        {\n            _2252 = _2198 > _1231.fa_shadow_split.z;\n        }\n        else\n        {\n            _2252 = _2245;\n        }\n        if (_2252)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _491 [[buffer(1)]], constant fa_shadows& _1231 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3925 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3925 = -_3925;\n    }\n    float3 _3560 = fast::normalize(_491.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _491, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3925, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3560, short(gl_FrontFacing) };\n    Surface _3568 = fa_standard_surface(param_1, _491, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3964 = _3568.albedo;\n    float _3965 = _3568.alpha;\n    float3 _3966 = _3568.normal;\n    float _3967 = _3568.metallic;\n    float _3968 = _3568.roughness;\n    float _3969 = _3568.occlusion;\n    float3 _3970 = _3568.emission;\n    float _3971 = _3568.clearcoat;\n    float _3972 = _3568.clearcoat_roughness;\n    float3 _3973 = _3568.sheen_color;\n    float _3974 = _3568.sheen_roughness;\n    float _3975 = _3568.anisotropy;\n    float _3976 = _3568.anisotropy_rotation;\n    float _3977 = _3568.specular;\n    float _3978 = _3568.ior;\n    float3 _3979 = _3568.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3925, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3560, short(gl_FrontFacing) };\n    Surface param_3 = _3568;\n    surface(param_2, param_3);\n    _3964 = param_3.albedo;\n    _3965 = param_3.alpha;\n    _3966 = param_3.normal;\n    _3967 = param_3.metallic;\n    _3968 = param_3.roughness;\n    _3969 = param_3.occlusion;\n    _3970 = param_3.emission;\n    _3971 = param_3.clearcoat;\n    _3972 = param_3.clearcoat_roughness;\n    _3973 = param_3.sheen_color;\n    _3974 = param_3.sheen_roughness;\n    _3975 = param_3.anisotropy;\n    _3976 = param_3.anisotropy_rotation;\n    _3977 = param_3.specular;\n    _3978 = param_3.ior;\n    _3979 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _3925;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _491, fa_decal_tex, fa_env_smp);\n    _3964 = param_6;\n    _3966 = param_7;\n    float3 result;\n    if (_491.fa_emissive.w > 0.5)\n    {\n        result = _3964;\n    }\n    else\n    {\n        float3 _3606 = _3966;\n        float3 _3607 = fast::normalize(_3606);\n        _3966 = _3607;\n        float3 param_8 = _3607;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _3925, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3560, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _3964, _3965, _3966, _3967, _3968, _3969, _3970, _3971, _3972, _3973, _3974, _3975, _3976, _3977, _3978, _3979 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _491, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11, _491, fa_env_smp, fa_env_tex);\n        int _3626 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3626; ln++)\n        {\n            int param_12 = ln;\n            int _3639 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _491, fa_cl_ndir, fa_cl_slot);\n            bool _3642 = in.fa_lm.z > 0.5;\n            bool _3648;\n            if (_3642)\n            {\n                int param_13 = _3639;\n                _3648 = fa_light_baked(param_13, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _3648 = _3642;\n            }\n            if (_3648)\n            {\n                continue;\n            }\n            int param_14 = _3639;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _3925;\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _3925, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3560, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _3964, _3965, _3966, _3967, _3968, _3969, _3970, _3971, _3972, _3973, _3974, _3975, _3976, _3977, _3978, _3979 };\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16, fa_light_tex, fa_shadow_smp, _491, gl_FragCoord, _1231, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _3675 = result;\n    float3 _3676 = _3675 + _3970;\n    result = _3676;\n    float3 param_20 = _3676;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _1231);\n    bool _3685 = _491.fa_fog.w > 0.0;\n    bool _3692;\n    if (!_3685)\n    {\n        _3692 = _491.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3692 = _3685;\n    }\n    if (_3692)\n    {\n        float3 _3701 = in.fa_world_pos - _491.fa_camera_pos.xyz;\n        float _3707 = dot(_3701, _491.fa_fog_c.xyz);\n        bool _3711 = _491.fa_fog_c.w > 0.5;\n        float _3712;\n        if (_3711)\n        {\n            _3712 = _3707;\n        }\n        else\n        {\n            _3712 = length(_3701);\n        }\n        float _3724 = _3712 - _491.fa_fog_b.x;\n        if (_3724 > 0.0)\n        {\n            float _3733 = _491.fa_fog.w * _3724;\n            float tau = _3733 * _3733;\n            if (_491.fa_fog_b.y > 0.0)\n            {\n                float _3749;\n                if (_3711)\n                {\n                    _3749 = in.fa_world_pos.y - (_491.fa_fog_c.y * _3707);\n                }\n                else\n                {\n                    _3749 = _491.fa_camera_pos.y;\n                }\n                float _3770 = mix(_3749, in.fa_world_pos.y, fast::clamp(_491.fa_fog_b.x / _3712, 0.0, 1.0));\n                float _3774 = in.fa_world_pos.y - _3770;\n                float _3779 = _3770 - _491.fa_fog_b.z;\n                float _3784 = in.fa_world_pos.y - _491.fa_fog_b.z;\n                bool _3787 = _3779 <= 0.0;\n                bool _3788 = !_3787;\n                bool _3794;\n                if (_3788)\n                {\n                    _3794 = _491.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3794 = _3787;\n                }\n                float _3795;\n                if (_3794)\n                {\n                    _3795 = _491.fa_fog_b.y;\n                }\n                else\n                {\n                    _3795 = _491.fa_fog_b.y * exp(-fast::min(_491.fa_fog_b.w * _3779, 80.0));\n                }\n                bool _3822;\n                if (_3788)\n                {\n                    _3822 = _491.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3822 = _3787;\n                }\n                float _3823;\n                if (_3822)\n                {\n                    _3823 = _491.fa_fog_b.y * _3779;\n                }\n                else\n                {\n                    _3823 = (_491.fa_fog_b.y * (1.0 - exp(-fast::min(_491.fa_fog_b.w * _3779, 80.0)))) / _491.fa_fog_b.w;\n                }\n                bool _3848 = _3784 <= 0.0;\n                bool _3855;\n                if (!_3848)\n                {\n                    _3855 = _491.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3855 = _3848;\n                }\n                float _3856;\n                if (_3855)\n                {\n                    _3856 = _491.fa_fog_b.y * _3784;\n                }\n                else\n                {\n                    _3856 = (_491.fa_fog_b.y * (1.0 - exp(-fast::min(_491.fa_fog_b.w * _3784, 80.0)))) / _491.fa_fog_b.w;\n                }\n                float _3883;\n                if (abs(_3774) < 0.001000000047497451305389404296875)\n                {\n                    _3883 = _3795;\n                }\n                else\n                {\n                    _3883 = (_3856 - _3823) / _3774;\n                }\n                tau += (_3724 * fast::max(_3883, 0.0));\n            }\n            result = mix(result, _491.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3965);\n    return out;\n}\n\n",
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
            "inst_name": "_491",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1231",
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
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 10
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
