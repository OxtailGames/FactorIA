{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "3995aa0ba56be221fe15f8a0d00a1f706ae46d0f598c3711968fac755bdd80f5",
  "slang": "metal_macos",
  "params": [
    "offset"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    packed_float3 offset;\n    float fa_pad0;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _145)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _145.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, constant fa_material_vs& _45)\n{\n    v.world_pos += float3(_45.offset);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_material_vs& _45, constant fa_mesh_vs_params& _145, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _145);\n    vertex0(param_6, _45);\n    float4 _185 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = _145.fa_light_vp * _185;\n    gl_Position = _145.fa_view_proj * _185;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _145 [[buffer(0)]], constant fa_material_vs& _45 [[buffer(4)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _45, _145, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nconstant spvUnsafeArray<float, 63> _783 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1645 = fa_linear_to_srgb(param);\n        c = _1645;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1653 = fa_srgb_to_linear(param_1);\n            c = _1653;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _167;\n    if (bool(i.front_facing))\n    {\n        _167 = i.world_normal;\n    }\n    else\n    {\n        _167 = -i.world_normal;\n    }\n    float3 _191 = fast::normalize(i.world_tangent.xyz - (_167 * dot(_167, i.world_tangent.xyz)));\n    float3 _219 = fast::normalize(((_191 * m.x) + ((cross(_167, _191) * i.world_tangent.w) * m.y)) + (_167 * m.z));\n    float3 _222;\n    if (bool(i.front_facing))\n    {\n        _222 = _219;\n    }\n    else\n    {\n        _222 = -_219;\n    }\n    return _222;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _357, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _357.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1684 = fa_tex_fix(param_2, param_3);\n    float4 _2844 = base_t;\n    _2844.x = _1684.x;\n    _2844.y = _1684.y;\n    _2844.z = _1684.z;\n    base_t = _2844;\n    float4 _1698 = (_2844 * _357.fa_base_color) * i.vertex_color;\n    float3 _2787 = i.world_normal;\n    if (_357.fa_maps.z > 0.5)\n    {\n        float param_4 = _357.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1731 = fa_tex_fix(param_6, param_7);\n        float3 _1734 = (_1731 * 2.0) - float3(1.0);\n        float2 _1739 = _1734.xy * _357.fa_maps.x;\n        float3 _2852 = _1734;\n        _2852.x = _1739.x;\n        _2852.y = _1739.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2852;\n        _2787 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _357.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1768 = fa_tex_fix(param_12, param_13);\n    float4 _2855 = mrt;\n    _2855.x = _1768.x;\n    _2855.y = _1768.y;\n    _2855.z = _1768.z;\n    mrt = _2855;\n    float4 _1796 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _357.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _1796.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1808 = fa_tex_fix(param_16, param_17);\n    float param_18 = _357.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1838 = fa_tex_fix(param_20, param_21);\n    float _2792 = _357.fa_layers_a.x;\n    float _2793 = _357.fa_layers_a.y;\n    float _2796 = _357.fa_layers_a.z;\n    float _2795 = _357.fa_layers_b.w;\n    float _2798 = _357.fa_layers_c.x;\n    if (_357.fa_layers_c.z > 0.5)\n    {\n        if (mod(_357.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2792 *= _1808.y;\n            _2793 *= _1808.z;\n            _2795 *= _1796.w;\n        }\n        if (_357.fa_layers_c.z > 1.5)\n        {\n            _2796 *= mrt.x;\n            _2798 *= mrt.w;\n        }\n    }\n    return Surface{ _1698.xyz, _1698.w, _2787, fast::clamp(_357.fa_pbr.x * _1768.z, 0.0, 1.0), fast::clamp(_357.fa_pbr.y * _1768.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_357.fa_maps.y * (_1808.x - 1.0)), _357.fa_emissive.xyz + (_357.fa_model_emissive.xyz * _1838), _2792, _2793, _357.fa_layers_b.xyz, _2795, _2796, _357.fa_layers_a.w, _2798, _357.fa_layers_c.y, _357.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _708 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _716 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _719 = int(_708);\n    int _722 = int(_716);\n    float _732 = _716 - float(_722);\n    int _788 = (_719 * 9) + _722;\n    int _808 = ((_719 + 1) * 9) + _722;\n    return mix(mix(_783[_788], _783[_788 + 1], _732), mix(_783[_808], _783[_808 + 1], _732), _708 - float(_719));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _2723 = false;\n    float _2724 = 1.0;\n    float _2725 = 1.0;\n    float _2726 = 1.0;\n    float _2727 = 0.0;\n    float _2728 = 0.0;\n    float _2729 = 0.0;\n    float _2730 = 0.0;\n    float _2732 = 1.0;\n    bool _2733 = false;\n    float3 _2734 = float3(0.0);\n    float _2735 = 1.0;\n    float _2736 = 1.0;\n    float _2737 = 1.0;\n    float _2738 = 0.0;\n    float _2739 = 0.0;\n    float3 _2740 = float3(1.0, 0.0, 0.0);\n    float3 _2741 = float3(0.0, 0.0, 1.0);\n    float _2742 = 1.0;\n    float _2743 = 1.0;\n    float _870 = fast::clamp(s.specular, 0.0, 1.0);\n    float _875 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _880 = (_870 != 1.0) || (_875 != 1.5);\n    bool _890;\n    if (!_880)\n    {\n        _890 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _890 = _880;\n    }\n    if (_890)\n    {\n        float _898 = (_875 - 1.0) / (_875 + 1.0);\n        f0 = mix(fast::min(float3(_898 * _898) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _870, s.albedo, float3(metallic));\n        _2724 = mix(_870, 1.0, metallic);\n        _2723 = true;\n    }\n    float _926 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_926 > 0.0)\n    {\n        float _934 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _2727 = _926;\n        _2728 = _934;\n        float _941 = _934 * _934;\n        _2729 = _941;\n        _2730 = _941 * _941;\n        float _953 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _2732 = _953;\n        _2725 = 1.0 - (_926 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(1.0 - _953, 5.0))));\n        _2723 = true;\n    }\n    float3 _972 = fast::max(s.sheen_color, float3(0.0));\n    float _981 = fast::max(_972.x, fast::max(_972.y, _972.z));\n    if (_981 > 0.0)\n    {\n        float _989 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _2733 = true;\n        _2734 = _972;\n        _2735 = _989;\n        _2736 = _989 * _989;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _989;\n        float _1006 = fa_sheen_albedo(param, param_1);\n        _2738 = _1006;\n        _2737 = 1.0 - fast::min(_981 * _1006, 1.0);\n        _2723 = true;\n    }\n    _2726 = _2725 * _2737;\n    float _1025 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_1025 != 0.0)\n    {\n        float3 _1040 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1040;\n        if (dot(_1040, _1040) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _1058 = t;\n        float3 _1059 = fast::normalize(_1058);\n        t = _1059;\n        float3 _1084 = fast::normalize((_1059 * cos(s.anisotropy_rotation)) + ((cross(n, _1059) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _2740 = _1084;\n        _2741 = cross(n, _1084);\n        float _1094 = roughness * roughness;\n        float _1100 = mix(_1094, 1.0, _1025 * _1025);\n        bool _1102 = _1025 > 0.0;\n        _2742 = _1102 ? _1100 : _1094;\n        _2743 = _1102 ? _1094 : _1100;\n        _2739 = _1025;\n        _2723 = true;\n    }\n    return FaLayers{ short(_2723), _2724, _2725, _2726, _2727, _2728, _2729, _2730, i.world_normal, _2732, short(_2733), _2734, _2735, _2736, _2737, _2738, _2739, _2740, _2741, _2742, _2743 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _357, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_357.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _357.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _239)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _250 = _239.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_250)\n    {\n        l = fast::normalize(_239.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _268 = _239.fa_light_pos[li].xyz - world_pos;\n        float _270 = length(_268);\n        dist = _270;\n        l = _268 / float3(fast::max(_270, 9.9999997473787516355514526367188e-05));\n        float _286 = _270 / fast::max(_239.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _292 = fast::clamp(1.0 - (_286 * _286), 0.0, 1.0);\n        atten = _292 * _292;\n        if (_239.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_239.fa_light_dir[li].w, mix(_239.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_239.fa_light_dir[li].xyz)));\n        }\n    }\n    int _343;\n    if (_250)\n    {\n        _343 = 0;\n    }\n    else\n    {\n        _343 = (_239.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _239.fa_light_color[li].xyz * atten, atten, 1.0, dist, _343 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_pcf(thread const float4& coord, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _357, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_357.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _370 = coord.xyz / float3(coord.w);\n    float3 p = _370;\n    float2 suv = (_370.xy * 0.5) + float2(0.5);\n    if (_357.fa_counts.z > 0.5)\n    {\n        float3 _2819 = p;\n        _2819.z = (_2819.z * 0.5) + 0.5;\n        p = _2819;\n    }\n    else\n    {\n        float2 _2822 = suv;\n        _2822.y = 1.0 - _2822.y;\n        suv = _2822;\n    }\n    bool _398 = suv.x < 0.0;\n    bool _405;\n    if (!_398)\n    {\n        _405 = suv.x > 1.0;\n    }\n    else\n    {\n        _405 = _398;\n    }\n    bool _412;\n    if (!_405)\n    {\n        _412 = suv.y < 0.0;\n    }\n    else\n    {\n        _412 = _405;\n    }\n    bool _419;\n    if (!_412)\n    {\n        _419 = suv.y > 1.0;\n    }\n    else\n    {\n        _419 = _412;\n    }\n    bool _426;\n    if (!_419)\n    {\n        _426 = p.z > 1.0;\n    }\n    else\n    {\n        _426 = _419;\n    }\n    if (_426)\n    {\n        return 1.0;\n    }\n    float _441 = _357.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _441) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _357.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _357, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2, _357, fa_shadow_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_lights& _239, constant fa_mesh_fs_params& _357, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1568 = fa_light_sample(param, param_1, _239);\n    float3 _2772 = _1568.direction;\n    float3 _2767 = _1568.color;\n    float _2774 = _1568.attenuation;\n    float _2769 = _1568.shadow;\n    int _2777 = _1568.type;\n    if ((_2777 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2772;\n        float _1582 = fa_shadow_factor(param_2, param_3, _357, fa_shadow_tex, fa_shadow_smp, fa_shadow_pos);\n        _2769 = _1582;\n        _2767 = _239.fa_light_color[li].xyz * (_2774 * _1582);\n    }\n    return LightSample{ _2772, _2767, _2774, _2769, _1568._distance, _2777 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _1252 = at * ab;\n    float3 _1263 = float3(ab * tdh, at * bdh, _1252 * ndh);\n    float _1269 = _1252 / dot(_1263, _1263);\n    return ((_1252 * _1269) * _1269) * 0.3183098733425140380859375;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    return fast::clamp(0.5 / fast::max((ndl * length(float3(at * tdv, ab * bdv, ndv))) + (ndv * length(float3(at * tdl, ab * bdl, ndl))), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    return ((2.0 + (1.0 / alpha)) * powr(fast::max(1.0 - (ndh * ndh), 0.0078125), 0.5 / alpha)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / ((ndl + ndv) - (ndl * ndv)), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _1347 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _1425 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _1425) * _1425);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(1.0 - vdh, 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _1347);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _1347));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _1498 = fast::max(dot(L.nc, l), 0.0);\n        float _1504 = fast::max(dot(L.nc, h), 0.0);\n        float _1513 = ((_1504 * _1504) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(1.0 - vdh, 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _1513) * _1513)) * (0.5 / fast::max(mix((2.0 * _1498) * L.coat_ndv, _1498 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1498)) * _1498);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _638 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _641 = _638.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_641 * _641, exp2((-9.27999973297119140625) * ndv)) * _641) + _638.y)) + _638.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _357, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_357.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _357.fa_env_horizon.w)).xyz;\n    }\n    float _541 = rough * rough;\n    float _572 = 0.60000002384185791015625 * _541;\n    return mix(mix(_357.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_357.fa_env_horizon.xyz, _357.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _541)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _572, 0.0500000007450580596923828125 + _572, d.y))), ((_357.fa_env_sky.xyz + _357.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_541 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _357, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _1135;\n        if (L.aniso >= 0.0)\n        {\n            _1135 = L.b;\n        }\n        else\n        {\n            _1135 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_1135, v), _1135), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1168 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _357, fa_env_tex, fa_env_smp) * ((f0 * _1168.x) + (float3(L.f90) * _1168.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _357, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1223 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _357, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _1223.x) + _1223.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _357, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _680 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _357, fa_env_tex, fa_env_smp) * ((f0 * _680.x) + float3(_680.y));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _357 [[buffer(1)]], constant fa_lights& _239 [[buffer(2)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2502 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2502 = -_2502;\n    }\n    float3 _1958 = fast::normalize(_357.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _2502, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1958, short(gl_FrontFacing) };\n    Surface _1963 = fa_standard_surface(param, _357, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2533 = _1963.albedo;\n    float _2534 = _1963.alpha;\n    float3 _2535 = _1963.normal;\n    float _2536 = _1963.metallic;\n    float _2537 = _1963.roughness;\n    float _2538 = _1963.occlusion;\n    float3 _2539 = _1963.emission;\n    float _2540 = _1963.clearcoat;\n    float _2541 = _1963.clearcoat_roughness;\n    float3 _2542 = _1963.sheen_color;\n    float _2543 = _1963.sheen_roughness;\n    float _2544 = _1963.anisotropy;\n    float _2545 = _1963.anisotropy_rotation;\n    float _2546 = _1963.specular;\n    float _2547 = _1963.ior;\n    float3 _2548 = _1963.specular_color;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2502, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1958, short(gl_FrontFacing) };\n    Surface param_2 = _1963;\n    surface(param_1, param_2);\n    _2533 = param_2.albedo;\n    _2534 = param_2.alpha;\n    _2535 = param_2.normal;\n    _2536 = param_2.metallic;\n    _2537 = param_2.roughness;\n    _2538 = param_2.occlusion;\n    _2539 = param_2.emission;\n    _2540 = param_2.clearcoat;\n    _2541 = param_2.clearcoat_roughness;\n    _2542 = param_2.sheen_color;\n    _2543 = param_2.sheen_roughness;\n    _2544 = param_2.anisotropy;\n    _2545 = param_2.anisotropy_rotation;\n    _2546 = param_2.specular;\n    _2547 = param_2.ior;\n    _2548 = param_2.specular_color;\n    float3 result;\n    if (_357.fa_emissive.w > 0.5)\n    {\n        result = _2533;\n    }\n    else\n    {\n        float3 _1985 = fast::normalize(_2535);\n        float _1992 = fast::clamp(_2536, 0.0, 1.0);\n        float _1996 = fast::clamp(_2537, 0.0500000007450580596923828125, 1.0);\n        float _2000 = _1996 * _1996;\n        float _2004 = _2000 * _2000;\n        float _2009 = fast::max(dot(_1985, _1958), 9.9999997473787516355514526367188e-05);\n        float3 _2015 = _2533 * (1.0 - _1992);\n        float3 _2022 = mix(float3(0.039999999105930328369140625), _2533, float3(_1992));\n        float3 f0 = _2022;\n        SurfaceInput param_3 = SurfaceInput{ in.fa_world_pos, _2502, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1958, short(gl_FrontFacing) };\n        Surface param_4 = Surface{ _2533, _2534, _2535, _2536, _2537, _2538, _2539, _2540, _2541, _2542, _2543, _2544, _2545, _2546, _2547, _2548 };\n        float3 param_5 = _1985;\n        float3 param_6 = _1958;\n        float param_7 = _1992;\n        float param_8 = _1996;\n        float3 param_9 = _2022;\n        FaLayers _2038 = fa_layers_setup(param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n        f0 = param_9;\n        float3 param_10 = _1985;\n        float3 lit = (fa_ambient_light(param_10, _357, fa_env_smp, fa_irr_tex) * _2015) * _2538;\n        if (_2038.on)\n        {\n            lit *= _2038.base_scale;\n        }\n        int _2060 = int(_357.fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _2060)\n            {\n                break;\n            }\n            int param_11 = li;\n            float3 param_12 = in.fa_world_pos;\n            float3 param_13 = _2502;\n            LightSample _2084 = fa_light_shadowed(param_11, param_12, param_13, _239, _357, fa_shadow_tex, fa_shadow_smp, in.fa_shadow_pos);\n            float3 _2707 = _2084.direction;\n            float _2092 = fast::max(dot(_1985, _2707), 0.0);\n            float _2098 = _2084.attenuation * _2084.shadow;\n            float3 _2103 = fast::normalize(_2707 + _1958);\n            float _2108 = fast::max(dot(_1985, _2103), 0.0);\n            float _2113 = fast::max(dot(_1958, _2103), 0.0);\n            if (_2038.on)\n            {\n                FaLayers param_14 = _2038;\n                float3 param_15 = _2015;\n                float3 param_16 = f0;\n                float3 param_17 = _1985;\n                float3 param_18 = _1958;\n                float3 param_19 = _2707;\n                float3 param_20 = _2103;\n                float param_21 = _2092;\n                float param_22 = _2009;\n                float param_23 = _2108;\n                float param_24 = _2113;\n                float param_25 = _2000;\n                float param_26 = _2004;\n                lit += (fa_layers_light(param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26) * (_239.fa_light_color[li].xyz * _2098));\n            }\n            else\n            {\n                float _2162 = ((_2108 * _2108) * (_2004 - 1.0)) + 1.0;\n                lit += (((_2015 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _2113, 5.0))) * (((_2004 / ((3.1415927410125732421875 * _2162) * _2162)) * (0.5 / fast::max(mix((2.0 * _2092) * _2009, _2092 + _2009, _2000), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2092))) * _239.fa_light_color[li].xyz) * (_2092 * _2098));\n            }\n        }\n        if (_2038.on)\n        {\n            FaLayers param_27 = _2038;\n            float3 param_28 = _1985;\n            float3 param_29 = _1958;\n            float3 param_30 = f0;\n            float param_31 = _1996;\n            lit += (fa_layers_ibl(param_27, param_28, param_29, param_30, param_31, _357, fa_env_tex, fa_env_smp) * _2538);\n        }\n        else\n        {\n            float3 param_32 = _1985;\n            float3 param_33 = _1958;\n            float3 param_34 = f0;\n            float param_35 = _1996;\n            lit += (fa_sky_reflection(param_32, param_33, param_34, param_35, _357, fa_env_tex, fa_env_smp) * _2538);\n        }\n        result = lit;\n    }\n    result += _2539;\n    bool _2260 = _357.fa_fog.w > 0.0;\n    bool _2267;\n    if (!_2260)\n    {\n        _2267 = _357.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2267 = _2260;\n    }\n    if (_2267)\n    {\n        float3 _2276 = in.fa_world_pos - _357.fa_camera_pos.xyz;\n        float _2282 = dot(_2276, _357.fa_fog_c.xyz);\n        bool _2286 = _357.fa_fog_c.w > 0.5;\n        float _2287;\n        if (_2286)\n        {\n            _2287 = _2282;\n        }\n        else\n        {\n            _2287 = length(_2276);\n        }\n        float _2299 = _2287 - _357.fa_fog_b.x;\n        if (_2299 > 0.0)\n        {\n            float _2308 = _357.fa_fog.w * _2299;\n            float tau = _2308 * _2308;\n            if (_357.fa_fog_b.y > 0.0)\n            {\n                float _2324;\n                if (_2286)\n                {\n                    _2324 = in.fa_world_pos.y - (_357.fa_fog_c.y * _2282);\n                }\n                else\n                {\n                    _2324 = _357.fa_camera_pos.y;\n                }\n                float _2345 = mix(_2324, in.fa_world_pos.y, fast::clamp(_357.fa_fog_b.x / _2287, 0.0, 1.0));\n                float _2349 = in.fa_world_pos.y - _2345;\n                float _2354 = _2345 - _357.fa_fog_b.z;\n                float _2359 = in.fa_world_pos.y - _357.fa_fog_b.z;\n                bool _2362 = _2354 <= 0.0;\n                bool _2363 = !_2362;\n                bool _2369;\n                if (_2363)\n                {\n                    _2369 = _357.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2369 = _2362;\n                }\n                float _2370;\n                if (_2369)\n                {\n                    _2370 = _357.fa_fog_b.y;\n                }\n                else\n                {\n                    _2370 = _357.fa_fog_b.y * exp(-fast::min(_357.fa_fog_b.w * _2354, 80.0));\n                }\n                bool _2397;\n                if (_2363)\n                {\n                    _2397 = _357.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2397 = _2362;\n                }\n                float _2398;\n                if (_2397)\n                {\n                    _2398 = _357.fa_fog_b.y * _2354;\n                }\n                else\n                {\n                    _2398 = (_357.fa_fog_b.y * (1.0 - exp(-fast::min(_357.fa_fog_b.w * _2354, 80.0)))) / _357.fa_fog_b.w;\n                }\n                bool _2423 = _2359 <= 0.0;\n                bool _2430;\n                if (!_2423)\n                {\n                    _2430 = _357.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2430 = _2423;\n                }\n                float _2431;\n                if (_2430)\n                {\n                    _2431 = _357.fa_fog_b.y * _2359;\n                }\n                else\n                {\n                    _2431 = (_357.fa_fog_b.y * (1.0 - exp(-fast::min(_357.fa_fog_b.w * _2359, 80.0)))) / _357.fa_fog_b.w;\n                }\n                float _2458;\n                if (abs(_2349) < 0.001000000047497451305389404296875)\n                {\n                    _2458 = _2370;\n                }\n                else\n                {\n                    _2458 = (_2431 - _2398) / _2349;\n                }\n                tau += (_2299 * fast::max(_2458, 0.0));\n            }\n            result = mix(result, _357.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2534);\n    return out;\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_45",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_145",
            "msl_buffer_n": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_239",
            "msl_buffer_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_357",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 7,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    packed_float3 offset;\n    float fa_pad0;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _197)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _188 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_197.fa_joint_rows[_188] * weights[i]);\n        r1 += (_197.fa_joint_rows[_188 + 1] * weights[i]);\n        r2 += (_197.fa_joint_rows[_188 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _150)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _150.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, constant fa_material_vs& _50)\n{\n    v.world_pos += float3(_50.offset);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_material_vs& _50, constant fa_mesh_vs_params& _150, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _150);\n    vertex0(param_6, _50);\n    float4 _298 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = _150.fa_light_vp * _298;\n    gl_Position = _150.fa_view_proj * _298;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _150 [[buffer(0)]], constant fa_skin& _197 [[buffer(3)]], constant fa_material_vs& _50 [[buffer(4)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _197);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _50, _150, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nconstant spvUnsafeArray<float, 63> _783 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1645 = fa_linear_to_srgb(param);\n        c = _1645;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1653 = fa_srgb_to_linear(param_1);\n            c = _1653;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _167;\n    if (bool(i.front_facing))\n    {\n        _167 = i.world_normal;\n    }\n    else\n    {\n        _167 = -i.world_normal;\n    }\n    float3 _191 = fast::normalize(i.world_tangent.xyz - (_167 * dot(_167, i.world_tangent.xyz)));\n    float3 _219 = fast::normalize(((_191 * m.x) + ((cross(_167, _191) * i.world_tangent.w) * m.y)) + (_167 * m.z));\n    float3 _222;\n    if (bool(i.front_facing))\n    {\n        _222 = _219;\n    }\n    else\n    {\n        _222 = -_219;\n    }\n    return _222;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _357, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _357.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1684 = fa_tex_fix(param_2, param_3);\n    float4 _2844 = base_t;\n    _2844.x = _1684.x;\n    _2844.y = _1684.y;\n    _2844.z = _1684.z;\n    base_t = _2844;\n    float4 _1698 = (_2844 * _357.fa_base_color) * i.vertex_color;\n    float3 _2787 = i.world_normal;\n    if (_357.fa_maps.z > 0.5)\n    {\n        float param_4 = _357.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1731 = fa_tex_fix(param_6, param_7);\n        float3 _1734 = (_1731 * 2.0) - float3(1.0);\n        float2 _1739 = _1734.xy * _357.fa_maps.x;\n        float3 _2852 = _1734;\n        _2852.x = _1739.x;\n        _2852.y = _1739.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2852;\n        _2787 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _357.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1768 = fa_tex_fix(param_12, param_13);\n    float4 _2855 = mrt;\n    _2855.x = _1768.x;\n    _2855.y = _1768.y;\n    _2855.z = _1768.z;\n    mrt = _2855;\n    float4 _1796 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _357.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _1796.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1808 = fa_tex_fix(param_16, param_17);\n    float param_18 = _357.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1838 = fa_tex_fix(param_20, param_21);\n    float _2792 = _357.fa_layers_a.x;\n    float _2793 = _357.fa_layers_a.y;\n    float _2796 = _357.fa_layers_a.z;\n    float _2795 = _357.fa_layers_b.w;\n    float _2798 = _357.fa_layers_c.x;\n    if (_357.fa_layers_c.z > 0.5)\n    {\n        if (mod(_357.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2792 *= _1808.y;\n            _2793 *= _1808.z;\n            _2795 *= _1796.w;\n        }\n        if (_357.fa_layers_c.z > 1.5)\n        {\n            _2796 *= mrt.x;\n            _2798 *= mrt.w;\n        }\n    }\n    return Surface{ _1698.xyz, _1698.w, _2787, fast::clamp(_357.fa_pbr.x * _1768.z, 0.0, 1.0), fast::clamp(_357.fa_pbr.y * _1768.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_357.fa_maps.y * (_1808.x - 1.0)), _357.fa_emissive.xyz + (_357.fa_model_emissive.xyz * _1838), _2792, _2793, _357.fa_layers_b.xyz, _2795, _2796, _357.fa_layers_a.w, _2798, _357.fa_layers_c.y, _357.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _708 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _716 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _719 = int(_708);\n    int _722 = int(_716);\n    float _732 = _716 - float(_722);\n    int _788 = (_719 * 9) + _722;\n    int _808 = ((_719 + 1) * 9) + _722;\n    return mix(mix(_783[_788], _783[_788 + 1], _732), mix(_783[_808], _783[_808 + 1], _732), _708 - float(_719));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _2723 = false;\n    float _2724 = 1.0;\n    float _2725 = 1.0;\n    float _2726 = 1.0;\n    float _2727 = 0.0;\n    float _2728 = 0.0;\n    float _2729 = 0.0;\n    float _2730 = 0.0;\n    float _2732 = 1.0;\n    bool _2733 = false;\n    float3 _2734 = float3(0.0);\n    float _2735 = 1.0;\n    float _2736 = 1.0;\n    float _2737 = 1.0;\n    float _2738 = 0.0;\n    float _2739 = 0.0;\n    float3 _2740 = float3(1.0, 0.0, 0.0);\n    float3 _2741 = float3(0.0, 0.0, 1.0);\n    float _2742 = 1.0;\n    float _2743 = 1.0;\n    float _870 = fast::clamp(s.specular, 0.0, 1.0);\n    float _875 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _880 = (_870 != 1.0) || (_875 != 1.5);\n    bool _890;\n    if (!_880)\n    {\n        _890 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _890 = _880;\n    }\n    if (_890)\n    {\n        float _898 = (_875 - 1.0) / (_875 + 1.0);\n        f0 = mix(fast::min(float3(_898 * _898) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _870, s.albedo, float3(metallic));\n        _2724 = mix(_870, 1.0, metallic);\n        _2723 = true;\n    }\n    float _926 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_926 > 0.0)\n    {\n        float _934 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _2727 = _926;\n        _2728 = _934;\n        float _941 = _934 * _934;\n        _2729 = _941;\n        _2730 = _941 * _941;\n        float _953 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _2732 = _953;\n        _2725 = 1.0 - (_926 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(1.0 - _953, 5.0))));\n        _2723 = true;\n    }\n    float3 _972 = fast::max(s.sheen_color, float3(0.0));\n    float _981 = fast::max(_972.x, fast::max(_972.y, _972.z));\n    if (_981 > 0.0)\n    {\n        float _989 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _2733 = true;\n        _2734 = _972;\n        _2735 = _989;\n        _2736 = _989 * _989;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _989;\n        float _1006 = fa_sheen_albedo(param, param_1);\n        _2738 = _1006;\n        _2737 = 1.0 - fast::min(_981 * _1006, 1.0);\n        _2723 = true;\n    }\n    _2726 = _2725 * _2737;\n    float _1025 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_1025 != 0.0)\n    {\n        float3 _1040 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1040;\n        if (dot(_1040, _1040) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _1058 = t;\n        float3 _1059 = fast::normalize(_1058);\n        t = _1059;\n        float3 _1084 = fast::normalize((_1059 * cos(s.anisotropy_rotation)) + ((cross(n, _1059) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _2740 = _1084;\n        _2741 = cross(n, _1084);\n        float _1094 = roughness * roughness;\n        float _1100 = mix(_1094, 1.0, _1025 * _1025);\n        bool _1102 = _1025 > 0.0;\n        _2742 = _1102 ? _1100 : _1094;\n        _2743 = _1102 ? _1094 : _1100;\n        _2739 = _1025;\n        _2723 = true;\n    }\n    return FaLayers{ short(_2723), _2724, _2725, _2726, _2727, _2728, _2729, _2730, i.world_normal, _2732, short(_2733), _2734, _2735, _2736, _2737, _2738, _2739, _2740, _2741, _2742, _2743 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _357, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_357.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _357.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _239)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _250 = _239.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_250)\n    {\n        l = fast::normalize(_239.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _268 = _239.fa_light_pos[li].xyz - world_pos;\n        float _270 = length(_268);\n        dist = _270;\n        l = _268 / float3(fast::max(_270, 9.9999997473787516355514526367188e-05));\n        float _286 = _270 / fast::max(_239.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _292 = fast::clamp(1.0 - (_286 * _286), 0.0, 1.0);\n        atten = _292 * _292;\n        if (_239.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_239.fa_light_dir[li].w, mix(_239.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_239.fa_light_dir[li].xyz)));\n        }\n    }\n    int _343;\n    if (_250)\n    {\n        _343 = 0;\n    }\n    else\n    {\n        _343 = (_239.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _239.fa_light_color[li].xyz * atten, atten, 1.0, dist, _343 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_pcf(thread const float4& coord, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _357, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_357.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _370 = coord.xyz / float3(coord.w);\n    float3 p = _370;\n    float2 suv = (_370.xy * 0.5) + float2(0.5);\n    if (_357.fa_counts.z > 0.5)\n    {\n        float3 _2819 = p;\n        _2819.z = (_2819.z * 0.5) + 0.5;\n        p = _2819;\n    }\n    else\n    {\n        float2 _2822 = suv;\n        _2822.y = 1.0 - _2822.y;\n        suv = _2822;\n    }\n    bool _398 = suv.x < 0.0;\n    bool _405;\n    if (!_398)\n    {\n        _405 = suv.x > 1.0;\n    }\n    else\n    {\n        _405 = _398;\n    }\n    bool _412;\n    if (!_405)\n    {\n        _412 = suv.y < 0.0;\n    }\n    else\n    {\n        _412 = _405;\n    }\n    bool _419;\n    if (!_412)\n    {\n        _419 = suv.y > 1.0;\n    }\n    else\n    {\n        _419 = _412;\n    }\n    bool _426;\n    if (!_419)\n    {\n        _426 = p.z > 1.0;\n    }\n    else\n    {\n        _426 = _419;\n    }\n    if (_426)\n    {\n        return 1.0;\n    }\n    float _441 = _357.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _441) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _357.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _357, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2, _357, fa_shadow_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_lights& _239, constant fa_mesh_fs_params& _357, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1568 = fa_light_sample(param, param_1, _239);\n    float3 _2772 = _1568.direction;\n    float3 _2767 = _1568.color;\n    float _2774 = _1568.attenuation;\n    float _2769 = _1568.shadow;\n    int _2777 = _1568.type;\n    if ((_2777 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2772;\n        float _1582 = fa_shadow_factor(param_2, param_3, _357, fa_shadow_tex, fa_shadow_smp, fa_shadow_pos);\n        _2769 = _1582;\n        _2767 = _239.fa_light_color[li].xyz * (_2774 * _1582);\n    }\n    return LightSample{ _2772, _2767, _2774, _2769, _1568._distance, _2777 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _1252 = at * ab;\n    float3 _1263 = float3(ab * tdh, at * bdh, _1252 * ndh);\n    float _1269 = _1252 / dot(_1263, _1263);\n    return ((_1252 * _1269) * _1269) * 0.3183098733425140380859375;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    return fast::clamp(0.5 / fast::max((ndl * length(float3(at * tdv, ab * bdv, ndv))) + (ndv * length(float3(at * tdl, ab * bdl, ndl))), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    return ((2.0 + (1.0 / alpha)) * powr(fast::max(1.0 - (ndh * ndh), 0.0078125), 0.5 / alpha)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / ((ndl + ndv) - (ndl * ndv)), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _1347 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _1425 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _1425) * _1425);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(1.0 - vdh, 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _1347);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _1347));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _1498 = fast::max(dot(L.nc, l), 0.0);\n        float _1504 = fast::max(dot(L.nc, h), 0.0);\n        float _1513 = ((_1504 * _1504) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(1.0 - vdh, 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _1513) * _1513)) * (0.5 / fast::max(mix((2.0 * _1498) * L.coat_ndv, _1498 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1498)) * _1498);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _638 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _641 = _638.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_641 * _641, exp2((-9.27999973297119140625) * ndv)) * _641) + _638.y)) + _638.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _357, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_357.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _357.fa_env_horizon.w)).xyz;\n    }\n    float _541 = rough * rough;\n    float _572 = 0.60000002384185791015625 * _541;\n    return mix(mix(_357.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_357.fa_env_horizon.xyz, _357.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _541)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _572, 0.0500000007450580596923828125 + _572, d.y))), ((_357.fa_env_sky.xyz + _357.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_541 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _357, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _1135;\n        if (L.aniso >= 0.0)\n        {\n            _1135 = L.b;\n        }\n        else\n        {\n            _1135 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_1135, v), _1135), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1168 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _357, fa_env_tex, fa_env_smp) * ((f0 * _1168.x) + (float3(L.f90) * _1168.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _357, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1223 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _357, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _1223.x) + _1223.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _357, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _680 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _357, fa_env_tex, fa_env_smp) * ((f0 * _680.x) + float3(_680.y));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _357 [[buffer(1)]], constant fa_lights& _239 [[buffer(2)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2502 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2502 = -_2502;\n    }\n    float3 _1958 = fast::normalize(_357.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _2502, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1958, short(gl_FrontFacing) };\n    Surface _1963 = fa_standard_surface(param, _357, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2533 = _1963.albedo;\n    float _2534 = _1963.alpha;\n    float3 _2535 = _1963.normal;\n    float _2536 = _1963.metallic;\n    float _2537 = _1963.roughness;\n    float _2538 = _1963.occlusion;\n    float3 _2539 = _1963.emission;\n    float _2540 = _1963.clearcoat;\n    float _2541 = _1963.clearcoat_roughness;\n    float3 _2542 = _1963.sheen_color;\n    float _2543 = _1963.sheen_roughness;\n    float _2544 = _1963.anisotropy;\n    float _2545 = _1963.anisotropy_rotation;\n    float _2546 = _1963.specular;\n    float _2547 = _1963.ior;\n    float3 _2548 = _1963.specular_color;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2502, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1958, short(gl_FrontFacing) };\n    Surface param_2 = _1963;\n    surface(param_1, param_2);\n    _2533 = param_2.albedo;\n    _2534 = param_2.alpha;\n    _2535 = param_2.normal;\n    _2536 = param_2.metallic;\n    _2537 = param_2.roughness;\n    _2538 = param_2.occlusion;\n    _2539 = param_2.emission;\n    _2540 = param_2.clearcoat;\n    _2541 = param_2.clearcoat_roughness;\n    _2542 = param_2.sheen_color;\n    _2543 = param_2.sheen_roughness;\n    _2544 = param_2.anisotropy;\n    _2545 = param_2.anisotropy_rotation;\n    _2546 = param_2.specular;\n    _2547 = param_2.ior;\n    _2548 = param_2.specular_color;\n    float3 result;\n    if (_357.fa_emissive.w > 0.5)\n    {\n        result = _2533;\n    }\n    else\n    {\n        float3 _1985 = fast::normalize(_2535);\n        float _1992 = fast::clamp(_2536, 0.0, 1.0);\n        float _1996 = fast::clamp(_2537, 0.0500000007450580596923828125, 1.0);\n        float _2000 = _1996 * _1996;\n        float _2004 = _2000 * _2000;\n        float _2009 = fast::max(dot(_1985, _1958), 9.9999997473787516355514526367188e-05);\n        float3 _2015 = _2533 * (1.0 - _1992);\n        float3 _2022 = mix(float3(0.039999999105930328369140625), _2533, float3(_1992));\n        float3 f0 = _2022;\n        SurfaceInput param_3 = SurfaceInput{ in.fa_world_pos, _2502, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1958, short(gl_FrontFacing) };\n        Surface param_4 = Surface{ _2533, _2534, _2535, _2536, _2537, _2538, _2539, _2540, _2541, _2542, _2543, _2544, _2545, _2546, _2547, _2548 };\n        float3 param_5 = _1985;\n        float3 param_6 = _1958;\n        float param_7 = _1992;\n        float param_8 = _1996;\n        float3 param_9 = _2022;\n        FaLayers _2038 = fa_layers_setup(param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n        f0 = param_9;\n        float3 param_10 = _1985;\n        float3 lit = (fa_ambient_light(param_10, _357, fa_env_smp, fa_irr_tex) * _2015) * _2538;\n        if (_2038.on)\n        {\n            lit *= _2038.base_scale;\n        }\n        int _2060 = int(_357.fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _2060)\n            {\n                break;\n            }\n            int param_11 = li;\n            float3 param_12 = in.fa_world_pos;\n            float3 param_13 = _2502;\n            LightSample _2084 = fa_light_shadowed(param_11, param_12, param_13, _239, _357, fa_shadow_tex, fa_shadow_smp, in.fa_shadow_pos);\n            float3 _2707 = _2084.direction;\n            float _2092 = fast::max(dot(_1985, _2707), 0.0);\n            float _2098 = _2084.attenuation * _2084.shadow;\n            float3 _2103 = fast::normalize(_2707 + _1958);\n            float _2108 = fast::max(dot(_1985, _2103), 0.0);\n            float _2113 = fast::max(dot(_1958, _2103), 0.0);\n            if (_2038.on)\n            {\n                FaLayers param_14 = _2038;\n                float3 param_15 = _2015;\n                float3 param_16 = f0;\n                float3 param_17 = _1985;\n                float3 param_18 = _1958;\n                float3 param_19 = _2707;\n                float3 param_20 = _2103;\n                float param_21 = _2092;\n                float param_22 = _2009;\n                float param_23 = _2108;\n                float param_24 = _2113;\n                float param_25 = _2000;\n                float param_26 = _2004;\n                lit += (fa_layers_light(param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26) * (_239.fa_light_color[li].xyz * _2098));\n            }\n            else\n            {\n                float _2162 = ((_2108 * _2108) * (_2004 - 1.0)) + 1.0;\n                lit += (((_2015 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _2113, 5.0))) * (((_2004 / ((3.1415927410125732421875 * _2162) * _2162)) * (0.5 / fast::max(mix((2.0 * _2092) * _2009, _2092 + _2009, _2000), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2092))) * _239.fa_light_color[li].xyz) * (_2092 * _2098));\n            }\n        }\n        if (_2038.on)\n        {\n            FaLayers param_27 = _2038;\n            float3 param_28 = _1985;\n            float3 param_29 = _1958;\n            float3 param_30 = f0;\n            float param_31 = _1996;\n            lit += (fa_layers_ibl(param_27, param_28, param_29, param_30, param_31, _357, fa_env_tex, fa_env_smp) * _2538);\n        }\n        else\n        {\n            float3 param_32 = _1985;\n            float3 param_33 = _1958;\n            float3 param_34 = f0;\n            float param_35 = _1996;\n            lit += (fa_sky_reflection(param_32, param_33, param_34, param_35, _357, fa_env_tex, fa_env_smp) * _2538);\n        }\n        result = lit;\n    }\n    result += _2539;\n    bool _2260 = _357.fa_fog.w > 0.0;\n    bool _2267;\n    if (!_2260)\n    {\n        _2267 = _357.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2267 = _2260;\n    }\n    if (_2267)\n    {\n        float3 _2276 = in.fa_world_pos - _357.fa_camera_pos.xyz;\n        float _2282 = dot(_2276, _357.fa_fog_c.xyz);\n        bool _2286 = _357.fa_fog_c.w > 0.5;\n        float _2287;\n        if (_2286)\n        {\n            _2287 = _2282;\n        }\n        else\n        {\n            _2287 = length(_2276);\n        }\n        float _2299 = _2287 - _357.fa_fog_b.x;\n        if (_2299 > 0.0)\n        {\n            float _2308 = _357.fa_fog.w * _2299;\n            float tau = _2308 * _2308;\n            if (_357.fa_fog_b.y > 0.0)\n            {\n                float _2324;\n                if (_2286)\n                {\n                    _2324 = in.fa_world_pos.y - (_357.fa_fog_c.y * _2282);\n                }\n                else\n                {\n                    _2324 = _357.fa_camera_pos.y;\n                }\n                float _2345 = mix(_2324, in.fa_world_pos.y, fast::clamp(_357.fa_fog_b.x / _2287, 0.0, 1.0));\n                float _2349 = in.fa_world_pos.y - _2345;\n                float _2354 = _2345 - _357.fa_fog_b.z;\n                float _2359 = in.fa_world_pos.y - _357.fa_fog_b.z;\n                bool _2362 = _2354 <= 0.0;\n                bool _2363 = !_2362;\n                bool _2369;\n                if (_2363)\n                {\n                    _2369 = _357.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2369 = _2362;\n                }\n                float _2370;\n                if (_2369)\n                {\n                    _2370 = _357.fa_fog_b.y;\n                }\n                else\n                {\n                    _2370 = _357.fa_fog_b.y * exp(-fast::min(_357.fa_fog_b.w * _2354, 80.0));\n                }\n                bool _2397;\n                if (_2363)\n                {\n                    _2397 = _357.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2397 = _2362;\n                }\n                float _2398;\n                if (_2397)\n                {\n                    _2398 = _357.fa_fog_b.y * _2354;\n                }\n                else\n                {\n                    _2398 = (_357.fa_fog_b.y * (1.0 - exp(-fast::min(_357.fa_fog_b.w * _2354, 80.0)))) / _357.fa_fog_b.w;\n                }\n                bool _2423 = _2359 <= 0.0;\n                bool _2430;\n                if (!_2423)\n                {\n                    _2430 = _357.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2430 = _2423;\n                }\n                float _2431;\n                if (_2430)\n                {\n                    _2431 = _357.fa_fog_b.y * _2359;\n                }\n                else\n                {\n                    _2431 = (_357.fa_fog_b.y * (1.0 - exp(-fast::min(_357.fa_fog_b.w * _2359, 80.0)))) / _357.fa_fog_b.w;\n                }\n                float _2458;\n                if (abs(_2349) < 0.001000000047497451305389404296875)\n                {\n                    _2458 = _2370;\n                }\n                else\n                {\n                    _2458 = (_2431 - _2398) / _2349;\n                }\n                tau += (_2299 * fast::max(_2458, 0.0));\n            }\n            result = mix(result, _357.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2534);\n    return out;\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_50",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_150",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_197",
            "msl_buffer_n": 3
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_239",
            "msl_buffer_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_357",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 7,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    packed_float3 offset;\n    float fa_pad0;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _145)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _145.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, constant fa_material_vs& _45)\n{\n    v.world_pos += float3(_45.offset);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_material_vs& _45, constant fa_mesh_vs_params& _145, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _145);\n    vertex0(param_6, _45);\n    float4 _189 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_145.fa_light_vp * _189).z;\n    fa_pre_r0 = float3(_145.fa_light_vp[0].x, _145.fa_light_vp[1].x, _145.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_145.fa_light_vp[0].y, _145.fa_light_vp[1].y, _145.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_145.fa_light_vp[0].z, _145.fa_light_vp[1].z, _145.fa_light_vp[2].z);\n    gl_Position = _145.fa_view_proj * _189;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _145 [[buffer(0)]], constant fa_material_vs& _45 [[buffer(4)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _45, _145, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _733 = base_t;\n    _733.x = _225.x;\n    _733.y = _225.y;\n    _733.z = _225.z;\n    base_t = _733;\n    float4 _241 = (_733 * _213.fa_base_color) * i.vertex_color;\n    float3 _696 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _741 = _279;\n        _741.x = _284.x;\n        _741.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _741;\n        _696 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _744 = mrt;\n    _744.x = _313.x;\n    _744.y = _313.y;\n    _744.z = _313.z;\n    mrt = _744;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _701 = _213.fa_layers_a.x;\n    float _702 = _213.fa_layers_a.y;\n    float _705 = _213.fa_layers_a.z;\n    float _704 = _213.fa_layers_b.w;\n    float _707 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _701 *= _355.y;\n            _702 *= _355.z;\n            _704 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _705 *= mrt.x;\n            _707 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _696, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _701, _702, _213.fa_layers_b.xyz, _704, _705, _213.fa_layers_a.w, _707, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _607 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _607 = -_607;\n    }\n    float3 _517 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _607, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _517, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _607, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _517, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _532 = fast::normalize(param_2.normal);\n    float3 _547 = fast::normalize(float3(dot(in.fa_pre_r0, _532), dot(in.fa_pre_r1, _532), dot(in.fa_pre_r2, _532)));\n    float _559 = _547.z;\n    float2 e = _547.xy / float2((abs(_547.x) + abs(_547.y)) + abs(_559));\n    if (_559 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_45",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_145",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    packed_float3 offset;\n    float fa_pad0;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _197)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _188 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_197.fa_joint_rows[_188] * weights[i]);\n        r1 += (_197.fa_joint_rows[_188 + 1] * weights[i]);\n        r2 += (_197.fa_joint_rows[_188 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _150)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _150.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, constant fa_material_vs& _50)\n{\n    v.world_pos += float3(_50.offset);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_material_vs& _50, constant fa_mesh_vs_params& _150, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _150);\n    vertex0(param_6, _50);\n    float4 _302 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_150.fa_light_vp * _302).z;\n    fa_pre_r0 = float3(_150.fa_light_vp[0].x, _150.fa_light_vp[1].x, _150.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_150.fa_light_vp[0].y, _150.fa_light_vp[1].y, _150.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_150.fa_light_vp[0].z, _150.fa_light_vp[1].z, _150.fa_light_vp[2].z);\n    gl_Position = _150.fa_view_proj * _302;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _150 [[buffer(0)]], constant fa_skin& _197 [[buffer(3)]], constant fa_material_vs& _50 [[buffer(4)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _197);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _50, _150, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _733 = base_t;\n    _733.x = _225.x;\n    _733.y = _225.y;\n    _733.z = _225.z;\n    base_t = _733;\n    float4 _241 = (_733 * _213.fa_base_color) * i.vertex_color;\n    float3 _696 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _741 = _279;\n        _741.x = _284.x;\n        _741.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _741;\n        _696 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _744 = mrt;\n    _744.x = _313.x;\n    _744.y = _313.y;\n    _744.z = _313.z;\n    mrt = _744;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _701 = _213.fa_layers_a.x;\n    float _702 = _213.fa_layers_a.y;\n    float _705 = _213.fa_layers_a.z;\n    float _704 = _213.fa_layers_b.w;\n    float _707 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _701 *= _355.y;\n            _702 *= _355.z;\n            _704 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _705 *= mrt.x;\n            _707 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _696, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _701, _702, _213.fa_layers_b.xyz, _704, _705, _213.fa_layers_a.w, _707, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _607 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _607 = -_607;\n    }\n    float3 _517 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _607, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _517, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _607, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _517, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _532 = fast::normalize(param_2.normal);\n    float3 _547 = fast::normalize(float3(dot(in.fa_pre_r0, _532), dot(in.fa_pre_r1, _532), dot(in.fa_pre_r2, _532)));\n    float _559 = _547.z;\n    float2 e = _547.xy / float2((abs(_547.x) + abs(_547.y)) + abs(_559));\n    if (_559 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_50",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_150",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_197",
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
    },
    "shadow": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    packed_float3 offset;\n    float fa_pad0;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float3 fa_normal [[attribute(5)]];\n    float2 fa_texcoord0 [[attribute(6)]];\n    float4 fa_tangent [[attribute(7)]];\n    float4 fa_color [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, constant fa_material_vs& _36)\n{\n    v.world_pos += float3(_36.offset);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_material_vs& _36 [[buffer(4)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    vertex0(param_6, _36);\n    out.gl_Position = _136.fa_light_vp * float4(param_6.world_pos, 1.0);\n    return out;\n}\n\n",
      "fs": "#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nfragment main0_out main0(float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    out.fa_frag_color = float4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n    return out;\n}\n\n",
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
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec4",
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
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec2",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_36",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "msl_buffer_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    packed_float3 offset;\n    float fa_pad0;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float4 fa_joints [[attribute(5)]];\n    float4 fa_weights [[attribute(6)]];\n    float3 fa_normal [[attribute(7)]];\n    float2 fa_texcoord0 [[attribute(8)]];\n    float4 fa_tangent [[attribute(9)]];\n    float4 fa_color [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _188)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _179 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_188.fa_joint_rows[_179] * weights[i]);\n        r1 += (_188.fa_joint_rows[_179 + 1] * weights[i]);\n        r2 += (_188.fa_joint_rows[_179 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _141)\n{\n    float3 _79 = cross(model[1].xyz, model[2].xyz);\n    float _85 = (dot(model[0].xyz, _79) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_79 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _85, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _85), texcoord0 * _141.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, constant fa_material_vs& _41)\n{\n    v.world_pos += float3(_41.offset);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _141 [[buffer(0)]], constant fa_skin& _188 [[buffer(3)]], constant fa_material_vs& _41 [[buffer(4)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _188);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7, _141);\n    vertex0(param_8, _41);\n    out.gl_Position = _141.fa_light_vp * float4(param_8.world_pos, 1.0);\n    return out;\n}\n\n",
      "fs": "#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nfragment main0_out main0(float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    out.fa_frag_color = float4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n    return out;\n}\n\n",
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
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec4",
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
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec2",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_41",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_141",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_188",
            "msl_buffer_n": 3
          }
        ]
      }
    }
  }
}
