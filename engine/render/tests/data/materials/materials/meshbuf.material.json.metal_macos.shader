{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "67b1186c6e51021b07dd68cec7aaad42a4febc7364ef358b4473bc1e089911c0",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "buffers": [
    {
      "name": "points",
      "binding": 0,
      "stride": 32,
      "access": "read",
      "fields": [
        {
          "name": "pos",
          "type": "vec4",
          "offset": 0
        },
        {
          "name": "tint",
          "type": "vec4",
          "offset": 16
        }
      ]
    }
  ],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _168)\n{\n    float3 _109 = cross(model[1].xyz, model[2].xyz);\n    float _114 = (dot(model[0].xyz, _109) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_109 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _114, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _114), texcoord0 * _168.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex)\n{\n    if (fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, constant fa_mesh_vs_params& _168, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _168);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex);\n    float4 _206 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = _168.fa_light_vp * _206;\n    gl_Position = _168.fa_view_proj * _206;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _168 [[buffer(0)]], constant fa_inst_base& _243 [[buffer(6)]], const device fa_vs_points_buf& fa_vs_points [[buffer(8)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = _243.fa_base_model;\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, fa_vs_points, gl_InstanceIndex, _168, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nconstant spvUnsafeArray<float, 63> _790 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1706 = fa_linear_to_srgb(param);\n        c = _1706;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1714 = fa_srgb_to_linear(param_1);\n            c = _1714;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _174;\n    if (bool(i.front_facing))\n    {\n        _174 = i.world_normal;\n    }\n    else\n    {\n        _174 = -i.world_normal;\n    }\n    float3 _198 = fast::normalize(i.world_tangent.xyz - (_174 * dot(_174, i.world_tangent.xyz)));\n    float3 _226 = fast::normalize(((_198 * m.x) + ((cross(_174, _198) * i.world_tangent.w) * m.y)) + (_174 * m.z));\n    float3 _229;\n    if (bool(i.front_facing))\n    {\n        _229 = _226;\n    }\n    else\n    {\n        _229 = -_226;\n    }\n    return _229;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _364, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _364.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1745 = fa_tex_fix(param_2, param_3);\n    float4 _2902 = base_t;\n    _2902.x = _1745.x;\n    _2902.y = _1745.y;\n    _2902.z = _1745.z;\n    base_t = _2902;\n    float4 _1759 = (_2902 * _364.fa_base_color) * i.vertex_color;\n    float3 _2845 = i.world_normal;\n    if (_364.fa_maps.z > 0.5)\n    {\n        float param_4 = _364.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1792 = fa_tex_fix(param_6, param_7);\n        float3 _1795 = (_1792 * 2.0) - float3(1.0);\n        float2 _1800 = _1795.xy * _364.fa_maps.x;\n        float3 _2910 = _1795;\n        _2910.x = _1800.x;\n        _2910.y = _1800.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2910;\n        _2845 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _364.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1829 = fa_tex_fix(param_12, param_13);\n    float4 _2913 = mrt;\n    _2913.x = _1829.x;\n    _2913.y = _1829.y;\n    _2913.z = _1829.z;\n    mrt = _2913;\n    float4 _1857 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _364.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _1857.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1869 = fa_tex_fix(param_16, param_17);\n    float param_18 = _364.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1899 = fa_tex_fix(param_20, param_21);\n    float _2850 = _364.fa_layers_a.x;\n    float _2851 = _364.fa_layers_a.y;\n    float _2854 = _364.fa_layers_a.z;\n    float _2853 = _364.fa_layers_b.w;\n    float _2856 = _364.fa_layers_c.x;\n    if (_364.fa_layers_c.z > 0.5)\n    {\n        if (mod(_364.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2850 *= _1869.y;\n            _2851 *= _1869.z;\n            _2853 *= _1857.w;\n        }\n        if (_364.fa_layers_c.z > 1.5)\n        {\n            _2854 *= mrt.x;\n            _2856 *= mrt.w;\n        }\n    }\n    return Surface{ _1759.xyz, _1759.w, _2845, fast::clamp(_364.fa_pbr.x * _1829.z, 0.0, 1.0), fast::clamp(_364.fa_pbr.y * _1829.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_364.fa_maps.y * (_1869.x - 1.0)), _364.fa_emissive.xyz + (_364.fa_model_emissive.xyz * _1899), _2850, _2851, _364.fa_layers_b.xyz, _2853, _2854, _364.fa_layers_a.w, _2856, _364.fa_layers_c.y, _364.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, const device fa_points_buf& points)\n{\n    s.emission += (i.vertex_color.xyz * ((device float*)&points.data[0].tint)[3u]);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _715 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _723 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _726 = int(_715);\n    int _729 = int(_723);\n    float _739 = _723 - float(_729);\n    int _795 = (_726 * 9) + _729;\n    int _815 = ((_726 + 1) * 9) + _729;\n    return mix(mix(_790[_795], _790[_795 + 1], _739), mix(_790[_815], _790[_815 + 1], _739), _715 - float(_726));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _2781 = false;\n    float _2782 = 1.0;\n    float _2783 = 1.0;\n    float _2784 = 1.0;\n    float _2785 = 0.0;\n    float _2786 = 0.0;\n    float _2787 = 0.0;\n    float _2788 = 0.0;\n    float _2790 = 1.0;\n    bool _2791 = false;\n    float3 _2792 = float3(0.0);\n    float _2793 = 1.0;\n    float _2794 = 1.0;\n    float _2795 = 1.0;\n    float _2796 = 0.0;\n    float _2797 = 0.0;\n    float3 _2798 = float3(1.0, 0.0, 0.0);\n    float3 _2799 = float3(0.0, 0.0, 1.0);\n    float _2800 = 1.0;\n    float _2801 = 1.0;\n    float _877 = fast::clamp(s.specular, 0.0, 1.0);\n    float _882 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _887 = (_877 != 1.0) || (_882 != 1.5);\n    bool _897;\n    if (!_887)\n    {\n        _897 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _897 = _887;\n    }\n    if (_897)\n    {\n        float _905 = (_882 - 1.0) / (_882 + 1.0);\n        f0 = mix(fast::min(float3(_905 * _905) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _877, s.albedo, float3(metallic));\n        _2782 = mix(_877, 1.0, metallic);\n        _2781 = true;\n    }\n    float _933 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_933 > 0.0)\n    {\n        float _941 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _2785 = _933;\n        _2786 = _941;\n        float _948 = _941 * _941;\n        _2787 = _948;\n        _2788 = _948 * _948;\n        float _960 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _2790 = _960;\n        _2783 = 1.0 - (_933 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _960, 0.0, 1.0), 5.0))));\n        _2781 = true;\n    }\n    float3 _980 = fast::max(s.sheen_color, float3(0.0));\n    float _989 = fast::max(_980.x, fast::max(_980.y, _980.z));\n    if (_989 > 0.0)\n    {\n        float _997 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _2791 = true;\n        _2792 = _980;\n        _2793 = _997;\n        _2794 = _997 * _997;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _997;\n        float _1014 = fa_sheen_albedo(param, param_1);\n        _2796 = _1014;\n        _2795 = 1.0 - fast::min(_989 * _1014, 1.0);\n        _2781 = true;\n    }\n    _2784 = _2783 * _2795;\n    float _1033 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_1033 != 0.0)\n    {\n        float3 _1048 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1048;\n        if (dot(_1048, _1048) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _1066 = t;\n        float3 _1067 = fast::normalize(_1066);\n        t = _1067;\n        float3 _1092 = fast::normalize((_1067 * cos(s.anisotropy_rotation)) + ((cross(n, _1067) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _2798 = _1092;\n        _2799 = cross(n, _1092);\n        float _1102 = roughness * roughness;\n        float _1108 = mix(_1102, 1.0, _1033 * _1033);\n        bool _1110 = _1033 > 0.0;\n        _2800 = _1110 ? _1108 : _1102;\n        _2801 = _1110 ? _1102 : _1108;\n        _2797 = _1033;\n        _2781 = true;\n    }\n    return FaLayers{ short(_2781), _2782, _2783, _2784, _2785, _2786, _2787, _2788, i.world_normal, _2790, short(_2791), _2792, _2793, _2794, _2795, _2796, _2797, _2798, _2799, _2800, _2801 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _364, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_364.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _364.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _246)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _257 = _246.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_257)\n    {\n        l = fast::normalize(_246.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _275 = _246.fa_light_pos[li].xyz - world_pos;\n        float _277 = length(_275);\n        dist = _277;\n        l = _275 / float3(fast::max(_277, 9.9999997473787516355514526367188e-05));\n        float _293 = _277 / fast::max(_246.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _299 = fast::clamp(1.0 - (_293 * _293), 0.0, 1.0);\n        atten = _299 * _299;\n        if (_246.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_246.fa_light_dir[li].w, mix(_246.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_246.fa_light_dir[li].xyz)));\n        }\n    }\n    int _350;\n    if (_257)\n    {\n        _350 = 0;\n    }\n    else\n    {\n        _350 = (_246.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _246.fa_light_color[li].xyz * atten, atten, 1.0, dist, _350 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_pcf(thread const float4& coord, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _364, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_364.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _377 = coord.xyz / float3(coord.w);\n    float3 p = _377;\n    float2 suv = (_377.xy * 0.5) + float2(0.5);\n    if (_364.fa_counts.z > 0.5)\n    {\n        float3 _2877 = p;\n        _2877.z = (_2877.z * 0.5) + 0.5;\n        p = _2877;\n    }\n    else\n    {\n        float2 _2880 = suv;\n        _2880.y = 1.0 - _2880.y;\n        suv = _2880;\n    }\n    bool _405 = suv.x < 0.0;\n    bool _412;\n    if (!_405)\n    {\n        _412 = suv.x > 1.0;\n    }\n    else\n    {\n        _412 = _405;\n    }\n    bool _419;\n    if (!_412)\n    {\n        _419 = suv.y < 0.0;\n    }\n    else\n    {\n        _419 = _412;\n    }\n    bool _426;\n    if (!_419)\n    {\n        _426 = suv.y > 1.0;\n    }\n    else\n    {\n        _426 = _419;\n    }\n    bool _433;\n    if (!_426)\n    {\n        _433 = p.z > 1.0;\n    }\n    else\n    {\n        _433 = _426;\n    }\n    if (_433)\n    {\n        return 1.0;\n    }\n    float _448 = _364.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _448) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _364.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _364, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2, _364, fa_shadow_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_lights& _246, constant fa_mesh_fs_params& _364, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1614 = fa_light_sample(param, param_1, _246);\n    float3 _2830 = _1614.direction;\n    float3 _2825 = _1614.color;\n    float _2832 = _1614.attenuation;\n    float _2827 = _1614.shadow;\n    int _2835 = _1614.type;\n    if ((_2835 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2830;\n        float _1628 = fa_shadow_factor(param_2, param_3, _364, fa_shadow_tex, fa_shadow_smp, fa_shadow_pos);\n        _2827 = _1628;\n        _2825 = _246.fa_light_color[li].xyz * (_2832 * _1628);\n    }\n    return LightSample{ _2830, _2825, _2832, _2827, _1614._distance, _2835 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _1260 = tdh / at;\n    float _1264 = bdh / ab;\n    float _1276 = ((_1260 * _1260) + (_1264 * _1264)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _1276) * _1276);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _1358 = 1.0 / alpha;\n    return ((2.0 + _1358) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _1358)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _1391 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _1470 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _1470) * _1470);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _1391);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _1391));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _1543 = fast::max(dot(L.nc, l), 0.0);\n        float _1549 = fast::max(dot(L.nc, h), 0.0);\n        float _1558 = ((_1549 * _1549) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _1558) * _1558)) * (0.5 / fast::max(mix((2.0 * _1543) * L.coat_ndv, _1543 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1543)) * _1543);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _645 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _648 = _645.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_648 * _648, exp2((-9.27999973297119140625) * ndv)) * _648) + _645.y)) + _645.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _364, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_364.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _364.fa_env_horizon.w)).xyz;\n    }\n    float _548 = rough * rough;\n    float _579 = 0.60000002384185791015625 * _548;\n    return mix(mix(_364.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_364.fa_env_horizon.xyz, _364.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _548)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _579, 0.0500000007450580596923828125 + _579, d.y))), ((_364.fa_env_sky.xyz + _364.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_548 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _364, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _1143;\n        if (L.aniso >= 0.0)\n        {\n            _1143 = L.b;\n        }\n        else\n        {\n            _1143 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_1143, v), _1143), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1176 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _364, fa_env_tex, fa_env_smp) * ((f0 * _1176.x) + (float3(L.f90) * _1176.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _364, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1231 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _364, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _1231.x) + _1231.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _364, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _687 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _364, fa_env_tex, fa_env_smp) * ((f0 * _687.x) + float3(_687.y));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _364 [[buffer(1)]], constant fa_lights& _246 [[buffer(2)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2560 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2560 = -_2560;\n    }\n    float3 _2019 = fast::normalize(_364.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _2560, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2019, short(gl_FrontFacing) };\n    Surface _2024 = fa_standard_surface(param, _364, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2591 = _2024.albedo;\n    float _2592 = _2024.alpha;\n    float3 _2593 = _2024.normal;\n    float _2594 = _2024.metallic;\n    float _2595 = _2024.roughness;\n    float _2596 = _2024.occlusion;\n    float3 _2597 = _2024.emission;\n    float _2598 = _2024.clearcoat;\n    float _2599 = _2024.clearcoat_roughness;\n    float3 _2600 = _2024.sheen_color;\n    float _2601 = _2024.sheen_roughness;\n    float _2602 = _2024.anisotropy;\n    float _2603 = _2024.anisotropy_rotation;\n    float _2604 = _2024.specular;\n    float _2605 = _2024.ior;\n    float3 _2606 = _2024.specular_color;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2560, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2019, short(gl_FrontFacing) };\n    Surface param_2 = _2024;\n    surface(param_1, param_2, points);\n    _2591 = param_2.albedo;\n    _2592 = param_2.alpha;\n    _2593 = param_2.normal;\n    _2594 = param_2.metallic;\n    _2595 = param_2.roughness;\n    _2596 = param_2.occlusion;\n    _2597 = param_2.emission;\n    _2598 = param_2.clearcoat;\n    _2599 = param_2.clearcoat_roughness;\n    _2600 = param_2.sheen_color;\n    _2601 = param_2.sheen_roughness;\n    _2602 = param_2.anisotropy;\n    _2603 = param_2.anisotropy_rotation;\n    _2604 = param_2.specular;\n    _2605 = param_2.ior;\n    _2606 = param_2.specular_color;\n    float3 result;\n    if (_364.fa_emissive.w > 0.5)\n    {\n        result = _2591;\n    }\n    else\n    {\n        float3 _2046 = fast::normalize(_2593);\n        float _2053 = fast::clamp(_2594, 0.0, 1.0);\n        float _2057 = fast::clamp(_2595, 0.0500000007450580596923828125, 1.0);\n        float _2061 = _2057 * _2057;\n        float _2065 = _2061 * _2061;\n        float _2070 = fast::max(dot(_2046, _2019), 9.9999997473787516355514526367188e-05);\n        float3 _2076 = _2591 * (1.0 - _2053);\n        float3 _2083 = mix(float3(0.039999999105930328369140625), _2591, float3(_2053));\n        float3 f0 = _2083;\n        SurfaceInput param_3 = SurfaceInput{ in.fa_world_pos, _2560, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2019, short(gl_FrontFacing) };\n        Surface param_4 = Surface{ _2591, _2592, _2593, _2594, _2595, _2596, _2597, _2598, _2599, _2600, _2601, _2602, _2603, _2604, _2605, _2606 };\n        float3 param_5 = _2046;\n        float3 param_6 = _2019;\n        float param_7 = _2053;\n        float param_8 = _2057;\n        float3 param_9 = _2083;\n        FaLayers _2099 = fa_layers_setup(param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n        f0 = param_9;\n        float3 param_10 = _2046;\n        float3 lit = (fa_ambient_light(param_10, _364, fa_env_smp, fa_irr_tex) * _2076) * _2596;\n        if (_2099.on)\n        {\n            lit *= _2099.base_scale;\n        }\n        int _2121 = int(_364.fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _2121)\n            {\n                break;\n            }\n            int param_11 = li;\n            float3 param_12 = in.fa_world_pos;\n            float3 param_13 = _2560;\n            LightSample _2145 = fa_light_shadowed(param_11, param_12, param_13, _246, _364, fa_shadow_tex, fa_shadow_smp, in.fa_shadow_pos);\n            float3 _2765 = _2145.direction;\n            float _2153 = fast::max(dot(_2046, _2765), 0.0);\n            float _2159 = _2145.attenuation * _2145.shadow;\n            float3 _2164 = fast::normalize(_2765 + _2019);\n            float _2169 = fast::max(dot(_2046, _2164), 0.0);\n            float _2174 = fast::max(dot(_2019, _2164), 0.0);\n            if (_2099.on)\n            {\n                FaLayers param_14 = _2099;\n                float3 param_15 = _2076;\n                float3 param_16 = f0;\n                float3 param_17 = _2046;\n                float3 param_18 = _2019;\n                float3 param_19 = _2765;\n                float3 param_20 = _2164;\n                float param_21 = _2153;\n                float param_22 = _2070;\n                float param_23 = _2169;\n                float param_24 = _2174;\n                float param_25 = _2061;\n                float param_26 = _2065;\n                lit += (fa_layers_light(param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26) * (_246.fa_light_color[li].xyz * _2159));\n            }\n            else\n            {\n                float _2223 = ((_2169 * _2169) * (_2065 - 1.0)) + 1.0;\n                lit += (((_2076 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _2174, 5.0))) * (((_2065 / ((3.1415927410125732421875 * _2223) * _2223)) * (0.5 / fast::max(mix((2.0 * _2153) * _2070, _2153 + _2070, _2061), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2153))) * _246.fa_light_color[li].xyz) * (_2153 * _2159));\n            }\n        }\n        if (_2099.on)\n        {\n            FaLayers param_27 = _2099;\n            float3 param_28 = _2046;\n            float3 param_29 = _2019;\n            float3 param_30 = f0;\n            float param_31 = _2057;\n            lit += (fa_layers_ibl(param_27, param_28, param_29, param_30, param_31, _364, fa_env_tex, fa_env_smp) * _2596);\n        }\n        else\n        {\n            float3 param_32 = _2046;\n            float3 param_33 = _2019;\n            float3 param_34 = f0;\n            float param_35 = _2057;\n            lit += (fa_sky_reflection(param_32, param_33, param_34, param_35, _364, fa_env_tex, fa_env_smp) * _2596);\n        }\n        result = lit;\n    }\n    result += _2597;\n    bool _2321 = _364.fa_fog.w > 0.0;\n    bool _2328;\n    if (!_2321)\n    {\n        _2328 = _364.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2328 = _2321;\n    }\n    if (_2328)\n    {\n        float3 _2337 = in.fa_world_pos - _364.fa_camera_pos.xyz;\n        float _2343 = dot(_2337, _364.fa_fog_c.xyz);\n        bool _2347 = _364.fa_fog_c.w > 0.5;\n        float _2348;\n        if (_2347)\n        {\n            _2348 = _2343;\n        }\n        else\n        {\n            _2348 = length(_2337);\n        }\n        float _2360 = _2348 - _364.fa_fog_b.x;\n        if (_2360 > 0.0)\n        {\n            float _2369 = _364.fa_fog.w * _2360;\n            float tau = _2369 * _2369;\n            if (_364.fa_fog_b.y > 0.0)\n            {\n                float _2385;\n                if (_2347)\n                {\n                    _2385 = in.fa_world_pos.y - (_364.fa_fog_c.y * _2343);\n                }\n                else\n                {\n                    _2385 = _364.fa_camera_pos.y;\n                }\n                float _2406 = mix(_2385, in.fa_world_pos.y, fast::clamp(_364.fa_fog_b.x / _2348, 0.0, 1.0));\n                float _2410 = in.fa_world_pos.y - _2406;\n                float _2415 = _2406 - _364.fa_fog_b.z;\n                float _2420 = in.fa_world_pos.y - _364.fa_fog_b.z;\n                bool _2423 = _2415 <= 0.0;\n                bool _2424 = !_2423;\n                bool _2430;\n                if (_2424)\n                {\n                    _2430 = _364.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2430 = _2423;\n                }\n                float _2431;\n                if (_2430)\n                {\n                    _2431 = _364.fa_fog_b.y;\n                }\n                else\n                {\n                    _2431 = _364.fa_fog_b.y * exp(-fast::min(_364.fa_fog_b.w * _2415, 80.0));\n                }\n                bool _2458;\n                if (_2424)\n                {\n                    _2458 = _364.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2458 = _2423;\n                }\n                float _2459;\n                if (_2458)\n                {\n                    _2459 = _364.fa_fog_b.y * _2415;\n                }\n                else\n                {\n                    _2459 = (_364.fa_fog_b.y * (1.0 - exp(-fast::min(_364.fa_fog_b.w * _2415, 80.0)))) / _364.fa_fog_b.w;\n                }\n                bool _2484 = _2420 <= 0.0;\n                bool _2491;\n                if (!_2484)\n                {\n                    _2491 = _364.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2491 = _2484;\n                }\n                float _2492;\n                if (_2491)\n                {\n                    _2492 = _364.fa_fog_b.y * _2420;\n                }\n                else\n                {\n                    _2492 = (_364.fa_fog_b.y * (1.0 - exp(-fast::min(_364.fa_fog_b.w * _2420, 80.0)))) / _364.fa_fog_b.w;\n                }\n                float _2519;\n                if (abs(_2410) < 0.001000000047497451305389404296875)\n                {\n                    _2519 = _2431;\n                }\n                else\n                {\n                    _2519 = (_2492 - _2459) / _2410;\n                }\n                tau += (_2360 * fast::max(_2519, 0.0));\n            }\n            result = mix(result, _364.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2592);\n    return out;\n}\n\n",
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
            "inst_name": "_168",
            "msl_buffer_n": 0
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_243",
            "msl_buffer_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_246",
            "msl_buffer_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_364",
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
          },
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 8
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 8
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _217)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _208 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_217.fa_joint_rows[_208] * weights[i]);\n        r1 += (_217.fa_joint_rows[_208 + 1] * weights[i]);\n        r2 += (_217.fa_joint_rows[_208 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _173)\n{\n    float3 _114 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _114) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_114 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * _173.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex)\n{\n    if (fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, constant fa_mesh_vs_params& _173, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _173);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex);\n    float4 _318 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = _173.fa_light_vp * _318;\n    gl_Position = _173.fa_view_proj * _318;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _173 [[buffer(0)]], constant fa_skin& _217 [[buffer(3)]], constant fa_inst_base& _355 [[buffer(6)]], const device fa_vs_points_buf& fa_vs_points [[buffer(8)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = _355.fa_base_model * fa_skin_matrix(param, param_1, _217);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, fa_vs_points, gl_InstanceIndex, _173, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nconstant spvUnsafeArray<float, 63> _790 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1706 = fa_linear_to_srgb(param);\n        c = _1706;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1714 = fa_srgb_to_linear(param_1);\n            c = _1714;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _174;\n    if (bool(i.front_facing))\n    {\n        _174 = i.world_normal;\n    }\n    else\n    {\n        _174 = -i.world_normal;\n    }\n    float3 _198 = fast::normalize(i.world_tangent.xyz - (_174 * dot(_174, i.world_tangent.xyz)));\n    float3 _226 = fast::normalize(((_198 * m.x) + ((cross(_174, _198) * i.world_tangent.w) * m.y)) + (_174 * m.z));\n    float3 _229;\n    if (bool(i.front_facing))\n    {\n        _229 = _226;\n    }\n    else\n    {\n        _229 = -_226;\n    }\n    return _229;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _364, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _364.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1745 = fa_tex_fix(param_2, param_3);\n    float4 _2902 = base_t;\n    _2902.x = _1745.x;\n    _2902.y = _1745.y;\n    _2902.z = _1745.z;\n    base_t = _2902;\n    float4 _1759 = (_2902 * _364.fa_base_color) * i.vertex_color;\n    float3 _2845 = i.world_normal;\n    if (_364.fa_maps.z > 0.5)\n    {\n        float param_4 = _364.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1792 = fa_tex_fix(param_6, param_7);\n        float3 _1795 = (_1792 * 2.0) - float3(1.0);\n        float2 _1800 = _1795.xy * _364.fa_maps.x;\n        float3 _2910 = _1795;\n        _2910.x = _1800.x;\n        _2910.y = _1800.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2910;\n        _2845 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _364.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1829 = fa_tex_fix(param_12, param_13);\n    float4 _2913 = mrt;\n    _2913.x = _1829.x;\n    _2913.y = _1829.y;\n    _2913.z = _1829.z;\n    mrt = _2913;\n    float4 _1857 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _364.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _1857.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1869 = fa_tex_fix(param_16, param_17);\n    float param_18 = _364.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1899 = fa_tex_fix(param_20, param_21);\n    float _2850 = _364.fa_layers_a.x;\n    float _2851 = _364.fa_layers_a.y;\n    float _2854 = _364.fa_layers_a.z;\n    float _2853 = _364.fa_layers_b.w;\n    float _2856 = _364.fa_layers_c.x;\n    if (_364.fa_layers_c.z > 0.5)\n    {\n        if (mod(_364.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2850 *= _1869.y;\n            _2851 *= _1869.z;\n            _2853 *= _1857.w;\n        }\n        if (_364.fa_layers_c.z > 1.5)\n        {\n            _2854 *= mrt.x;\n            _2856 *= mrt.w;\n        }\n    }\n    return Surface{ _1759.xyz, _1759.w, _2845, fast::clamp(_364.fa_pbr.x * _1829.z, 0.0, 1.0), fast::clamp(_364.fa_pbr.y * _1829.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_364.fa_maps.y * (_1869.x - 1.0)), _364.fa_emissive.xyz + (_364.fa_model_emissive.xyz * _1899), _2850, _2851, _364.fa_layers_b.xyz, _2853, _2854, _364.fa_layers_a.w, _2856, _364.fa_layers_c.y, _364.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, const device fa_points_buf& points)\n{\n    s.emission += (i.vertex_color.xyz * ((device float*)&points.data[0].tint)[3u]);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _715 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _723 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _726 = int(_715);\n    int _729 = int(_723);\n    float _739 = _723 - float(_729);\n    int _795 = (_726 * 9) + _729;\n    int _815 = ((_726 + 1) * 9) + _729;\n    return mix(mix(_790[_795], _790[_795 + 1], _739), mix(_790[_815], _790[_815 + 1], _739), _715 - float(_726));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _2781 = false;\n    float _2782 = 1.0;\n    float _2783 = 1.0;\n    float _2784 = 1.0;\n    float _2785 = 0.0;\n    float _2786 = 0.0;\n    float _2787 = 0.0;\n    float _2788 = 0.0;\n    float _2790 = 1.0;\n    bool _2791 = false;\n    float3 _2792 = float3(0.0);\n    float _2793 = 1.0;\n    float _2794 = 1.0;\n    float _2795 = 1.0;\n    float _2796 = 0.0;\n    float _2797 = 0.0;\n    float3 _2798 = float3(1.0, 0.0, 0.0);\n    float3 _2799 = float3(0.0, 0.0, 1.0);\n    float _2800 = 1.0;\n    float _2801 = 1.0;\n    float _877 = fast::clamp(s.specular, 0.0, 1.0);\n    float _882 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _887 = (_877 != 1.0) || (_882 != 1.5);\n    bool _897;\n    if (!_887)\n    {\n        _897 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _897 = _887;\n    }\n    if (_897)\n    {\n        float _905 = (_882 - 1.0) / (_882 + 1.0);\n        f0 = mix(fast::min(float3(_905 * _905) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _877, s.albedo, float3(metallic));\n        _2782 = mix(_877, 1.0, metallic);\n        _2781 = true;\n    }\n    float _933 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_933 > 0.0)\n    {\n        float _941 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _2785 = _933;\n        _2786 = _941;\n        float _948 = _941 * _941;\n        _2787 = _948;\n        _2788 = _948 * _948;\n        float _960 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _2790 = _960;\n        _2783 = 1.0 - (_933 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _960, 0.0, 1.0), 5.0))));\n        _2781 = true;\n    }\n    float3 _980 = fast::max(s.sheen_color, float3(0.0));\n    float _989 = fast::max(_980.x, fast::max(_980.y, _980.z));\n    if (_989 > 0.0)\n    {\n        float _997 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _2791 = true;\n        _2792 = _980;\n        _2793 = _997;\n        _2794 = _997 * _997;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _997;\n        float _1014 = fa_sheen_albedo(param, param_1);\n        _2796 = _1014;\n        _2795 = 1.0 - fast::min(_989 * _1014, 1.0);\n        _2781 = true;\n    }\n    _2784 = _2783 * _2795;\n    float _1033 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_1033 != 0.0)\n    {\n        float3 _1048 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1048;\n        if (dot(_1048, _1048) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _1066 = t;\n        float3 _1067 = fast::normalize(_1066);\n        t = _1067;\n        float3 _1092 = fast::normalize((_1067 * cos(s.anisotropy_rotation)) + ((cross(n, _1067) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _2798 = _1092;\n        _2799 = cross(n, _1092);\n        float _1102 = roughness * roughness;\n        float _1108 = mix(_1102, 1.0, _1033 * _1033);\n        bool _1110 = _1033 > 0.0;\n        _2800 = _1110 ? _1108 : _1102;\n        _2801 = _1110 ? _1102 : _1108;\n        _2797 = _1033;\n        _2781 = true;\n    }\n    return FaLayers{ short(_2781), _2782, _2783, _2784, _2785, _2786, _2787, _2788, i.world_normal, _2790, short(_2791), _2792, _2793, _2794, _2795, _2796, _2797, _2798, _2799, _2800, _2801 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _364, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_364.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _364.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _246)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _257 = _246.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_257)\n    {\n        l = fast::normalize(_246.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _275 = _246.fa_light_pos[li].xyz - world_pos;\n        float _277 = length(_275);\n        dist = _277;\n        l = _275 / float3(fast::max(_277, 9.9999997473787516355514526367188e-05));\n        float _293 = _277 / fast::max(_246.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _299 = fast::clamp(1.0 - (_293 * _293), 0.0, 1.0);\n        atten = _299 * _299;\n        if (_246.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_246.fa_light_dir[li].w, mix(_246.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_246.fa_light_dir[li].xyz)));\n        }\n    }\n    int _350;\n    if (_257)\n    {\n        _350 = 0;\n    }\n    else\n    {\n        _350 = (_246.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _246.fa_light_color[li].xyz * atten, atten, 1.0, dist, _350 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_pcf(thread const float4& coord, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _364, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_364.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _377 = coord.xyz / float3(coord.w);\n    float3 p = _377;\n    float2 suv = (_377.xy * 0.5) + float2(0.5);\n    if (_364.fa_counts.z > 0.5)\n    {\n        float3 _2877 = p;\n        _2877.z = (_2877.z * 0.5) + 0.5;\n        p = _2877;\n    }\n    else\n    {\n        float2 _2880 = suv;\n        _2880.y = 1.0 - _2880.y;\n        suv = _2880;\n    }\n    bool _405 = suv.x < 0.0;\n    bool _412;\n    if (!_405)\n    {\n        _412 = suv.x > 1.0;\n    }\n    else\n    {\n        _412 = _405;\n    }\n    bool _419;\n    if (!_412)\n    {\n        _419 = suv.y < 0.0;\n    }\n    else\n    {\n        _419 = _412;\n    }\n    bool _426;\n    if (!_419)\n    {\n        _426 = suv.y > 1.0;\n    }\n    else\n    {\n        _426 = _419;\n    }\n    bool _433;\n    if (!_426)\n    {\n        _433 = p.z > 1.0;\n    }\n    else\n    {\n        _433 = _426;\n    }\n    if (_433)\n    {\n        return 1.0;\n    }\n    float _448 = _364.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _448) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _364.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _364, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2, _364, fa_shadow_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_lights& _246, constant fa_mesh_fs_params& _364, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1614 = fa_light_sample(param, param_1, _246);\n    float3 _2830 = _1614.direction;\n    float3 _2825 = _1614.color;\n    float _2832 = _1614.attenuation;\n    float _2827 = _1614.shadow;\n    int _2835 = _1614.type;\n    if ((_2835 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2830;\n        float _1628 = fa_shadow_factor(param_2, param_3, _364, fa_shadow_tex, fa_shadow_smp, fa_shadow_pos);\n        _2827 = _1628;\n        _2825 = _246.fa_light_color[li].xyz * (_2832 * _1628);\n    }\n    return LightSample{ _2830, _2825, _2832, _2827, _1614._distance, _2835 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _1260 = tdh / at;\n    float _1264 = bdh / ab;\n    float _1276 = ((_1260 * _1260) + (_1264 * _1264)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _1276) * _1276);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _1358 = 1.0 / alpha;\n    return ((2.0 + _1358) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _1358)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _1391 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _1470 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _1470) * _1470);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _1391);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _1391));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _1543 = fast::max(dot(L.nc, l), 0.0);\n        float _1549 = fast::max(dot(L.nc, h), 0.0);\n        float _1558 = ((_1549 * _1549) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _1558) * _1558)) * (0.5 / fast::max(mix((2.0 * _1543) * L.coat_ndv, _1543 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1543)) * _1543);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _645 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _648 = _645.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_648 * _648, exp2((-9.27999973297119140625) * ndv)) * _648) + _645.y)) + _645.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _364, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_364.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _364.fa_env_horizon.w)).xyz;\n    }\n    float _548 = rough * rough;\n    float _579 = 0.60000002384185791015625 * _548;\n    return mix(mix(_364.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_364.fa_env_horizon.xyz, _364.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _548)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _579, 0.0500000007450580596923828125 + _579, d.y))), ((_364.fa_env_sky.xyz + _364.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_548 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _364, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _1143;\n        if (L.aniso >= 0.0)\n        {\n            _1143 = L.b;\n        }\n        else\n        {\n            _1143 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_1143, v), _1143), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1176 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _364, fa_env_tex, fa_env_smp) * ((f0 * _1176.x) + (float3(L.f90) * _1176.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _364, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1231 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _364, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _1231.x) + _1231.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _364, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _687 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _364, fa_env_tex, fa_env_smp) * ((f0 * _687.x) + float3(_687.y));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _364 [[buffer(1)]], constant fa_lights& _246 [[buffer(2)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2560 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2560 = -_2560;\n    }\n    float3 _2019 = fast::normalize(_364.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _2560, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2019, short(gl_FrontFacing) };\n    Surface _2024 = fa_standard_surface(param, _364, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2591 = _2024.albedo;\n    float _2592 = _2024.alpha;\n    float3 _2593 = _2024.normal;\n    float _2594 = _2024.metallic;\n    float _2595 = _2024.roughness;\n    float _2596 = _2024.occlusion;\n    float3 _2597 = _2024.emission;\n    float _2598 = _2024.clearcoat;\n    float _2599 = _2024.clearcoat_roughness;\n    float3 _2600 = _2024.sheen_color;\n    float _2601 = _2024.sheen_roughness;\n    float _2602 = _2024.anisotropy;\n    float _2603 = _2024.anisotropy_rotation;\n    float _2604 = _2024.specular;\n    float _2605 = _2024.ior;\n    float3 _2606 = _2024.specular_color;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2560, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2019, short(gl_FrontFacing) };\n    Surface param_2 = _2024;\n    surface(param_1, param_2, points);\n    _2591 = param_2.albedo;\n    _2592 = param_2.alpha;\n    _2593 = param_2.normal;\n    _2594 = param_2.metallic;\n    _2595 = param_2.roughness;\n    _2596 = param_2.occlusion;\n    _2597 = param_2.emission;\n    _2598 = param_2.clearcoat;\n    _2599 = param_2.clearcoat_roughness;\n    _2600 = param_2.sheen_color;\n    _2601 = param_2.sheen_roughness;\n    _2602 = param_2.anisotropy;\n    _2603 = param_2.anisotropy_rotation;\n    _2604 = param_2.specular;\n    _2605 = param_2.ior;\n    _2606 = param_2.specular_color;\n    float3 result;\n    if (_364.fa_emissive.w > 0.5)\n    {\n        result = _2591;\n    }\n    else\n    {\n        float3 _2046 = fast::normalize(_2593);\n        float _2053 = fast::clamp(_2594, 0.0, 1.0);\n        float _2057 = fast::clamp(_2595, 0.0500000007450580596923828125, 1.0);\n        float _2061 = _2057 * _2057;\n        float _2065 = _2061 * _2061;\n        float _2070 = fast::max(dot(_2046, _2019), 9.9999997473787516355514526367188e-05);\n        float3 _2076 = _2591 * (1.0 - _2053);\n        float3 _2083 = mix(float3(0.039999999105930328369140625), _2591, float3(_2053));\n        float3 f0 = _2083;\n        SurfaceInput param_3 = SurfaceInput{ in.fa_world_pos, _2560, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2019, short(gl_FrontFacing) };\n        Surface param_4 = Surface{ _2591, _2592, _2593, _2594, _2595, _2596, _2597, _2598, _2599, _2600, _2601, _2602, _2603, _2604, _2605, _2606 };\n        float3 param_5 = _2046;\n        float3 param_6 = _2019;\n        float param_7 = _2053;\n        float param_8 = _2057;\n        float3 param_9 = _2083;\n        FaLayers _2099 = fa_layers_setup(param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n        f0 = param_9;\n        float3 param_10 = _2046;\n        float3 lit = (fa_ambient_light(param_10, _364, fa_env_smp, fa_irr_tex) * _2076) * _2596;\n        if (_2099.on)\n        {\n            lit *= _2099.base_scale;\n        }\n        int _2121 = int(_364.fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _2121)\n            {\n                break;\n            }\n            int param_11 = li;\n            float3 param_12 = in.fa_world_pos;\n            float3 param_13 = _2560;\n            LightSample _2145 = fa_light_shadowed(param_11, param_12, param_13, _246, _364, fa_shadow_tex, fa_shadow_smp, in.fa_shadow_pos);\n            float3 _2765 = _2145.direction;\n            float _2153 = fast::max(dot(_2046, _2765), 0.0);\n            float _2159 = _2145.attenuation * _2145.shadow;\n            float3 _2164 = fast::normalize(_2765 + _2019);\n            float _2169 = fast::max(dot(_2046, _2164), 0.0);\n            float _2174 = fast::max(dot(_2019, _2164), 0.0);\n            if (_2099.on)\n            {\n                FaLayers param_14 = _2099;\n                float3 param_15 = _2076;\n                float3 param_16 = f0;\n                float3 param_17 = _2046;\n                float3 param_18 = _2019;\n                float3 param_19 = _2765;\n                float3 param_20 = _2164;\n                float param_21 = _2153;\n                float param_22 = _2070;\n                float param_23 = _2169;\n                float param_24 = _2174;\n                float param_25 = _2061;\n                float param_26 = _2065;\n                lit += (fa_layers_light(param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26) * (_246.fa_light_color[li].xyz * _2159));\n            }\n            else\n            {\n                float _2223 = ((_2169 * _2169) * (_2065 - 1.0)) + 1.0;\n                lit += (((_2076 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _2174, 5.0))) * (((_2065 / ((3.1415927410125732421875 * _2223) * _2223)) * (0.5 / fast::max(mix((2.0 * _2153) * _2070, _2153 + _2070, _2061), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2153))) * _246.fa_light_color[li].xyz) * (_2153 * _2159));\n            }\n        }\n        if (_2099.on)\n        {\n            FaLayers param_27 = _2099;\n            float3 param_28 = _2046;\n            float3 param_29 = _2019;\n            float3 param_30 = f0;\n            float param_31 = _2057;\n            lit += (fa_layers_ibl(param_27, param_28, param_29, param_30, param_31, _364, fa_env_tex, fa_env_smp) * _2596);\n        }\n        else\n        {\n            float3 param_32 = _2046;\n            float3 param_33 = _2019;\n            float3 param_34 = f0;\n            float param_35 = _2057;\n            lit += (fa_sky_reflection(param_32, param_33, param_34, param_35, _364, fa_env_tex, fa_env_smp) * _2596);\n        }\n        result = lit;\n    }\n    result += _2597;\n    bool _2321 = _364.fa_fog.w > 0.0;\n    bool _2328;\n    if (!_2321)\n    {\n        _2328 = _364.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2328 = _2321;\n    }\n    if (_2328)\n    {\n        float3 _2337 = in.fa_world_pos - _364.fa_camera_pos.xyz;\n        float _2343 = dot(_2337, _364.fa_fog_c.xyz);\n        bool _2347 = _364.fa_fog_c.w > 0.5;\n        float _2348;\n        if (_2347)\n        {\n            _2348 = _2343;\n        }\n        else\n        {\n            _2348 = length(_2337);\n        }\n        float _2360 = _2348 - _364.fa_fog_b.x;\n        if (_2360 > 0.0)\n        {\n            float _2369 = _364.fa_fog.w * _2360;\n            float tau = _2369 * _2369;\n            if (_364.fa_fog_b.y > 0.0)\n            {\n                float _2385;\n                if (_2347)\n                {\n                    _2385 = in.fa_world_pos.y - (_364.fa_fog_c.y * _2343);\n                }\n                else\n                {\n                    _2385 = _364.fa_camera_pos.y;\n                }\n                float _2406 = mix(_2385, in.fa_world_pos.y, fast::clamp(_364.fa_fog_b.x / _2348, 0.0, 1.0));\n                float _2410 = in.fa_world_pos.y - _2406;\n                float _2415 = _2406 - _364.fa_fog_b.z;\n                float _2420 = in.fa_world_pos.y - _364.fa_fog_b.z;\n                bool _2423 = _2415 <= 0.0;\n                bool _2424 = !_2423;\n                bool _2430;\n                if (_2424)\n                {\n                    _2430 = _364.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2430 = _2423;\n                }\n                float _2431;\n                if (_2430)\n                {\n                    _2431 = _364.fa_fog_b.y;\n                }\n                else\n                {\n                    _2431 = _364.fa_fog_b.y * exp(-fast::min(_364.fa_fog_b.w * _2415, 80.0));\n                }\n                bool _2458;\n                if (_2424)\n                {\n                    _2458 = _364.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2458 = _2423;\n                }\n                float _2459;\n                if (_2458)\n                {\n                    _2459 = _364.fa_fog_b.y * _2415;\n                }\n                else\n                {\n                    _2459 = (_364.fa_fog_b.y * (1.0 - exp(-fast::min(_364.fa_fog_b.w * _2415, 80.0)))) / _364.fa_fog_b.w;\n                }\n                bool _2484 = _2420 <= 0.0;\n                bool _2491;\n                if (!_2484)\n                {\n                    _2491 = _364.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2491 = _2484;\n                }\n                float _2492;\n                if (_2491)\n                {\n                    _2492 = _364.fa_fog_b.y * _2420;\n                }\n                else\n                {\n                    _2492 = (_364.fa_fog_b.y * (1.0 - exp(-fast::min(_364.fa_fog_b.w * _2420, 80.0)))) / _364.fa_fog_b.w;\n                }\n                float _2519;\n                if (abs(_2410) < 0.001000000047497451305389404296875)\n                {\n                    _2519 = _2431;\n                }\n                else\n                {\n                    _2519 = (_2492 - _2459) / _2410;\n                }\n                tau += (_2360 * fast::max(_2519, 0.0));\n            }\n            result = mix(result, _364.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2592);\n    return out;\n}\n\n",
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
            "inst_name": "_173",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_217",
            "msl_buffer_n": 3
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_355",
            "msl_buffer_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_246",
            "msl_buffer_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_364",
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
          },
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 8
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 8
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _168)\n{\n    float3 _109 = cross(model[1].xyz, model[2].xyz);\n    float _114 = (dot(model[0].xyz, _109) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_109 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _114, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _114), texcoord0 * _168.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex)\n{\n    if (fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, constant fa_mesh_vs_params& _168, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _168);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex);\n    float4 _210 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_168.fa_light_vp * _210).z;\n    fa_pre_r0 = float3(_168.fa_light_vp[0].x, _168.fa_light_vp[1].x, _168.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_168.fa_light_vp[0].y, _168.fa_light_vp[1].y, _168.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_168.fa_light_vp[0].z, _168.fa_light_vp[1].z, _168.fa_light_vp[2].z);\n    gl_Position = _168.fa_view_proj * _210;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _168 [[buffer(0)]], constant fa_inst_base& _272 [[buffer(6)]], const device fa_vs_points_buf& fa_vs_points [[buffer(8)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = _272.fa_base_model;\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, fa_vs_points, gl_InstanceIndex, _168, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _231, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _231.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _745 = base_t;\n    _745.x = _242.x;\n    _745.y = _242.y;\n    _745.z = _242.z;\n    base_t = _745;\n    float4 _257 = (_745 * _231.fa_base_color) * i.vertex_color;\n    float3 _708 = i.world_normal;\n    if (_231.fa_maps.z > 0.5)\n    {\n        float param_4 = _231.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _290 = fa_tex_fix(param_6, param_7);\n        float3 _294 = (_290 * 2.0) - float3(1.0);\n        float2 _299 = _294.xy * _231.fa_maps.x;\n        float3 _753 = _294;\n        _753.x = _299.x;\n        _753.y = _299.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _753;\n        _708 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _231.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _328 = fa_tex_fix(param_12, param_13);\n    float4 _756 = mrt;\n    _756.x = _328.x;\n    _756.y = _328.y;\n    _756.z = _328.z;\n    mrt = _756;\n    float4 _358 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _231.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = _231.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _400 = fa_tex_fix(param_20, param_21);\n    float _713 = _231.fa_layers_a.x;\n    float _714 = _231.fa_layers_a.y;\n    float _717 = _231.fa_layers_a.z;\n    float _716 = _231.fa_layers_b.w;\n    float _719 = _231.fa_layers_c.x;\n    if (_231.fa_layers_c.z > 0.5)\n    {\n        if (mod(_231.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _713 *= _370.y;\n            _714 *= _370.z;\n            _716 *= _358.w;\n        }\n        if (_231.fa_layers_c.z > 1.5)\n        {\n            _717 *= mrt.x;\n            _719 *= mrt.w;\n        }\n    }\n    return Surface{ _257.xyz, _257.w, _708, fast::clamp(_231.fa_pbr.x * _328.z, 0.0, 1.0), fast::clamp(_231.fa_pbr.y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_231.fa_maps.y * (_370.x - 1.0)), _231.fa_emissive.xyz + (_231.fa_model_emissive.xyz * _400), _713, _714, _231.fa_layers_b.xyz, _716, _717, _231.fa_layers_a.w, _719, _231.fa_layers_c.y, _231.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, const device fa_points_buf& points)\n{\n    s.emission += (i.vertex_color.xyz * ((device float*)&points.data[0].tint)[3u]);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _231 [[buffer(1)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _619 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _619 = -_619;\n    }\n    float3 _532 = fast::normalize(_231.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _619, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _532, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _619, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _532, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _231, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, points);\n    float3 _547 = fast::normalize(param_2.normal);\n    float3 _562 = fast::normalize(float3(dot(in.fa_pre_r0, _547), dot(in.fa_pre_r1, _547), dot(in.fa_pre_r2, _547)));\n    float _574 = _562.z;\n    float2 e = _562.xy / float2((abs(_562.x) + abs(_562.y)) + abs(_574));\n    if (_574 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "inst_name": "_168",
            "msl_buffer_n": 0
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_272",
            "msl_buffer_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_231",
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
          },
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 8
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 8
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _217)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _208 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_217.fa_joint_rows[_208] * weights[i]);\n        r1 += (_217.fa_joint_rows[_208 + 1] * weights[i]);\n        r2 += (_217.fa_joint_rows[_208 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _173)\n{\n    float3 _114 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _114) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_114 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * _173.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex)\n{\n    if (fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, constant fa_mesh_vs_params& _173, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _173);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex);\n    float4 _322 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_173.fa_light_vp * _322).z;\n    fa_pre_r0 = float3(_173.fa_light_vp[0].x, _173.fa_light_vp[1].x, _173.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_173.fa_light_vp[0].y, _173.fa_light_vp[1].y, _173.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_173.fa_light_vp[0].z, _173.fa_light_vp[1].z, _173.fa_light_vp[2].z);\n    gl_Position = _173.fa_view_proj * _322;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _173 [[buffer(0)]], constant fa_skin& _217 [[buffer(3)]], constant fa_inst_base& _384 [[buffer(6)]], const device fa_vs_points_buf& fa_vs_points [[buffer(8)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = _384.fa_base_model * fa_skin_matrix(param, param_1, _217);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, fa_vs_points, gl_InstanceIndex, _173, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _231, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _231.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _745 = base_t;\n    _745.x = _242.x;\n    _745.y = _242.y;\n    _745.z = _242.z;\n    base_t = _745;\n    float4 _257 = (_745 * _231.fa_base_color) * i.vertex_color;\n    float3 _708 = i.world_normal;\n    if (_231.fa_maps.z > 0.5)\n    {\n        float param_4 = _231.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _290 = fa_tex_fix(param_6, param_7);\n        float3 _294 = (_290 * 2.0) - float3(1.0);\n        float2 _299 = _294.xy * _231.fa_maps.x;\n        float3 _753 = _294;\n        _753.x = _299.x;\n        _753.y = _299.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _753;\n        _708 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _231.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _328 = fa_tex_fix(param_12, param_13);\n    float4 _756 = mrt;\n    _756.x = _328.x;\n    _756.y = _328.y;\n    _756.z = _328.z;\n    mrt = _756;\n    float4 _358 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _231.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = _231.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _400 = fa_tex_fix(param_20, param_21);\n    float _713 = _231.fa_layers_a.x;\n    float _714 = _231.fa_layers_a.y;\n    float _717 = _231.fa_layers_a.z;\n    float _716 = _231.fa_layers_b.w;\n    float _719 = _231.fa_layers_c.x;\n    if (_231.fa_layers_c.z > 0.5)\n    {\n        if (mod(_231.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _713 *= _370.y;\n            _714 *= _370.z;\n            _716 *= _358.w;\n        }\n        if (_231.fa_layers_c.z > 1.5)\n        {\n            _717 *= mrt.x;\n            _719 *= mrt.w;\n        }\n    }\n    return Surface{ _257.xyz, _257.w, _708, fast::clamp(_231.fa_pbr.x * _328.z, 0.0, 1.0), fast::clamp(_231.fa_pbr.y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_231.fa_maps.y * (_370.x - 1.0)), _231.fa_emissive.xyz + (_231.fa_model_emissive.xyz * _400), _713, _714, _231.fa_layers_b.xyz, _716, _717, _231.fa_layers_a.w, _719, _231.fa_layers_c.y, _231.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, const device fa_points_buf& points)\n{\n    s.emission += (i.vertex_color.xyz * ((device float*)&points.data[0].tint)[3u]);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _231 [[buffer(1)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _619 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _619 = -_619;\n    }\n    float3 _532 = fast::normalize(_231.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _619, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _532, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _619, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _532, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _231, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, points);\n    float3 _547 = fast::normalize(param_2.normal);\n    float3 _562 = fast::normalize(float3(dot(in.fa_pre_r0, _547), dot(in.fa_pre_r1, _547), dot(in.fa_pre_r2, _547)));\n    float _574 = _562.z;\n    float2 e = _562.xy / float2((abs(_562.x) + abs(_562.y)) + abs(_574));\n    if (_574 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "inst_name": "_173",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_217",
            "msl_buffer_n": 3
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_384",
            "msl_buffer_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_231",
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
          },
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 8
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 8
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(5)]];\n    float2 fa_texcoord0 [[attribute(6)]];\n    float4 fa_tangent [[attribute(7)]];\n    float4 fa_color [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _159)\n{\n    float3 _100 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _100) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_100 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _159.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex)\n{\n    if (fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _159 [[buffer(0)]], constant fa_inst_base& _176 [[buffer(6)]], const device fa_vs_points_buf& fa_vs_points [[buffer(8)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = _176.fa_base_model;\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _159);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex);\n    out.gl_Position = _159.fa_light_vp * float4(param_6.world_pos, 1.0);\n    return out;\n}\n\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_159",
            "msl_buffer_n": 0
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_176",
            "msl_buffer_n": 6
          }
        ],
        "views": [
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 8
            }
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_joints [[attribute(5)]];\n    float4 fa_weights [[attribute(6)]];\n    float3 fa_normal [[attribute(7)]];\n    float2 fa_texcoord0 [[attribute(8)]];\n    float4 fa_tangent [[attribute(9)]];\n    float4 fa_color [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _208)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _199 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_208.fa_joint_rows[_199] * weights[i]);\n        r1 += (_208.fa_joint_rows[_199 + 1] * weights[i]);\n        r2 += (_208.fa_joint_rows[_199 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _164)\n{\n    float3 _105 = cross(model[1].xyz, model[2].xyz);\n    float _110 = (dot(model[0].xyz, _105) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_105 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _110, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _110), texcoord0 * _164.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex)\n{\n    if (fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _164 [[buffer(0)]], constant fa_skin& _208 [[buffer(3)]], constant fa_inst_base& _288 [[buffer(6)]], const device fa_vs_points_buf& fa_vs_points [[buffer(8)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = _288.fa_base_model * fa_skin_matrix(param, param_1, _208);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7, _164);\n    vertex0(param_8, fa_vs_points, gl_InstanceIndex);\n    out.gl_Position = _164.fa_light_vp * float4(param_8.world_pos, 1.0);\n    return out;\n}\n\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_164",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_208",
            "msl_buffer_n": 3
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_288",
            "msl_buffer_n": 6
          }
        ],
        "views": [
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 8
            }
          }
        ]
      }
    }
  }
}
