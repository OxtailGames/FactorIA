{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "cdeb0668828214c74f0c30d588a05ff792b9d23c1a6a8d04f213c29c73527515",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _168)\n{\n    float3 _109 = cross(model[1].xyz, model[2].xyz);\n    float _114 = (dot(model[0].xyz, _109) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_109 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _114, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _114), texcoord0 * _168.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex)\n{\n    if (fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, constant fa_mesh_vs_params& _168, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _168);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _168.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _168 [[buffer(0)]], constant fa_inst_base& _238 [[buffer(6)]], const device fa_vs_points_buf& fa_vs_points [[buffer(8)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = _238.fa_base_model;\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, fa_vs_points, gl_InstanceIndex, _168, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nconstant spvUnsafeArray<float, 63> _2747 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555)\n{\n    bool _560 = _555.fa_cl_info.x < 0.0;\n    bool _567;\n    if (!_560)\n    {\n        _567 = _555.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _567 = _560;\n    }\n    bool _575;\n    if (!_567)\n    {\n        _575 = _555.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _575 = _567;\n    }\n    bool _582;\n    if (!_575)\n    {\n        _582 = _555.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _582 = _575;\n    }\n    bool _589;\n    if (!_582)\n    {\n        _589 = _555.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _589 = _582;\n    }\n    if (_589)\n    {\n        return float4(0.0);\n    }\n    float4 _599 = float4(world_pos, 1.0);\n    float _606 = dot(_555.fa_cl_vpw, _599);\n    if (!(_606 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _628 = float2(dot(_555.fa_cl_vpx, _599), dot(_555.fa_cl_vpy, _599)) / float2(_606);\n    int _632 = int(_555.fa_cl_grid.x);\n    int _636 = int(_555.fa_cl_grid.y);\n    int param = (int(_555.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_555.fa_cl_fwd.xyz, world_pos) + _555.fa_cl_fwd.w, _555.fa_cl_grid.w) / _555.fa_cl_grid.w) * _555.fa_cl_grid.z)), 0, int(_555.fa_cl_info.y) - 1) * _636) + clamp(int(floor(((_628.y * 0.5) + 0.5) * _555.fa_cl_grid.y)), 0, _636 - 1)) * _632)) + clamp(int(floor(((_628.x * 0.5) + 0.5) * _555.fa_cl_grid.x)), 0, _632 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555)\n{\n    float3 param = world_pos;\n    float4 _712 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _555);\n    return int2(int(_712.x), int(_712.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_555.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3811 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _555);\n    fa_cl_slot = _3811.x;\n    fa_cl_local = _3811.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _4015 = fa_linear_to_srgb(param);\n        c = _4015;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _4023 = fa_srgb_to_linear(param_1);\n            c = _4023;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _311;\n    if (bool(i.front_facing))\n    {\n        _311 = i.world_normal;\n    }\n    else\n    {\n        _311 = -i.world_normal;\n    }\n    float3 _335 = fast::normalize(i.world_tangent.xyz - (_311 * dot(_311, i.world_tangent.xyz)));\n    float3 _362 = fast::normalize(((_335 * m.x) + ((cross(_311, _335) * i.world_tangent.w) * m.y)) + (_311 * m.z));\n    float3 _365;\n    if (bool(i.front_facing))\n    {\n        _365 = _362;\n    }\n    else\n    {\n        _365 = -_362;\n    }\n    return _365;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _555, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _555.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4054 = fa_tex_fix(param_2, param_3);\n    float4 _5366 = base_t;\n    _5366.x = _4054.x;\n    _5366.y = _4054.y;\n    _5366.z = _4054.z;\n    base_t = _5366;\n    float4 _4068 = (_5366 * _555.fa_base_color) * i.vertex_color;\n    float3 _5220 = i.world_normal;\n    if (_555.fa_maps.z > 0.5)\n    {\n        float param_4 = _555.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4100 = fa_tex_fix(param_6, param_7);\n        float3 _4103 = (_4100 * 2.0) - float3(1.0);\n        float2 _4108 = _4103.xy * _555.fa_maps.x;\n        float3 _5374 = _4103;\n        _5374.x = _4108.x;\n        _5374.y = _4108.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5374;\n        _5220 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _555.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4137 = fa_tex_fix(param_12, param_13);\n    float4 _5377 = mrt;\n    _5377.x = _4137.x;\n    _5377.y = _4137.y;\n    _5377.z = _4137.z;\n    mrt = _5377;\n    float4 _4165 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _555.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _4165.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4177 = fa_tex_fix(param_16, param_17);\n    float param_18 = _555.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4207 = fa_tex_fix(param_20, param_21);\n    float _5225 = _555.fa_layers_a.x;\n    float _5226 = _555.fa_layers_a.y;\n    float _5229 = _555.fa_layers_a.z;\n    float _5228 = _555.fa_layers_b.w;\n    float _5231 = _555.fa_layers_c.x;\n    if (_555.fa_layers_c.z > 0.5)\n    {\n        if (mod(_555.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _5225 *= _4177.y;\n            _5226 *= _4177.z;\n            _5228 *= _4165.w;\n        }\n        if (_555.fa_layers_c.z > 1.5)\n        {\n            _5229 *= mrt.x;\n            _5231 *= mrt.w;\n        }\n    }\n    return Surface{ _4068.xyz, _4068.w, _5220, fast::clamp(_555.fa_pbr.x * _4137.z, 0.0, 1.0), fast::clamp(_555.fa_pbr.y * _4137.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_555.fa_maps.y * (_4177.x - 1.0)), _555.fa_emissive.xyz + (_555.fa_model_emissive.xyz * _4207), _5225, _5226, _555.fa_layers_b.xyz, _5228, _5229, _555.fa_layers_a.w, _5231, _555.fa_layers_c.y, _555.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, const device fa_points_buf& points)\n{\n    s.emission += (i.vertex_color.xyz * ((device float*)&points.data[0].tint)[3u]);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _793 = rect.zw - rect.xy;\n    float2 _797 = _793 * atlas;\n    float2 _801 = ddx * _797;\n    float2 _805 = ddy * _797;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _793)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_801, _801), dot(_805, _805)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _840 = _555.fa_counts.y < 0.5;\n    bool _847;\n    if (!_840)\n    {\n        _847 = _555.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _847 = _840;\n    }\n    if (_847)\n    {\n        return;\n    }\n    float3 _853 = dfdx(world_pos);\n    float3 _856 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _860 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _555);\n    int _864 = int(_860.w);\n    if (_864 < 1)\n    {\n        return;\n    }\n    int _874 = int(_555.fa_counts.y + 0.5);\n    int param_1 = _874;\n    float4 _878 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _881 = _878.yz;\n    int _885 = int(_878.w);\n    int param_2 = _874 + 1;\n    float4 _890 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _891 = _890.x;\n    int _897 = int(_555.fa_counts.w + 0.5) - 1;\n    int _901 = int(_860.z);\n    float3 _1167;\n    for (int k = 0; k < _864; k++)\n    {\n        int _914 = _901 + k;\n        int param_3 = _885 + (_914 >> 2);\n        int _932 = (_874 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_914 & 3]) * 7);\n        int param_4 = _932 + 6;\n        float4 _937 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_937.w + 0.5) >> _897) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _932;\n        float4 _952 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _932 + 1;\n        float4 _957 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _932 + 2;\n        float4 _962 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _965 = _952.xyz;\n        float _970 = dot(_965, world_pos) + _952.w;\n        float3 _972 = _957.xyz;\n        float _977 = dot(_972, world_pos) + _957.w;\n        float3 _979 = _962.xyz;\n        float _984 = dot(_979, world_pos) + _962.w;\n        bool _989 = abs(_970) > 0.5;\n        bool _997;\n        if (!_989)\n        {\n            _997 = abs(_977) > 0.5;\n        }\n        else\n        {\n            _997 = _989;\n        }\n        bool _1005;\n        if (!_997)\n        {\n            _1005 = abs(_984) > 0.5;\n        }\n        else\n        {\n            _1005 = _997;\n        }\n        if (_1005)\n        {\n            continue;\n        }\n        float _1020 = fast::clamp(dot(geo_normal, fast::normalize(_979)) * _937.z, 0.0, 1.0);\n        if (_1020 <= 0.0)\n        {\n            continue;\n        }\n        float _1040 = (fast::clamp((0.5 - abs(_984)) * 10.0, 0.0, 1.0) * _1020) * _937.x;\n        float2 _1048 = float2(_970 + 0.5, 0.5 - _977);\n        float2 _1058 = float2(dot(_965, _853), dot(_972, _853));\n        float2 _1068 = float2(dot(_965, _856), dot(_972, _856));\n        int param_8 = _932 + 5;\n        float4 _1073 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _932 + 3;\n        float4 _1078 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _932 + 4;\n        float4 _1083 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1073.xyz;\n        bool _1093 = _1078.z > _1078.x;\n        if (_1093)\n        {\n            float4 param_11 = _1078;\n            float2 param_12 = _1048;\n            float2 param_13 = _881;\n            float2 param_14 = _1058;\n            float2 param_15 = _1068;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_891 > 0.5) && (_891 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1119 = fa_dc_to_linear(param_16);\n                float4 _5276 = tx;\n                _5276.x = _1119.x;\n                _5276.y = _1119.y;\n                _5276.z = _1119.z;\n                tx = _5276;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1040 * tex_a) * _1073.w, 0.0, 1.0)));\n        if (_1083.z > _1083.x)\n        {\n            float4 param_17 = _1083;\n            float2 param_18 = _1048;\n            float2 param_19 = _881;\n            float2 param_20 = _1058;\n            float2 param_21 = _1068;\n            float4 _1163 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_891 > 1.5)\n            {\n                float3 param_22 = _1163.xyz;\n                float3 _1173 = fa_dc_to_srgb(param_22);\n                _1167 = _1173;\n            }\n            else\n            {\n                _1167 = _1163.xyz;\n            }\n            float3 _1183 = (_1167 * 2.0) - float3(1.0);\n            float2 _1188 = _1183.xy * _937.y;\n            float3 _1210 = (fast::normalize(_965) * _1188.x) + (fast::normalize(_972) * _1188.y);\n            float3 _1213 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1213, fast::normalize((_1213 * fast::max(_1183.z, 0.0500000007450580596923828125)) + (_1210 - (_1213 * dot(_1213, _1210)))), float3(fast::clamp(_1040 * (_1093 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _2673 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2680 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2683 = int(_2673);\n    int _2686 = int(_2680);\n    float _2696 = _2680 - float(_2686);\n    int _2751 = (_2683 * 9) + _2686;\n    int _2771 = ((_2683 + 1) * 9) + _2686;\n    return mix(mix(_2747[_2751], _2747[_2751 + 1], _2696), mix(_2747[_2771], _2747[_2771 + 1], _2696), _2673 - float(_2683));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _5143 = false;\n    float _5144 = 1.0;\n    float _5145 = 1.0;\n    float _5146 = 1.0;\n    float _5147 = 0.0;\n    float _5148 = 0.0;\n    float _5149 = 0.0;\n    float _5150 = 0.0;\n    float _5152 = 1.0;\n    bool _5153 = false;\n    float3 _5154 = float3(0.0);\n    float _5155 = 1.0;\n    float _5156 = 1.0;\n    float _5157 = 1.0;\n    float _5158 = 0.0;\n    float _5159 = 0.0;\n    float3 _5160 = float3(1.0, 0.0, 0.0);\n    float3 _5161 = float3(0.0, 0.0, 1.0);\n    float _5162 = 1.0;\n    float _5163 = 1.0;\n    float _2824 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2828 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2833 = (_2824 != 1.0) || (_2828 != 1.5);\n    bool _2843;\n    if (!_2833)\n    {\n        _2843 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2843 = _2833;\n    }\n    if (_2843)\n    {\n        float _2851 = (_2828 - 1.0) / (_2828 + 1.0);\n        f0 = mix(fast::min(float3(_2851 * _2851) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2824, s.albedo, float3(metallic));\n        _5144 = mix(_2824, 1.0, metallic);\n        _5143 = true;\n    }\n    float _2879 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2879 > 0.0)\n    {\n        float _2887 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5147 = _2879;\n        _5148 = _2887;\n        float _2894 = _2887 * _2887;\n        _5149 = _2894;\n        _5150 = _2894 * _2894;\n        float _2906 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5152 = _2906;\n        _5145 = 1.0 - (_2879 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2906, 0.0, 1.0), 5.0))));\n        _5143 = true;\n    }\n    float3 _2925 = fast::max(s.sheen_color, float3(0.0));\n    float _2934 = fast::max(_2925.x, fast::max(_2925.y, _2925.z));\n    if (_2934 > 0.0)\n    {\n        float _2942 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5153 = true;\n        _5154 = _2925;\n        _5155 = _2942;\n        _5156 = _2942 * _2942;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2942;\n        float _2959 = fa_sheen_albedo(param, param_1);\n        _5158 = _2959;\n        _5157 = 1.0 - fast::min(_2934 * _2959, 1.0);\n        _5143 = true;\n    }\n    _5146 = _5145 * _5157;\n    float _2978 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2978 != 0.0)\n    {\n        float3 _2993 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2993;\n        if (dot(_2993, _2993) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _3010 = t;\n        float3 _3011 = fast::normalize(_3010);\n        t = _3011;\n        float3 _3036 = fast::normalize((_3011 * cos(s.anisotropy_rotation)) + ((cross(n, _3011) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5160 = _3036;\n        _5161 = cross(n, _3036);\n        float _3046 = roughness * roughness;\n        float _3052 = mix(_3046, 1.0, _2978 * _2978);\n        bool _3054 = _2978 > 0.0;\n        _5162 = _3054 ? _3052 : _3046;\n        _5163 = _3054 ? _3046 : _3052;\n        _5159 = _2978;\n        _5143 = true;\n    }\n    return FaLayers{ short(_5143), _5144, _5145, _5146, _5147, _5148, _5149, _5150, i.world_normal, _5152, short(_5153), _5154, _5155, _5156, _5157, _5158, _5159, _5160, _5161, _5162, _5163 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_555.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _2430 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _2430;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_555.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _555, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _555.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _555, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555)\n{\n    int param = (int(_555.fa_cl_info.x) + int(_555.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _555);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _429 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _435 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _438 = _435.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _444 = _438 < 0.5;\n    float3 l;\n    if (_444)\n    {\n        l = fast::normalize(_429.xyz);\n    }\n    else\n    {\n        float3 _456 = _429.xyz - world_pos;\n        float _458 = length(_456);\n        dist = _458;\n        l = _456 / float3(fast::max(_458, 9.9999997473787516355514526367188e-05));\n        float _473 = _458 / fast::max(_429.w, 0.001000000047497451305389404296875);\n        float _479 = fast::clamp(1.0 - (_473 * _473), 0.0, 1.0);\n        atten = _479 * _479;\n        if (_438 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _493 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _503 = _493.w;\n            int param_3 = (li * 4) + 3;\n            float4 _509 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _510 = _509.x;\n            float cos_inner = _510;\n            if (_510 > 1.5)\n            {\n                cos_inner = mix(_503, 1.0, 0.25);\n            }\n            atten *= smoothstep(_503, cos_inner, dot(-l, fast::normalize(_493.xyz)));\n        }\n    }\n    int _541;\n    if (_444)\n    {\n        _541 = 0;\n    }\n    else\n    {\n        _541 = (_438 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _435.xyz * atten, atten, 1.0, dist, _541 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1295)\n{\n    float _1285;\n    if (i == 0)\n    {\n        _1285 = _1295.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1301;\n        if (i == 1)\n        {\n            _1301 = _1295.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1309;\n            if (i == 2)\n            {\n                _1309 = _1295.fa_shadow_split.z;\n            }\n            else\n            {\n                _1309 = _1295.fa_shadow_split.w;\n            }\n            _1301 = _1309;\n        }\n        _1285 = _1301;\n    }\n    return _1285;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1342 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1346;\n    if (conv.x < 0.5)\n    {\n        _1346 = _1342;\n    }\n    else\n    {\n        _1346 = (conv.y * conv.z) / (conv.z - (_1342 * (conv.z - conv.y)));\n    }\n    return _1346;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1273 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1273), sin(_1273)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1392 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1406 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1392;\n            float2 _1425 = fa_shadow_vogel(param_3, param_4, param_5) * _1406;\n            float2 param_6 = uv + (_1425 * _1295.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1437 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1437 < (zr - (length(_1425) * plane)))\n            {\n                sum += _1437;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1481 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1481; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1481;\n        float param_11 = _1392;\n        float2 _1500 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1500 * _1295.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1500) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1481);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex)\n{\n    float _1542 = fast::max(_1295.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1547 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1553 = sqrt(1.0 - (_1547 * _1547));\n    float _1560 = fast::min(_1553 / fast::max(_1547, 0.20000000298023223876953125), 4.0);\n    float _1565;\n    if (_1295.fa_shadow_bias.y > 0.0)\n    {\n        _1565 = _1295.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1565 = 1.5 * _1295.fa_shadow_info[ci].x;\n    }\n    float4 _1590 = _1295.fa_shadow_mat[ci] * float4(world + (n * (_1565 * _1553)), 1.0);\n    float _1597 = _1590.x;\n    bool _1600 = _1597 < _1295.fa_shadow_rect[ci].x;\n    bool _1609;\n    if (!_1600)\n    {\n        _1609 = _1597 > _1295.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1609 = _1600;\n    }\n    bool _1618;\n    if (!_1609)\n    {\n        _1618 = _1590.y < _1295.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1618 = _1609;\n    }\n    bool _1627;\n    if (!_1618)\n    {\n        _1627 = _1590.y > _1295.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1627 = _1618;\n    }\n    bool _1634;\n    if (!_1627)\n    {\n        _1634 = _1590.z > 1.0;\n    }\n    else\n    {\n        _1634 = _1627;\n    }\n    if (_1634)\n    {\n        return -1.0;\n    }\n    float _1643;\n    if (_1295.fa_shadow_bias.x > 0.0)\n    {\n        _1643 = _1295.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1643 = 1.5 * _1295.fa_shadow_info[ci].x;\n    }\n    float2 param = _1590.xy;\n    float4 param_1 = _1295.fa_shadow_rect[ci];\n    float param_2 = _1590.z - ((_1643 * (1.0 + (0.5 * _1560))) / _1542);\n    float param_3 = _1295.fa_shadow_info[ci].x;\n    float param_4 = _1542;\n    float param_5 = _1542 * 0.25;\n    float param_6 = ((_1295.fa_shadow_info[ci].x * fast::min(_1560, 3.0)) * 0.5) / _1542;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1295.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1295.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1295, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex)\n{\n    if (_555.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2070 = int(_1295.fa_shadow_cfg.x + 0.5);\n    if (_2070 < 1)\n    {\n        return 1.0;\n    }\n    float _2085 = dot(world - _1295.fa_shadow_eye.xyz, _1295.fa_shadow_fwd.xyz);\n    int param = _2070 - 1;\n    if (_2085 > fa_shadow_split_at(param, _1295))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2097 = _2070 > 1;\n    bool _2104;\n    if (_2097)\n    {\n        _2104 = _2085 > _1295.fa_shadow_split.x;\n    }\n    else\n    {\n        _2104 = _2097;\n    }\n    if (_2104)\n    {\n        ci = 1;\n    }\n    bool _2108 = _2070 > 2;\n    bool _2115;\n    if (_2108)\n    {\n        _2115 = _2085 > _1295.fa_shadow_split.y;\n    }\n    else\n    {\n        _2115 = _2108;\n    }\n    if (_2115)\n    {\n        ci = 2;\n    }\n    bool _2119 = _2070 > 3;\n    bool _2126;\n    if (_2119)\n    {\n        _2126 = _2085 > _1295.fa_shadow_split.z;\n    }\n    else\n    {\n        _2126 = _2119;\n    }\n    if (_2126)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2070)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2152 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1295, fa_shadow_tex);\n        s = _2152;\n        if (_2152 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1295.fa_shadow_cfg.y > 0.0)\n    {\n        float _2177;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2177 = fa_shadow_split_at(param_5, _1295);\n        }\n        else\n        {\n            _2177 = _1295.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2196 = _1295.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1295) - _2177, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2207 = fast::clamp((_2085 - (fa_shadow_split_at(param_7, _1295) - _2196)) / _2196, 0.0, 1.0);\n        if (_2207 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2070)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2228 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1295, fa_shadow_tex);\n                s2 = _2228;\n                if (_2228 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2207);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _555, gl_FragCoord, _1295, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex)\n{\n    bool _1701 = _555.fa_pbr.z < 0.5;\n    bool _1709;\n    if (!_1701)\n    {\n        _1709 = _1295.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1709 = _1701;\n    }\n    if (_1709)\n    {\n        return 1.0;\n    }\n    int param = (int(_1295.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1722 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1723 = _1722.x;\n    if (_1723 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1732 = int(_1723 + 0.5);\n    int param_1 = _1732;\n    float4 _1736 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1732 + 1;\n    float4 _1741 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1744 = _1736.y;\n    if (_1744 > 0.0)\n    {\n        float _1761 = 1.0 - smoothstep(0.75 * _1744, _1744, length(world - _1295.fa_shadow_eye.xyz));\n        fade = _1761;\n        if (_1761 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1736.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1780 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1783 = abs(_1780);\n        float _1785 = _1783.x;\n        float _1787 = _1783.y;\n        bool _1788 = _1785 >= _1787;\n        bool _1796;\n        if (_1788)\n        {\n            _1796 = _1785 >= _1783.z;\n        }\n        else\n        {\n            _1796 = _1788;\n        }\n        int _1797;\n        if (_1796)\n        {\n            _1797 = (_1780.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1810;\n            if (_1787 >= _1783.z)\n            {\n                _1810 = (_1780.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1810 = (_1780.z > 0.0) ? 4 : 5;\n            }\n            _1797 = _1810;\n        }\n        face = _1797;\n    }\n    int _1829 = (_1732 + 2) + (face * 6);\n    int param_4 = _1829;\n    int param_5 = _1829 + 1;\n    int param_6 = _1829 + 3;\n    float4 _1843 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1829 + 4;\n    float4 _1848 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1829 + 5;\n    float4 _1853 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1865 = _1853.x * fast::max(dot(_1843, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1870 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1893 = fast::clamp(dot(n, _1843.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1916 = fast::min(sqrt(1.0 - (_1893 * _1893)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1843, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1919 = _1741.y;\n    float _1921;\n    if (_1919 > 0.0)\n    {\n        _1921 = _1919;\n    }\n    else\n    {\n        _1921 = 1.5 * _1865;\n    }\n    float4 _1941 = float4(world + (n * (_1921 * sqrt(1.0 - (_1870 * _1870)))), 1.0);\n    float _1945 = dot(_1843, _1941);\n    float _1948 = _1853.y;\n    if (_1945 < _1948)\n    {\n        return 1.0;\n    }\n    float2 _1963 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1941), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1941)) / float2(_1945);\n    float _1965 = _1963.x;\n    bool _1968 = _1965 < _1848.x;\n    bool _1977;\n    if (!_1968)\n    {\n        _1977 = _1965 > _1848.z;\n    }\n    else\n    {\n        _1977 = _1968;\n    }\n    bool _1986;\n    if (!_1977)\n    {\n        _1986 = _1963.y < _1848.y;\n    }\n    else\n    {\n        _1986 = _1977;\n    }\n    bool _1995;\n    if (!_1986)\n    {\n        _1995 = _1963.y > _1848.w;\n    }\n    else\n    {\n        _1995 = _1986;\n    }\n    if (_1995)\n    {\n        return 1.0;\n    }\n    float _2001 = _1741.x;\n    float _2003;\n    if (_2001 > 0.0)\n    {\n        _2003 = _2001;\n    }\n    else\n    {\n        _2003 = 1.5 * _1865;\n    }\n    float2 param_10 = _1963;\n    float4 param_11 = _1848;\n    float param_12 = _1945 - (_2003 * (1.0 + (0.5 * _1916)));\n    float param_13 = _1865;\n    float param_14 = 1.0;\n    float param_15 = _1853.z * 0.25;\n    float param_16 = (_1865 * fast::min(_1916, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1948, _1853.z);\n    int param_18 = int(_1736.z + 0.5);\n    float param_19 = _1736.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1295, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_contact_shadow(thread const int& li, thread const float3& world, thread const float3& gn, thread const float3& l, thread const float& dist, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_screen_tex)\n{\n    bool _3553 = _555.fa_ct_a.x < 0.5;\n    bool _3560;\n    if (!_3553)\n    {\n        _3560 = _1295.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _3560 = _3553;\n    }\n    if (_3560)\n    {\n        return 1.0;\n    }\n    int param = (int(_1295.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _3573 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _3574 = _3573.y;\n    float len = _3574;\n    if (_3574 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3586 = length(world - _555.fa_camera_pos.xyz);\n    float _3596 = 1.0 - smoothstep(0.5 * _555.fa_ct_b.x, _555.fa_ct_b.x, _3586);\n    if (_3596 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3602 = len;\n    float _3605 = fast::min(_3602, 0.89999997615814208984375 * dist);\n    len = _3605;\n    float _3610 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3586);\n    float _3615 = _3610 + (0.5 * _3605);\n    float3 _3621 = world + (gn * _3610);\n    float _3623 = fa_shadow_noise(gl_FragCoord);\n    float occ = 0.0;\n    float _3687;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3638 = (float(k) + _3623) * 0.083333335816860198974609375;\n        float3 _3646 = _3621 + (l * (_3638 * len));\n        float4 _3652 = float4(_3646, 1.0);\n        float _3658 = dot(_555.fa_ct_vpw, _3652);\n        if (_3658 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        float2 _3678 = float2(dot(_555.fa_ct_vpx, _3652), dot(_555.fa_ct_vpy, _3652)) / float2(_3658);\n        float _3682 = _3678.x * 0.5;\n        float _3683 = _3682 + 0.5;\n        if (_555.fa_ct_a.y > 0.5)\n        {\n            _3687 = (_3678.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3687 = 0.5 - (_3678.y * 0.5);\n        }\n        bool _3703 = _3683 < 0.0;\n        bool _3710;\n        if (!_3703)\n        {\n            _3710 = _3683 >= 1.0;\n        }\n        else\n        {\n            _3710 = _3703;\n        }\n        bool _3717;\n        if (!_3710)\n        {\n            _3717 = _3687 < 0.0;\n        }\n        else\n        {\n            _3717 = _3710;\n        }\n        bool _3724;\n        if (!_3717)\n        {\n            _3724 = _3687 >= 1.0;\n        }\n        else\n        {\n            _3724 = _3717;\n        }\n        if (_3724)\n        {\n            break;\n        }\n        float4 _3743 = fa_screen_tex.read(uint2(int2(float2(_3683, _3687) * _555.fa_ct_a.zw)), 0);\n        if (_3743.w < 0.5)\n        {\n            continue;\n        }\n        float _3762 = (dot(_555.fa_ct_fwd.xyz, _3646) + _555.fa_ct_fwd.w) - _3743.x;\n        if ((_3762 > _3610) && (_3762 < _3615))\n        {\n            occ = fast::max(occ, (1.0 - (_3638 * _3638)) * smoothstep(0.0, 0.0500000007450580596923828125, fast::min(fast::min(_3683, 0.5 - _3682), fast::min(_3687, 1.0 - _3687))));\n        }\n    }\n    return 1.0 - (occ * _3596);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread float3& fa_lm)\n{\n    bool _3838 = fa_lm.z > 0.5;\n    bool _3844;\n    if (_3838)\n    {\n        int param = li;\n        _3844 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3844 = _3838;\n    }\n    if (_3844)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3866 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _5205 = _3866.direction;\n    float3 _5200 = _3866.color;\n    float _5207 = _3866.attenuation;\n    float _5202 = _3866.shadow;\n    float _5209 = _3866._distance;\n    int _5210 = _3866.type;\n    bool _3869 = _5210 == 0;\n    if (_3869 && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _5205;\n        float _3880 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _555, gl_FragCoord, _1295, fa_shadow_tex, fa_world_pos);\n        _5202 = _3880;\n        _5200 *= _3880;\n    }\n    else\n    {\n        bool _3891 = _5210 != 0;\n        bool _3897;\n        if (_3891)\n        {\n            _3897 = _5207 > 0.0;\n        }\n        else\n        {\n            _3897 = _3891;\n        }\n        if (_3897)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _5205;\n            float _3909 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _555, gl_FragCoord, _1295, fa_shadow_tex);\n            _5202 = _3909;\n            _5200 *= _3909;\n        }\n    }\n    bool _3919 = _555.fa_ct_a.x > 0.5;\n    bool _3925;\n    if (_3919)\n    {\n        _3925 = _5207 > 0.0;\n    }\n    else\n    {\n        _3925 = _3919;\n    }\n    if (_3925)\n    {\n        float _3932;\n        if (_3869)\n        {\n            _3932 = 1000000000.0;\n        }\n        else\n        {\n            _3932 = _5209;\n        }\n        int param_10 = li;\n        float3 param_11 = world_pos;\n        float3 param_12 = gn;\n        float3 param_13 = _5205;\n        float param_14 = _3932;\n        float _3950 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14, fa_light_tex, fa_shadow_smp, _555, gl_FragCoord, _1295, fa_screen_tex);\n        _5202 *= _3950;\n        _5200 *= _3950;\n    }\n    return LightSample{ _5205, _5200, _5207, _5202, _5209, _5210 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _3204 = tdh / at;\n    float _3208 = bdh / ab;\n    float _3220 = ((_3204 * _3204) + (_3208 * _3208)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3220) * _3220);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _3301 = 1.0 / alpha;\n    return ((2.0 + _3301) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3301)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _3333 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3412 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3412) * _3412);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3333);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3333));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3485 = fast::max(dot(L.nc, l), 0.0);\n        float _3491 = fast::max(dot(L.nc, h), 0.0);\n        float _3500 = ((_3491 * _3491) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3500) * _3500)) * (0.5 / fast::max(mix((2.0 * _3485) * L.coat_ndv, _3485 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3485)) * _3485);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _2605 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2608 = _2605.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_2608 * _2608, exp2((-9.27999973297119140625) * ndv)) * _2608) + _2605.y)) + _2605.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_555.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _555.fa_env_horizon.w)).xyz;\n    }\n    float _2459 = rough * rough;\n    float _2489 = 0.60000002384185791015625 * _2459;\n    return mix(mix(_555.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_555.fa_env_horizon.xyz, _555.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _2459)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _2489, 0.0500000007450580596923828125 + _2489, d.y))), ((_555.fa_env_sky.xyz + _555.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_2459 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _3087;\n        if (L.aniso >= 0.0)\n        {\n            _3087 = L.b;\n        }\n        else\n        {\n            _3087 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_3087, v), _3087), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3120 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _555, fa_env_smp, fa_env_tex) * ((f0 * _3120.x) + (float3(L.f90) * _3120.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _555, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3175 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _555, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _3175.x) + _3175.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2647 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _555, fa_env_smp, fa_env_tex) * ((f0 * _2647.x) + float3(_2647.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1295)\n{\n    if (_1295.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2252 = int(_1295.fa_shadow_cfg.x + 0.5);\n    float _2262 = dot(world - _1295.fa_shadow_eye.xyz, _1295.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2267 = _2252 > 0;\n    bool _2276;\n    if (_2267)\n    {\n        int param = _2252 - 1;\n        _2276 = _2262 <= fa_shadow_split_at(param, _1295);\n    }\n    else\n    {\n        _2276 = _2267;\n    }\n    if (_2276)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2283 = _2252 > 1;\n        bool _2290;\n        if (_2283)\n        {\n            _2290 = _2262 > _1295.fa_shadow_split.x;\n        }\n        else\n        {\n            _2290 = _2283;\n        }\n        if (_2290)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2296 = _2252 > 2;\n        bool _2303;\n        if (_2296)\n        {\n            _2303 = _2262 > _1295.fa_shadow_split.y;\n        }\n        else\n        {\n            _2303 = _2296;\n        }\n        if (_2303)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2309 = _2252 > 3;\n        bool _2316;\n        if (_2309)\n        {\n            _2316 = _2262 > _1295.fa_shadow_split.z;\n        }\n        else\n        {\n            _2316 = _2309;\n        }\n        if (_2316)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _555 [[buffer(1)]], constant fa_shadows& _1295 [[buffer(7)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], texture2d<float> fa_screen_tex [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4922 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4922 = -_4922;\n    }\n    float3 _4347 = fast::normalize(_555.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _555, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4922, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4347, short(gl_FrontFacing) };\n    Surface _4355 = fa_standard_surface(param_1, _555, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4953 = _4355.albedo;\n    float _4954 = _4355.alpha;\n    float3 _4955 = _4355.normal;\n    float _4956 = _4355.metallic;\n    float _4957 = _4355.roughness;\n    float _4958 = _4355.occlusion;\n    float3 _4959 = _4355.emission;\n    float _4960 = _4355.clearcoat;\n    float _4961 = _4355.clearcoat_roughness;\n    float3 _4962 = _4355.sheen_color;\n    float _4963 = _4355.sheen_roughness;\n    float _4964 = _4355.anisotropy;\n    float _4965 = _4355.anisotropy_rotation;\n    float _4966 = _4355.specular;\n    float _4967 = _4355.ior;\n    float3 _4968 = _4355.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4922, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4347, short(gl_FrontFacing) };\n    Surface param_3 = _4355;\n    surface(param_2, param_3, points);\n    _4953 = param_3.albedo;\n    _4954 = param_3.alpha;\n    _4955 = param_3.normal;\n    _4956 = param_3.metallic;\n    _4957 = param_3.roughness;\n    _4958 = param_3.occlusion;\n    _4959 = param_3.emission;\n    _4960 = param_3.clearcoat;\n    _4961 = param_3.clearcoat_roughness;\n    _4962 = param_3.sheen_color;\n    _4963 = param_3.sheen_roughness;\n    _4964 = param_3.anisotropy;\n    _4965 = param_3.anisotropy_rotation;\n    _4966 = param_3.specular;\n    _4967 = param_3.ior;\n    _4968 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4922;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _555, fa_decal_tex, fa_env_smp);\n    _4953 = param_6;\n    _4955 = param_7;\n    float3 result;\n    if (_555.fa_emissive.w > 0.5)\n    {\n        result = _4953;\n    }\n    else\n    {\n        float3 _4394 = fast::normalize(_4955);\n        float _4401 = fast::clamp(_4956, 0.0, 1.0);\n        float _4405 = fast::clamp(_4957, 0.0500000007450580596923828125, 1.0);\n        float _4409 = _4405 * _4405;\n        float _4413 = _4409 * _4409;\n        float _4418 = fast::max(dot(_4394, _4347), 9.9999997473787516355514526367188e-05);\n        float3 _4424 = _4953 * (1.0 - _4401);\n        float3 _4431 = mix(float3(0.039999999105930328369140625), _4953, float3(_4401));\n        float3 f0 = _4431;\n        SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _4922, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4347, short(gl_FrontFacing) };\n        Surface param_9 = Surface{ _4953, _4954, _4955, _4956, _4957, _4958, _4959, _4960, _4961, _4962, _4963, _4964, _4965, _4966, _4967, _4968 };\n        float3 param_10 = _4394;\n        float3 param_11 = _4347;\n        float param_12 = _4401;\n        float param_13 = _4405;\n        float3 param_14 = _4431;\n        FaLayers _4447 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _4394;\n        float3 lit = (fa_indirect_diffuse(param_15, _555, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap) * _4424) * _4958;\n        if (_4447.on)\n        {\n            lit *= _4447.base_scale;\n        }\n        int _4469 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4469; ln++)\n        {\n            int param_16 = ln;\n            int _4482 = fa_cl_light(param_16, fa_light_tex, fa_shadow_smp, _555, fa_cl_ndir, fa_cl_slot);\n            bool _4485 = in.fa_lm.z > 0.5;\n            bool _4491;\n            if (_4485)\n            {\n                int param_17 = _4482;\n                _4491 = fa_light_baked(param_17, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _4491 = _4485;\n            }\n            if (_4491)\n            {\n                continue;\n            }\n            int param_18 = _4482;\n            float3 param_19 = in.fa_world_pos;\n            float3 param_20 = _4922;\n            LightSample _4503 = fa_light_shadowed(param_18, param_19, param_20, fa_light_tex, fa_shadow_smp, _555, gl_FragCoord, _1295, fa_shadow_tex, in.fa_world_pos, fa_screen_tex, in.fa_lm);\n            float3 _5127 = _4503.direction;\n            float _4511 = fast::max(dot(_4394, _5127), 0.0);\n            float _4517 = _4503.attenuation * _4503.shadow;\n            float3 _4522 = fast::normalize(_5127 + _4347);\n            float _4527 = fast::max(dot(_4394, _4522), 0.0);\n            float _4532 = fast::max(dot(_4347, _4522), 0.0);\n            if (_4447.on)\n            {\n                FaLayers param_21 = _4447;\n                float3 param_22 = _4424;\n                float3 param_23 = f0;\n                float3 param_24 = _4394;\n                float3 param_25 = _4347;\n                float3 param_26 = _5127;\n                float3 param_27 = _4522;\n                float param_28 = _4511;\n                float param_29 = _4418;\n                float param_30 = _4527;\n                float param_31 = _4532;\n                float param_32 = _4409;\n                float param_33 = _4413;\n                int param_34 = _4482;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34, fa_light_tex, fa_shadow_smp) * _4517));\n            }\n            else\n            {\n                float _4580 = ((_4527 * _4527) * (_4413 - 1.0)) + 1.0;\n                int param_35 = _4482;\n                lit += (((_4424 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _4532, 5.0))) * (((_4413 / ((3.1415927410125732421875 * _4580) * _4580)) * (0.5 / fast::max(mix((2.0 * _4511) * _4418, _4511 + _4418, _4409), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4511))) * fa_light_rgb(param_35, fa_light_tex, fa_shadow_smp)) * (_4511 * _4517));\n            }\n        }\n        if (_4447.on)\n        {\n            FaLayers param_36 = _4447;\n            float3 param_37 = _4394;\n            float3 param_38 = _4347;\n            float3 param_39 = f0;\n            float param_40 = _4405;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40, _555, fa_env_smp, fa_env_tex) * _4958);\n        }\n        else\n        {\n            float3 param_41 = _4394;\n            float3 param_42 = _4347;\n            float3 param_43 = f0;\n            float param_44 = _4405;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44, _555, fa_env_smp, fa_env_tex) * _4958);\n        }\n        result = lit;\n    }\n    float3 _4673 = result;\n    float3 _4674 = _4673 + _4959;\n    result = _4674;\n    float3 param_45 = _4674;\n    float3 param_46 = in.fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46, _1295);\n    bool _4683 = _555.fa_fog.w > 0.0;\n    bool _4690;\n    if (!_4683)\n    {\n        _4690 = _555.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4690 = _4683;\n    }\n    if (_4690)\n    {\n        float3 _4699 = in.fa_world_pos - _555.fa_camera_pos.xyz;\n        float _4705 = dot(_4699, _555.fa_fog_c.xyz);\n        bool _4709 = _555.fa_fog_c.w > 0.5;\n        float _4710;\n        if (_4709)\n        {\n            _4710 = _4705;\n        }\n        else\n        {\n            _4710 = length(_4699);\n        }\n        float _4722 = _4710 - _555.fa_fog_b.x;\n        if (_4722 > 0.0)\n        {\n            float _4731 = _555.fa_fog.w * _4722;\n            float tau = _4731 * _4731;\n            if (_555.fa_fog_b.y > 0.0)\n            {\n                float _4747;\n                if (_4709)\n                {\n                    _4747 = in.fa_world_pos.y - (_555.fa_fog_c.y * _4705);\n                }\n                else\n                {\n                    _4747 = _555.fa_camera_pos.y;\n                }\n                float _4768 = mix(_4747, in.fa_world_pos.y, fast::clamp(_555.fa_fog_b.x / _4710, 0.0, 1.0));\n                float _4772 = in.fa_world_pos.y - _4768;\n                float _4777 = _4768 - _555.fa_fog_b.z;\n                float _4782 = in.fa_world_pos.y - _555.fa_fog_b.z;\n                bool _4785 = _4777 <= 0.0;\n                bool _4786 = !_4785;\n                bool _4792;\n                if (_4786)\n                {\n                    _4792 = _555.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4792 = _4785;\n                }\n                float _4793;\n                if (_4792)\n                {\n                    _4793 = _555.fa_fog_b.y;\n                }\n                else\n                {\n                    _4793 = _555.fa_fog_b.y * exp(-fast::min(_555.fa_fog_b.w * _4777, 80.0));\n                }\n                bool _4820;\n                if (_4786)\n                {\n                    _4820 = _555.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4820 = _4785;\n                }\n                float _4821;\n                if (_4820)\n                {\n                    _4821 = _555.fa_fog_b.y * _4777;\n                }\n                else\n                {\n                    _4821 = (_555.fa_fog_b.y * (1.0 - exp(-fast::min(_555.fa_fog_b.w * _4777, 80.0)))) / _555.fa_fog_b.w;\n                }\n                bool _4846 = _4782 <= 0.0;\n                bool _4853;\n                if (!_4846)\n                {\n                    _4853 = _555.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4853 = _4846;\n                }\n                float _4854;\n                if (_4853)\n                {\n                    _4854 = _555.fa_fog_b.y * _4782;\n                }\n                else\n                {\n                    _4854 = (_555.fa_fog_b.y * (1.0 - exp(-fast::min(_555.fa_fog_b.w * _4782, 80.0)))) / _555.fa_fog_b.w;\n                }\n                float _4881;\n                if (abs(_4772) < 0.001000000047497451305389404296875)\n                {\n                    _4881 = _4793;\n                }\n                else\n                {\n                    _4881 = (_4854 - _4821) / _4772;\n                }\n                tau += (_4722 * fast::max(_4881, 0.0));\n            }\n            result = mix(result, _555.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4954);\n    return out;\n}\n\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_555",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1295",
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
              "msl_texture_n": 7
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
              "msl_texture_n": 8
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
              "msl_texture_n": 9
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _217)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _208 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_217.fa_joint_rows[_208] * weights[i]);\n        r1 += (_217.fa_joint_rows[_208 + 1] * weights[i]);\n        r2 += (_217.fa_joint_rows[_208 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _173)\n{\n    float3 _114 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _114) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_114 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * _173.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex)\n{\n    if (fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, constant fa_mesh_vs_params& _173, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _173);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _173.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _173 [[buffer(0)]], constant fa_skin& _217 [[buffer(3)]], constant fa_inst_base& _350 [[buffer(6)]], const device fa_vs_points_buf& fa_vs_points [[buffer(8)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = _350.fa_base_model * fa_skin_matrix(param, param_1, _217);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, fa_vs_points, gl_InstanceIndex, _173, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nconstant spvUnsafeArray<float, 63> _2747 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555)\n{\n    bool _560 = _555.fa_cl_info.x < 0.0;\n    bool _567;\n    if (!_560)\n    {\n        _567 = _555.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _567 = _560;\n    }\n    bool _575;\n    if (!_567)\n    {\n        _575 = _555.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _575 = _567;\n    }\n    bool _582;\n    if (!_575)\n    {\n        _582 = _555.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _582 = _575;\n    }\n    bool _589;\n    if (!_582)\n    {\n        _589 = _555.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _589 = _582;\n    }\n    if (_589)\n    {\n        return float4(0.0);\n    }\n    float4 _599 = float4(world_pos, 1.0);\n    float _606 = dot(_555.fa_cl_vpw, _599);\n    if (!(_606 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _628 = float2(dot(_555.fa_cl_vpx, _599), dot(_555.fa_cl_vpy, _599)) / float2(_606);\n    int _632 = int(_555.fa_cl_grid.x);\n    int _636 = int(_555.fa_cl_grid.y);\n    int param = (int(_555.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_555.fa_cl_fwd.xyz, world_pos) + _555.fa_cl_fwd.w, _555.fa_cl_grid.w) / _555.fa_cl_grid.w) * _555.fa_cl_grid.z)), 0, int(_555.fa_cl_info.y) - 1) * _636) + clamp(int(floor(((_628.y * 0.5) + 0.5) * _555.fa_cl_grid.y)), 0, _636 - 1)) * _632)) + clamp(int(floor(((_628.x * 0.5) + 0.5) * _555.fa_cl_grid.x)), 0, _632 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555)\n{\n    float3 param = world_pos;\n    float4 _712 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _555);\n    return int2(int(_712.x), int(_712.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_555.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3811 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _555);\n    fa_cl_slot = _3811.x;\n    fa_cl_local = _3811.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _4015 = fa_linear_to_srgb(param);\n        c = _4015;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _4023 = fa_srgb_to_linear(param_1);\n            c = _4023;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _311;\n    if (bool(i.front_facing))\n    {\n        _311 = i.world_normal;\n    }\n    else\n    {\n        _311 = -i.world_normal;\n    }\n    float3 _335 = fast::normalize(i.world_tangent.xyz - (_311 * dot(_311, i.world_tangent.xyz)));\n    float3 _362 = fast::normalize(((_335 * m.x) + ((cross(_311, _335) * i.world_tangent.w) * m.y)) + (_311 * m.z));\n    float3 _365;\n    if (bool(i.front_facing))\n    {\n        _365 = _362;\n    }\n    else\n    {\n        _365 = -_362;\n    }\n    return _365;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _555, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _555.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4054 = fa_tex_fix(param_2, param_3);\n    float4 _5366 = base_t;\n    _5366.x = _4054.x;\n    _5366.y = _4054.y;\n    _5366.z = _4054.z;\n    base_t = _5366;\n    float4 _4068 = (_5366 * _555.fa_base_color) * i.vertex_color;\n    float3 _5220 = i.world_normal;\n    if (_555.fa_maps.z > 0.5)\n    {\n        float param_4 = _555.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4100 = fa_tex_fix(param_6, param_7);\n        float3 _4103 = (_4100 * 2.0) - float3(1.0);\n        float2 _4108 = _4103.xy * _555.fa_maps.x;\n        float3 _5374 = _4103;\n        _5374.x = _4108.x;\n        _5374.y = _4108.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5374;\n        _5220 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _555.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4137 = fa_tex_fix(param_12, param_13);\n    float4 _5377 = mrt;\n    _5377.x = _4137.x;\n    _5377.y = _4137.y;\n    _5377.z = _4137.z;\n    mrt = _5377;\n    float4 _4165 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _555.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _4165.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4177 = fa_tex_fix(param_16, param_17);\n    float param_18 = _555.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4207 = fa_tex_fix(param_20, param_21);\n    float _5225 = _555.fa_layers_a.x;\n    float _5226 = _555.fa_layers_a.y;\n    float _5229 = _555.fa_layers_a.z;\n    float _5228 = _555.fa_layers_b.w;\n    float _5231 = _555.fa_layers_c.x;\n    if (_555.fa_layers_c.z > 0.5)\n    {\n        if (mod(_555.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _5225 *= _4177.y;\n            _5226 *= _4177.z;\n            _5228 *= _4165.w;\n        }\n        if (_555.fa_layers_c.z > 1.5)\n        {\n            _5229 *= mrt.x;\n            _5231 *= mrt.w;\n        }\n    }\n    return Surface{ _4068.xyz, _4068.w, _5220, fast::clamp(_555.fa_pbr.x * _4137.z, 0.0, 1.0), fast::clamp(_555.fa_pbr.y * _4137.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_555.fa_maps.y * (_4177.x - 1.0)), _555.fa_emissive.xyz + (_555.fa_model_emissive.xyz * _4207), _5225, _5226, _555.fa_layers_b.xyz, _5228, _5229, _555.fa_layers_a.w, _5231, _555.fa_layers_c.y, _555.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, const device fa_points_buf& points)\n{\n    s.emission += (i.vertex_color.xyz * ((device float*)&points.data[0].tint)[3u]);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _793 = rect.zw - rect.xy;\n    float2 _797 = _793 * atlas;\n    float2 _801 = ddx * _797;\n    float2 _805 = ddy * _797;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _793)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_801, _801), dot(_805, _805)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _840 = _555.fa_counts.y < 0.5;\n    bool _847;\n    if (!_840)\n    {\n        _847 = _555.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _847 = _840;\n    }\n    if (_847)\n    {\n        return;\n    }\n    float3 _853 = dfdx(world_pos);\n    float3 _856 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _860 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _555);\n    int _864 = int(_860.w);\n    if (_864 < 1)\n    {\n        return;\n    }\n    int _874 = int(_555.fa_counts.y + 0.5);\n    int param_1 = _874;\n    float4 _878 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _881 = _878.yz;\n    int _885 = int(_878.w);\n    int param_2 = _874 + 1;\n    float4 _890 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _891 = _890.x;\n    int _897 = int(_555.fa_counts.w + 0.5) - 1;\n    int _901 = int(_860.z);\n    float3 _1167;\n    for (int k = 0; k < _864; k++)\n    {\n        int _914 = _901 + k;\n        int param_3 = _885 + (_914 >> 2);\n        int _932 = (_874 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_914 & 3]) * 7);\n        int param_4 = _932 + 6;\n        float4 _937 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_937.w + 0.5) >> _897) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _932;\n        float4 _952 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _932 + 1;\n        float4 _957 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _932 + 2;\n        float4 _962 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _965 = _952.xyz;\n        float _970 = dot(_965, world_pos) + _952.w;\n        float3 _972 = _957.xyz;\n        float _977 = dot(_972, world_pos) + _957.w;\n        float3 _979 = _962.xyz;\n        float _984 = dot(_979, world_pos) + _962.w;\n        bool _989 = abs(_970) > 0.5;\n        bool _997;\n        if (!_989)\n        {\n            _997 = abs(_977) > 0.5;\n        }\n        else\n        {\n            _997 = _989;\n        }\n        bool _1005;\n        if (!_997)\n        {\n            _1005 = abs(_984) > 0.5;\n        }\n        else\n        {\n            _1005 = _997;\n        }\n        if (_1005)\n        {\n            continue;\n        }\n        float _1020 = fast::clamp(dot(geo_normal, fast::normalize(_979)) * _937.z, 0.0, 1.0);\n        if (_1020 <= 0.0)\n        {\n            continue;\n        }\n        float _1040 = (fast::clamp((0.5 - abs(_984)) * 10.0, 0.0, 1.0) * _1020) * _937.x;\n        float2 _1048 = float2(_970 + 0.5, 0.5 - _977);\n        float2 _1058 = float2(dot(_965, _853), dot(_972, _853));\n        float2 _1068 = float2(dot(_965, _856), dot(_972, _856));\n        int param_8 = _932 + 5;\n        float4 _1073 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _932 + 3;\n        float4 _1078 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _932 + 4;\n        float4 _1083 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1073.xyz;\n        bool _1093 = _1078.z > _1078.x;\n        if (_1093)\n        {\n            float4 param_11 = _1078;\n            float2 param_12 = _1048;\n            float2 param_13 = _881;\n            float2 param_14 = _1058;\n            float2 param_15 = _1068;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_891 > 0.5) && (_891 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1119 = fa_dc_to_linear(param_16);\n                float4 _5276 = tx;\n                _5276.x = _1119.x;\n                _5276.y = _1119.y;\n                _5276.z = _1119.z;\n                tx = _5276;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1040 * tex_a) * _1073.w, 0.0, 1.0)));\n        if (_1083.z > _1083.x)\n        {\n            float4 param_17 = _1083;\n            float2 param_18 = _1048;\n            float2 param_19 = _881;\n            float2 param_20 = _1058;\n            float2 param_21 = _1068;\n            float4 _1163 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_891 > 1.5)\n            {\n                float3 param_22 = _1163.xyz;\n                float3 _1173 = fa_dc_to_srgb(param_22);\n                _1167 = _1173;\n            }\n            else\n            {\n                _1167 = _1163.xyz;\n            }\n            float3 _1183 = (_1167 * 2.0) - float3(1.0);\n            float2 _1188 = _1183.xy * _937.y;\n            float3 _1210 = (fast::normalize(_965) * _1188.x) + (fast::normalize(_972) * _1188.y);\n            float3 _1213 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1213, fast::normalize((_1213 * fast::max(_1183.z, 0.0500000007450580596923828125)) + (_1210 - (_1213 * dot(_1213, _1210)))), float3(fast::clamp(_1040 * (_1093 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _2673 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2680 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2683 = int(_2673);\n    int _2686 = int(_2680);\n    float _2696 = _2680 - float(_2686);\n    int _2751 = (_2683 * 9) + _2686;\n    int _2771 = ((_2683 + 1) * 9) + _2686;\n    return mix(mix(_2747[_2751], _2747[_2751 + 1], _2696), mix(_2747[_2771], _2747[_2771 + 1], _2696), _2673 - float(_2683));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _5143 = false;\n    float _5144 = 1.0;\n    float _5145 = 1.0;\n    float _5146 = 1.0;\n    float _5147 = 0.0;\n    float _5148 = 0.0;\n    float _5149 = 0.0;\n    float _5150 = 0.0;\n    float _5152 = 1.0;\n    bool _5153 = false;\n    float3 _5154 = float3(0.0);\n    float _5155 = 1.0;\n    float _5156 = 1.0;\n    float _5157 = 1.0;\n    float _5158 = 0.0;\n    float _5159 = 0.0;\n    float3 _5160 = float3(1.0, 0.0, 0.0);\n    float3 _5161 = float3(0.0, 0.0, 1.0);\n    float _5162 = 1.0;\n    float _5163 = 1.0;\n    float _2824 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2828 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2833 = (_2824 != 1.0) || (_2828 != 1.5);\n    bool _2843;\n    if (!_2833)\n    {\n        _2843 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2843 = _2833;\n    }\n    if (_2843)\n    {\n        float _2851 = (_2828 - 1.0) / (_2828 + 1.0);\n        f0 = mix(fast::min(float3(_2851 * _2851) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2824, s.albedo, float3(metallic));\n        _5144 = mix(_2824, 1.0, metallic);\n        _5143 = true;\n    }\n    float _2879 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2879 > 0.0)\n    {\n        float _2887 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5147 = _2879;\n        _5148 = _2887;\n        float _2894 = _2887 * _2887;\n        _5149 = _2894;\n        _5150 = _2894 * _2894;\n        float _2906 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5152 = _2906;\n        _5145 = 1.0 - (_2879 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2906, 0.0, 1.0), 5.0))));\n        _5143 = true;\n    }\n    float3 _2925 = fast::max(s.sheen_color, float3(0.0));\n    float _2934 = fast::max(_2925.x, fast::max(_2925.y, _2925.z));\n    if (_2934 > 0.0)\n    {\n        float _2942 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5153 = true;\n        _5154 = _2925;\n        _5155 = _2942;\n        _5156 = _2942 * _2942;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2942;\n        float _2959 = fa_sheen_albedo(param, param_1);\n        _5158 = _2959;\n        _5157 = 1.0 - fast::min(_2934 * _2959, 1.0);\n        _5143 = true;\n    }\n    _5146 = _5145 * _5157;\n    float _2978 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2978 != 0.0)\n    {\n        float3 _2993 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2993;\n        if (dot(_2993, _2993) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _3010 = t;\n        float3 _3011 = fast::normalize(_3010);\n        t = _3011;\n        float3 _3036 = fast::normalize((_3011 * cos(s.anisotropy_rotation)) + ((cross(n, _3011) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5160 = _3036;\n        _5161 = cross(n, _3036);\n        float _3046 = roughness * roughness;\n        float _3052 = mix(_3046, 1.0, _2978 * _2978);\n        bool _3054 = _2978 > 0.0;\n        _5162 = _3054 ? _3052 : _3046;\n        _5163 = _3054 ? _3046 : _3052;\n        _5159 = _2978;\n        _5143 = true;\n    }\n    return FaLayers{ short(_5143), _5144, _5145, _5146, _5147, _5148, _5149, _5150, i.world_normal, _5152, short(_5153), _5154, _5155, _5156, _5157, _5158, _5159, _5160, _5161, _5162, _5163 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_555.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _2430 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _2430;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_555.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _555, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _555.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _555, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555)\n{\n    int param = (int(_555.fa_cl_info.x) + int(_555.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _555);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _429 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _435 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _438 = _435.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _444 = _438 < 0.5;\n    float3 l;\n    if (_444)\n    {\n        l = fast::normalize(_429.xyz);\n    }\n    else\n    {\n        float3 _456 = _429.xyz - world_pos;\n        float _458 = length(_456);\n        dist = _458;\n        l = _456 / float3(fast::max(_458, 9.9999997473787516355514526367188e-05));\n        float _473 = _458 / fast::max(_429.w, 0.001000000047497451305389404296875);\n        float _479 = fast::clamp(1.0 - (_473 * _473), 0.0, 1.0);\n        atten = _479 * _479;\n        if (_438 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _493 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _503 = _493.w;\n            int param_3 = (li * 4) + 3;\n            float4 _509 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _510 = _509.x;\n            float cos_inner = _510;\n            if (_510 > 1.5)\n            {\n                cos_inner = mix(_503, 1.0, 0.25);\n            }\n            atten *= smoothstep(_503, cos_inner, dot(-l, fast::normalize(_493.xyz)));\n        }\n    }\n    int _541;\n    if (_444)\n    {\n        _541 = 0;\n    }\n    else\n    {\n        _541 = (_438 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _435.xyz * atten, atten, 1.0, dist, _541 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1295)\n{\n    float _1285;\n    if (i == 0)\n    {\n        _1285 = _1295.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1301;\n        if (i == 1)\n        {\n            _1301 = _1295.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1309;\n            if (i == 2)\n            {\n                _1309 = _1295.fa_shadow_split.z;\n            }\n            else\n            {\n                _1309 = _1295.fa_shadow_split.w;\n            }\n            _1301 = _1309;\n        }\n        _1285 = _1301;\n    }\n    return _1285;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1342 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1346;\n    if (conv.x < 0.5)\n    {\n        _1346 = _1342;\n    }\n    else\n    {\n        _1346 = (conv.y * conv.z) / (conv.z - (_1342 * (conv.z - conv.y)));\n    }\n    return _1346;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1273 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1273), sin(_1273)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1392 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1406 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1392;\n            float2 _1425 = fa_shadow_vogel(param_3, param_4, param_5) * _1406;\n            float2 param_6 = uv + (_1425 * _1295.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1437 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1437 < (zr - (length(_1425) * plane)))\n            {\n                sum += _1437;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1481 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1481; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1481;\n        float param_11 = _1392;\n        float2 _1500 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1500 * _1295.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1500) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1481);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex)\n{\n    float _1542 = fast::max(_1295.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1547 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1553 = sqrt(1.0 - (_1547 * _1547));\n    float _1560 = fast::min(_1553 / fast::max(_1547, 0.20000000298023223876953125), 4.0);\n    float _1565;\n    if (_1295.fa_shadow_bias.y > 0.0)\n    {\n        _1565 = _1295.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1565 = 1.5 * _1295.fa_shadow_info[ci].x;\n    }\n    float4 _1590 = _1295.fa_shadow_mat[ci] * float4(world + (n * (_1565 * _1553)), 1.0);\n    float _1597 = _1590.x;\n    bool _1600 = _1597 < _1295.fa_shadow_rect[ci].x;\n    bool _1609;\n    if (!_1600)\n    {\n        _1609 = _1597 > _1295.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1609 = _1600;\n    }\n    bool _1618;\n    if (!_1609)\n    {\n        _1618 = _1590.y < _1295.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1618 = _1609;\n    }\n    bool _1627;\n    if (!_1618)\n    {\n        _1627 = _1590.y > _1295.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1627 = _1618;\n    }\n    bool _1634;\n    if (!_1627)\n    {\n        _1634 = _1590.z > 1.0;\n    }\n    else\n    {\n        _1634 = _1627;\n    }\n    if (_1634)\n    {\n        return -1.0;\n    }\n    float _1643;\n    if (_1295.fa_shadow_bias.x > 0.0)\n    {\n        _1643 = _1295.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1643 = 1.5 * _1295.fa_shadow_info[ci].x;\n    }\n    float2 param = _1590.xy;\n    float4 param_1 = _1295.fa_shadow_rect[ci];\n    float param_2 = _1590.z - ((_1643 * (1.0 + (0.5 * _1560))) / _1542);\n    float param_3 = _1295.fa_shadow_info[ci].x;\n    float param_4 = _1542;\n    float param_5 = _1542 * 0.25;\n    float param_6 = ((_1295.fa_shadow_info[ci].x * fast::min(_1560, 3.0)) * 0.5) / _1542;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1295.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1295.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1295, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex)\n{\n    if (_555.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2070 = int(_1295.fa_shadow_cfg.x + 0.5);\n    if (_2070 < 1)\n    {\n        return 1.0;\n    }\n    float _2085 = dot(world - _1295.fa_shadow_eye.xyz, _1295.fa_shadow_fwd.xyz);\n    int param = _2070 - 1;\n    if (_2085 > fa_shadow_split_at(param, _1295))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2097 = _2070 > 1;\n    bool _2104;\n    if (_2097)\n    {\n        _2104 = _2085 > _1295.fa_shadow_split.x;\n    }\n    else\n    {\n        _2104 = _2097;\n    }\n    if (_2104)\n    {\n        ci = 1;\n    }\n    bool _2108 = _2070 > 2;\n    bool _2115;\n    if (_2108)\n    {\n        _2115 = _2085 > _1295.fa_shadow_split.y;\n    }\n    else\n    {\n        _2115 = _2108;\n    }\n    if (_2115)\n    {\n        ci = 2;\n    }\n    bool _2119 = _2070 > 3;\n    bool _2126;\n    if (_2119)\n    {\n        _2126 = _2085 > _1295.fa_shadow_split.z;\n    }\n    else\n    {\n        _2126 = _2119;\n    }\n    if (_2126)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2070)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2152 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1295, fa_shadow_tex);\n        s = _2152;\n        if (_2152 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1295.fa_shadow_cfg.y > 0.0)\n    {\n        float _2177;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2177 = fa_shadow_split_at(param_5, _1295);\n        }\n        else\n        {\n            _2177 = _1295.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2196 = _1295.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1295) - _2177, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2207 = fast::clamp((_2085 - (fa_shadow_split_at(param_7, _1295) - _2196)) / _2196, 0.0, 1.0);\n        if (_2207 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2070)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2228 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1295, fa_shadow_tex);\n                s2 = _2228;\n                if (_2228 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2207);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _555, gl_FragCoord, _1295, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex)\n{\n    bool _1701 = _555.fa_pbr.z < 0.5;\n    bool _1709;\n    if (!_1701)\n    {\n        _1709 = _1295.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1709 = _1701;\n    }\n    if (_1709)\n    {\n        return 1.0;\n    }\n    int param = (int(_1295.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1722 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1723 = _1722.x;\n    if (_1723 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1732 = int(_1723 + 0.5);\n    int param_1 = _1732;\n    float4 _1736 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1732 + 1;\n    float4 _1741 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1744 = _1736.y;\n    if (_1744 > 0.0)\n    {\n        float _1761 = 1.0 - smoothstep(0.75 * _1744, _1744, length(world - _1295.fa_shadow_eye.xyz));\n        fade = _1761;\n        if (_1761 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1736.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1780 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1783 = abs(_1780);\n        float _1785 = _1783.x;\n        float _1787 = _1783.y;\n        bool _1788 = _1785 >= _1787;\n        bool _1796;\n        if (_1788)\n        {\n            _1796 = _1785 >= _1783.z;\n        }\n        else\n        {\n            _1796 = _1788;\n        }\n        int _1797;\n        if (_1796)\n        {\n            _1797 = (_1780.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1810;\n            if (_1787 >= _1783.z)\n            {\n                _1810 = (_1780.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1810 = (_1780.z > 0.0) ? 4 : 5;\n            }\n            _1797 = _1810;\n        }\n        face = _1797;\n    }\n    int _1829 = (_1732 + 2) + (face * 6);\n    int param_4 = _1829;\n    int param_5 = _1829 + 1;\n    int param_6 = _1829 + 3;\n    float4 _1843 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1829 + 4;\n    float4 _1848 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1829 + 5;\n    float4 _1853 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1865 = _1853.x * fast::max(dot(_1843, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1870 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1893 = fast::clamp(dot(n, _1843.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1916 = fast::min(sqrt(1.0 - (_1893 * _1893)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1843, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1919 = _1741.y;\n    float _1921;\n    if (_1919 > 0.0)\n    {\n        _1921 = _1919;\n    }\n    else\n    {\n        _1921 = 1.5 * _1865;\n    }\n    float4 _1941 = float4(world + (n * (_1921 * sqrt(1.0 - (_1870 * _1870)))), 1.0);\n    float _1945 = dot(_1843, _1941);\n    float _1948 = _1853.y;\n    if (_1945 < _1948)\n    {\n        return 1.0;\n    }\n    float2 _1963 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1941), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1941)) / float2(_1945);\n    float _1965 = _1963.x;\n    bool _1968 = _1965 < _1848.x;\n    bool _1977;\n    if (!_1968)\n    {\n        _1977 = _1965 > _1848.z;\n    }\n    else\n    {\n        _1977 = _1968;\n    }\n    bool _1986;\n    if (!_1977)\n    {\n        _1986 = _1963.y < _1848.y;\n    }\n    else\n    {\n        _1986 = _1977;\n    }\n    bool _1995;\n    if (!_1986)\n    {\n        _1995 = _1963.y > _1848.w;\n    }\n    else\n    {\n        _1995 = _1986;\n    }\n    if (_1995)\n    {\n        return 1.0;\n    }\n    float _2001 = _1741.x;\n    float _2003;\n    if (_2001 > 0.0)\n    {\n        _2003 = _2001;\n    }\n    else\n    {\n        _2003 = 1.5 * _1865;\n    }\n    float2 param_10 = _1963;\n    float4 param_11 = _1848;\n    float param_12 = _1945 - (_2003 * (1.0 + (0.5 * _1916)));\n    float param_13 = _1865;\n    float param_14 = 1.0;\n    float param_15 = _1853.z * 0.25;\n    float param_16 = (_1865 * fast::min(_1916, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1948, _1853.z);\n    int param_18 = int(_1736.z + 0.5);\n    float param_19 = _1736.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1295, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_contact_shadow(thread const int& li, thread const float3& world, thread const float3& gn, thread const float3& l, thread const float& dist, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_screen_tex)\n{\n    bool _3553 = _555.fa_ct_a.x < 0.5;\n    bool _3560;\n    if (!_3553)\n    {\n        _3560 = _1295.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _3560 = _3553;\n    }\n    if (_3560)\n    {\n        return 1.0;\n    }\n    int param = (int(_1295.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _3573 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _3574 = _3573.y;\n    float len = _3574;\n    if (_3574 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3586 = length(world - _555.fa_camera_pos.xyz);\n    float _3596 = 1.0 - smoothstep(0.5 * _555.fa_ct_b.x, _555.fa_ct_b.x, _3586);\n    if (_3596 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3602 = len;\n    float _3605 = fast::min(_3602, 0.89999997615814208984375 * dist);\n    len = _3605;\n    float _3610 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3586);\n    float _3615 = _3610 + (0.5 * _3605);\n    float3 _3621 = world + (gn * _3610);\n    float _3623 = fa_shadow_noise(gl_FragCoord);\n    float occ = 0.0;\n    float _3687;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3638 = (float(k) + _3623) * 0.083333335816860198974609375;\n        float3 _3646 = _3621 + (l * (_3638 * len));\n        float4 _3652 = float4(_3646, 1.0);\n        float _3658 = dot(_555.fa_ct_vpw, _3652);\n        if (_3658 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        float2 _3678 = float2(dot(_555.fa_ct_vpx, _3652), dot(_555.fa_ct_vpy, _3652)) / float2(_3658);\n        float _3682 = _3678.x * 0.5;\n        float _3683 = _3682 + 0.5;\n        if (_555.fa_ct_a.y > 0.5)\n        {\n            _3687 = (_3678.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3687 = 0.5 - (_3678.y * 0.5);\n        }\n        bool _3703 = _3683 < 0.0;\n        bool _3710;\n        if (!_3703)\n        {\n            _3710 = _3683 >= 1.0;\n        }\n        else\n        {\n            _3710 = _3703;\n        }\n        bool _3717;\n        if (!_3710)\n        {\n            _3717 = _3687 < 0.0;\n        }\n        else\n        {\n            _3717 = _3710;\n        }\n        bool _3724;\n        if (!_3717)\n        {\n            _3724 = _3687 >= 1.0;\n        }\n        else\n        {\n            _3724 = _3717;\n        }\n        if (_3724)\n        {\n            break;\n        }\n        float4 _3743 = fa_screen_tex.read(uint2(int2(float2(_3683, _3687) * _555.fa_ct_a.zw)), 0);\n        if (_3743.w < 0.5)\n        {\n            continue;\n        }\n        float _3762 = (dot(_555.fa_ct_fwd.xyz, _3646) + _555.fa_ct_fwd.w) - _3743.x;\n        if ((_3762 > _3610) && (_3762 < _3615))\n        {\n            occ = fast::max(occ, (1.0 - (_3638 * _3638)) * smoothstep(0.0, 0.0500000007450580596923828125, fast::min(fast::min(_3683, 0.5 - _3682), fast::min(_3687, 1.0 - _3687))));\n        }\n    }\n    return 1.0 - (occ * _3596);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread float3& fa_lm)\n{\n    bool _3838 = fa_lm.z > 0.5;\n    bool _3844;\n    if (_3838)\n    {\n        int param = li;\n        _3844 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3844 = _3838;\n    }\n    if (_3844)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3866 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _5205 = _3866.direction;\n    float3 _5200 = _3866.color;\n    float _5207 = _3866.attenuation;\n    float _5202 = _3866.shadow;\n    float _5209 = _3866._distance;\n    int _5210 = _3866.type;\n    bool _3869 = _5210 == 0;\n    if (_3869 && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _5205;\n        float _3880 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _555, gl_FragCoord, _1295, fa_shadow_tex, fa_world_pos);\n        _5202 = _3880;\n        _5200 *= _3880;\n    }\n    else\n    {\n        bool _3891 = _5210 != 0;\n        bool _3897;\n        if (_3891)\n        {\n            _3897 = _5207 > 0.0;\n        }\n        else\n        {\n            _3897 = _3891;\n        }\n        if (_3897)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _5205;\n            float _3909 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _555, gl_FragCoord, _1295, fa_shadow_tex);\n            _5202 = _3909;\n            _5200 *= _3909;\n        }\n    }\n    bool _3919 = _555.fa_ct_a.x > 0.5;\n    bool _3925;\n    if (_3919)\n    {\n        _3925 = _5207 > 0.0;\n    }\n    else\n    {\n        _3925 = _3919;\n    }\n    if (_3925)\n    {\n        float _3932;\n        if (_3869)\n        {\n            _3932 = 1000000000.0;\n        }\n        else\n        {\n            _3932 = _5209;\n        }\n        int param_10 = li;\n        float3 param_11 = world_pos;\n        float3 param_12 = gn;\n        float3 param_13 = _5205;\n        float param_14 = _3932;\n        float _3950 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14, fa_light_tex, fa_shadow_smp, _555, gl_FragCoord, _1295, fa_screen_tex);\n        _5202 *= _3950;\n        _5200 *= _3950;\n    }\n    return LightSample{ _5205, _5200, _5207, _5202, _5209, _5210 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _3204 = tdh / at;\n    float _3208 = bdh / ab;\n    float _3220 = ((_3204 * _3204) + (_3208 * _3208)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3220) * _3220);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _3301 = 1.0 / alpha;\n    return ((2.0 + _3301) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3301)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _3333 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3412 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3412) * _3412);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3333);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3333));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3485 = fast::max(dot(L.nc, l), 0.0);\n        float _3491 = fast::max(dot(L.nc, h), 0.0);\n        float _3500 = ((_3491 * _3491) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3500) * _3500)) * (0.5 / fast::max(mix((2.0 * _3485) * L.coat_ndv, _3485 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3485)) * _3485);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _2605 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2608 = _2605.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_2608 * _2608, exp2((-9.27999973297119140625) * ndv)) * _2608) + _2605.y)) + _2605.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_555.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _555.fa_env_horizon.w)).xyz;\n    }\n    float _2459 = rough * rough;\n    float _2489 = 0.60000002384185791015625 * _2459;\n    return mix(mix(_555.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_555.fa_env_horizon.xyz, _555.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _2459)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _2489, 0.0500000007450580596923828125 + _2489, d.y))), ((_555.fa_env_sky.xyz + _555.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_2459 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _3087;\n        if (L.aniso >= 0.0)\n        {\n            _3087 = L.b;\n        }\n        else\n        {\n            _3087 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_3087, v), _3087), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3120 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _555, fa_env_smp, fa_env_tex) * ((f0 * _3120.x) + (float3(L.f90) * _3120.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _555, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3175 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _555, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _3175.x) + _3175.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2647 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _555, fa_env_smp, fa_env_tex) * ((f0 * _2647.x) + float3(_2647.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1295)\n{\n    if (_1295.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2252 = int(_1295.fa_shadow_cfg.x + 0.5);\n    float _2262 = dot(world - _1295.fa_shadow_eye.xyz, _1295.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2267 = _2252 > 0;\n    bool _2276;\n    if (_2267)\n    {\n        int param = _2252 - 1;\n        _2276 = _2262 <= fa_shadow_split_at(param, _1295);\n    }\n    else\n    {\n        _2276 = _2267;\n    }\n    if (_2276)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2283 = _2252 > 1;\n        bool _2290;\n        if (_2283)\n        {\n            _2290 = _2262 > _1295.fa_shadow_split.x;\n        }\n        else\n        {\n            _2290 = _2283;\n        }\n        if (_2290)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2296 = _2252 > 2;\n        bool _2303;\n        if (_2296)\n        {\n            _2303 = _2262 > _1295.fa_shadow_split.y;\n        }\n        else\n        {\n            _2303 = _2296;\n        }\n        if (_2303)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2309 = _2252 > 3;\n        bool _2316;\n        if (_2309)\n        {\n            _2316 = _2262 > _1295.fa_shadow_split.z;\n        }\n        else\n        {\n            _2316 = _2309;\n        }\n        if (_2316)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _555 [[buffer(1)]], constant fa_shadows& _1295 [[buffer(7)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], texture2d<float> fa_screen_tex [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4922 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4922 = -_4922;\n    }\n    float3 _4347 = fast::normalize(_555.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _555, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4922, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4347, short(gl_FrontFacing) };\n    Surface _4355 = fa_standard_surface(param_1, _555, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4953 = _4355.albedo;\n    float _4954 = _4355.alpha;\n    float3 _4955 = _4355.normal;\n    float _4956 = _4355.metallic;\n    float _4957 = _4355.roughness;\n    float _4958 = _4355.occlusion;\n    float3 _4959 = _4355.emission;\n    float _4960 = _4355.clearcoat;\n    float _4961 = _4355.clearcoat_roughness;\n    float3 _4962 = _4355.sheen_color;\n    float _4963 = _4355.sheen_roughness;\n    float _4964 = _4355.anisotropy;\n    float _4965 = _4355.anisotropy_rotation;\n    float _4966 = _4355.specular;\n    float _4967 = _4355.ior;\n    float3 _4968 = _4355.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4922, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4347, short(gl_FrontFacing) };\n    Surface param_3 = _4355;\n    surface(param_2, param_3, points);\n    _4953 = param_3.albedo;\n    _4954 = param_3.alpha;\n    _4955 = param_3.normal;\n    _4956 = param_3.metallic;\n    _4957 = param_3.roughness;\n    _4958 = param_3.occlusion;\n    _4959 = param_3.emission;\n    _4960 = param_3.clearcoat;\n    _4961 = param_3.clearcoat_roughness;\n    _4962 = param_3.sheen_color;\n    _4963 = param_3.sheen_roughness;\n    _4964 = param_3.anisotropy;\n    _4965 = param_3.anisotropy_rotation;\n    _4966 = param_3.specular;\n    _4967 = param_3.ior;\n    _4968 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4922;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _555, fa_decal_tex, fa_env_smp);\n    _4953 = param_6;\n    _4955 = param_7;\n    float3 result;\n    if (_555.fa_emissive.w > 0.5)\n    {\n        result = _4953;\n    }\n    else\n    {\n        float3 _4394 = fast::normalize(_4955);\n        float _4401 = fast::clamp(_4956, 0.0, 1.0);\n        float _4405 = fast::clamp(_4957, 0.0500000007450580596923828125, 1.0);\n        float _4409 = _4405 * _4405;\n        float _4413 = _4409 * _4409;\n        float _4418 = fast::max(dot(_4394, _4347), 9.9999997473787516355514526367188e-05);\n        float3 _4424 = _4953 * (1.0 - _4401);\n        float3 _4431 = mix(float3(0.039999999105930328369140625), _4953, float3(_4401));\n        float3 f0 = _4431;\n        SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _4922, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4347, short(gl_FrontFacing) };\n        Surface param_9 = Surface{ _4953, _4954, _4955, _4956, _4957, _4958, _4959, _4960, _4961, _4962, _4963, _4964, _4965, _4966, _4967, _4968 };\n        float3 param_10 = _4394;\n        float3 param_11 = _4347;\n        float param_12 = _4401;\n        float param_13 = _4405;\n        float3 param_14 = _4431;\n        FaLayers _4447 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _4394;\n        float3 lit = (fa_indirect_diffuse(param_15, _555, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap) * _4424) * _4958;\n        if (_4447.on)\n        {\n            lit *= _4447.base_scale;\n        }\n        int _4469 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4469; ln++)\n        {\n            int param_16 = ln;\n            int _4482 = fa_cl_light(param_16, fa_light_tex, fa_shadow_smp, _555, fa_cl_ndir, fa_cl_slot);\n            bool _4485 = in.fa_lm.z > 0.5;\n            bool _4491;\n            if (_4485)\n            {\n                int param_17 = _4482;\n                _4491 = fa_light_baked(param_17, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _4491 = _4485;\n            }\n            if (_4491)\n            {\n                continue;\n            }\n            int param_18 = _4482;\n            float3 param_19 = in.fa_world_pos;\n            float3 param_20 = _4922;\n            LightSample _4503 = fa_light_shadowed(param_18, param_19, param_20, fa_light_tex, fa_shadow_smp, _555, gl_FragCoord, _1295, fa_shadow_tex, in.fa_world_pos, fa_screen_tex, in.fa_lm);\n            float3 _5127 = _4503.direction;\n            float _4511 = fast::max(dot(_4394, _5127), 0.0);\n            float _4517 = _4503.attenuation * _4503.shadow;\n            float3 _4522 = fast::normalize(_5127 + _4347);\n            float _4527 = fast::max(dot(_4394, _4522), 0.0);\n            float _4532 = fast::max(dot(_4347, _4522), 0.0);\n            if (_4447.on)\n            {\n                FaLayers param_21 = _4447;\n                float3 param_22 = _4424;\n                float3 param_23 = f0;\n                float3 param_24 = _4394;\n                float3 param_25 = _4347;\n                float3 param_26 = _5127;\n                float3 param_27 = _4522;\n                float param_28 = _4511;\n                float param_29 = _4418;\n                float param_30 = _4527;\n                float param_31 = _4532;\n                float param_32 = _4409;\n                float param_33 = _4413;\n                int param_34 = _4482;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34, fa_light_tex, fa_shadow_smp) * _4517));\n            }\n            else\n            {\n                float _4580 = ((_4527 * _4527) * (_4413 - 1.0)) + 1.0;\n                int param_35 = _4482;\n                lit += (((_4424 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _4532, 5.0))) * (((_4413 / ((3.1415927410125732421875 * _4580) * _4580)) * (0.5 / fast::max(mix((2.0 * _4511) * _4418, _4511 + _4418, _4409), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4511))) * fa_light_rgb(param_35, fa_light_tex, fa_shadow_smp)) * (_4511 * _4517));\n            }\n        }\n        if (_4447.on)\n        {\n            FaLayers param_36 = _4447;\n            float3 param_37 = _4394;\n            float3 param_38 = _4347;\n            float3 param_39 = f0;\n            float param_40 = _4405;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40, _555, fa_env_smp, fa_env_tex) * _4958);\n        }\n        else\n        {\n            float3 param_41 = _4394;\n            float3 param_42 = _4347;\n            float3 param_43 = f0;\n            float param_44 = _4405;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44, _555, fa_env_smp, fa_env_tex) * _4958);\n        }\n        result = lit;\n    }\n    float3 _4673 = result;\n    float3 _4674 = _4673 + _4959;\n    result = _4674;\n    float3 param_45 = _4674;\n    float3 param_46 = in.fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46, _1295);\n    bool _4683 = _555.fa_fog.w > 0.0;\n    bool _4690;\n    if (!_4683)\n    {\n        _4690 = _555.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4690 = _4683;\n    }\n    if (_4690)\n    {\n        float3 _4699 = in.fa_world_pos - _555.fa_camera_pos.xyz;\n        float _4705 = dot(_4699, _555.fa_fog_c.xyz);\n        bool _4709 = _555.fa_fog_c.w > 0.5;\n        float _4710;\n        if (_4709)\n        {\n            _4710 = _4705;\n        }\n        else\n        {\n            _4710 = length(_4699);\n        }\n        float _4722 = _4710 - _555.fa_fog_b.x;\n        if (_4722 > 0.0)\n        {\n            float _4731 = _555.fa_fog.w * _4722;\n            float tau = _4731 * _4731;\n            if (_555.fa_fog_b.y > 0.0)\n            {\n                float _4747;\n                if (_4709)\n                {\n                    _4747 = in.fa_world_pos.y - (_555.fa_fog_c.y * _4705);\n                }\n                else\n                {\n                    _4747 = _555.fa_camera_pos.y;\n                }\n                float _4768 = mix(_4747, in.fa_world_pos.y, fast::clamp(_555.fa_fog_b.x / _4710, 0.0, 1.0));\n                float _4772 = in.fa_world_pos.y - _4768;\n                float _4777 = _4768 - _555.fa_fog_b.z;\n                float _4782 = in.fa_world_pos.y - _555.fa_fog_b.z;\n                bool _4785 = _4777 <= 0.0;\n                bool _4786 = !_4785;\n                bool _4792;\n                if (_4786)\n                {\n                    _4792 = _555.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4792 = _4785;\n                }\n                float _4793;\n                if (_4792)\n                {\n                    _4793 = _555.fa_fog_b.y;\n                }\n                else\n                {\n                    _4793 = _555.fa_fog_b.y * exp(-fast::min(_555.fa_fog_b.w * _4777, 80.0));\n                }\n                bool _4820;\n                if (_4786)\n                {\n                    _4820 = _555.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4820 = _4785;\n                }\n                float _4821;\n                if (_4820)\n                {\n                    _4821 = _555.fa_fog_b.y * _4777;\n                }\n                else\n                {\n                    _4821 = (_555.fa_fog_b.y * (1.0 - exp(-fast::min(_555.fa_fog_b.w * _4777, 80.0)))) / _555.fa_fog_b.w;\n                }\n                bool _4846 = _4782 <= 0.0;\n                bool _4853;\n                if (!_4846)\n                {\n                    _4853 = _555.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4853 = _4846;\n                }\n                float _4854;\n                if (_4853)\n                {\n                    _4854 = _555.fa_fog_b.y * _4782;\n                }\n                else\n                {\n                    _4854 = (_555.fa_fog_b.y * (1.0 - exp(-fast::min(_555.fa_fog_b.w * _4782, 80.0)))) / _555.fa_fog_b.w;\n                }\n                float _4881;\n                if (abs(_4772) < 0.001000000047497451305389404296875)\n                {\n                    _4881 = _4793;\n                }\n                else\n                {\n                    _4881 = (_4854 - _4821) / _4772;\n                }\n                tau += (_4722 * fast::max(_4881, 0.0));\n            }\n            result = mix(result, _555.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4954);\n    return out;\n}\n\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_555",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1295",
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
              "msl_texture_n": 7
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
              "msl_texture_n": 8
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
              "msl_texture_n": 9
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          }
        ]
      }
    },
    "prepass": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _168)\n{\n    float3 _109 = cross(model[1].xyz, model[2].xyz);\n    float _114 = (dot(model[0].xyz, _109) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_109 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _114, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _114), texcoord0 * _168.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex)\n{\n    if (fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, constant fa_mesh_vs_params& _168, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _168);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex);\n    float4 _210 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_168.fa_light_vp * _210).z;\n    fa_pre_r0 = float3(_168.fa_light_vp[0].x, _168.fa_light_vp[1].x, _168.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_168.fa_light_vp[0].y, _168.fa_light_vp[1].y, _168.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_168.fa_light_vp[0].z, _168.fa_light_vp[1].z, _168.fa_light_vp[2].z);\n    gl_Position = _168.fa_view_proj * _210;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _168 [[buffer(0)]], constant fa_inst_base& _272 [[buffer(6)]], const device fa_vs_points_buf& fa_vs_points [[buffer(8)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = _272.fa_base_model;\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, fa_vs_points, gl_InstanceIndex, _168, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _231, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _231.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _749 = base_t;\n    _749.x = _242.x;\n    _749.y = _242.y;\n    _749.z = _242.z;\n    base_t = _749;\n    float4 _257 = (_749 * _231.fa_base_color) * i.vertex_color;\n    float3 _712 = i.world_normal;\n    if (_231.fa_maps.z > 0.5)\n    {\n        float param_4 = _231.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _290 = fa_tex_fix(param_6, param_7);\n        float3 _294 = (_290 * 2.0) - float3(1.0);\n        float2 _299 = _294.xy * _231.fa_maps.x;\n        float3 _757 = _294;\n        _757.x = _299.x;\n        _757.y = _299.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _757;\n        _712 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _231.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _328 = fa_tex_fix(param_12, param_13);\n    float4 _760 = mrt;\n    _760.x = _328.x;\n    _760.y = _328.y;\n    _760.z = _328.z;\n    mrt = _760;\n    float4 _358 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _231.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = _231.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _400 = fa_tex_fix(param_20, param_21);\n    float _717 = _231.fa_layers_a.x;\n    float _718 = _231.fa_layers_a.y;\n    float _721 = _231.fa_layers_a.z;\n    float _720 = _231.fa_layers_b.w;\n    float _723 = _231.fa_layers_c.x;\n    if (_231.fa_layers_c.z > 0.5)\n    {\n        if (mod(_231.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _717 *= _370.y;\n            _718 *= _370.z;\n            _720 *= _358.w;\n        }\n        if (_231.fa_layers_c.z > 1.5)\n        {\n            _721 *= mrt.x;\n            _723 *= mrt.w;\n        }\n    }\n    return Surface{ _257.xyz, _257.w, _712, fast::clamp(_231.fa_pbr.x * _328.z, 0.0, 1.0), fast::clamp(_231.fa_pbr.y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_231.fa_maps.y * (_370.x - 1.0)), _231.fa_emissive.xyz + (_231.fa_model_emissive.xyz * _400), _717, _718, _231.fa_layers_b.xyz, _720, _721, _231.fa_layers_a.w, _723, _231.fa_layers_c.y, _231.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, const device fa_points_buf& points)\n{\n    s.emission += (i.vertex_color.xyz * ((device float*)&points.data[0].tint)[3u]);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _231 [[buffer(1)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _623 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _623 = -_623;\n    }\n    float3 _534 = fast::normalize(_231.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _623, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _534, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _623, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _534, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _231, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, points);\n    float3 _549 = fast::normalize(param_2.normal);\n    float3 _564 = fast::normalize(float3(dot(in.fa_pre_r0, _549), dot(in.fa_pre_r1, _549), dot(in.fa_pre_r2, _549)));\n    float _576 = _564.z;\n    float2 e = _564.xy / float2((abs(_564.x) + abs(_564.y)) + abs(_576));\n    if (_576 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 480,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _217)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _208 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_217.fa_joint_rows[_208] * weights[i]);\n        r1 += (_217.fa_joint_rows[_208 + 1] * weights[i]);\n        r2 += (_217.fa_joint_rows[_208 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _173)\n{\n    float3 _114 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _114) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_114 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * _173.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex)\n{\n    if (fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, constant fa_mesh_vs_params& _173, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _173);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex);\n    float4 _322 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_173.fa_light_vp * _322).z;\n    fa_pre_r0 = float3(_173.fa_light_vp[0].x, _173.fa_light_vp[1].x, _173.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_173.fa_light_vp[0].y, _173.fa_light_vp[1].y, _173.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_173.fa_light_vp[0].z, _173.fa_light_vp[1].z, _173.fa_light_vp[2].z);\n    gl_Position = _173.fa_view_proj * _322;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _173 [[buffer(0)]], constant fa_skin& _217 [[buffer(3)]], constant fa_inst_base& _384 [[buffer(6)]], const device fa_vs_points_buf& fa_vs_points [[buffer(8)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = _384.fa_base_model * fa_skin_matrix(param, param_1, _217);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, fa_vs_points, gl_InstanceIndex, _173, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _231, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _231.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _749 = base_t;\n    _749.x = _242.x;\n    _749.y = _242.y;\n    _749.z = _242.z;\n    base_t = _749;\n    float4 _257 = (_749 * _231.fa_base_color) * i.vertex_color;\n    float3 _712 = i.world_normal;\n    if (_231.fa_maps.z > 0.5)\n    {\n        float param_4 = _231.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _290 = fa_tex_fix(param_6, param_7);\n        float3 _294 = (_290 * 2.0) - float3(1.0);\n        float2 _299 = _294.xy * _231.fa_maps.x;\n        float3 _757 = _294;\n        _757.x = _299.x;\n        _757.y = _299.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _757;\n        _712 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _231.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _328 = fa_tex_fix(param_12, param_13);\n    float4 _760 = mrt;\n    _760.x = _328.x;\n    _760.y = _328.y;\n    _760.z = _328.z;\n    mrt = _760;\n    float4 _358 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _231.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = _231.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _400 = fa_tex_fix(param_20, param_21);\n    float _717 = _231.fa_layers_a.x;\n    float _718 = _231.fa_layers_a.y;\n    float _721 = _231.fa_layers_a.z;\n    float _720 = _231.fa_layers_b.w;\n    float _723 = _231.fa_layers_c.x;\n    if (_231.fa_layers_c.z > 0.5)\n    {\n        if (mod(_231.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _717 *= _370.y;\n            _718 *= _370.z;\n            _720 *= _358.w;\n        }\n        if (_231.fa_layers_c.z > 1.5)\n        {\n            _721 *= mrt.x;\n            _723 *= mrt.w;\n        }\n    }\n    return Surface{ _257.xyz, _257.w, _712, fast::clamp(_231.fa_pbr.x * _328.z, 0.0, 1.0), fast::clamp(_231.fa_pbr.y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_231.fa_maps.y * (_370.x - 1.0)), _231.fa_emissive.xyz + (_231.fa_model_emissive.xyz * _400), _717, _718, _231.fa_layers_b.xyz, _720, _721, _231.fa_layers_a.w, _723, _231.fa_layers_c.y, _231.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, const device fa_points_buf& points)\n{\n    s.emission += (i.vertex_color.xyz * ((device float*)&points.data[0].tint)[3u]);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _231 [[buffer(1)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _623 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _623 = -_623;\n    }\n    float3 _534 = fast::normalize(_231.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _623, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _534, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _623, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _534, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _231, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, points);\n    float3 _549 = fast::normalize(param_2.normal);\n    float3 _564 = fast::normalize(float3(dot(in.fa_pre_r0, _549), dot(in.fa_pre_r1, _549), dot(in.fa_pre_r2, _549)));\n    float _576 = _564.z;\n    float2 e = _564.xy / float2((abs(_564.x) + abs(_564.y)) + abs(_576));\n    if (_576 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 480,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(5)]];\n    float2 fa_texcoord0 [[attribute(6)]];\n    float4 fa_tangent [[attribute(7)]];\n    float4 fa_color [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _159)\n{\n    float3 _100 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _100) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_100 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _159.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex)\n{\n    if (fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _159 [[buffer(0)]], constant fa_inst_base& _176 [[buffer(6)]], const device fa_vs_points_buf& fa_vs_points [[buffer(8)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = _176.fa_base_model;\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _159);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex);\n    out.gl_Position = _159.fa_light_vp * float4(param_6.world_pos, 1.0);\n    return out;\n}\n\n",
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
            "size": 176,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_joints [[attribute(5)]];\n    float4 fa_weights [[attribute(6)]];\n    float3 fa_normal [[attribute(7)]];\n    float2 fa_texcoord0 [[attribute(8)]];\n    float4 fa_tangent [[attribute(9)]];\n    float4 fa_color [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _208)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _199 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_208.fa_joint_rows[_199] * weights[i]);\n        r1 += (_208.fa_joint_rows[_199 + 1] * weights[i]);\n        r2 += (_208.fa_joint_rows[_199 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _164)\n{\n    float3 _105 = cross(model[1].xyz, model[2].xyz);\n    float _110 = (dot(model[0].xyz, _105) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_105 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _110, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _110), texcoord0 * _164.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex)\n{\n    if (fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _164 [[buffer(0)]], constant fa_skin& _208 [[buffer(3)]], constant fa_inst_base& _288 [[buffer(6)]], const device fa_vs_points_buf& fa_vs_points [[buffer(8)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = _288.fa_base_model * fa_skin_matrix(param, param_1, _208);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7, _164);\n    vertex0(param_8, fa_vs_points, gl_InstanceIndex);\n    out.gl_Position = _164.fa_light_vp * float4(param_8.world_pos, 1.0);\n    return out;\n}\n\n",
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
            "size": 176,
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
