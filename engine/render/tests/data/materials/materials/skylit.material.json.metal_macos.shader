{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "3995aa0ba56be221fe15f8a0d00a1f706ae46d0f598c3711968fac755bdd80f5",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _270 = _160.world_pos;\n    float4 _167 = float4(_270, 1.0);\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_shadow_pos = _131.fa_light_vp * _167;\n    gl_Position = _131.fa_view_proj * _167;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nconstant spvUnsafeArray<float, 63> _757 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1386 = fa_linear_to_srgb(param);\n        c = _1386;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1394 = fa_srgb_to_linear(param_1);\n            c = _1394;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _142;\n    if (bool(i.front_facing))\n    {\n        _142 = i.world_normal;\n    }\n    else\n    {\n        _142 = -i.world_normal;\n    }\n    float3 _166 = fast::normalize(i.world_tangent.xyz - (_142 * dot(_142, i.world_tangent.xyz)));\n    float3 _194 = fast::normalize(((_166 * m.x) + ((cross(_142, _166) * i.world_tangent.w) * m.y)) + (_142 * m.z));\n    float3 _197;\n    if (bool(i.front_facing))\n    {\n        _197 = _194;\n    }\n    else\n    {\n        _197 = -_194;\n    }\n    return _197;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _331, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _331.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1426 = fa_tex_fix(param_2, param_3);\n    float4 _2384 = base_t;\n    _2384.x = _1426.x;\n    _2384.y = _1426.y;\n    _2384.z = _1426.z;\n    base_t = _2384;\n    float4 _1440 = (_2384 * _331.fa_base_color) * i.vertex_color;\n    float3 _2327 = i.world_normal;\n    if (_331.fa_maps.z > 0.5)\n    {\n        float param_4 = _331.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1473 = fa_tex_fix(param_6, param_7);\n        float3 _1476 = (_1473 * 2.0) - float3(1.0);\n        float2 _1481 = _1476.xy * _331.fa_maps.x;\n        float3 _2392 = _1476;\n        _2392.x = _1481.x;\n        _2392.y = _1481.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2392;\n        _2327 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _331.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1510 = fa_tex_fix(param_12, param_13);\n    float4 _2395 = mrt;\n    _2395.x = _1510.x;\n    _2395.y = _1510.y;\n    _2395.z = _1510.z;\n    mrt = _2395;\n    float4 _1538 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _331.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _1538.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1550 = fa_tex_fix(param_16, param_17);\n    float param_18 = _331.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1580 = fa_tex_fix(param_20, param_21);\n    float _2332 = _331.fa_layers_a.x;\n    float _2333 = _331.fa_layers_a.y;\n    float _2336 = _331.fa_layers_a.z;\n    float _2335 = _331.fa_layers_b.w;\n    float _2338 = _331.fa_layers_c.x;\n    if (_331.fa_layers_c.z > 0.5)\n    {\n        if (mod(_331.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2332 *= _1550.y;\n            _2333 *= _1550.z;\n            _2335 *= _1538.w;\n        }\n        if (_331.fa_layers_c.z > 1.5)\n        {\n            _2336 *= mrt.x;\n            _2338 *= mrt.w;\n        }\n    }\n    return Surface{ _1440.xyz, _1440.w, _2327, fast::clamp(_331.fa_pbr.x * _1510.z, 0.0, 1.0), fast::clamp(_331.fa_pbr.y * _1510.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_331.fa_maps.y * (_1550.x - 1.0)), _331.fa_emissive.xyz + (_331.fa_model_emissive.xyz * _1580), _2332, _2333, _331.fa_layers_b.xyz, _2335, _2336, _331.fa_layers_a.w, _2338, _331.fa_layers_c.y, _331.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _331, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_331.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _331.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _682 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _690 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _693 = int(_682);\n    int _696 = int(_690);\n    float _706 = _690 - float(_696);\n    int _762 = (_693 * 9) + _696;\n    int _782 = ((_693 + 1) * 9) + _696;\n    return mix(mix(_757[_762], _757[_762 + 1], _706), mix(_757[_782], _757[_782 + 1], _706), _682 - float(_693));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _2199 = false;\n    float _2200 = 1.0;\n    float _2201 = 1.0;\n    float _2202 = 1.0;\n    float _2203 = 0.0;\n    float _2204 = 0.0;\n    float _2205 = 0.0;\n    float _2206 = 0.0;\n    float _2208 = 1.0;\n    bool _2209 = false;\n    float3 _2210 = float3(0.0);\n    float _2211 = 1.0;\n    float _2212 = 1.0;\n    float _2213 = 1.0;\n    float _2214 = 0.0;\n    float _2215 = 0.0;\n    float3 _2216 = float3(1.0, 0.0, 0.0);\n    float3 _2217 = float3(0.0, 0.0, 1.0);\n    float _2218 = 1.0;\n    float _2219 = 1.0;\n    float _844 = fast::clamp(s.specular, 0.0, 1.0);\n    float _849 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _854 = (_844 != 1.0) || (_849 != 1.5);\n    bool _864;\n    if (!_854)\n    {\n        _864 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _864 = _854;\n    }\n    if (_864)\n    {\n        float _872 = (_849 - 1.0) / (_849 + 1.0);\n        f0 = mix(fast::min(float3(_872 * _872) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _844, s.albedo, float3(metallic));\n        _2200 = mix(_844, 1.0, metallic);\n        _2199 = true;\n    }\n    float _900 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_900 > 0.0)\n    {\n        float _908 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _2203 = _900;\n        _2204 = _908;\n        float _915 = _908 * _908;\n        _2205 = _915;\n        _2206 = _915 * _915;\n        float _927 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _2208 = _927;\n        _2201 = 1.0 - (_900 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(1.0 - _927, 5.0))));\n        _2199 = true;\n    }\n    float3 _946 = fast::max(s.sheen_color, float3(0.0));\n    float _955 = fast::max(_946.x, fast::max(_946.y, _946.z));\n    if (_955 > 0.0)\n    {\n        float _963 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _2209 = true;\n        _2210 = _946;\n        _2211 = _963;\n        _2212 = _963 * _963;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _963;\n        float _980 = fa_sheen_albedo(param, param_1);\n        _2214 = _980;\n        _2213 = 1.0 - fast::min(_955 * _980, 1.0);\n        _2199 = true;\n    }\n    _2202 = _2201 * _2213;\n    float _999 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_999 != 0.0)\n    {\n        float3 _1014 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1014;\n        if (dot(_1014, _1014) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _1032 = t;\n        float3 _1033 = fast::normalize(_1032);\n        t = _1033;\n        float3 _1058 = fast::normalize((_1033 * cos(s.anisotropy_rotation)) + ((cross(n, _1033) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _2216 = _1058;\n        _2217 = cross(n, _1058);\n        float _1068 = roughness * roughness;\n        float _1074 = mix(_1068, 1.0, _999 * _999);\n        bool _1076 = _999 > 0.0;\n        _2218 = _1076 ? _1074 : _1068;\n        _2219 = _1076 ? _1068 : _1074;\n        _2215 = _999;\n        _2199 = true;\n    }\n    return FaLayers{ short(_2199), _2200, _2201, _2202, _2203, _2204, _2205, _2206, i.world_normal, _2208, short(_2209), _2210, _2211, _2212, _2213, _2214, _2215, _2216, _2217, _2218, _2219 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _612 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _615 = _612.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_615 * _615, exp2((-9.27999973297119140625) * ndv)) * _615) + _612.y)) + _612.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _331, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_331.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _331.fa_env_horizon.w)).xyz;\n    }\n    float _515 = rough * rough;\n    float _546 = 0.60000002384185791015625 * _515;\n    return mix(mix(_331.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_331.fa_env_horizon.xyz, _331.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _515)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _546, 0.0500000007450580596923828125 + _546, d.y))), ((_331.fa_env_sky.xyz + _331.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_515 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _331, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _1109;\n        if (L.aniso >= 0.0)\n        {\n            _1109 = L.b;\n        }\n        else\n        {\n            _1109 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_1109, v), _1109), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1142 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _331, fa_env_tex, fa_env_smp) * ((f0 * _1142.x) + (float3(L.f90) * _1142.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _331, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1197 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _331, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _1197.x) + _1197.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _331, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _654 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _331, fa_env_tex, fa_env_smp) * ((f0 * _654.x) + float3(_654.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _331, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float _1226 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _1230 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _1237 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_1226));\n    float3 f0 = _1237;\n    float3 _1241 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _1241;\n    float3 param_3 = i.view_dir;\n    float param_4 = _1226;\n    float param_5 = _1230;\n    float3 param_6 = _1237;\n    FaLayers _1258 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_1258.on)\n    {\n        FaLayers param_7 = _1258;\n        float3 param_8 = _1241;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _1230;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _331, fa_env_tex, fa_env_smp) * s.occlusion;\n    }\n    float3 param_12 = _1241;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _1230;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _331, fa_env_tex, fa_env_smp) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor, constant fa_mesh_fs_params& _331, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1, _331, fa_env_tex, fa_env_smp);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _214)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _225 = _214.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_225)\n    {\n        l = fast::normalize(_214.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _243 = _214.fa_light_pos[li].xyz - world_pos;\n        float _245 = length(_243);\n        dist = _245;\n        l = _243 / float3(fast::max(_245, 9.9999997473787516355514526367188e-05));\n        float _261 = _245 / fast::max(_214.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _267 = fast::clamp(1.0 - (_261 * _261), 0.0, 1.0);\n        atten = _267 * _267;\n        if (_214.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_214.fa_light_dir[li].w, mix(_214.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_214.fa_light_dir[li].xyz)));\n        }\n    }\n    int _317;\n    if (_225)\n    {\n        _317 = 0;\n    }\n    else\n    {\n        _317 = (_214.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _214.fa_light_color[li].xyz * atten, atten, 1.0, dist, _317 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_pcf(thread const float4& coord, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _331, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_331.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _344 = coord.xyz / float3(coord.w);\n    float3 p = _344;\n    float2 suv = (_344.xy * 0.5) + float2(0.5);\n    if (_331.fa_counts.z > 0.5)\n    {\n        float3 _2359 = p;\n        _2359.z = (_2359.z * 0.5) + 0.5;\n        p = _2359;\n    }\n    else\n    {\n        float2 _2362 = suv;\n        _2362.y = 1.0 - _2362.y;\n        suv = _2362;\n    }\n    bool _372 = suv.x < 0.0;\n    bool _379;\n    if (!_372)\n    {\n        _379 = suv.x > 1.0;\n    }\n    else\n    {\n        _379 = _372;\n    }\n    bool _386;\n    if (!_379)\n    {\n        _386 = suv.y < 0.0;\n    }\n    else\n    {\n        _386 = _379;\n    }\n    bool _393;\n    if (!_386)\n    {\n        _393 = suv.y > 1.0;\n    }\n    else\n    {\n        _393 = _386;\n    }\n    bool _400;\n    if (!_393)\n    {\n        _400 = p.z > 1.0;\n    }\n    else\n    {\n        _400 = _393;\n    }\n    if (_400)\n    {\n        return 1.0;\n    }\n    float _415 = _331.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _415) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _331.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _331, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2, _331, fa_shadow_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_lights& _214, constant fa_mesh_fs_params& _331, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1300 = fa_light_sample(param, param_1, _214);\n    float3 _2312 = _1300.direction;\n    float3 _2307 = _1300.color;\n    float _2314 = _1300.attenuation;\n    float _2309 = _1300.shadow;\n    int _2317 = _1300.type;\n    if ((_2317 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2312;\n        float _1314 = fa_shadow_factor(param_2, param_3, _331, fa_shadow_tex, fa_shadow_smp, fa_shadow_pos);\n        _2309 = _1314;\n        _2307 = _214.fa_light_color[li].xyz * (_2314 * _1314);\n    }\n    return LightSample{ _2312, _2307, _2314, _2309, _1300._distance, _2317 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _331 [[buffer(1)]], constant fa_lights& _214 [[buffer(2)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2029 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2029 = -_2029;\n    }\n    float3 _1700 = fast::normalize(_331.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _2029, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1700, short(gl_FrontFacing) };\n    Surface _1705 = fa_standard_surface(param, _331, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2068 = _1705.albedo;\n    float _2069 = _1705.alpha;\n    float3 _2070 = _1705.normal;\n    float _2071 = _1705.metallic;\n    float _2072 = _1705.roughness;\n    float _2073 = _1705.occlusion;\n    float3 _2074 = _1705.emission;\n    float _2075 = _1705.clearcoat;\n    float _2076 = _1705.clearcoat_roughness;\n    float3 _2077 = _1705.sheen_color;\n    float _2078 = _1705.sheen_roughness;\n    float _2079 = _1705.anisotropy;\n    float _2080 = _1705.anisotropy_rotation;\n    float _2081 = _1705.specular;\n    float _2082 = _1705.ior;\n    float3 _2083 = _1705.specular_color;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2029, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1700, short(gl_FrontFacing) };\n    Surface param_2 = _1705;\n    surface(param_1, param_2);\n    _2068 = param_2.albedo;\n    _2069 = param_2.alpha;\n    _2070 = param_2.normal;\n    _2071 = param_2.metallic;\n    _2072 = param_2.roughness;\n    _2073 = param_2.occlusion;\n    _2074 = param_2.emission;\n    _2075 = param_2.clearcoat;\n    _2076 = param_2.clearcoat_roughness;\n    _2077 = param_2.sheen_color;\n    _2078 = param_2.sheen_roughness;\n    _2079 = param_2.anisotropy;\n    _2080 = param_2.anisotropy_rotation;\n    _2081 = param_2.specular;\n    _2082 = param_2.ior;\n    _2083 = param_2.specular_color;\n    float3 result;\n    if (_331.fa_emissive.w > 0.5)\n    {\n        result = _2068;\n    }\n    else\n    {\n        float3 _1726 = _2070;\n        float3 _1727 = fast::normalize(_1726);\n        _2070 = _1727;\n        float3 param_3 = _1727;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _2029, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1700, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _2068, _2069, _2070, _2071, _2072, _2073, _2074, _2075, _2076, _2077, _2078, _2079, _2080, _2081, _2082, _2083 };\n        float3 param_6 = fa_ambient_light(param_3, _331, fa_env_smp, fa_irr_tex);\n        float3 lit = ambient(param_4, param_5, param_6, _331, fa_env_tex, fa_env_smp);\n        int _1746 = int(_331.fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1746)\n            {\n                break;\n            }\n            int param_7 = li;\n            float3 param_8 = in.fa_world_pos;\n            float3 param_9 = _2029;\n            SurfaceInput param_10 = SurfaceInput{ in.fa_world_pos, _2029, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1700, short(gl_FrontFacing) };\n            Surface param_11 = Surface{ _2068, _2069, _2070, _2071, _2072, _2073, _2074, _2075, _2076, _2077, _2078, _2079, _2080, _2081, _2082, _2083 };\n            LightSample param_12 = fa_light_shadowed(param_7, param_8, param_9, _214, _331, fa_shadow_tex, fa_shadow_smp, in.fa_shadow_pos);\n            lit += light(param_10, param_11, param_12);\n        }\n        result = lit;\n    }\n    result += _2074;\n    bool _1789 = _331.fa_fog.w > 0.0;\n    bool _1796;\n    if (!_1789)\n    {\n        _1796 = _331.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1796 = _1789;\n    }\n    if (_1796)\n    {\n        float3 _1805 = in.fa_world_pos - _331.fa_camera_pos.xyz;\n        float _1811 = dot(_1805, _331.fa_fog_c.xyz);\n        bool _1815 = _331.fa_fog_c.w > 0.5;\n        float _1816;\n        if (_1815)\n        {\n            _1816 = _1811;\n        }\n        else\n        {\n            _1816 = length(_1805);\n        }\n        float _1828 = _1816 - _331.fa_fog_b.x;\n        if (_1828 > 0.0)\n        {\n            float _1837 = _331.fa_fog.w * _1828;\n            float tau = _1837 * _1837;\n            if (_331.fa_fog_b.y > 0.0)\n            {\n                float _1853;\n                if (_1815)\n                {\n                    _1853 = in.fa_world_pos.y - (_331.fa_fog_c.y * _1811);\n                }\n                else\n                {\n                    _1853 = _331.fa_camera_pos.y;\n                }\n                float _1874 = mix(_1853, in.fa_world_pos.y, fast::clamp(_331.fa_fog_b.x / _1816, 0.0, 1.0));\n                float _1878 = in.fa_world_pos.y - _1874;\n                float _1883 = _1874 - _331.fa_fog_b.z;\n                float _1888 = in.fa_world_pos.y - _331.fa_fog_b.z;\n                bool _1891 = _1883 <= 0.0;\n                bool _1892 = !_1891;\n                bool _1898;\n                if (_1892)\n                {\n                    _1898 = _331.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1898 = _1891;\n                }\n                float _1899;\n                if (_1898)\n                {\n                    _1899 = _331.fa_fog_b.y;\n                }\n                else\n                {\n                    _1899 = _331.fa_fog_b.y * exp(-fast::min(_331.fa_fog_b.w * _1883, 80.0));\n                }\n                bool _1926;\n                if (_1892)\n                {\n                    _1926 = _331.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1926 = _1891;\n                }\n                float _1927;\n                if (_1926)\n                {\n                    _1927 = _331.fa_fog_b.y * _1883;\n                }\n                else\n                {\n                    _1927 = (_331.fa_fog_b.y * (1.0 - exp(-fast::min(_331.fa_fog_b.w * _1883, 80.0)))) / _331.fa_fog_b.w;\n                }\n                bool _1952 = _1888 <= 0.0;\n                bool _1959;\n                if (!_1952)\n                {\n                    _1959 = _331.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1959 = _1952;\n                }\n                float _1960;\n                if (_1959)\n                {\n                    _1960 = _331.fa_fog_b.y * _1888;\n                }\n                else\n                {\n                    _1960 = (_331.fa_fog_b.y * (1.0 - exp(-fast::min(_331.fa_fog_b.w * _1888, 80.0)))) / _331.fa_fog_b.w;\n                }\n                float _1987;\n                if (abs(_1878) < 0.001000000047497451305389404296875)\n                {\n                    _1987 = _1899;\n                }\n                else\n                {\n                    _1987 = (_1960 - _1927) / _1878;\n                }\n                tau += (_1828 * fast::max(_1987, 0.0));\n            }\n            result = mix(result, _331.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2069);\n    return out;\n}\n\n",
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
            "inst_name": "_214",
            "msl_buffer_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_331",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _391 = _273.world_pos;\n    float4 _280 = float4(_391, 1.0);\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_shadow_pos = _136.fa_light_vp * _280;\n    gl_Position = _136.fa_view_proj * _280;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nconstant spvUnsafeArray<float, 63> _757 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1386 = fa_linear_to_srgb(param);\n        c = _1386;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1394 = fa_srgb_to_linear(param_1);\n            c = _1394;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _142;\n    if (bool(i.front_facing))\n    {\n        _142 = i.world_normal;\n    }\n    else\n    {\n        _142 = -i.world_normal;\n    }\n    float3 _166 = fast::normalize(i.world_tangent.xyz - (_142 * dot(_142, i.world_tangent.xyz)));\n    float3 _194 = fast::normalize(((_166 * m.x) + ((cross(_142, _166) * i.world_tangent.w) * m.y)) + (_142 * m.z));\n    float3 _197;\n    if (bool(i.front_facing))\n    {\n        _197 = _194;\n    }\n    else\n    {\n        _197 = -_194;\n    }\n    return _197;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _331, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _331.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1426 = fa_tex_fix(param_2, param_3);\n    float4 _2384 = base_t;\n    _2384.x = _1426.x;\n    _2384.y = _1426.y;\n    _2384.z = _1426.z;\n    base_t = _2384;\n    float4 _1440 = (_2384 * _331.fa_base_color) * i.vertex_color;\n    float3 _2327 = i.world_normal;\n    if (_331.fa_maps.z > 0.5)\n    {\n        float param_4 = _331.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1473 = fa_tex_fix(param_6, param_7);\n        float3 _1476 = (_1473 * 2.0) - float3(1.0);\n        float2 _1481 = _1476.xy * _331.fa_maps.x;\n        float3 _2392 = _1476;\n        _2392.x = _1481.x;\n        _2392.y = _1481.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2392;\n        _2327 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _331.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1510 = fa_tex_fix(param_12, param_13);\n    float4 _2395 = mrt;\n    _2395.x = _1510.x;\n    _2395.y = _1510.y;\n    _2395.z = _1510.z;\n    mrt = _2395;\n    float4 _1538 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _331.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _1538.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1550 = fa_tex_fix(param_16, param_17);\n    float param_18 = _331.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1580 = fa_tex_fix(param_20, param_21);\n    float _2332 = _331.fa_layers_a.x;\n    float _2333 = _331.fa_layers_a.y;\n    float _2336 = _331.fa_layers_a.z;\n    float _2335 = _331.fa_layers_b.w;\n    float _2338 = _331.fa_layers_c.x;\n    if (_331.fa_layers_c.z > 0.5)\n    {\n        if (mod(_331.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2332 *= _1550.y;\n            _2333 *= _1550.z;\n            _2335 *= _1538.w;\n        }\n        if (_331.fa_layers_c.z > 1.5)\n        {\n            _2336 *= mrt.x;\n            _2338 *= mrt.w;\n        }\n    }\n    return Surface{ _1440.xyz, _1440.w, _2327, fast::clamp(_331.fa_pbr.x * _1510.z, 0.0, 1.0), fast::clamp(_331.fa_pbr.y * _1510.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_331.fa_maps.y * (_1550.x - 1.0)), _331.fa_emissive.xyz + (_331.fa_model_emissive.xyz * _1580), _2332, _2333, _331.fa_layers_b.xyz, _2335, _2336, _331.fa_layers_a.w, _2338, _331.fa_layers_c.y, _331.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _331, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_331.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _331.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _682 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _690 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _693 = int(_682);\n    int _696 = int(_690);\n    float _706 = _690 - float(_696);\n    int _762 = (_693 * 9) + _696;\n    int _782 = ((_693 + 1) * 9) + _696;\n    return mix(mix(_757[_762], _757[_762 + 1], _706), mix(_757[_782], _757[_782 + 1], _706), _682 - float(_693));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _2199 = false;\n    float _2200 = 1.0;\n    float _2201 = 1.0;\n    float _2202 = 1.0;\n    float _2203 = 0.0;\n    float _2204 = 0.0;\n    float _2205 = 0.0;\n    float _2206 = 0.0;\n    float _2208 = 1.0;\n    bool _2209 = false;\n    float3 _2210 = float3(0.0);\n    float _2211 = 1.0;\n    float _2212 = 1.0;\n    float _2213 = 1.0;\n    float _2214 = 0.0;\n    float _2215 = 0.0;\n    float3 _2216 = float3(1.0, 0.0, 0.0);\n    float3 _2217 = float3(0.0, 0.0, 1.0);\n    float _2218 = 1.0;\n    float _2219 = 1.0;\n    float _844 = fast::clamp(s.specular, 0.0, 1.0);\n    float _849 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _854 = (_844 != 1.0) || (_849 != 1.5);\n    bool _864;\n    if (!_854)\n    {\n        _864 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _864 = _854;\n    }\n    if (_864)\n    {\n        float _872 = (_849 - 1.0) / (_849 + 1.0);\n        f0 = mix(fast::min(float3(_872 * _872) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _844, s.albedo, float3(metallic));\n        _2200 = mix(_844, 1.0, metallic);\n        _2199 = true;\n    }\n    float _900 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_900 > 0.0)\n    {\n        float _908 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _2203 = _900;\n        _2204 = _908;\n        float _915 = _908 * _908;\n        _2205 = _915;\n        _2206 = _915 * _915;\n        float _927 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _2208 = _927;\n        _2201 = 1.0 - (_900 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(1.0 - _927, 5.0))));\n        _2199 = true;\n    }\n    float3 _946 = fast::max(s.sheen_color, float3(0.0));\n    float _955 = fast::max(_946.x, fast::max(_946.y, _946.z));\n    if (_955 > 0.0)\n    {\n        float _963 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _2209 = true;\n        _2210 = _946;\n        _2211 = _963;\n        _2212 = _963 * _963;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _963;\n        float _980 = fa_sheen_albedo(param, param_1);\n        _2214 = _980;\n        _2213 = 1.0 - fast::min(_955 * _980, 1.0);\n        _2199 = true;\n    }\n    _2202 = _2201 * _2213;\n    float _999 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_999 != 0.0)\n    {\n        float3 _1014 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1014;\n        if (dot(_1014, _1014) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _1032 = t;\n        float3 _1033 = fast::normalize(_1032);\n        t = _1033;\n        float3 _1058 = fast::normalize((_1033 * cos(s.anisotropy_rotation)) + ((cross(n, _1033) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _2216 = _1058;\n        _2217 = cross(n, _1058);\n        float _1068 = roughness * roughness;\n        float _1074 = mix(_1068, 1.0, _999 * _999);\n        bool _1076 = _999 > 0.0;\n        _2218 = _1076 ? _1074 : _1068;\n        _2219 = _1076 ? _1068 : _1074;\n        _2215 = _999;\n        _2199 = true;\n    }\n    return FaLayers{ short(_2199), _2200, _2201, _2202, _2203, _2204, _2205, _2206, i.world_normal, _2208, short(_2209), _2210, _2211, _2212, _2213, _2214, _2215, _2216, _2217, _2218, _2219 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _612 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _615 = _612.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_615 * _615, exp2((-9.27999973297119140625) * ndv)) * _615) + _612.y)) + _612.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _331, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_331.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _331.fa_env_horizon.w)).xyz;\n    }\n    float _515 = rough * rough;\n    float _546 = 0.60000002384185791015625 * _515;\n    return mix(mix(_331.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_331.fa_env_horizon.xyz, _331.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _515)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _546, 0.0500000007450580596923828125 + _546, d.y))), ((_331.fa_env_sky.xyz + _331.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_515 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _331, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _1109;\n        if (L.aniso >= 0.0)\n        {\n            _1109 = L.b;\n        }\n        else\n        {\n            _1109 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_1109, v), _1109), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1142 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _331, fa_env_tex, fa_env_smp) * ((f0 * _1142.x) + (float3(L.f90) * _1142.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _331, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1197 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _331, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _1197.x) + _1197.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _331, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _654 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _331, fa_env_tex, fa_env_smp) * ((f0 * _654.x) + float3(_654.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _331, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float _1226 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _1230 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _1237 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_1226));\n    float3 f0 = _1237;\n    float3 _1241 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _1241;\n    float3 param_3 = i.view_dir;\n    float param_4 = _1226;\n    float param_5 = _1230;\n    float3 param_6 = _1237;\n    FaLayers _1258 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_1258.on)\n    {\n        FaLayers param_7 = _1258;\n        float3 param_8 = _1241;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _1230;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _331, fa_env_tex, fa_env_smp) * s.occlusion;\n    }\n    float3 param_12 = _1241;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _1230;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _331, fa_env_tex, fa_env_smp) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor, constant fa_mesh_fs_params& _331, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1, _331, fa_env_tex, fa_env_smp);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _214)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _225 = _214.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_225)\n    {\n        l = fast::normalize(_214.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _243 = _214.fa_light_pos[li].xyz - world_pos;\n        float _245 = length(_243);\n        dist = _245;\n        l = _243 / float3(fast::max(_245, 9.9999997473787516355514526367188e-05));\n        float _261 = _245 / fast::max(_214.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _267 = fast::clamp(1.0 - (_261 * _261), 0.0, 1.0);\n        atten = _267 * _267;\n        if (_214.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_214.fa_light_dir[li].w, mix(_214.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_214.fa_light_dir[li].xyz)));\n        }\n    }\n    int _317;\n    if (_225)\n    {\n        _317 = 0;\n    }\n    else\n    {\n        _317 = (_214.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _214.fa_light_color[li].xyz * atten, atten, 1.0, dist, _317 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_pcf(thread const float4& coord, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _331, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_331.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _344 = coord.xyz / float3(coord.w);\n    float3 p = _344;\n    float2 suv = (_344.xy * 0.5) + float2(0.5);\n    if (_331.fa_counts.z > 0.5)\n    {\n        float3 _2359 = p;\n        _2359.z = (_2359.z * 0.5) + 0.5;\n        p = _2359;\n    }\n    else\n    {\n        float2 _2362 = suv;\n        _2362.y = 1.0 - _2362.y;\n        suv = _2362;\n    }\n    bool _372 = suv.x < 0.0;\n    bool _379;\n    if (!_372)\n    {\n        _379 = suv.x > 1.0;\n    }\n    else\n    {\n        _379 = _372;\n    }\n    bool _386;\n    if (!_379)\n    {\n        _386 = suv.y < 0.0;\n    }\n    else\n    {\n        _386 = _379;\n    }\n    bool _393;\n    if (!_386)\n    {\n        _393 = suv.y > 1.0;\n    }\n    else\n    {\n        _393 = _386;\n    }\n    bool _400;\n    if (!_393)\n    {\n        _400 = p.z > 1.0;\n    }\n    else\n    {\n        _400 = _393;\n    }\n    if (_400)\n    {\n        return 1.0;\n    }\n    float _415 = _331.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _415) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _331.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _331, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2, _331, fa_shadow_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_lights& _214, constant fa_mesh_fs_params& _331, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1300 = fa_light_sample(param, param_1, _214);\n    float3 _2312 = _1300.direction;\n    float3 _2307 = _1300.color;\n    float _2314 = _1300.attenuation;\n    float _2309 = _1300.shadow;\n    int _2317 = _1300.type;\n    if ((_2317 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2312;\n        float _1314 = fa_shadow_factor(param_2, param_3, _331, fa_shadow_tex, fa_shadow_smp, fa_shadow_pos);\n        _2309 = _1314;\n        _2307 = _214.fa_light_color[li].xyz * (_2314 * _1314);\n    }\n    return LightSample{ _2312, _2307, _2314, _2309, _1300._distance, _2317 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _331 [[buffer(1)]], constant fa_lights& _214 [[buffer(2)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2029 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2029 = -_2029;\n    }\n    float3 _1700 = fast::normalize(_331.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _2029, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1700, short(gl_FrontFacing) };\n    Surface _1705 = fa_standard_surface(param, _331, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2068 = _1705.albedo;\n    float _2069 = _1705.alpha;\n    float3 _2070 = _1705.normal;\n    float _2071 = _1705.metallic;\n    float _2072 = _1705.roughness;\n    float _2073 = _1705.occlusion;\n    float3 _2074 = _1705.emission;\n    float _2075 = _1705.clearcoat;\n    float _2076 = _1705.clearcoat_roughness;\n    float3 _2077 = _1705.sheen_color;\n    float _2078 = _1705.sheen_roughness;\n    float _2079 = _1705.anisotropy;\n    float _2080 = _1705.anisotropy_rotation;\n    float _2081 = _1705.specular;\n    float _2082 = _1705.ior;\n    float3 _2083 = _1705.specular_color;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2029, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1700, short(gl_FrontFacing) };\n    Surface param_2 = _1705;\n    surface(param_1, param_2);\n    _2068 = param_2.albedo;\n    _2069 = param_2.alpha;\n    _2070 = param_2.normal;\n    _2071 = param_2.metallic;\n    _2072 = param_2.roughness;\n    _2073 = param_2.occlusion;\n    _2074 = param_2.emission;\n    _2075 = param_2.clearcoat;\n    _2076 = param_2.clearcoat_roughness;\n    _2077 = param_2.sheen_color;\n    _2078 = param_2.sheen_roughness;\n    _2079 = param_2.anisotropy;\n    _2080 = param_2.anisotropy_rotation;\n    _2081 = param_2.specular;\n    _2082 = param_2.ior;\n    _2083 = param_2.specular_color;\n    float3 result;\n    if (_331.fa_emissive.w > 0.5)\n    {\n        result = _2068;\n    }\n    else\n    {\n        float3 _1726 = _2070;\n        float3 _1727 = fast::normalize(_1726);\n        _2070 = _1727;\n        float3 param_3 = _1727;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _2029, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1700, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _2068, _2069, _2070, _2071, _2072, _2073, _2074, _2075, _2076, _2077, _2078, _2079, _2080, _2081, _2082, _2083 };\n        float3 param_6 = fa_ambient_light(param_3, _331, fa_env_smp, fa_irr_tex);\n        float3 lit = ambient(param_4, param_5, param_6, _331, fa_env_tex, fa_env_smp);\n        int _1746 = int(_331.fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1746)\n            {\n                break;\n            }\n            int param_7 = li;\n            float3 param_8 = in.fa_world_pos;\n            float3 param_9 = _2029;\n            SurfaceInput param_10 = SurfaceInput{ in.fa_world_pos, _2029, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1700, short(gl_FrontFacing) };\n            Surface param_11 = Surface{ _2068, _2069, _2070, _2071, _2072, _2073, _2074, _2075, _2076, _2077, _2078, _2079, _2080, _2081, _2082, _2083 };\n            LightSample param_12 = fa_light_shadowed(param_7, param_8, param_9, _214, _331, fa_shadow_tex, fa_shadow_smp, in.fa_shadow_pos);\n            lit += light(param_10, param_11, param_12);\n        }\n        result = lit;\n    }\n    result += _2074;\n    bool _1789 = _331.fa_fog.w > 0.0;\n    bool _1796;\n    if (!_1789)\n    {\n        _1796 = _331.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1796 = _1789;\n    }\n    if (_1796)\n    {\n        float3 _1805 = in.fa_world_pos - _331.fa_camera_pos.xyz;\n        float _1811 = dot(_1805, _331.fa_fog_c.xyz);\n        bool _1815 = _331.fa_fog_c.w > 0.5;\n        float _1816;\n        if (_1815)\n        {\n            _1816 = _1811;\n        }\n        else\n        {\n            _1816 = length(_1805);\n        }\n        float _1828 = _1816 - _331.fa_fog_b.x;\n        if (_1828 > 0.0)\n        {\n            float _1837 = _331.fa_fog.w * _1828;\n            float tau = _1837 * _1837;\n            if (_331.fa_fog_b.y > 0.0)\n            {\n                float _1853;\n                if (_1815)\n                {\n                    _1853 = in.fa_world_pos.y - (_331.fa_fog_c.y * _1811);\n                }\n                else\n                {\n                    _1853 = _331.fa_camera_pos.y;\n                }\n                float _1874 = mix(_1853, in.fa_world_pos.y, fast::clamp(_331.fa_fog_b.x / _1816, 0.0, 1.0));\n                float _1878 = in.fa_world_pos.y - _1874;\n                float _1883 = _1874 - _331.fa_fog_b.z;\n                float _1888 = in.fa_world_pos.y - _331.fa_fog_b.z;\n                bool _1891 = _1883 <= 0.0;\n                bool _1892 = !_1891;\n                bool _1898;\n                if (_1892)\n                {\n                    _1898 = _331.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1898 = _1891;\n                }\n                float _1899;\n                if (_1898)\n                {\n                    _1899 = _331.fa_fog_b.y;\n                }\n                else\n                {\n                    _1899 = _331.fa_fog_b.y * exp(-fast::min(_331.fa_fog_b.w * _1883, 80.0));\n                }\n                bool _1926;\n                if (_1892)\n                {\n                    _1926 = _331.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1926 = _1891;\n                }\n                float _1927;\n                if (_1926)\n                {\n                    _1927 = _331.fa_fog_b.y * _1883;\n                }\n                else\n                {\n                    _1927 = (_331.fa_fog_b.y * (1.0 - exp(-fast::min(_331.fa_fog_b.w * _1883, 80.0)))) / _331.fa_fog_b.w;\n                }\n                bool _1952 = _1888 <= 0.0;\n                bool _1959;\n                if (!_1952)\n                {\n                    _1959 = _331.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1959 = _1952;\n                }\n                float _1960;\n                if (_1959)\n                {\n                    _1960 = _331.fa_fog_b.y * _1888;\n                }\n                else\n                {\n                    _1960 = (_331.fa_fog_b.y * (1.0 - exp(-fast::min(_331.fa_fog_b.w * _1888, 80.0)))) / _331.fa_fog_b.w;\n                }\n                float _1987;\n                if (abs(_1878) < 0.001000000047497451305389404296875)\n                {\n                    _1987 = _1899;\n                }\n                else\n                {\n                    _1987 = (_1960 - _1927) / _1878;\n                }\n                tau += (_1828 * fast::max(_1987, 0.0));\n            }\n            result = mix(result, _331.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2069);\n    return out;\n}\n\n",
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
            "inst_name": "_214",
            "msl_buffer_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_331",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _780 = base_t;\n    _780.x = _225.x;\n    _780.y = _225.y;\n    _780.z = _225.z;\n    base_t = _780;\n    float4 _241 = (_780 * _213.fa_base_color) * i.vertex_color;\n    float3 _743 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _788 = _279;\n        _788.x = _284.x;\n        _788.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _788;\n        _743 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _791 = mrt;\n    _791.x = _313.x;\n    _791.y = _313.y;\n    _791.z = _313.z;\n    mrt = _791;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _748 = _213.fa_layers_a.x;\n    float _749 = _213.fa_layers_a.y;\n    float _752 = _213.fa_layers_a.z;\n    float _751 = _213.fa_layers_b.w;\n    float _754 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _748 *= _355.y;\n            _749 *= _355.z;\n            _751 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _752 *= mrt.x;\n            _754 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _743, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _748, _749, _213.fa_layers_b.xyz, _751, _752, _213.fa_layers_a.w, _754, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _654 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _654 = -_654;\n    }\n    float3 _517 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _654, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _517, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _654, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _517, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _532 = fast::normalize(param_2.normal);\n    float3 _547 = fast::normalize(float3(dot(in.fa_pre_r0, _532), dot(in.fa_pre_r1, _532), dot(in.fa_pre_r2, _532)));\n    float _559 = _547.z;\n    float2 e = _547.xy / float2((abs(_547.x) + abs(_547.y)) + abs(_559));\n    if (_559 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _780 = base_t;\n    _780.x = _225.x;\n    _780.y = _225.y;\n    _780.z = _225.z;\n    base_t = _780;\n    float4 _241 = (_780 * _213.fa_base_color) * i.vertex_color;\n    float3 _743 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _788 = _279;\n        _788.x = _284.x;\n        _788.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _788;\n        _743 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _791 = mrt;\n    _791.x = _313.x;\n    _791.y = _313.y;\n    _791.z = _313.z;\n    mrt = _791;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _748 = _213.fa_layers_a.x;\n    float _749 = _213.fa_layers_a.y;\n    float _752 = _213.fa_layers_a.z;\n    float _751 = _213.fa_layers_b.w;\n    float _754 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _748 *= _355.y;\n            _749 *= _355.z;\n            _751 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _752 *= mrt.x;\n            _754 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _743, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _748, _749, _213.fa_layers_b.xyz, _751, _752, _213.fa_layers_a.w, _754, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _654 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _654 = -_654;\n    }\n    float3 _517 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _654, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _517, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _654, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _517, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _532 = fast::normalize(param_2.normal);\n    float3 _547 = fast::normalize(float3(dot(in.fa_pre_r0, _532), dot(in.fa_pre_r1, _532), dot(in.fa_pre_r2, _532)));\n    float _559 = _547.z;\n    float2 e = _547.xy / float2((abs(_547.x) + abs(_547.y)) + abs(_559));\n    if (_559 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
