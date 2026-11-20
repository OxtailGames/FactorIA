{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "7cd31c28ac6572768802838498bbbd3180b96e0a1bb1bab7ad49d1d6af9d528c",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _168)\n{\n    float3 _109 = cross(model[1].xyz, model[2].xyz);\n    float _114 = (dot(model[0].xyz, _109) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_109 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _114, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _114), texcoord0 * _168.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex)\n{\n    if (fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, constant fa_mesh_vs_params& _168, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _168);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _168.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _168 [[buffer(0)]], constant fa_inst_base& _238 [[buffer(6)]], const device fa_vs_points_buf& fa_vs_points [[buffer(8)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = _238.fa_base_model;\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, fa_vs_points, gl_InstanceIndex, _168, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nconstant spvUnsafeArray<float, 63> _1997 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _484)\n{\n    bool _489 = _484.fa_cl_info.x < 0.0;\n    bool _496;\n    if (!_489)\n    {\n        _496 = _484.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _496 = _489;\n    }\n    bool _504;\n    if (!_496)\n    {\n        _504 = _484.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _504 = _496;\n    }\n    bool _511;\n    if (!_504)\n    {\n        _511 = _484.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _511 = _504;\n    }\n    bool _518;\n    if (!_511)\n    {\n        _518 = _484.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _518 = _511;\n    }\n    if (_518)\n    {\n        return int2(0);\n    }\n    float4 _528 = float4(world_pos, 1.0);\n    float _535 = dot(_484.fa_cl_vpw, _528);\n    if (!(_535 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _557 = float2(dot(_484.fa_cl_vpx, _528), dot(_484.fa_cl_vpy, _528)) / float2(_535);\n    int _561 = int(_484.fa_cl_grid.x);\n    int _565 = int(_484.fa_cl_grid.y);\n    int param = (int(_484.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_484.fa_cl_fwd.xyz, world_pos) + _484.fa_cl_fwd.w, _484.fa_cl_grid.w) / _484.fa_cl_grid.w) * _484.fa_cl_grid.z)), 0, int(_484.fa_cl_info.y) - 1) * _565) + clamp(int(floor(((_557.y * 0.5) + 0.5) * _484.fa_cl_grid.y)), 0, _565 - 1)) * _561)) + clamp(int(floor(((_557.x * 0.5) + 0.5) * _484.fa_cl_grid.x)), 0, _561 - 1);\n    float4 _636 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_636.x), int(_636.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _484, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_484.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2814 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _484);\n    fa_cl_slot = _2814.x;\n    fa_cl_local = _2814.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2958 = fa_linear_to_srgb(param);\n        c = _2958;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2966 = fa_srgb_to_linear(param_1);\n            c = _2966;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _256;\n    if (bool(i.front_facing))\n    {\n        _256 = i.world_normal;\n    }\n    else\n    {\n        _256 = -i.world_normal;\n    }\n    float3 _280 = fast::normalize(i.world_tangent.xyz - (_256 * dot(_256, i.world_tangent.xyz)));\n    float3 _308 = fast::normalize(((_280 * m.x) + ((cross(_256, _280) * i.world_tangent.w) * m.y)) + (_256 * m.z));\n    float3 _311;\n    if (bool(i.front_facing))\n    {\n        _311 = _308;\n    }\n    else\n    {\n        _311 = -_308;\n    }\n    return _311;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _484, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _484.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2997 = fa_tex_fix(param_2, param_3);\n    float4 _4200 = base_t;\n    _4200.x = _2997.x;\n    _4200.y = _2997.y;\n    _4200.z = _2997.z;\n    base_t = _4200;\n    float4 _3011 = (_4200 * _484.fa_base_color) * i.vertex_color;\n    float3 _4102 = i.world_normal;\n    if (_484.fa_maps.z > 0.5)\n    {\n        float param_4 = _484.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3043 = fa_tex_fix(param_6, param_7);\n        float3 _3046 = (_3043 * 2.0) - float3(1.0);\n        float2 _3051 = _3046.xy * _484.fa_maps.x;\n        float3 _4208 = _3046;\n        _4208.x = _3051.x;\n        _4208.y = _3051.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4208;\n        _4102 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _484.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3080 = fa_tex_fix(param_12, param_13);\n    float4 _4211 = mrt;\n    _4211.x = _3080.x;\n    _4211.y = _3080.y;\n    _4211.z = _3080.z;\n    mrt = _4211;\n    float4 _3108 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _484.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3108.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3120 = fa_tex_fix(param_16, param_17);\n    float param_18 = _484.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3150 = fa_tex_fix(param_20, param_21);\n    float _4107 = _484.fa_layers_a.x;\n    float _4108 = _484.fa_layers_a.y;\n    float _4111 = _484.fa_layers_a.z;\n    float _4110 = _484.fa_layers_b.w;\n    float _4113 = _484.fa_layers_c.x;\n    if (_484.fa_layers_c.z > 0.5)\n    {\n        if (mod(_484.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4107 *= _3120.y;\n            _4108 *= _3120.z;\n            _4110 *= _3108.w;\n        }\n        if (_484.fa_layers_c.z > 1.5)\n        {\n            _4111 *= mrt.x;\n            _4113 *= mrt.w;\n        }\n    }\n    return Surface{ _3011.xyz, _3011.w, _4102, fast::clamp(_484.fa_pbr.x * _3080.z, 0.0, 1.0), fast::clamp(_484.fa_pbr.y * _3080.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_484.fa_maps.y * (_3120.x - 1.0)), _484.fa_emissive.xyz + (_484.fa_model_emissive.xyz * _3150), _4107, _4108, _484.fa_layers_b.xyz, _4110, _4111, _484.fa_layers_a.w, _4113, _484.fa_layers_c.y, _484.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, const device fa_points_buf& points)\n{\n    s.emission += (i.vertex_color.xyz * ((device float*)&points.data[0].tint)[3u]);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1922 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1930 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1933 = int(_1922);\n    int _1936 = int(_1930);\n    float _1946 = _1930 - float(_1936);\n    int _2002 = (_1933 * 9) + _1936;\n    int _2022 = ((_1933 + 1) * 9) + _1936;\n    return mix(mix(_1997[_2002], _1997[_2002 + 1], _1946), mix(_1997[_2022], _1997[_2022 + 1], _1946), _1922 - float(_1933));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4038 = false;\n    float _4039 = 1.0;\n    float _4040 = 1.0;\n    float _4041 = 1.0;\n    float _4042 = 0.0;\n    float _4043 = 0.0;\n    float _4044 = 0.0;\n    float _4045 = 0.0;\n    float _4047 = 1.0;\n    bool _4048 = false;\n    float3 _4049 = float3(0.0);\n    float _4050 = 1.0;\n    float _4051 = 1.0;\n    float _4052 = 1.0;\n    float _4053 = 0.0;\n    float _4054 = 0.0;\n    float3 _4055 = float3(1.0, 0.0, 0.0);\n    float3 _4056 = float3(0.0, 0.0, 1.0);\n    float _4057 = 1.0;\n    float _4058 = 1.0;\n    float _2075 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2079 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2084 = (_2075 != 1.0) || (_2079 != 1.5);\n    bool _2094;\n    if (!_2084)\n    {\n        _2094 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2094 = _2084;\n    }\n    if (_2094)\n    {\n        float _2102 = (_2079 - 1.0) / (_2079 + 1.0);\n        f0 = mix(fast::min(float3(_2102 * _2102) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2075, s.albedo, float3(metallic));\n        _4039 = mix(_2075, 1.0, metallic);\n        _4038 = true;\n    }\n    float _2130 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2130 > 0.0)\n    {\n        float _2138 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4042 = _2130;\n        _4043 = _2138;\n        float _2145 = _2138 * _2138;\n        _4044 = _2145;\n        _4045 = _2145 * _2145;\n        float _2157 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4047 = _2157;\n        _4040 = 1.0 - (_2130 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2157, 0.0, 1.0), 5.0))));\n        _4038 = true;\n    }\n    float3 _2177 = fast::max(s.sheen_color, float3(0.0));\n    float _2186 = fast::max(_2177.x, fast::max(_2177.y, _2177.z));\n    if (_2186 > 0.0)\n    {\n        float _2194 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4048 = true;\n        _4049 = _2177;\n        _4050 = _2194;\n        _4051 = _2194 * _2194;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2194;\n        float _2211 = fa_sheen_albedo(param, param_1);\n        _4053 = _2211;\n        _4052 = 1.0 - fast::min(_2186 * _2211, 1.0);\n        _4038 = true;\n    }\n    _4041 = _4040 * _4052;\n    float _2230 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2230 != 0.0)\n    {\n        float3 _2245 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2245;\n        if (dot(_2245, _2245) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2263 = t;\n        float3 _2264 = fast::normalize(_2263);\n        t = _2264;\n        float3 _2289 = fast::normalize((_2264 * cos(s.anisotropy_rotation)) + ((cross(n, _2264) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4055 = _2289;\n        _4056 = cross(n, _2289);\n        float _2299 = roughness * roughness;\n        float _2305 = mix(_2299, 1.0, _2230 * _2230);\n        bool _2307 = _2230 > 0.0;\n        _4057 = _2307 ? _2305 : _2299;\n        _4058 = _2307 ? _2299 : _2305;\n        _4054 = _2230;\n        _4038 = true;\n    }\n    return FaLayers{ short(_4038), _4039, _4040, _4041, _4042, _4043, _4044, _4045, i.world_normal, _4047, short(_4048), _4049, _4050, _4051, _4052, _4053, _4054, _4055, _4056, _4057, _4058 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _484, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_484.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _484.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _484)\n{\n    int param = (int(_484.fa_cl_info.x) + int(_484.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _484, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _484);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _356 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _362 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _365 = _362.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _372 = _365 < 0.5;\n    float3 l;\n    if (_372)\n    {\n        l = fast::normalize(_356.xyz);\n    }\n    else\n    {\n        float3 _384 = _356.xyz - world_pos;\n        float _386 = length(_384);\n        dist = _386;\n        l = _384 / float3(fast::max(_386, 9.9999997473787516355514526367188e-05));\n        float _401 = _386 / fast::max(_356.w, 0.001000000047497451305389404296875);\n        float _407 = fast::clamp(1.0 - (_401 * _401), 0.0, 1.0);\n        atten = _407 * _407;\n        if (_365 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _421 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _431 = _421.w;\n            int param_3 = (li * 4) + 3;\n            float4 _438 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _439 = _438.x;\n            float cos_inner = _439;\n            if (_439 > 1.5)\n            {\n                cos_inner = mix(_431, 1.0, 0.25);\n            }\n            atten *= smoothstep(_431, cos_inner, dot(-l, fast::normalize(_421.xyz)));\n        }\n    }\n    int _470;\n    if (_372)\n    {\n        _470 = 0;\n    }\n    else\n    {\n        _470 = (_365 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _362.xyz * atten, atten, 1.0, dist, _470 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _720)\n{\n    float _710;\n    if (i == 0)\n    {\n        _710 = _720.fa_shadow_split.x;\n    }\n    else\n    {\n        float _726;\n        if (i == 1)\n        {\n            _726 = _720.fa_shadow_split.y;\n        }\n        else\n        {\n            float _734;\n            if (i == 2)\n            {\n                _734 = _720.fa_shadow_split.z;\n            }\n            else\n            {\n                _734 = _720.fa_shadow_split.w;\n            }\n            _726 = _734;\n        }\n        _710 = _726;\n    }\n    return _710;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _767 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _771;\n    if (conv.x < 0.5)\n    {\n        _771 = _767;\n    }\n    else\n    {\n        _771 = (conv.y * conv.z) / (conv.z - (_767 * (conv.z - conv.y)));\n    }\n    return _771;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _698 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_698), sin(_698)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _720, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _817 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _831 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _817;\n            float2 _850 = fa_shadow_vogel(param_3, param_4, param_5) * _831;\n            float2 param_6 = uv + (_850 * _720.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _862 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_862 < (zr - (length(_850) * plane)))\n            {\n                sum += _862;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _906 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _906; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _906;\n        float param_11 = _817;\n        float2 _925 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_925 * _720.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_925) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_906);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _720, texture2d<float> fa_shadow_tex)\n{\n    float _967 = fast::max(_720.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _972 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _978 = sqrt(1.0 - (_972 * _972));\n    float _986 = fast::min(_978 / fast::max(_972, 0.20000000298023223876953125), 4.0);\n    float _991;\n    if (_720.fa_shadow_bias.y > 0.0)\n    {\n        _991 = _720.fa_shadow_bias.y;\n    }\n    else\n    {\n        _991 = 1.5 * _720.fa_shadow_info[ci].x;\n    }\n    float4 _1016 = _720.fa_shadow_mat[ci] * float4(world + (n * (_991 * _978)), 1.0);\n    float _1023 = _1016.x;\n    bool _1026 = _1023 < _720.fa_shadow_rect[ci].x;\n    bool _1035;\n    if (!_1026)\n    {\n        _1035 = _1023 > _720.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1035 = _1026;\n    }\n    bool _1044;\n    if (!_1035)\n    {\n        _1044 = _1016.y < _720.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1044 = _1035;\n    }\n    bool _1053;\n    if (!_1044)\n    {\n        _1053 = _1016.y > _720.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1053 = _1044;\n    }\n    bool _1060;\n    if (!_1053)\n    {\n        _1060 = _1016.z > 1.0;\n    }\n    else\n    {\n        _1060 = _1053;\n    }\n    if (_1060)\n    {\n        return -1.0;\n    }\n    float _1069;\n    if (_720.fa_shadow_bias.x > 0.0)\n    {\n        _1069 = _720.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1069 = 1.5 * _720.fa_shadow_info[ci].x;\n    }\n    float2 param = _1016.xy;\n    float4 param_1 = _720.fa_shadow_rect[ci];\n    float param_2 = _1016.z - ((_1069 * (1.0 + (0.5 * _986))) / _967);\n    float param_3 = _720.fa_shadow_info[ci].x;\n    float param_4 = _967;\n    float param_5 = _967 * 0.25;\n    float param_6 = ((_720.fa_shadow_info[ci].x * fast::min(_986, 3.0)) * 0.5) / _967;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_720.fa_shadow_cfg.z + 0.5);\n    float param_9 = _720.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _720, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _484, thread float4& gl_FragCoord, constant fa_shadows& _720, texture2d<float> fa_shadow_tex)\n{\n    if (_484.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1463 = int(_720.fa_shadow_cfg.x + 0.5);\n    if (_1463 < 1)\n    {\n        return 1.0;\n    }\n    float _1479 = dot(world - _720.fa_shadow_eye.xyz, _720.fa_shadow_fwd.xyz);\n    int param = _1463 - 1;\n    if (_1479 > fa_shadow_split_at(param, _720))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1491 = _1463 > 1;\n    bool _1498;\n    if (_1491)\n    {\n        _1498 = _1479 > _720.fa_shadow_split.x;\n    }\n    else\n    {\n        _1498 = _1491;\n    }\n    if (_1498)\n    {\n        ci = 1;\n    }\n    bool _1502 = _1463 > 2;\n    bool _1509;\n    if (_1502)\n    {\n        _1509 = _1479 > _720.fa_shadow_split.y;\n    }\n    else\n    {\n        _1509 = _1502;\n    }\n    if (_1509)\n    {\n        ci = 2;\n    }\n    bool _1513 = _1463 > 3;\n    bool _1520;\n    if (_1513)\n    {\n        _1520 = _1479 > _720.fa_shadow_split.z;\n    }\n    else\n    {\n        _1520 = _1513;\n    }\n    if (_1520)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1463)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1546 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _720, fa_shadow_tex);\n        s = _1546;\n        if (_1546 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_720.fa_shadow_cfg.y > 0.0)\n    {\n        float _1571;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1571 = fa_shadow_split_at(param_5, _720);\n        }\n        else\n        {\n            _1571 = _720.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1590 = _720.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _720) - _1571, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1601 = fast::clamp((_1479 - (fa_shadow_split_at(param_7, _720) - _1590)) / _1590, 0.0, 1.0);\n        if (_1601 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1463)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1622 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _720, fa_shadow_tex);\n                s2 = _1622;\n                if (_1622 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1601);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _484, thread float4& gl_FragCoord, constant fa_shadows& _720, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _484, gl_FragCoord, _720, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _484, thread float4& gl_FragCoord, constant fa_shadows& _720, texture2d<float> fa_shadow_tex)\n{\n    bool _1128 = _484.fa_pbr.z < 0.5;\n    bool _1136;\n    if (!_1128)\n    {\n        _1136 = _720.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1136 = _1128;\n    }\n    if (_1136)\n    {\n        return 1.0;\n    }\n    int param = (int(_720.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1149 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1150 = _1149.x;\n    if (_1150 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1159 = int(_1150 + 0.5);\n    int param_1 = _1159;\n    float4 _1163 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1159 + 1;\n    float4 _1168 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1171 = _1163.y;\n    if (_1171 > 0.0)\n    {\n        float _1188 = 1.0 - smoothstep(0.75 * _1171, _1171, length(world - _720.fa_shadow_eye.xyz));\n        fade = _1188;\n        if (_1188 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1163.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1207 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1210 = abs(_1207);\n        float _1212 = _1210.x;\n        float _1214 = _1210.y;\n        bool _1215 = _1212 >= _1214;\n        bool _1223;\n        if (_1215)\n        {\n            _1223 = _1212 >= _1210.z;\n        }\n        else\n        {\n            _1223 = _1215;\n        }\n        int _1224;\n        if (_1223)\n        {\n            _1224 = (_1207.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1237;\n            if (_1214 >= _1210.z)\n            {\n                _1237 = (_1207.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1237 = (_1207.z > 0.0) ? 4 : 5;\n            }\n            _1224 = _1237;\n        }\n        face = _1224;\n    }\n    int _1256 = (_1159 + 2) + (face * 6);\n    int param_4 = _1256;\n    int param_5 = _1256 + 1;\n    int param_6 = _1256 + 3;\n    float4 _1270 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1256 + 4;\n    float4 _1275 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1256 + 5;\n    float4 _1280 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1292 = _1280.x * fast::max(dot(_1270, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1297 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1303 = sqrt(1.0 - (_1297 * _1297));\n    float _1309 = fast::min(_1303 / fast::max(_1297, 0.20000000298023223876953125), 4.0);\n    float _1312 = _1168.y;\n    float _1314;\n    if (_1312 > 0.0)\n    {\n        _1314 = _1312;\n    }\n    else\n    {\n        _1314 = 1.5 * _1292;\n    }\n    float4 _1334 = float4(world + (n * (_1314 * _1303)), 1.0);\n    float _1338 = dot(_1270, _1334);\n    float _1341 = _1280.y;\n    if (_1338 < _1341)\n    {\n        return 1.0;\n    }\n    float2 _1356 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1334), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1334)) / float2(_1338);\n    float _1358 = _1356.x;\n    bool _1361 = _1358 < _1275.x;\n    bool _1370;\n    if (!_1361)\n    {\n        _1370 = _1358 > _1275.z;\n    }\n    else\n    {\n        _1370 = _1361;\n    }\n    bool _1379;\n    if (!_1370)\n    {\n        _1379 = _1356.y < _1275.y;\n    }\n    else\n    {\n        _1379 = _1370;\n    }\n    bool _1388;\n    if (!_1379)\n    {\n        _1388 = _1356.y > _1275.w;\n    }\n    else\n    {\n        _1388 = _1379;\n    }\n    if (_1388)\n    {\n        return 1.0;\n    }\n    float _1394 = _1168.x;\n    float _1396;\n    if (_1394 > 0.0)\n    {\n        _1396 = _1394;\n    }\n    else\n    {\n        _1396 = 1.5 * _1292;\n    }\n    float2 param_9 = _1356;\n    float4 param_10 = _1275;\n    float param_11 = _1338 - (_1396 * (1.0 + (0.5 * _1309)));\n    float param_12 = _1292;\n    float param_13 = 1.0;\n    float param_14 = _1280.z * 0.25;\n    float param_15 = (_1292 * fast::min(_1309, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _1341, _1280.z);\n    int param_17 = int(_1163.z + 0.5);\n    float param_18 = _1163.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _720, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _484, thread float4& gl_FragCoord, constant fa_shadows& _720, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2842 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _4087 = _2842.direction;\n    float3 _4082 = _2842.color;\n    float _4089 = _2842.attenuation;\n    float _4084 = _2842.shadow;\n    int _4092 = _2842.type;\n    if ((_4092 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _4087;\n        float _2856 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _484, gl_FragCoord, _720, fa_shadow_tex, fa_world_pos);\n        _4084 = _2856;\n        _4082 *= _2856;\n    }\n    else\n    {\n        bool _2867 = _4092 != 0;\n        bool _2873;\n        if (_2867)\n        {\n            _2873 = _4089 > 0.0;\n        }\n        else\n        {\n            _2873 = _2867;\n        }\n        if (_2873)\n        {\n            int param_4 = li;\n            float3 param_5 = world_pos;\n            float3 param_6 = gn;\n            float3 param_7 = _4087;\n            float _2885 = fa_shadow_local(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _484, gl_FragCoord, _720, fa_shadow_tex);\n            _4084 = _2885;\n            _4082 *= _2885;\n        }\n    }\n    return LightSample{ _4087, _4082, _4089, _4084, _2842._distance, _4092 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _2457 = tdh / at;\n    float _2461 = bdh / ab;\n    float _2473 = ((_2457 * _2457) + (_2461 * _2461)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2473) * _2473);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _2554 = 1.0 / alpha;\n    return ((2.0 + _2554) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2554)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _2587 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2666 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2666) * _2666);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2587);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2587));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2739 = fast::max(dot(L.nc, l), 0.0);\n        float _2745 = fast::max(dot(L.nc, h), 0.0);\n        float _2754 = ((_2745 * _2745) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2754) * _2754)) * (0.5 / fast::max(mix((2.0 * _2739) * L.coat_ndv, _2739 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2739)) * _2739);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1854 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1857 = _1854.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1857 * _1857, exp2((-9.27999973297119140625) * ndv)) * _1857) + _1854.y)) + _1854.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _484, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_484.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _484.fa_env_horizon.w)).xyz;\n    }\n    float _1759 = rough * rough;\n    float _1789 = 0.60000002384185791015625 * _1759;\n    return mix(mix(_484.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_484.fa_env_horizon.xyz, _484.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1759)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1789, 0.0500000007450580596923828125 + _1789, d.y))), ((_484.fa_env_sky.xyz + _484.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1759 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _484, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2340;\n        if (L.aniso >= 0.0)\n        {\n            _2340 = L.b;\n        }\n        else\n        {\n            _2340 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2340, v), _2340), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2373 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _484, fa_env_tex, fa_env_smp) * ((f0 * _2373.x) + (float3(L.f90) * _2373.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _484, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2428 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _484, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _2428.x) + _2428.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _484, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1896 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _484, fa_env_tex, fa_env_smp) * ((f0 * _1896.x) + float3(_1896.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _720)\n{\n    if (_720.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1646 = int(_720.fa_shadow_cfg.x + 0.5);\n    float _1656 = dot(world - _720.fa_shadow_eye.xyz, _720.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1661 = _1646 > 0;\n    bool _1670;\n    if (_1661)\n    {\n        int param = _1646 - 1;\n        _1670 = _1656 <= fa_shadow_split_at(param, _720);\n    }\n    else\n    {\n        _1670 = _1661;\n    }\n    if (_1670)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1677 = _1646 > 1;\n        bool _1684;\n        if (_1677)\n        {\n            _1684 = _1656 > _720.fa_shadow_split.x;\n        }\n        else\n        {\n            _1684 = _1677;\n        }\n        if (_1684)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1690 = _1646 > 2;\n        bool _1697;\n        if (_1690)\n        {\n            _1697 = _1656 > _720.fa_shadow_split.y;\n        }\n        else\n        {\n            _1697 = _1690;\n        }\n        if (_1697)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1703 = _1646 > 3;\n        bool _1710;\n        if (_1703)\n        {\n            _1710 = _1656 > _720.fa_shadow_split.z;\n        }\n        else\n        {\n            _1710 = _1703;\n        }\n        if (_1710)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _484 [[buffer(1)]], constant fa_shadows& _720 [[buffer(7)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3817 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3817 = -_3817;\n    }\n    float3 _3271 = fast::normalize(_484.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _484, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3817, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3271, short(gl_FrontFacing) };\n    Surface _3279 = fa_standard_surface(param_1, _484, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3848 = _3279.albedo;\n    float _3849 = _3279.alpha;\n    float3 _3850 = _3279.normal;\n    float _3851 = _3279.metallic;\n    float _3852 = _3279.roughness;\n    float _3853 = _3279.occlusion;\n    float3 _3854 = _3279.emission;\n    float _3855 = _3279.clearcoat;\n    float _3856 = _3279.clearcoat_roughness;\n    float3 _3857 = _3279.sheen_color;\n    float _3858 = _3279.sheen_roughness;\n    float _3859 = _3279.anisotropy;\n    float _3860 = _3279.anisotropy_rotation;\n    float _3861 = _3279.specular;\n    float _3862 = _3279.ior;\n    float3 _3863 = _3279.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3817, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3271, short(gl_FrontFacing) };\n    Surface param_3 = _3279;\n    surface(param_2, param_3, points);\n    _3848 = param_3.albedo;\n    _3849 = param_3.alpha;\n    _3850 = param_3.normal;\n    _3851 = param_3.metallic;\n    _3852 = param_3.roughness;\n    _3853 = param_3.occlusion;\n    _3854 = param_3.emission;\n    _3855 = param_3.clearcoat;\n    _3856 = param_3.clearcoat_roughness;\n    _3857 = param_3.sheen_color;\n    _3858 = param_3.sheen_roughness;\n    _3859 = param_3.anisotropy;\n    _3860 = param_3.anisotropy_rotation;\n    _3861 = param_3.specular;\n    _3862 = param_3.ior;\n    _3863 = param_3.specular_color;\n    float3 result;\n    if (_484.fa_emissive.w > 0.5)\n    {\n        result = _3848;\n    }\n    else\n    {\n        float3 _3301 = fast::normalize(_3850);\n        float _3308 = fast::clamp(_3851, 0.0, 1.0);\n        float _3312 = fast::clamp(_3852, 0.0500000007450580596923828125, 1.0);\n        float _3316 = _3312 * _3312;\n        float _3320 = _3316 * _3316;\n        float _3325 = fast::max(dot(_3301, _3271), 9.9999997473787516355514526367188e-05);\n        float3 _3331 = _3848 * (1.0 - _3308);\n        float3 _3338 = mix(float3(0.039999999105930328369140625), _3848, float3(_3308));\n        float3 f0 = _3338;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _3817, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3271, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _3848, _3849, _3850, _3851, _3852, _3853, _3854, _3855, _3856, _3857, _3858, _3859, _3860, _3861, _3862, _3863 };\n        float3 param_6 = _3301;\n        float3 param_7 = _3271;\n        float param_8 = _3308;\n        float param_9 = _3312;\n        float3 param_10 = _3338;\n        FaLayers _3354 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _3301;\n        float3 lit = (fa_ambient_light(param_11, _484, fa_env_smp, fa_irr_tex) * _3331) * _3853;\n        if (_3354.on)\n        {\n            lit *= _3354.base_scale;\n        }\n        int _3376 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3376; ln++)\n        {\n            int param_12 = ln;\n            int _3389 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _484, fa_cl_ndir, fa_cl_slot);\n            int param_13 = _3389;\n            float3 param_14 = in.fa_world_pos;\n            float3 param_15 = _3817;\n            LightSample _3398 = fa_light_shadowed(param_13, param_14, param_15, fa_light_tex, fa_shadow_smp, _484, gl_FragCoord, _720, fa_shadow_tex, in.fa_world_pos);\n            float3 _4022 = _3398.direction;\n            float _3406 = fast::max(dot(_3301, _4022), 0.0);\n            float _3412 = _3398.attenuation * _3398.shadow;\n            float3 _3417 = fast::normalize(_4022 + _3271);\n            float _3422 = fast::max(dot(_3301, _3417), 0.0);\n            float _3427 = fast::max(dot(_3271, _3417), 0.0);\n            if (_3354.on)\n            {\n                FaLayers param_16 = _3354;\n                float3 param_17 = _3331;\n                float3 param_18 = f0;\n                float3 param_19 = _3301;\n                float3 param_20 = _3271;\n                float3 param_21 = _4022;\n                float3 param_22 = _3417;\n                float param_23 = _3406;\n                float param_24 = _3325;\n                float param_25 = _3422;\n                float param_26 = _3427;\n                float param_27 = _3316;\n                float param_28 = _3320;\n                int param_29 = _3389;\n                lit += (fa_layers_light(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28) * (fa_light_rgb(param_29, fa_light_tex, fa_shadow_smp) * _3412));\n            }\n            else\n            {\n                float _3475 = ((_3422 * _3422) * (_3320 - 1.0)) + 1.0;\n                int param_30 = _3389;\n                lit += (((_3331 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _3427, 5.0))) * (((_3320 / ((3.1415927410125732421875 * _3475) * _3475)) * (0.5 / fast::max(mix((2.0 * _3406) * _3325, _3406 + _3325, _3316), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3406))) * fa_light_rgb(param_30, fa_light_tex, fa_shadow_smp)) * (_3406 * _3412));\n            }\n        }\n        if (_3354.on)\n        {\n            FaLayers param_31 = _3354;\n            float3 param_32 = _3301;\n            float3 param_33 = _3271;\n            float3 param_34 = f0;\n            float param_35 = _3312;\n            lit += (fa_layers_ibl(param_31, param_32, param_33, param_34, param_35, _484, fa_env_tex, fa_env_smp) * _3853);\n        }\n        else\n        {\n            float3 param_36 = _3301;\n            float3 param_37 = _3271;\n            float3 param_38 = f0;\n            float param_39 = _3312;\n            lit += (fa_sky_reflection(param_36, param_37, param_38, param_39, _484, fa_env_tex, fa_env_smp) * _3853);\n        }\n        result = lit;\n    }\n    float3 _3568 = result;\n    float3 _3569 = _3568 + _3854;\n    result = _3569;\n    float3 param_40 = _3569;\n    float3 param_41 = in.fa_world_pos;\n    result = fa_shadow_debug(param_40, param_41, _720);\n    bool _3578 = _484.fa_fog.w > 0.0;\n    bool _3585;\n    if (!_3578)\n    {\n        _3585 = _484.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3585 = _3578;\n    }\n    if (_3585)\n    {\n        float3 _3594 = in.fa_world_pos - _484.fa_camera_pos.xyz;\n        float _3600 = dot(_3594, _484.fa_fog_c.xyz);\n        bool _3604 = _484.fa_fog_c.w > 0.5;\n        float _3605;\n        if (_3604)\n        {\n            _3605 = _3600;\n        }\n        else\n        {\n            _3605 = length(_3594);\n        }\n        float _3617 = _3605 - _484.fa_fog_b.x;\n        if (_3617 > 0.0)\n        {\n            float _3626 = _484.fa_fog.w * _3617;\n            float tau = _3626 * _3626;\n            if (_484.fa_fog_b.y > 0.0)\n            {\n                float _3642;\n                if (_3604)\n                {\n                    _3642 = in.fa_world_pos.y - (_484.fa_fog_c.y * _3600);\n                }\n                else\n                {\n                    _3642 = _484.fa_camera_pos.y;\n                }\n                float _3663 = mix(_3642, in.fa_world_pos.y, fast::clamp(_484.fa_fog_b.x / _3605, 0.0, 1.0));\n                float _3667 = in.fa_world_pos.y - _3663;\n                float _3672 = _3663 - _484.fa_fog_b.z;\n                float _3677 = in.fa_world_pos.y - _484.fa_fog_b.z;\n                bool _3680 = _3672 <= 0.0;\n                bool _3681 = !_3680;\n                bool _3687;\n                if (_3681)\n                {\n                    _3687 = _484.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3687 = _3680;\n                }\n                float _3688;\n                if (_3687)\n                {\n                    _3688 = _484.fa_fog_b.y;\n                }\n                else\n                {\n                    _3688 = _484.fa_fog_b.y * exp(-fast::min(_484.fa_fog_b.w * _3672, 80.0));\n                }\n                bool _3715;\n                if (_3681)\n                {\n                    _3715 = _484.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3715 = _3680;\n                }\n                float _3716;\n                if (_3715)\n                {\n                    _3716 = _484.fa_fog_b.y * _3672;\n                }\n                else\n                {\n                    _3716 = (_484.fa_fog_b.y * (1.0 - exp(-fast::min(_484.fa_fog_b.w * _3672, 80.0)))) / _484.fa_fog_b.w;\n                }\n                bool _3741 = _3677 <= 0.0;\n                bool _3748;\n                if (!_3741)\n                {\n                    _3748 = _484.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3748 = _3741;\n                }\n                float _3749;\n                if (_3748)\n                {\n                    _3749 = _484.fa_fog_b.y * _3677;\n                }\n                else\n                {\n                    _3749 = (_484.fa_fog_b.y * (1.0 - exp(-fast::min(_484.fa_fog_b.w * _3677, 80.0)))) / _484.fa_fog_b.w;\n                }\n                float _3776;\n                if (abs(_3667) < 0.001000000047497451305389404296875)\n                {\n                    _3776 = _3688;\n                }\n                else\n                {\n                    _3776 = (_3749 - _3716) / _3667;\n                }\n                tau += (_3617 * fast::max(_3776, 0.0));\n            }\n            result = mix(result, _484.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3849);\n    return out;\n}\n\n",
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
            "inst_name": "_238",
            "msl_buffer_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_484",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_720",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _217)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _208 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_217.fa_joint_rows[_208] * weights[i]);\n        r1 += (_217.fa_joint_rows[_208 + 1] * weights[i]);\n        r2 += (_217.fa_joint_rows[_208 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _173)\n{\n    float3 _114 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _114) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_114 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * _173.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex)\n{\n    if (fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, constant fa_mesh_vs_params& _173, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _173);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _173.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _173 [[buffer(0)]], constant fa_skin& _217 [[buffer(3)]], constant fa_inst_base& _350 [[buffer(6)]], const device fa_vs_points_buf& fa_vs_points [[buffer(8)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = _350.fa_base_model * fa_skin_matrix(param, param_1, _217);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, fa_vs_points, gl_InstanceIndex, _173, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nconstant spvUnsafeArray<float, 63> _1997 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _484)\n{\n    bool _489 = _484.fa_cl_info.x < 0.0;\n    bool _496;\n    if (!_489)\n    {\n        _496 = _484.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _496 = _489;\n    }\n    bool _504;\n    if (!_496)\n    {\n        _504 = _484.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _504 = _496;\n    }\n    bool _511;\n    if (!_504)\n    {\n        _511 = _484.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _511 = _504;\n    }\n    bool _518;\n    if (!_511)\n    {\n        _518 = _484.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _518 = _511;\n    }\n    if (_518)\n    {\n        return int2(0);\n    }\n    float4 _528 = float4(world_pos, 1.0);\n    float _535 = dot(_484.fa_cl_vpw, _528);\n    if (!(_535 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _557 = float2(dot(_484.fa_cl_vpx, _528), dot(_484.fa_cl_vpy, _528)) / float2(_535);\n    int _561 = int(_484.fa_cl_grid.x);\n    int _565 = int(_484.fa_cl_grid.y);\n    int param = (int(_484.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_484.fa_cl_fwd.xyz, world_pos) + _484.fa_cl_fwd.w, _484.fa_cl_grid.w) / _484.fa_cl_grid.w) * _484.fa_cl_grid.z)), 0, int(_484.fa_cl_info.y) - 1) * _565) + clamp(int(floor(((_557.y * 0.5) + 0.5) * _484.fa_cl_grid.y)), 0, _565 - 1)) * _561)) + clamp(int(floor(((_557.x * 0.5) + 0.5) * _484.fa_cl_grid.x)), 0, _561 - 1);\n    float4 _636 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_636.x), int(_636.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _484, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_484.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2814 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _484);\n    fa_cl_slot = _2814.x;\n    fa_cl_local = _2814.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2958 = fa_linear_to_srgb(param);\n        c = _2958;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2966 = fa_srgb_to_linear(param_1);\n            c = _2966;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _256;\n    if (bool(i.front_facing))\n    {\n        _256 = i.world_normal;\n    }\n    else\n    {\n        _256 = -i.world_normal;\n    }\n    float3 _280 = fast::normalize(i.world_tangent.xyz - (_256 * dot(_256, i.world_tangent.xyz)));\n    float3 _308 = fast::normalize(((_280 * m.x) + ((cross(_256, _280) * i.world_tangent.w) * m.y)) + (_256 * m.z));\n    float3 _311;\n    if (bool(i.front_facing))\n    {\n        _311 = _308;\n    }\n    else\n    {\n        _311 = -_308;\n    }\n    return _311;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _484, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _484.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2997 = fa_tex_fix(param_2, param_3);\n    float4 _4200 = base_t;\n    _4200.x = _2997.x;\n    _4200.y = _2997.y;\n    _4200.z = _2997.z;\n    base_t = _4200;\n    float4 _3011 = (_4200 * _484.fa_base_color) * i.vertex_color;\n    float3 _4102 = i.world_normal;\n    if (_484.fa_maps.z > 0.5)\n    {\n        float param_4 = _484.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3043 = fa_tex_fix(param_6, param_7);\n        float3 _3046 = (_3043 * 2.0) - float3(1.0);\n        float2 _3051 = _3046.xy * _484.fa_maps.x;\n        float3 _4208 = _3046;\n        _4208.x = _3051.x;\n        _4208.y = _3051.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4208;\n        _4102 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _484.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3080 = fa_tex_fix(param_12, param_13);\n    float4 _4211 = mrt;\n    _4211.x = _3080.x;\n    _4211.y = _3080.y;\n    _4211.z = _3080.z;\n    mrt = _4211;\n    float4 _3108 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _484.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3108.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3120 = fa_tex_fix(param_16, param_17);\n    float param_18 = _484.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3150 = fa_tex_fix(param_20, param_21);\n    float _4107 = _484.fa_layers_a.x;\n    float _4108 = _484.fa_layers_a.y;\n    float _4111 = _484.fa_layers_a.z;\n    float _4110 = _484.fa_layers_b.w;\n    float _4113 = _484.fa_layers_c.x;\n    if (_484.fa_layers_c.z > 0.5)\n    {\n        if (mod(_484.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4107 *= _3120.y;\n            _4108 *= _3120.z;\n            _4110 *= _3108.w;\n        }\n        if (_484.fa_layers_c.z > 1.5)\n        {\n            _4111 *= mrt.x;\n            _4113 *= mrt.w;\n        }\n    }\n    return Surface{ _3011.xyz, _3011.w, _4102, fast::clamp(_484.fa_pbr.x * _3080.z, 0.0, 1.0), fast::clamp(_484.fa_pbr.y * _3080.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_484.fa_maps.y * (_3120.x - 1.0)), _484.fa_emissive.xyz + (_484.fa_model_emissive.xyz * _3150), _4107, _4108, _484.fa_layers_b.xyz, _4110, _4111, _484.fa_layers_a.w, _4113, _484.fa_layers_c.y, _484.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, const device fa_points_buf& points)\n{\n    s.emission += (i.vertex_color.xyz * ((device float*)&points.data[0].tint)[3u]);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1922 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1930 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1933 = int(_1922);\n    int _1936 = int(_1930);\n    float _1946 = _1930 - float(_1936);\n    int _2002 = (_1933 * 9) + _1936;\n    int _2022 = ((_1933 + 1) * 9) + _1936;\n    return mix(mix(_1997[_2002], _1997[_2002 + 1], _1946), mix(_1997[_2022], _1997[_2022 + 1], _1946), _1922 - float(_1933));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4038 = false;\n    float _4039 = 1.0;\n    float _4040 = 1.0;\n    float _4041 = 1.0;\n    float _4042 = 0.0;\n    float _4043 = 0.0;\n    float _4044 = 0.0;\n    float _4045 = 0.0;\n    float _4047 = 1.0;\n    bool _4048 = false;\n    float3 _4049 = float3(0.0);\n    float _4050 = 1.0;\n    float _4051 = 1.0;\n    float _4052 = 1.0;\n    float _4053 = 0.0;\n    float _4054 = 0.0;\n    float3 _4055 = float3(1.0, 0.0, 0.0);\n    float3 _4056 = float3(0.0, 0.0, 1.0);\n    float _4057 = 1.0;\n    float _4058 = 1.0;\n    float _2075 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2079 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2084 = (_2075 != 1.0) || (_2079 != 1.5);\n    bool _2094;\n    if (!_2084)\n    {\n        _2094 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2094 = _2084;\n    }\n    if (_2094)\n    {\n        float _2102 = (_2079 - 1.0) / (_2079 + 1.0);\n        f0 = mix(fast::min(float3(_2102 * _2102) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2075, s.albedo, float3(metallic));\n        _4039 = mix(_2075, 1.0, metallic);\n        _4038 = true;\n    }\n    float _2130 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2130 > 0.0)\n    {\n        float _2138 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4042 = _2130;\n        _4043 = _2138;\n        float _2145 = _2138 * _2138;\n        _4044 = _2145;\n        _4045 = _2145 * _2145;\n        float _2157 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4047 = _2157;\n        _4040 = 1.0 - (_2130 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2157, 0.0, 1.0), 5.0))));\n        _4038 = true;\n    }\n    float3 _2177 = fast::max(s.sheen_color, float3(0.0));\n    float _2186 = fast::max(_2177.x, fast::max(_2177.y, _2177.z));\n    if (_2186 > 0.0)\n    {\n        float _2194 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4048 = true;\n        _4049 = _2177;\n        _4050 = _2194;\n        _4051 = _2194 * _2194;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2194;\n        float _2211 = fa_sheen_albedo(param, param_1);\n        _4053 = _2211;\n        _4052 = 1.0 - fast::min(_2186 * _2211, 1.0);\n        _4038 = true;\n    }\n    _4041 = _4040 * _4052;\n    float _2230 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2230 != 0.0)\n    {\n        float3 _2245 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2245;\n        if (dot(_2245, _2245) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2263 = t;\n        float3 _2264 = fast::normalize(_2263);\n        t = _2264;\n        float3 _2289 = fast::normalize((_2264 * cos(s.anisotropy_rotation)) + ((cross(n, _2264) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4055 = _2289;\n        _4056 = cross(n, _2289);\n        float _2299 = roughness * roughness;\n        float _2305 = mix(_2299, 1.0, _2230 * _2230);\n        bool _2307 = _2230 > 0.0;\n        _4057 = _2307 ? _2305 : _2299;\n        _4058 = _2307 ? _2299 : _2305;\n        _4054 = _2230;\n        _4038 = true;\n    }\n    return FaLayers{ short(_4038), _4039, _4040, _4041, _4042, _4043, _4044, _4045, i.world_normal, _4047, short(_4048), _4049, _4050, _4051, _4052, _4053, _4054, _4055, _4056, _4057, _4058 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _484, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_484.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _484.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _484)\n{\n    int param = (int(_484.fa_cl_info.x) + int(_484.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _484, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _484);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _356 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _362 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _365 = _362.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _372 = _365 < 0.5;\n    float3 l;\n    if (_372)\n    {\n        l = fast::normalize(_356.xyz);\n    }\n    else\n    {\n        float3 _384 = _356.xyz - world_pos;\n        float _386 = length(_384);\n        dist = _386;\n        l = _384 / float3(fast::max(_386, 9.9999997473787516355514526367188e-05));\n        float _401 = _386 / fast::max(_356.w, 0.001000000047497451305389404296875);\n        float _407 = fast::clamp(1.0 - (_401 * _401), 0.0, 1.0);\n        atten = _407 * _407;\n        if (_365 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _421 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _431 = _421.w;\n            int param_3 = (li * 4) + 3;\n            float4 _438 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _439 = _438.x;\n            float cos_inner = _439;\n            if (_439 > 1.5)\n            {\n                cos_inner = mix(_431, 1.0, 0.25);\n            }\n            atten *= smoothstep(_431, cos_inner, dot(-l, fast::normalize(_421.xyz)));\n        }\n    }\n    int _470;\n    if (_372)\n    {\n        _470 = 0;\n    }\n    else\n    {\n        _470 = (_365 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _362.xyz * atten, atten, 1.0, dist, _470 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _720)\n{\n    float _710;\n    if (i == 0)\n    {\n        _710 = _720.fa_shadow_split.x;\n    }\n    else\n    {\n        float _726;\n        if (i == 1)\n        {\n            _726 = _720.fa_shadow_split.y;\n        }\n        else\n        {\n            float _734;\n            if (i == 2)\n            {\n                _734 = _720.fa_shadow_split.z;\n            }\n            else\n            {\n                _734 = _720.fa_shadow_split.w;\n            }\n            _726 = _734;\n        }\n        _710 = _726;\n    }\n    return _710;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _767 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _771;\n    if (conv.x < 0.5)\n    {\n        _771 = _767;\n    }\n    else\n    {\n        _771 = (conv.y * conv.z) / (conv.z - (_767 * (conv.z - conv.y)));\n    }\n    return _771;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _698 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_698), sin(_698)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _720, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _817 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _831 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _817;\n            float2 _850 = fa_shadow_vogel(param_3, param_4, param_5) * _831;\n            float2 param_6 = uv + (_850 * _720.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _862 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_862 < (zr - (length(_850) * plane)))\n            {\n                sum += _862;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _906 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _906; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _906;\n        float param_11 = _817;\n        float2 _925 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_925 * _720.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_925) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_906);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _720, texture2d<float> fa_shadow_tex)\n{\n    float _967 = fast::max(_720.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _972 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _978 = sqrt(1.0 - (_972 * _972));\n    float _986 = fast::min(_978 / fast::max(_972, 0.20000000298023223876953125), 4.0);\n    float _991;\n    if (_720.fa_shadow_bias.y > 0.0)\n    {\n        _991 = _720.fa_shadow_bias.y;\n    }\n    else\n    {\n        _991 = 1.5 * _720.fa_shadow_info[ci].x;\n    }\n    float4 _1016 = _720.fa_shadow_mat[ci] * float4(world + (n * (_991 * _978)), 1.0);\n    float _1023 = _1016.x;\n    bool _1026 = _1023 < _720.fa_shadow_rect[ci].x;\n    bool _1035;\n    if (!_1026)\n    {\n        _1035 = _1023 > _720.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1035 = _1026;\n    }\n    bool _1044;\n    if (!_1035)\n    {\n        _1044 = _1016.y < _720.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1044 = _1035;\n    }\n    bool _1053;\n    if (!_1044)\n    {\n        _1053 = _1016.y > _720.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1053 = _1044;\n    }\n    bool _1060;\n    if (!_1053)\n    {\n        _1060 = _1016.z > 1.0;\n    }\n    else\n    {\n        _1060 = _1053;\n    }\n    if (_1060)\n    {\n        return -1.0;\n    }\n    float _1069;\n    if (_720.fa_shadow_bias.x > 0.0)\n    {\n        _1069 = _720.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1069 = 1.5 * _720.fa_shadow_info[ci].x;\n    }\n    float2 param = _1016.xy;\n    float4 param_1 = _720.fa_shadow_rect[ci];\n    float param_2 = _1016.z - ((_1069 * (1.0 + (0.5 * _986))) / _967);\n    float param_3 = _720.fa_shadow_info[ci].x;\n    float param_4 = _967;\n    float param_5 = _967 * 0.25;\n    float param_6 = ((_720.fa_shadow_info[ci].x * fast::min(_986, 3.0)) * 0.5) / _967;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_720.fa_shadow_cfg.z + 0.5);\n    float param_9 = _720.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _720, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _484, thread float4& gl_FragCoord, constant fa_shadows& _720, texture2d<float> fa_shadow_tex)\n{\n    if (_484.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1463 = int(_720.fa_shadow_cfg.x + 0.5);\n    if (_1463 < 1)\n    {\n        return 1.0;\n    }\n    float _1479 = dot(world - _720.fa_shadow_eye.xyz, _720.fa_shadow_fwd.xyz);\n    int param = _1463 - 1;\n    if (_1479 > fa_shadow_split_at(param, _720))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1491 = _1463 > 1;\n    bool _1498;\n    if (_1491)\n    {\n        _1498 = _1479 > _720.fa_shadow_split.x;\n    }\n    else\n    {\n        _1498 = _1491;\n    }\n    if (_1498)\n    {\n        ci = 1;\n    }\n    bool _1502 = _1463 > 2;\n    bool _1509;\n    if (_1502)\n    {\n        _1509 = _1479 > _720.fa_shadow_split.y;\n    }\n    else\n    {\n        _1509 = _1502;\n    }\n    if (_1509)\n    {\n        ci = 2;\n    }\n    bool _1513 = _1463 > 3;\n    bool _1520;\n    if (_1513)\n    {\n        _1520 = _1479 > _720.fa_shadow_split.z;\n    }\n    else\n    {\n        _1520 = _1513;\n    }\n    if (_1520)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1463)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1546 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _720, fa_shadow_tex);\n        s = _1546;\n        if (_1546 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_720.fa_shadow_cfg.y > 0.0)\n    {\n        float _1571;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1571 = fa_shadow_split_at(param_5, _720);\n        }\n        else\n        {\n            _1571 = _720.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1590 = _720.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _720) - _1571, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1601 = fast::clamp((_1479 - (fa_shadow_split_at(param_7, _720) - _1590)) / _1590, 0.0, 1.0);\n        if (_1601 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1463)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1622 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _720, fa_shadow_tex);\n                s2 = _1622;\n                if (_1622 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1601);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _484, thread float4& gl_FragCoord, constant fa_shadows& _720, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _484, gl_FragCoord, _720, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _484, thread float4& gl_FragCoord, constant fa_shadows& _720, texture2d<float> fa_shadow_tex)\n{\n    bool _1128 = _484.fa_pbr.z < 0.5;\n    bool _1136;\n    if (!_1128)\n    {\n        _1136 = _720.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1136 = _1128;\n    }\n    if (_1136)\n    {\n        return 1.0;\n    }\n    int param = (int(_720.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1149 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1150 = _1149.x;\n    if (_1150 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1159 = int(_1150 + 0.5);\n    int param_1 = _1159;\n    float4 _1163 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1159 + 1;\n    float4 _1168 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1171 = _1163.y;\n    if (_1171 > 0.0)\n    {\n        float _1188 = 1.0 - smoothstep(0.75 * _1171, _1171, length(world - _720.fa_shadow_eye.xyz));\n        fade = _1188;\n        if (_1188 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1163.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1207 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1210 = abs(_1207);\n        float _1212 = _1210.x;\n        float _1214 = _1210.y;\n        bool _1215 = _1212 >= _1214;\n        bool _1223;\n        if (_1215)\n        {\n            _1223 = _1212 >= _1210.z;\n        }\n        else\n        {\n            _1223 = _1215;\n        }\n        int _1224;\n        if (_1223)\n        {\n            _1224 = (_1207.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1237;\n            if (_1214 >= _1210.z)\n            {\n                _1237 = (_1207.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1237 = (_1207.z > 0.0) ? 4 : 5;\n            }\n            _1224 = _1237;\n        }\n        face = _1224;\n    }\n    int _1256 = (_1159 + 2) + (face * 6);\n    int param_4 = _1256;\n    int param_5 = _1256 + 1;\n    int param_6 = _1256 + 3;\n    float4 _1270 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1256 + 4;\n    float4 _1275 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1256 + 5;\n    float4 _1280 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1292 = _1280.x * fast::max(dot(_1270, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1297 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1303 = sqrt(1.0 - (_1297 * _1297));\n    float _1309 = fast::min(_1303 / fast::max(_1297, 0.20000000298023223876953125), 4.0);\n    float _1312 = _1168.y;\n    float _1314;\n    if (_1312 > 0.0)\n    {\n        _1314 = _1312;\n    }\n    else\n    {\n        _1314 = 1.5 * _1292;\n    }\n    float4 _1334 = float4(world + (n * (_1314 * _1303)), 1.0);\n    float _1338 = dot(_1270, _1334);\n    float _1341 = _1280.y;\n    if (_1338 < _1341)\n    {\n        return 1.0;\n    }\n    float2 _1356 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1334), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1334)) / float2(_1338);\n    float _1358 = _1356.x;\n    bool _1361 = _1358 < _1275.x;\n    bool _1370;\n    if (!_1361)\n    {\n        _1370 = _1358 > _1275.z;\n    }\n    else\n    {\n        _1370 = _1361;\n    }\n    bool _1379;\n    if (!_1370)\n    {\n        _1379 = _1356.y < _1275.y;\n    }\n    else\n    {\n        _1379 = _1370;\n    }\n    bool _1388;\n    if (!_1379)\n    {\n        _1388 = _1356.y > _1275.w;\n    }\n    else\n    {\n        _1388 = _1379;\n    }\n    if (_1388)\n    {\n        return 1.0;\n    }\n    float _1394 = _1168.x;\n    float _1396;\n    if (_1394 > 0.0)\n    {\n        _1396 = _1394;\n    }\n    else\n    {\n        _1396 = 1.5 * _1292;\n    }\n    float2 param_9 = _1356;\n    float4 param_10 = _1275;\n    float param_11 = _1338 - (_1396 * (1.0 + (0.5 * _1309)));\n    float param_12 = _1292;\n    float param_13 = 1.0;\n    float param_14 = _1280.z * 0.25;\n    float param_15 = (_1292 * fast::min(_1309, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _1341, _1280.z);\n    int param_17 = int(_1163.z + 0.5);\n    float param_18 = _1163.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _720, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _484, thread float4& gl_FragCoord, constant fa_shadows& _720, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2842 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _4087 = _2842.direction;\n    float3 _4082 = _2842.color;\n    float _4089 = _2842.attenuation;\n    float _4084 = _2842.shadow;\n    int _4092 = _2842.type;\n    if ((_4092 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _4087;\n        float _2856 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _484, gl_FragCoord, _720, fa_shadow_tex, fa_world_pos);\n        _4084 = _2856;\n        _4082 *= _2856;\n    }\n    else\n    {\n        bool _2867 = _4092 != 0;\n        bool _2873;\n        if (_2867)\n        {\n            _2873 = _4089 > 0.0;\n        }\n        else\n        {\n            _2873 = _2867;\n        }\n        if (_2873)\n        {\n            int param_4 = li;\n            float3 param_5 = world_pos;\n            float3 param_6 = gn;\n            float3 param_7 = _4087;\n            float _2885 = fa_shadow_local(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _484, gl_FragCoord, _720, fa_shadow_tex);\n            _4084 = _2885;\n            _4082 *= _2885;\n        }\n    }\n    return LightSample{ _4087, _4082, _4089, _4084, _2842._distance, _4092 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _2457 = tdh / at;\n    float _2461 = bdh / ab;\n    float _2473 = ((_2457 * _2457) + (_2461 * _2461)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2473) * _2473);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _2554 = 1.0 / alpha;\n    return ((2.0 + _2554) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2554)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _2587 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2666 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2666) * _2666);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2587);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2587));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2739 = fast::max(dot(L.nc, l), 0.0);\n        float _2745 = fast::max(dot(L.nc, h), 0.0);\n        float _2754 = ((_2745 * _2745) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2754) * _2754)) * (0.5 / fast::max(mix((2.0 * _2739) * L.coat_ndv, _2739 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2739)) * _2739);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1854 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1857 = _1854.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1857 * _1857, exp2((-9.27999973297119140625) * ndv)) * _1857) + _1854.y)) + _1854.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _484, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_484.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _484.fa_env_horizon.w)).xyz;\n    }\n    float _1759 = rough * rough;\n    float _1789 = 0.60000002384185791015625 * _1759;\n    return mix(mix(_484.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_484.fa_env_horizon.xyz, _484.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1759)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1789, 0.0500000007450580596923828125 + _1789, d.y))), ((_484.fa_env_sky.xyz + _484.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1759 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _484, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2340;\n        if (L.aniso >= 0.0)\n        {\n            _2340 = L.b;\n        }\n        else\n        {\n            _2340 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2340, v), _2340), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2373 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _484, fa_env_tex, fa_env_smp) * ((f0 * _2373.x) + (float3(L.f90) * _2373.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _484, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2428 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _484, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _2428.x) + _2428.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _484, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1896 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _484, fa_env_tex, fa_env_smp) * ((f0 * _1896.x) + float3(_1896.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _720)\n{\n    if (_720.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1646 = int(_720.fa_shadow_cfg.x + 0.5);\n    float _1656 = dot(world - _720.fa_shadow_eye.xyz, _720.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1661 = _1646 > 0;\n    bool _1670;\n    if (_1661)\n    {\n        int param = _1646 - 1;\n        _1670 = _1656 <= fa_shadow_split_at(param, _720);\n    }\n    else\n    {\n        _1670 = _1661;\n    }\n    if (_1670)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1677 = _1646 > 1;\n        bool _1684;\n        if (_1677)\n        {\n            _1684 = _1656 > _720.fa_shadow_split.x;\n        }\n        else\n        {\n            _1684 = _1677;\n        }\n        if (_1684)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1690 = _1646 > 2;\n        bool _1697;\n        if (_1690)\n        {\n            _1697 = _1656 > _720.fa_shadow_split.y;\n        }\n        else\n        {\n            _1697 = _1690;\n        }\n        if (_1697)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1703 = _1646 > 3;\n        bool _1710;\n        if (_1703)\n        {\n            _1710 = _1656 > _720.fa_shadow_split.z;\n        }\n        else\n        {\n            _1710 = _1703;\n        }\n        if (_1710)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _484 [[buffer(1)]], constant fa_shadows& _720 [[buffer(7)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3817 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3817 = -_3817;\n    }\n    float3 _3271 = fast::normalize(_484.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _484, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3817, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3271, short(gl_FrontFacing) };\n    Surface _3279 = fa_standard_surface(param_1, _484, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3848 = _3279.albedo;\n    float _3849 = _3279.alpha;\n    float3 _3850 = _3279.normal;\n    float _3851 = _3279.metallic;\n    float _3852 = _3279.roughness;\n    float _3853 = _3279.occlusion;\n    float3 _3854 = _3279.emission;\n    float _3855 = _3279.clearcoat;\n    float _3856 = _3279.clearcoat_roughness;\n    float3 _3857 = _3279.sheen_color;\n    float _3858 = _3279.sheen_roughness;\n    float _3859 = _3279.anisotropy;\n    float _3860 = _3279.anisotropy_rotation;\n    float _3861 = _3279.specular;\n    float _3862 = _3279.ior;\n    float3 _3863 = _3279.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3817, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3271, short(gl_FrontFacing) };\n    Surface param_3 = _3279;\n    surface(param_2, param_3, points);\n    _3848 = param_3.albedo;\n    _3849 = param_3.alpha;\n    _3850 = param_3.normal;\n    _3851 = param_3.metallic;\n    _3852 = param_3.roughness;\n    _3853 = param_3.occlusion;\n    _3854 = param_3.emission;\n    _3855 = param_3.clearcoat;\n    _3856 = param_3.clearcoat_roughness;\n    _3857 = param_3.sheen_color;\n    _3858 = param_3.sheen_roughness;\n    _3859 = param_3.anisotropy;\n    _3860 = param_3.anisotropy_rotation;\n    _3861 = param_3.specular;\n    _3862 = param_3.ior;\n    _3863 = param_3.specular_color;\n    float3 result;\n    if (_484.fa_emissive.w > 0.5)\n    {\n        result = _3848;\n    }\n    else\n    {\n        float3 _3301 = fast::normalize(_3850);\n        float _3308 = fast::clamp(_3851, 0.0, 1.0);\n        float _3312 = fast::clamp(_3852, 0.0500000007450580596923828125, 1.0);\n        float _3316 = _3312 * _3312;\n        float _3320 = _3316 * _3316;\n        float _3325 = fast::max(dot(_3301, _3271), 9.9999997473787516355514526367188e-05);\n        float3 _3331 = _3848 * (1.0 - _3308);\n        float3 _3338 = mix(float3(0.039999999105930328369140625), _3848, float3(_3308));\n        float3 f0 = _3338;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _3817, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3271, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _3848, _3849, _3850, _3851, _3852, _3853, _3854, _3855, _3856, _3857, _3858, _3859, _3860, _3861, _3862, _3863 };\n        float3 param_6 = _3301;\n        float3 param_7 = _3271;\n        float param_8 = _3308;\n        float param_9 = _3312;\n        float3 param_10 = _3338;\n        FaLayers _3354 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _3301;\n        float3 lit = (fa_ambient_light(param_11, _484, fa_env_smp, fa_irr_tex) * _3331) * _3853;\n        if (_3354.on)\n        {\n            lit *= _3354.base_scale;\n        }\n        int _3376 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3376; ln++)\n        {\n            int param_12 = ln;\n            int _3389 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _484, fa_cl_ndir, fa_cl_slot);\n            int param_13 = _3389;\n            float3 param_14 = in.fa_world_pos;\n            float3 param_15 = _3817;\n            LightSample _3398 = fa_light_shadowed(param_13, param_14, param_15, fa_light_tex, fa_shadow_smp, _484, gl_FragCoord, _720, fa_shadow_tex, in.fa_world_pos);\n            float3 _4022 = _3398.direction;\n            float _3406 = fast::max(dot(_3301, _4022), 0.0);\n            float _3412 = _3398.attenuation * _3398.shadow;\n            float3 _3417 = fast::normalize(_4022 + _3271);\n            float _3422 = fast::max(dot(_3301, _3417), 0.0);\n            float _3427 = fast::max(dot(_3271, _3417), 0.0);\n            if (_3354.on)\n            {\n                FaLayers param_16 = _3354;\n                float3 param_17 = _3331;\n                float3 param_18 = f0;\n                float3 param_19 = _3301;\n                float3 param_20 = _3271;\n                float3 param_21 = _4022;\n                float3 param_22 = _3417;\n                float param_23 = _3406;\n                float param_24 = _3325;\n                float param_25 = _3422;\n                float param_26 = _3427;\n                float param_27 = _3316;\n                float param_28 = _3320;\n                int param_29 = _3389;\n                lit += (fa_layers_light(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28) * (fa_light_rgb(param_29, fa_light_tex, fa_shadow_smp) * _3412));\n            }\n            else\n            {\n                float _3475 = ((_3422 * _3422) * (_3320 - 1.0)) + 1.0;\n                int param_30 = _3389;\n                lit += (((_3331 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _3427, 5.0))) * (((_3320 / ((3.1415927410125732421875 * _3475) * _3475)) * (0.5 / fast::max(mix((2.0 * _3406) * _3325, _3406 + _3325, _3316), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3406))) * fa_light_rgb(param_30, fa_light_tex, fa_shadow_smp)) * (_3406 * _3412));\n            }\n        }\n        if (_3354.on)\n        {\n            FaLayers param_31 = _3354;\n            float3 param_32 = _3301;\n            float3 param_33 = _3271;\n            float3 param_34 = f0;\n            float param_35 = _3312;\n            lit += (fa_layers_ibl(param_31, param_32, param_33, param_34, param_35, _484, fa_env_tex, fa_env_smp) * _3853);\n        }\n        else\n        {\n            float3 param_36 = _3301;\n            float3 param_37 = _3271;\n            float3 param_38 = f0;\n            float param_39 = _3312;\n            lit += (fa_sky_reflection(param_36, param_37, param_38, param_39, _484, fa_env_tex, fa_env_smp) * _3853);\n        }\n        result = lit;\n    }\n    float3 _3568 = result;\n    float3 _3569 = _3568 + _3854;\n    result = _3569;\n    float3 param_40 = _3569;\n    float3 param_41 = in.fa_world_pos;\n    result = fa_shadow_debug(param_40, param_41, _720);\n    bool _3578 = _484.fa_fog.w > 0.0;\n    bool _3585;\n    if (!_3578)\n    {\n        _3585 = _484.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3585 = _3578;\n    }\n    if (_3585)\n    {\n        float3 _3594 = in.fa_world_pos - _484.fa_camera_pos.xyz;\n        float _3600 = dot(_3594, _484.fa_fog_c.xyz);\n        bool _3604 = _484.fa_fog_c.w > 0.5;\n        float _3605;\n        if (_3604)\n        {\n            _3605 = _3600;\n        }\n        else\n        {\n            _3605 = length(_3594);\n        }\n        float _3617 = _3605 - _484.fa_fog_b.x;\n        if (_3617 > 0.0)\n        {\n            float _3626 = _484.fa_fog.w * _3617;\n            float tau = _3626 * _3626;\n            if (_484.fa_fog_b.y > 0.0)\n            {\n                float _3642;\n                if (_3604)\n                {\n                    _3642 = in.fa_world_pos.y - (_484.fa_fog_c.y * _3600);\n                }\n                else\n                {\n                    _3642 = _484.fa_camera_pos.y;\n                }\n                float _3663 = mix(_3642, in.fa_world_pos.y, fast::clamp(_484.fa_fog_b.x / _3605, 0.0, 1.0));\n                float _3667 = in.fa_world_pos.y - _3663;\n                float _3672 = _3663 - _484.fa_fog_b.z;\n                float _3677 = in.fa_world_pos.y - _484.fa_fog_b.z;\n                bool _3680 = _3672 <= 0.0;\n                bool _3681 = !_3680;\n                bool _3687;\n                if (_3681)\n                {\n                    _3687 = _484.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3687 = _3680;\n                }\n                float _3688;\n                if (_3687)\n                {\n                    _3688 = _484.fa_fog_b.y;\n                }\n                else\n                {\n                    _3688 = _484.fa_fog_b.y * exp(-fast::min(_484.fa_fog_b.w * _3672, 80.0));\n                }\n                bool _3715;\n                if (_3681)\n                {\n                    _3715 = _484.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3715 = _3680;\n                }\n                float _3716;\n                if (_3715)\n                {\n                    _3716 = _484.fa_fog_b.y * _3672;\n                }\n                else\n                {\n                    _3716 = (_484.fa_fog_b.y * (1.0 - exp(-fast::min(_484.fa_fog_b.w * _3672, 80.0)))) / _484.fa_fog_b.w;\n                }\n                bool _3741 = _3677 <= 0.0;\n                bool _3748;\n                if (!_3741)\n                {\n                    _3748 = _484.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3748 = _3741;\n                }\n                float _3749;\n                if (_3748)\n                {\n                    _3749 = _484.fa_fog_b.y * _3677;\n                }\n                else\n                {\n                    _3749 = (_484.fa_fog_b.y * (1.0 - exp(-fast::min(_484.fa_fog_b.w * _3677, 80.0)))) / _484.fa_fog_b.w;\n                }\n                float _3776;\n                if (abs(_3667) < 0.001000000047497451305389404296875)\n                {\n                    _3776 = _3688;\n                }\n                else\n                {\n                    _3776 = (_3749 - _3716) / _3667;\n                }\n                tau += (_3617 * fast::max(_3776, 0.0));\n            }\n            result = mix(result, _484.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3849);\n    return out;\n}\n\n",
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
            "inst_name": "_350",
            "msl_buffer_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_484",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_720",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _168)\n{\n    float3 _109 = cross(model[1].xyz, model[2].xyz);\n    float _114 = (dot(model[0].xyz, _109) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_109 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _114, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _114), texcoord0 * _168.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex)\n{\n    if (fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, constant fa_mesh_vs_params& _168, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _168);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex);\n    float4 _210 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_168.fa_light_vp * _210).z;\n    fa_pre_r0 = float3(_168.fa_light_vp[0].x, _168.fa_light_vp[1].x, _168.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_168.fa_light_vp[0].y, _168.fa_light_vp[1].y, _168.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_168.fa_light_vp[0].z, _168.fa_light_vp[1].z, _168.fa_light_vp[2].z);\n    gl_Position = _168.fa_view_proj * _210;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _168 [[buffer(0)]], constant fa_inst_base& _272 [[buffer(6)]], const device fa_vs_points_buf& fa_vs_points [[buffer(8)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = _272.fa_base_model;\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, fa_vs_points, gl_InstanceIndex, _168, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _231, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _231.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _748 = base_t;\n    _748.x = _242.x;\n    _748.y = _242.y;\n    _748.z = _242.z;\n    base_t = _748;\n    float4 _257 = (_748 * _231.fa_base_color) * i.vertex_color;\n    float3 _711 = i.world_normal;\n    if (_231.fa_maps.z > 0.5)\n    {\n        float param_4 = _231.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _290 = fa_tex_fix(param_6, param_7);\n        float3 _294 = (_290 * 2.0) - float3(1.0);\n        float2 _299 = _294.xy * _231.fa_maps.x;\n        float3 _756 = _294;\n        _756.x = _299.x;\n        _756.y = _299.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _756;\n        _711 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _231.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _328 = fa_tex_fix(param_12, param_13);\n    float4 _759 = mrt;\n    _759.x = _328.x;\n    _759.y = _328.y;\n    _759.z = _328.z;\n    mrt = _759;\n    float4 _358 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _231.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = _231.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _400 = fa_tex_fix(param_20, param_21);\n    float _716 = _231.fa_layers_a.x;\n    float _717 = _231.fa_layers_a.y;\n    float _720 = _231.fa_layers_a.z;\n    float _719 = _231.fa_layers_b.w;\n    float _722 = _231.fa_layers_c.x;\n    if (_231.fa_layers_c.z > 0.5)\n    {\n        if (mod(_231.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _716 *= _370.y;\n            _717 *= _370.z;\n            _719 *= _358.w;\n        }\n        if (_231.fa_layers_c.z > 1.5)\n        {\n            _720 *= mrt.x;\n            _722 *= mrt.w;\n        }\n    }\n    return Surface{ _257.xyz, _257.w, _711, fast::clamp(_231.fa_pbr.x * _328.z, 0.0, 1.0), fast::clamp(_231.fa_pbr.y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_231.fa_maps.y * (_370.x - 1.0)), _231.fa_emissive.xyz + (_231.fa_model_emissive.xyz * _400), _716, _717, _231.fa_layers_b.xyz, _719, _720, _231.fa_layers_a.w, _722, _231.fa_layers_c.y, _231.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, const device fa_points_buf& points)\n{\n    s.emission += (i.vertex_color.xyz * ((device float*)&points.data[0].tint)[3u]);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _231 [[buffer(1)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _622 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _622 = -_622;\n    }\n    float3 _534 = fast::normalize(_231.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _622, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _534, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _622, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _534, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _231, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, points);\n    float3 _549 = fast::normalize(param_2.normal);\n    float3 _564 = fast::normalize(float3(dot(in.fa_pre_r0, _549), dot(in.fa_pre_r1, _549), dot(in.fa_pre_r2, _549)));\n    float _576 = _564.z;\n    float2 e = _564.xy / float2((abs(_564.x) + abs(_564.y)) + abs(_576));\n    if (_576 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 384,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _231, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _231.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _748 = base_t;\n    _748.x = _242.x;\n    _748.y = _242.y;\n    _748.z = _242.z;\n    base_t = _748;\n    float4 _257 = (_748 * _231.fa_base_color) * i.vertex_color;\n    float3 _711 = i.world_normal;\n    if (_231.fa_maps.z > 0.5)\n    {\n        float param_4 = _231.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _290 = fa_tex_fix(param_6, param_7);\n        float3 _294 = (_290 * 2.0) - float3(1.0);\n        float2 _299 = _294.xy * _231.fa_maps.x;\n        float3 _756 = _294;\n        _756.x = _299.x;\n        _756.y = _299.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _756;\n        _711 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _231.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _328 = fa_tex_fix(param_12, param_13);\n    float4 _759 = mrt;\n    _759.x = _328.x;\n    _759.y = _328.y;\n    _759.z = _328.z;\n    mrt = _759;\n    float4 _358 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _231.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = _231.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _400 = fa_tex_fix(param_20, param_21);\n    float _716 = _231.fa_layers_a.x;\n    float _717 = _231.fa_layers_a.y;\n    float _720 = _231.fa_layers_a.z;\n    float _719 = _231.fa_layers_b.w;\n    float _722 = _231.fa_layers_c.x;\n    if (_231.fa_layers_c.z > 0.5)\n    {\n        if (mod(_231.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _716 *= _370.y;\n            _717 *= _370.z;\n            _719 *= _358.w;\n        }\n        if (_231.fa_layers_c.z > 1.5)\n        {\n            _720 *= mrt.x;\n            _722 *= mrt.w;\n        }\n    }\n    return Surface{ _257.xyz, _257.w, _711, fast::clamp(_231.fa_pbr.x * _328.z, 0.0, 1.0), fast::clamp(_231.fa_pbr.y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_231.fa_maps.y * (_370.x - 1.0)), _231.fa_emissive.xyz + (_231.fa_model_emissive.xyz * _400), _716, _717, _231.fa_layers_b.xyz, _719, _720, _231.fa_layers_a.w, _722, _231.fa_layers_c.y, _231.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, const device fa_points_buf& points)\n{\n    s.emission += (i.vertex_color.xyz * ((device float*)&points.data[0].tint)[3u]);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _231 [[buffer(1)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _622 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _622 = -_622;\n    }\n    float3 _534 = fast::normalize(_231.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _622, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _534, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _622, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _534, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _231, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, points);\n    float3 _549 = fast::normalize(param_2.normal);\n    float3 _564 = fast::normalize(float3(dot(in.fa_pre_r0, _549), dot(in.fa_pre_r1, _549), dot(in.fa_pre_r2, _549)));\n    float _576 = _564.z;\n    float2 e = _564.xy / float2((abs(_564.x) + abs(_564.y)) + abs(_576));\n    if (_576 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 384,
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
