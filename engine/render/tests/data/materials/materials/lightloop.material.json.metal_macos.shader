{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "3995aa0ba56be221fe15f8a0d00a1f706ae46d0f598c3711968fac755bdd80f5",
  "slang": "metal_macos",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _273 = _160.world_pos;\n    float4 _167 = float4(_273, 1.0);\n    fa_world_pos = _273;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_shadow_pos = _131.fa_light_vp * _167;\n    gl_Position = _131.fa_view_proj * _167;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float skyAmount;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nconstant spvUnsafeArray<float, 63> _743 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1517 = fa_linear_to_srgb(param);\n        c = _1517;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1525 = fa_srgb_to_linear(param_1);\n            c = _1525;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _145;\n    if (bool(i.front_facing))\n    {\n        _145 = i.world_normal;\n    }\n    else\n    {\n        _145 = -i.world_normal;\n    }\n    float3 _169 = fast::normalize(i.world_tangent.xyz - (_145 * dot(_145, i.world_tangent.xyz)));\n    float3 _197 = fast::normalize(((_169 * m.x) + ((cross(_145, _169) * i.world_tangent.w) * m.y)) + (_145 * m.z));\n    float3 _200;\n    if (bool(i.front_facing))\n    {\n        _200 = _197;\n    }\n    else\n    {\n        _200 = -_197;\n    }\n    return _200;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _335, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _335.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1557 = fa_tex_fix(param_2, param_3);\n    float4 _2451 = base_t;\n    _2451.x = _1557.x;\n    _2451.y = _1557.y;\n    _2451.z = _1557.z;\n    base_t = _2451;\n    float4 _1571 = (_2451 * _335.fa_base_color) * i.vertex_color;\n    float3 _2394 = i.world_normal;\n    if (_335.fa_maps.z > 0.5)\n    {\n        float param_4 = _335.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1604 = fa_tex_fix(param_6, param_7);\n        float3 _1607 = (_1604 * 2.0) - float3(1.0);\n        float2 _1612 = _1607.xy * _335.fa_maps.x;\n        float3 _2459 = _1607;\n        _2459.x = _1612.x;\n        _2459.y = _1612.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2459;\n        _2394 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _335.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1641 = fa_tex_fix(param_12, param_13);\n    float4 _2462 = mrt;\n    _2462.x = _1641.x;\n    _2462.y = _1641.y;\n    _2462.z = _1641.z;\n    mrt = _2462;\n    float4 _1669 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _335.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _1669.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1681 = fa_tex_fix(param_16, param_17);\n    float param_18 = _335.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1711 = fa_tex_fix(param_20, param_21);\n    float _2399 = _335.fa_layers_a.x;\n    float _2400 = _335.fa_layers_a.y;\n    float _2403 = _335.fa_layers_a.z;\n    float _2402 = _335.fa_layers_b.w;\n    float _2405 = _335.fa_layers_c.x;\n    if (_335.fa_layers_c.z > 0.5)\n    {\n        if (mod(_335.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2399 *= _1681.y;\n            _2400 *= _1681.z;\n            _2402 *= _1669.w;\n        }\n        if (_335.fa_layers_c.z > 1.5)\n        {\n            _2403 *= mrt.x;\n            _2405 *= mrt.w;\n        }\n    }\n    return Surface{ _1571.xyz, _1571.w, _2394, fast::clamp(_335.fa_pbr.x * _1641.z, 0.0, 1.0), fast::clamp(_335.fa_pbr.y * _1641.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_335.fa_maps.y * (_1681.x - 1.0)), _335.fa_emissive.xyz + (_335.fa_model_emissive.xyz * _1711), _2399, _2400, _335.fa_layers_b.xyz, _2402, _2403, _335.fa_layers_a.w, _2405, _335.fa_layers_c.y, _335.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(constant fa_mesh_fs_params& _335)\n{\n    return min(int(_335.fa_counts.x), 32);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_no_light()\n{\n    return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, 0 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _217)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _228 = _217.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_228)\n    {\n        l = fast::normalize(_217.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _246 = _217.fa_light_pos[li].xyz - world_pos;\n        float _248 = length(_246);\n        dist = _248;\n        l = _246 / float3(fast::max(_248, 9.9999997473787516355514526367188e-05));\n        float _264 = _248 / fast::max(_217.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _270 = fast::clamp(1.0 - (_264 * _264), 0.0, 1.0);\n        atten = _270 * _270;\n        if (_217.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_217.fa_light_dir[li].w, mix(_217.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_217.fa_light_dir[li].xyz)));\n        }\n    }\n    int _321;\n    if (_228)\n    {\n        _321 = 0;\n    }\n    else\n    {\n        _321 = (_217.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _217.fa_light_color[li].xyz * atten, atten, 1.0, dist, _321 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_unshadowed(thread const int& n, thread const SurfaceInput& i, constant fa_lights& _217, constant fa_mesh_fs_params& _335)\n{\n    bool _1358 = n < 0;\n    bool _1365;\n    if (!_1358)\n    {\n        _1365 = n >= fa_light_count(_335);\n    }\n    else\n    {\n        _1365 = _1358;\n    }\n    if (_1365)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    float3 param_1 = i.world_pos;\n    return fa_light_sample(param, param_1, _217);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_pcf(thread const float4& coord, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _335, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_335.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _348 = coord.xyz / float3(coord.w);\n    float3 p = _348;\n    float2 suv = (_348.xy * 0.5) + float2(0.5);\n    if (_335.fa_counts.z > 0.5)\n    {\n        float3 _2426 = p;\n        _2426.z = (_2426.z * 0.5) + 0.5;\n        p = _2426;\n    }\n    else\n    {\n        float2 _2429 = suv;\n        _2429.y = 1.0 - _2429.y;\n        suv = _2429;\n    }\n    bool _376 = suv.x < 0.0;\n    bool _383;\n    if (!_376)\n    {\n        _383 = suv.x > 1.0;\n    }\n    else\n    {\n        _383 = _376;\n    }\n    bool _390;\n    if (!_383)\n    {\n        _390 = suv.y < 0.0;\n    }\n    else\n    {\n        _390 = _383;\n    }\n    bool _397;\n    if (!_390)\n    {\n        _397 = suv.y > 1.0;\n    }\n    else\n    {\n        _397 = _390;\n    }\n    bool _404;\n    if (!_397)\n    {\n        _404 = p.z > 1.0;\n    }\n    else\n    {\n        _404 = _397;\n    }\n    if (_404)\n    {\n        return 1.0;\n    }\n    float _419 = _335.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _419) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _335.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _335, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2, _335, fa_shadow_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_lights& _217, constant fa_mesh_fs_params& _335, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1296 = fa_light_sample(param, param_1, _217);\n    float3 _2370 = _1296.direction;\n    float3 _2365 = _1296.color;\n    float _2372 = _1296.attenuation;\n    float _2367 = _1296.shadow;\n    int _2375 = _1296.type;\n    if ((_2375 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2370;\n        float _1310 = fa_shadow_factor(param_2, param_3, _335, fa_shadow_tex, fa_shadow_smp, fa_shadow_pos);\n        _2367 = _1310;\n        _2365 = _217.fa_light_color[li].xyz * (_2372 * _1310);\n    }\n    return LightSample{ _2370, _2365, _2372, _2367, _1296._distance, _2375 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& n, thread const SurfaceInput& i, constant fa_lights& _217, constant fa_mesh_fs_params& _335, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    bool _1334 = n < 0;\n    bool _1341;\n    if (!_1334)\n    {\n        _1341 = n >= fa_light_count(_335);\n    }\n    else\n    {\n        _1341 = _1334;\n    }\n    if (_1341)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    float3 param_1 = i.world_pos;\n    float3 param_2 = i.world_normal;\n    return fa_light_shadowed(param, param_1, param_2, _217, _335, fa_shadow_tex, fa_shadow_smp, fa_shadow_pos);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _668 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _676 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _679 = int(_668);\n    int _682 = int(_676);\n    float _692 = _676 - float(_682);\n    int _748 = (_679 * 9) + _682;\n    int _768 = ((_679 + 1) * 9) + _682;\n    return mix(mix(_743[_748], _743[_748 + 1], _692), mix(_743[_768], _743[_768 + 1], _692), _668 - float(_679));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _2244 = false;\n    float _2245 = 1.0;\n    float _2246 = 1.0;\n    float _2247 = 1.0;\n    float _2248 = 0.0;\n    float _2249 = 0.0;\n    float _2250 = 0.0;\n    float _2251 = 0.0;\n    float _2253 = 1.0;\n    bool _2254 = false;\n    float3 _2255 = float3(0.0);\n    float _2256 = 1.0;\n    float _2257 = 1.0;\n    float _2258 = 1.0;\n    float _2259 = 0.0;\n    float _2260 = 0.0;\n    float3 _2261 = float3(1.0, 0.0, 0.0);\n    float3 _2262 = float3(0.0, 0.0, 1.0);\n    float _2263 = 1.0;\n    float _2264 = 1.0;\n    float _830 = fast::clamp(s.specular, 0.0, 1.0);\n    float _835 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _840 = (_830 != 1.0) || (_835 != 1.5);\n    bool _850;\n    if (!_840)\n    {\n        _850 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _850 = _840;\n    }\n    if (_850)\n    {\n        float _858 = (_835 - 1.0) / (_835 + 1.0);\n        f0 = mix(fast::min(float3(_858 * _858) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _830, s.albedo, float3(metallic));\n        _2245 = mix(_830, 1.0, metallic);\n        _2244 = true;\n    }\n    float _886 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_886 > 0.0)\n    {\n        float _894 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _2248 = _886;\n        _2249 = _894;\n        float _901 = _894 * _894;\n        _2250 = _901;\n        _2251 = _901 * _901;\n        float _913 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _2253 = _913;\n        _2246 = 1.0 - (_886 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(1.0 - _913, 5.0))));\n        _2244 = true;\n    }\n    float3 _932 = fast::max(s.sheen_color, float3(0.0));\n    float _941 = fast::max(_932.x, fast::max(_932.y, _932.z));\n    if (_941 > 0.0)\n    {\n        float _949 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _2254 = true;\n        _2255 = _932;\n        _2256 = _949;\n        _2257 = _949 * _949;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _949;\n        float _966 = fa_sheen_albedo(param, param_1);\n        _2259 = _966;\n        _2258 = 1.0 - fast::min(_941 * _966, 1.0);\n        _2244 = true;\n    }\n    _2247 = _2246 * _2258;\n    float _985 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_985 != 0.0)\n    {\n        float3 _1000 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1000;\n        if (dot(_1000, _1000) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _1018 = t;\n        float3 _1019 = fast::normalize(_1018);\n        t = _1019;\n        float3 _1044 = fast::normalize((_1019 * cos(s.anisotropy_rotation)) + ((cross(n, _1019) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _2261 = _1044;\n        _2262 = cross(n, _1044);\n        float _1054 = roughness * roughness;\n        float _1060 = mix(_1054, 1.0, _985 * _985);\n        bool _1062 = _985 > 0.0;\n        _2263 = _1062 ? _1060 : _1054;\n        _2264 = _1062 ? _1054 : _1060;\n        _2260 = _985;\n        _2244 = true;\n    }\n    return FaLayers{ short(_2244), _2245, _2246, _2247, _2248, _2249, _2250, _2251, i.world_normal, _2253, short(_2254), _2255, _2256, _2257, _2258, _2259, _2260, _2261, _2262, _2263, _2264 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _598 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _601 = _598.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_601 * _601, exp2((-9.27999973297119140625) * ndv)) * _601) + _598.y)) + _598.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _335, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_335.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _335.fa_env_horizon.w)).xyz;\n    }\n    float _519 = rough * rough;\n    float _550 = 0.60000002384185791015625 * _519;\n    return mix(mix(_335.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_335.fa_env_horizon.xyz, _335.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _519)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _550, 0.0500000007450580596923828125 + _550, d.y))), ((_335.fa_env_sky.xyz + _335.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_519 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _335, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _1095;\n        if (L.aniso >= 0.0)\n        {\n            _1095 = L.b;\n        }\n        else\n        {\n            _1095 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_1095, v), _1095), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1128 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _335, fa_env_tex, fa_env_smp) * ((f0 * _1128.x) + (float3(L.f90) * _1128.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _335, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1183 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _335, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _1183.x) + _1183.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _335, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _640 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _335, fa_env_tex, fa_env_smp) * ((f0 * _640.x) + float3(_640.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _335, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float _1222 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _1226 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _1233 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_1222));\n    float3 f0 = _1233;\n    float3 _1237 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _1237;\n    float3 param_3 = i.view_dir;\n    float param_4 = _1222;\n    float param_5 = _1226;\n    float3 param_6 = _1233;\n    FaLayers _1254 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_1254.on)\n    {\n        FaLayers param_7 = _1254;\n        float3 param_8 = _1237;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _1226;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _335, fa_env_tex, fa_env_smp) * s.occlusion;\n    }\n    float3 param_12 = _1237;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _1226;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _335, fa_env_tex, fa_env_smp) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lighting(thread const SurfaceInput& i, thread const Surface& s, constant fa_lights& _217, constant fa_mesh_fs_params& _335, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos, texturecube<float> fa_env_tex, sampler fa_env_smp, constant fa_material& _1445)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(_335); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _1402 = dot(fa_light_unshadowed(param, param_1, _217, _335).color, float3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_1402 > bestPower)\n        {\n            bestPower = _1402;\n            best = n;\n        }\n    }\n    float3 lit = (_335.fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _1431 = fa_light(param_2, param_3, _217, _335, fa_shadow_tex, fa_shadow_smp, fa_shadow_pos);\n        float _1439;\n        if (dot(s.normal, _1431.direction) > 0.5)\n        {\n            _1439 = 1.0;\n        }\n        else\n        {\n            _1439 = _1445.dark;\n        }\n        lit += ((s.albedo * _1431.color) * _1439);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5, _335, fa_env_tex, fa_env_smp) * _1445.skyAmount);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _335 [[buffer(1)]], constant fa_lights& _217 [[buffer(2)]], constant fa_material& _1445 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2118 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2118 = -_2118;\n    }\n    float3 _1831 = fast::normalize(_335.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _2118, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1831, short(gl_FrontFacing) };\n    Surface _1836 = fa_standard_surface(param, _335, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2149 = _1836.albedo;\n    float _2150 = _1836.alpha;\n    float3 _2151 = _1836.normal;\n    float _2152 = _1836.metallic;\n    float _2153 = _1836.roughness;\n    float _2154 = _1836.occlusion;\n    float3 _2155 = _1836.emission;\n    float _2156 = _1836.clearcoat;\n    float _2157 = _1836.clearcoat_roughness;\n    float3 _2158 = _1836.sheen_color;\n    float _2159 = _1836.sheen_roughness;\n    float _2160 = _1836.anisotropy;\n    float _2161 = _1836.anisotropy_rotation;\n    float _2162 = _1836.specular;\n    float _2163 = _1836.ior;\n    float3 _2164 = _1836.specular_color;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2118, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1831, short(gl_FrontFacing) };\n    Surface param_2 = _1836;\n    surface(param_1, param_2);\n    _2149 = param_2.albedo;\n    _2150 = param_2.alpha;\n    _2151 = param_2.normal;\n    _2152 = param_2.metallic;\n    _2153 = param_2.roughness;\n    _2154 = param_2.occlusion;\n    _2155 = param_2.emission;\n    _2156 = param_2.clearcoat;\n    _2157 = param_2.clearcoat_roughness;\n    _2158 = param_2.sheen_color;\n    _2159 = param_2.sheen_roughness;\n    _2160 = param_2.anisotropy;\n    _2161 = param_2.anisotropy_rotation;\n    _2162 = param_2.specular;\n    _2163 = param_2.ior;\n    _2164 = param_2.specular_color;\n    float3 result;\n    if (_335.fa_emissive.w > 0.5)\n    {\n        result = _2149;\n    }\n    else\n    {\n        float3 _1857 = _2151;\n        float3 _1858 = fast::normalize(_1857);\n        _2151 = _1858;\n        SurfaceInput param_3 = SurfaceInput{ in.fa_world_pos, _2118, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1831, short(gl_FrontFacing) };\n        Surface param_4 = Surface{ _2149, _2150, _1858, _2152, _2153, _2154, _2155, _2156, _2157, _2158, _2159, _2160, _2161, _2162, _2163, _2164 };\n        result = lighting(param_3, param_4, _217, _335, fa_shadow_tex, fa_shadow_smp, in.fa_shadow_pos, fa_env_tex, fa_env_smp, _1445);\n    }\n    result += _2155;\n    bool _1877 = _335.fa_fog.w > 0.0;\n    bool _1884;\n    if (!_1877)\n    {\n        _1884 = _335.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1884 = _1877;\n    }\n    if (_1884)\n    {\n        float3 _1893 = in.fa_world_pos - _335.fa_camera_pos.xyz;\n        float _1899 = dot(_1893, _335.fa_fog_c.xyz);\n        bool _1903 = _335.fa_fog_c.w > 0.5;\n        float _1904;\n        if (_1903)\n        {\n            _1904 = _1899;\n        }\n        else\n        {\n            _1904 = length(_1893);\n        }\n        float _1916 = _1904 - _335.fa_fog_b.x;\n        if (_1916 > 0.0)\n        {\n            float _1925 = _335.fa_fog.w * _1916;\n            float tau = _1925 * _1925;\n            if (_335.fa_fog_b.y > 0.0)\n            {\n                float _1941;\n                if (_1903)\n                {\n                    _1941 = in.fa_world_pos.y - (_335.fa_fog_c.y * _1899);\n                }\n                else\n                {\n                    _1941 = _335.fa_camera_pos.y;\n                }\n                float _1962 = mix(_1941, in.fa_world_pos.y, fast::clamp(_335.fa_fog_b.x / _1904, 0.0, 1.0));\n                float _1966 = in.fa_world_pos.y - _1962;\n                float _1971 = _1962 - _335.fa_fog_b.z;\n                float _1976 = in.fa_world_pos.y - _335.fa_fog_b.z;\n                bool _1979 = _1971 <= 0.0;\n                bool _1980 = !_1979;\n                bool _1986;\n                if (_1980)\n                {\n                    _1986 = _335.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1986 = _1979;\n                }\n                float _1987;\n                if (_1986)\n                {\n                    _1987 = _335.fa_fog_b.y;\n                }\n                else\n                {\n                    _1987 = _335.fa_fog_b.y * exp(-fast::min(_335.fa_fog_b.w * _1971, 80.0));\n                }\n                bool _2014;\n                if (_1980)\n                {\n                    _2014 = _335.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2014 = _1979;\n                }\n                float _2015;\n                if (_2014)\n                {\n                    _2015 = _335.fa_fog_b.y * _1971;\n                }\n                else\n                {\n                    _2015 = (_335.fa_fog_b.y * (1.0 - exp(-fast::min(_335.fa_fog_b.w * _1971, 80.0)))) / _335.fa_fog_b.w;\n                }\n                bool _2040 = _1976 <= 0.0;\n                bool _2047;\n                if (!_2040)\n                {\n                    _2047 = _335.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2047 = _2040;\n                }\n                float _2048;\n                if (_2047)\n                {\n                    _2048 = _335.fa_fog_b.y * _1976;\n                }\n                else\n                {\n                    _2048 = (_335.fa_fog_b.y * (1.0 - exp(-fast::min(_335.fa_fog_b.w * _1976, 80.0)))) / _335.fa_fog_b.w;\n                }\n                float _2075;\n                if (abs(_1966) < 0.001000000047497451305389404296875)\n                {\n                    _2075 = _1987;\n                }\n                else\n                {\n                    _2075 = (_2048 - _2015) / _1966;\n                }\n                tau += (_1916 * fast::max(_2075, 0.0));\n            }\n            result = mix(result, _335.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2150);\n    return out;\n}\n\n",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_217",
            "msl_buffer_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_335",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_1445",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 6,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _394 = _273.world_pos;\n    float4 _280 = float4(_394, 1.0);\n    fa_world_pos = _394;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_shadow_pos = _136.fa_light_vp * _280;\n    gl_Position = _136.fa_view_proj * _280;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float skyAmount;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nconstant spvUnsafeArray<float, 63> _743 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1517 = fa_linear_to_srgb(param);\n        c = _1517;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1525 = fa_srgb_to_linear(param_1);\n            c = _1525;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _145;\n    if (bool(i.front_facing))\n    {\n        _145 = i.world_normal;\n    }\n    else\n    {\n        _145 = -i.world_normal;\n    }\n    float3 _169 = fast::normalize(i.world_tangent.xyz - (_145 * dot(_145, i.world_tangent.xyz)));\n    float3 _197 = fast::normalize(((_169 * m.x) + ((cross(_145, _169) * i.world_tangent.w) * m.y)) + (_145 * m.z));\n    float3 _200;\n    if (bool(i.front_facing))\n    {\n        _200 = _197;\n    }\n    else\n    {\n        _200 = -_197;\n    }\n    return _200;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _335, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _335.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1557 = fa_tex_fix(param_2, param_3);\n    float4 _2451 = base_t;\n    _2451.x = _1557.x;\n    _2451.y = _1557.y;\n    _2451.z = _1557.z;\n    base_t = _2451;\n    float4 _1571 = (_2451 * _335.fa_base_color) * i.vertex_color;\n    float3 _2394 = i.world_normal;\n    if (_335.fa_maps.z > 0.5)\n    {\n        float param_4 = _335.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1604 = fa_tex_fix(param_6, param_7);\n        float3 _1607 = (_1604 * 2.0) - float3(1.0);\n        float2 _1612 = _1607.xy * _335.fa_maps.x;\n        float3 _2459 = _1607;\n        _2459.x = _1612.x;\n        _2459.y = _1612.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2459;\n        _2394 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _335.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1641 = fa_tex_fix(param_12, param_13);\n    float4 _2462 = mrt;\n    _2462.x = _1641.x;\n    _2462.y = _1641.y;\n    _2462.z = _1641.z;\n    mrt = _2462;\n    float4 _1669 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _335.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _1669.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1681 = fa_tex_fix(param_16, param_17);\n    float param_18 = _335.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1711 = fa_tex_fix(param_20, param_21);\n    float _2399 = _335.fa_layers_a.x;\n    float _2400 = _335.fa_layers_a.y;\n    float _2403 = _335.fa_layers_a.z;\n    float _2402 = _335.fa_layers_b.w;\n    float _2405 = _335.fa_layers_c.x;\n    if (_335.fa_layers_c.z > 0.5)\n    {\n        if (mod(_335.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2399 *= _1681.y;\n            _2400 *= _1681.z;\n            _2402 *= _1669.w;\n        }\n        if (_335.fa_layers_c.z > 1.5)\n        {\n            _2403 *= mrt.x;\n            _2405 *= mrt.w;\n        }\n    }\n    return Surface{ _1571.xyz, _1571.w, _2394, fast::clamp(_335.fa_pbr.x * _1641.z, 0.0, 1.0), fast::clamp(_335.fa_pbr.y * _1641.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_335.fa_maps.y * (_1681.x - 1.0)), _335.fa_emissive.xyz + (_335.fa_model_emissive.xyz * _1711), _2399, _2400, _335.fa_layers_b.xyz, _2402, _2403, _335.fa_layers_a.w, _2405, _335.fa_layers_c.y, _335.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(constant fa_mesh_fs_params& _335)\n{\n    return min(int(_335.fa_counts.x), 32);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_no_light()\n{\n    return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, 0 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _217)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _228 = _217.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_228)\n    {\n        l = fast::normalize(_217.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _246 = _217.fa_light_pos[li].xyz - world_pos;\n        float _248 = length(_246);\n        dist = _248;\n        l = _246 / float3(fast::max(_248, 9.9999997473787516355514526367188e-05));\n        float _264 = _248 / fast::max(_217.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _270 = fast::clamp(1.0 - (_264 * _264), 0.0, 1.0);\n        atten = _270 * _270;\n        if (_217.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_217.fa_light_dir[li].w, mix(_217.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_217.fa_light_dir[li].xyz)));\n        }\n    }\n    int _321;\n    if (_228)\n    {\n        _321 = 0;\n    }\n    else\n    {\n        _321 = (_217.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _217.fa_light_color[li].xyz * atten, atten, 1.0, dist, _321 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_unshadowed(thread const int& n, thread const SurfaceInput& i, constant fa_lights& _217, constant fa_mesh_fs_params& _335)\n{\n    bool _1358 = n < 0;\n    bool _1365;\n    if (!_1358)\n    {\n        _1365 = n >= fa_light_count(_335);\n    }\n    else\n    {\n        _1365 = _1358;\n    }\n    if (_1365)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    float3 param_1 = i.world_pos;\n    return fa_light_sample(param, param_1, _217);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_pcf(thread const float4& coord, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _335, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_335.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _348 = coord.xyz / float3(coord.w);\n    float3 p = _348;\n    float2 suv = (_348.xy * 0.5) + float2(0.5);\n    if (_335.fa_counts.z > 0.5)\n    {\n        float3 _2426 = p;\n        _2426.z = (_2426.z * 0.5) + 0.5;\n        p = _2426;\n    }\n    else\n    {\n        float2 _2429 = suv;\n        _2429.y = 1.0 - _2429.y;\n        suv = _2429;\n    }\n    bool _376 = suv.x < 0.0;\n    bool _383;\n    if (!_376)\n    {\n        _383 = suv.x > 1.0;\n    }\n    else\n    {\n        _383 = _376;\n    }\n    bool _390;\n    if (!_383)\n    {\n        _390 = suv.y < 0.0;\n    }\n    else\n    {\n        _390 = _383;\n    }\n    bool _397;\n    if (!_390)\n    {\n        _397 = suv.y > 1.0;\n    }\n    else\n    {\n        _397 = _390;\n    }\n    bool _404;\n    if (!_397)\n    {\n        _404 = p.z > 1.0;\n    }\n    else\n    {\n        _404 = _397;\n    }\n    if (_404)\n    {\n        return 1.0;\n    }\n    float _419 = _335.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _419) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _335.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _335, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2, _335, fa_shadow_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_lights& _217, constant fa_mesh_fs_params& _335, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1296 = fa_light_sample(param, param_1, _217);\n    float3 _2370 = _1296.direction;\n    float3 _2365 = _1296.color;\n    float _2372 = _1296.attenuation;\n    float _2367 = _1296.shadow;\n    int _2375 = _1296.type;\n    if ((_2375 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2370;\n        float _1310 = fa_shadow_factor(param_2, param_3, _335, fa_shadow_tex, fa_shadow_smp, fa_shadow_pos);\n        _2367 = _1310;\n        _2365 = _217.fa_light_color[li].xyz * (_2372 * _1310);\n    }\n    return LightSample{ _2370, _2365, _2372, _2367, _1296._distance, _2375 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& n, thread const SurfaceInput& i, constant fa_lights& _217, constant fa_mesh_fs_params& _335, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    bool _1334 = n < 0;\n    bool _1341;\n    if (!_1334)\n    {\n        _1341 = n >= fa_light_count(_335);\n    }\n    else\n    {\n        _1341 = _1334;\n    }\n    if (_1341)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    float3 param_1 = i.world_pos;\n    float3 param_2 = i.world_normal;\n    return fa_light_shadowed(param, param_1, param_2, _217, _335, fa_shadow_tex, fa_shadow_smp, fa_shadow_pos);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _668 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _676 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _679 = int(_668);\n    int _682 = int(_676);\n    float _692 = _676 - float(_682);\n    int _748 = (_679 * 9) + _682;\n    int _768 = ((_679 + 1) * 9) + _682;\n    return mix(mix(_743[_748], _743[_748 + 1], _692), mix(_743[_768], _743[_768 + 1], _692), _668 - float(_679));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _2244 = false;\n    float _2245 = 1.0;\n    float _2246 = 1.0;\n    float _2247 = 1.0;\n    float _2248 = 0.0;\n    float _2249 = 0.0;\n    float _2250 = 0.0;\n    float _2251 = 0.0;\n    float _2253 = 1.0;\n    bool _2254 = false;\n    float3 _2255 = float3(0.0);\n    float _2256 = 1.0;\n    float _2257 = 1.0;\n    float _2258 = 1.0;\n    float _2259 = 0.0;\n    float _2260 = 0.0;\n    float3 _2261 = float3(1.0, 0.0, 0.0);\n    float3 _2262 = float3(0.0, 0.0, 1.0);\n    float _2263 = 1.0;\n    float _2264 = 1.0;\n    float _830 = fast::clamp(s.specular, 0.0, 1.0);\n    float _835 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _840 = (_830 != 1.0) || (_835 != 1.5);\n    bool _850;\n    if (!_840)\n    {\n        _850 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _850 = _840;\n    }\n    if (_850)\n    {\n        float _858 = (_835 - 1.0) / (_835 + 1.0);\n        f0 = mix(fast::min(float3(_858 * _858) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _830, s.albedo, float3(metallic));\n        _2245 = mix(_830, 1.0, metallic);\n        _2244 = true;\n    }\n    float _886 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_886 > 0.0)\n    {\n        float _894 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _2248 = _886;\n        _2249 = _894;\n        float _901 = _894 * _894;\n        _2250 = _901;\n        _2251 = _901 * _901;\n        float _913 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _2253 = _913;\n        _2246 = 1.0 - (_886 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(1.0 - _913, 5.0))));\n        _2244 = true;\n    }\n    float3 _932 = fast::max(s.sheen_color, float3(0.0));\n    float _941 = fast::max(_932.x, fast::max(_932.y, _932.z));\n    if (_941 > 0.0)\n    {\n        float _949 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _2254 = true;\n        _2255 = _932;\n        _2256 = _949;\n        _2257 = _949 * _949;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _949;\n        float _966 = fa_sheen_albedo(param, param_1);\n        _2259 = _966;\n        _2258 = 1.0 - fast::min(_941 * _966, 1.0);\n        _2244 = true;\n    }\n    _2247 = _2246 * _2258;\n    float _985 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_985 != 0.0)\n    {\n        float3 _1000 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1000;\n        if (dot(_1000, _1000) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _1018 = t;\n        float3 _1019 = fast::normalize(_1018);\n        t = _1019;\n        float3 _1044 = fast::normalize((_1019 * cos(s.anisotropy_rotation)) + ((cross(n, _1019) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _2261 = _1044;\n        _2262 = cross(n, _1044);\n        float _1054 = roughness * roughness;\n        float _1060 = mix(_1054, 1.0, _985 * _985);\n        bool _1062 = _985 > 0.0;\n        _2263 = _1062 ? _1060 : _1054;\n        _2264 = _1062 ? _1054 : _1060;\n        _2260 = _985;\n        _2244 = true;\n    }\n    return FaLayers{ short(_2244), _2245, _2246, _2247, _2248, _2249, _2250, _2251, i.world_normal, _2253, short(_2254), _2255, _2256, _2257, _2258, _2259, _2260, _2261, _2262, _2263, _2264 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _598 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _601 = _598.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_601 * _601, exp2((-9.27999973297119140625) * ndv)) * _601) + _598.y)) + _598.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _335, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_335.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _335.fa_env_horizon.w)).xyz;\n    }\n    float _519 = rough * rough;\n    float _550 = 0.60000002384185791015625 * _519;\n    return mix(mix(_335.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_335.fa_env_horizon.xyz, _335.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _519)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _550, 0.0500000007450580596923828125 + _550, d.y))), ((_335.fa_env_sky.xyz + _335.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_519 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _335, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _1095;\n        if (L.aniso >= 0.0)\n        {\n            _1095 = L.b;\n        }\n        else\n        {\n            _1095 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_1095, v), _1095), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1128 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _335, fa_env_tex, fa_env_smp) * ((f0 * _1128.x) + (float3(L.f90) * _1128.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _335, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1183 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _335, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _1183.x) + _1183.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _335, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _640 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _335, fa_env_tex, fa_env_smp) * ((f0 * _640.x) + float3(_640.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _335, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float _1222 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _1226 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _1233 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_1222));\n    float3 f0 = _1233;\n    float3 _1237 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _1237;\n    float3 param_3 = i.view_dir;\n    float param_4 = _1222;\n    float param_5 = _1226;\n    float3 param_6 = _1233;\n    FaLayers _1254 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_1254.on)\n    {\n        FaLayers param_7 = _1254;\n        float3 param_8 = _1237;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _1226;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _335, fa_env_tex, fa_env_smp) * s.occlusion;\n    }\n    float3 param_12 = _1237;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _1226;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _335, fa_env_tex, fa_env_smp) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lighting(thread const SurfaceInput& i, thread const Surface& s, constant fa_lights& _217, constant fa_mesh_fs_params& _335, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos, texturecube<float> fa_env_tex, sampler fa_env_smp, constant fa_material& _1445)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(_335); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _1402 = dot(fa_light_unshadowed(param, param_1, _217, _335).color, float3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_1402 > bestPower)\n        {\n            bestPower = _1402;\n            best = n;\n        }\n    }\n    float3 lit = (_335.fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _1431 = fa_light(param_2, param_3, _217, _335, fa_shadow_tex, fa_shadow_smp, fa_shadow_pos);\n        float _1439;\n        if (dot(s.normal, _1431.direction) > 0.5)\n        {\n            _1439 = 1.0;\n        }\n        else\n        {\n            _1439 = _1445.dark;\n        }\n        lit += ((s.albedo * _1431.color) * _1439);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5, _335, fa_env_tex, fa_env_smp) * _1445.skyAmount);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _335 [[buffer(1)]], constant fa_lights& _217 [[buffer(2)]], constant fa_material& _1445 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2118 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2118 = -_2118;\n    }\n    float3 _1831 = fast::normalize(_335.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _2118, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1831, short(gl_FrontFacing) };\n    Surface _1836 = fa_standard_surface(param, _335, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2149 = _1836.albedo;\n    float _2150 = _1836.alpha;\n    float3 _2151 = _1836.normal;\n    float _2152 = _1836.metallic;\n    float _2153 = _1836.roughness;\n    float _2154 = _1836.occlusion;\n    float3 _2155 = _1836.emission;\n    float _2156 = _1836.clearcoat;\n    float _2157 = _1836.clearcoat_roughness;\n    float3 _2158 = _1836.sheen_color;\n    float _2159 = _1836.sheen_roughness;\n    float _2160 = _1836.anisotropy;\n    float _2161 = _1836.anisotropy_rotation;\n    float _2162 = _1836.specular;\n    float _2163 = _1836.ior;\n    float3 _2164 = _1836.specular_color;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2118, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1831, short(gl_FrontFacing) };\n    Surface param_2 = _1836;\n    surface(param_1, param_2);\n    _2149 = param_2.albedo;\n    _2150 = param_2.alpha;\n    _2151 = param_2.normal;\n    _2152 = param_2.metallic;\n    _2153 = param_2.roughness;\n    _2154 = param_2.occlusion;\n    _2155 = param_2.emission;\n    _2156 = param_2.clearcoat;\n    _2157 = param_2.clearcoat_roughness;\n    _2158 = param_2.sheen_color;\n    _2159 = param_2.sheen_roughness;\n    _2160 = param_2.anisotropy;\n    _2161 = param_2.anisotropy_rotation;\n    _2162 = param_2.specular;\n    _2163 = param_2.ior;\n    _2164 = param_2.specular_color;\n    float3 result;\n    if (_335.fa_emissive.w > 0.5)\n    {\n        result = _2149;\n    }\n    else\n    {\n        float3 _1857 = _2151;\n        float3 _1858 = fast::normalize(_1857);\n        _2151 = _1858;\n        SurfaceInput param_3 = SurfaceInput{ in.fa_world_pos, _2118, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1831, short(gl_FrontFacing) };\n        Surface param_4 = Surface{ _2149, _2150, _1858, _2152, _2153, _2154, _2155, _2156, _2157, _2158, _2159, _2160, _2161, _2162, _2163, _2164 };\n        result = lighting(param_3, param_4, _217, _335, fa_shadow_tex, fa_shadow_smp, in.fa_shadow_pos, fa_env_tex, fa_env_smp, _1445);\n    }\n    result += _2155;\n    bool _1877 = _335.fa_fog.w > 0.0;\n    bool _1884;\n    if (!_1877)\n    {\n        _1884 = _335.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1884 = _1877;\n    }\n    if (_1884)\n    {\n        float3 _1893 = in.fa_world_pos - _335.fa_camera_pos.xyz;\n        float _1899 = dot(_1893, _335.fa_fog_c.xyz);\n        bool _1903 = _335.fa_fog_c.w > 0.5;\n        float _1904;\n        if (_1903)\n        {\n            _1904 = _1899;\n        }\n        else\n        {\n            _1904 = length(_1893);\n        }\n        float _1916 = _1904 - _335.fa_fog_b.x;\n        if (_1916 > 0.0)\n        {\n            float _1925 = _335.fa_fog.w * _1916;\n            float tau = _1925 * _1925;\n            if (_335.fa_fog_b.y > 0.0)\n            {\n                float _1941;\n                if (_1903)\n                {\n                    _1941 = in.fa_world_pos.y - (_335.fa_fog_c.y * _1899);\n                }\n                else\n                {\n                    _1941 = _335.fa_camera_pos.y;\n                }\n                float _1962 = mix(_1941, in.fa_world_pos.y, fast::clamp(_335.fa_fog_b.x / _1904, 0.0, 1.0));\n                float _1966 = in.fa_world_pos.y - _1962;\n                float _1971 = _1962 - _335.fa_fog_b.z;\n                float _1976 = in.fa_world_pos.y - _335.fa_fog_b.z;\n                bool _1979 = _1971 <= 0.0;\n                bool _1980 = !_1979;\n                bool _1986;\n                if (_1980)\n                {\n                    _1986 = _335.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1986 = _1979;\n                }\n                float _1987;\n                if (_1986)\n                {\n                    _1987 = _335.fa_fog_b.y;\n                }\n                else\n                {\n                    _1987 = _335.fa_fog_b.y * exp(-fast::min(_335.fa_fog_b.w * _1971, 80.0));\n                }\n                bool _2014;\n                if (_1980)\n                {\n                    _2014 = _335.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2014 = _1979;\n                }\n                float _2015;\n                if (_2014)\n                {\n                    _2015 = _335.fa_fog_b.y * _1971;\n                }\n                else\n                {\n                    _2015 = (_335.fa_fog_b.y * (1.0 - exp(-fast::min(_335.fa_fog_b.w * _1971, 80.0)))) / _335.fa_fog_b.w;\n                }\n                bool _2040 = _1976 <= 0.0;\n                bool _2047;\n                if (!_2040)\n                {\n                    _2047 = _335.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2047 = _2040;\n                }\n                float _2048;\n                if (_2047)\n                {\n                    _2048 = _335.fa_fog_b.y * _1976;\n                }\n                else\n                {\n                    _2048 = (_335.fa_fog_b.y * (1.0 - exp(-fast::min(_335.fa_fog_b.w * _1976, 80.0)))) / _335.fa_fog_b.w;\n                }\n                float _2075;\n                if (abs(_1966) < 0.001000000047497451305389404296875)\n                {\n                    _2075 = _1987;\n                }\n                else\n                {\n                    _2075 = (_2048 - _2015) / _1966;\n                }\n                tau += (_1916 * fast::max(_2075, 0.0));\n            }\n            result = mix(result, _335.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2150);\n    return out;\n}\n\n",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_217",
            "msl_buffer_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_335",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_1445",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 6,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    float4 _241 = (_783 * _213.fa_base_color) * i.vertex_color;\n    float3 _746 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = _213.fa_layers_a.x;\n    float _752 = _213.fa_layers_a.y;\n    float _755 = _213.fa_layers_a.z;\n    float _754 = _213.fa_layers_b.w;\n    float _757 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _746, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _751, _752, _213.fa_layers_b.xyz, _754, _755, _213.fa_layers_a.w, _757, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _657 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    float3 _517 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _657, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _517, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _657, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _517, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _532 = fast::normalize(param_2.normal);\n    float3 _547 = fast::normalize(float3(dot(in.fa_pre_r0, _532), dot(in.fa_pre_r1, _532), dot(in.fa_pre_r2, _532)));\n    float _559 = _547.z;\n    float2 e = _547.xy / float2((abs(_547.x) + abs(_547.y)) + abs(_559));\n    if (_559 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 288,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    float4 _241 = (_783 * _213.fa_base_color) * i.vertex_color;\n    float3 _746 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = _213.fa_layers_a.x;\n    float _752 = _213.fa_layers_a.y;\n    float _755 = _213.fa_layers_a.z;\n    float _754 = _213.fa_layers_b.w;\n    float _757 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _746, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _751, _752, _213.fa_layers_b.xyz, _754, _755, _213.fa_layers_a.w, _757, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _657 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    float3 _517 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _657, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _517, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _657, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _517, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _532 = fast::normalize(param_2.normal);\n    float3 _547 = fast::normalize(float3(dot(in.fa_pre_r0, _532), dot(in.fa_pre_r1, _532), dot(in.fa_pre_r2, _532)));\n    float _559 = _547.z;\n    float2 e = _547.xy / float2((abs(_547.x) + abs(_547.y)) + abs(_559));\n    if (_559 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 288,
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
