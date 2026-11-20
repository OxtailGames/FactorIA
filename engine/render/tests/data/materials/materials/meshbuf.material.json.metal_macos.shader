{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "fc5698cd941e0af057040ef4c307a7106b1e2971cc74f7501935817daedb7ce8",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nconstant spvUnsafeArray<float, 63> _3496 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1473 = _485.fa_cl_info.x < 0.0;\n    bool _1480;\n    if (!_1473)\n    {\n        _1480 = _485.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1480 = _1473;\n    }\n    bool _1488;\n    if (!_1480)\n    {\n        _1488 = _485.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1488 = _1480;\n    }\n    bool _1495;\n    if (!_1488)\n    {\n        _1495 = _485.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1495 = _1488;\n    }\n    bool _1502;\n    if (!_1495)\n    {\n        _1502 = _485.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1502 = _1495;\n    }\n    if (_1502)\n    {\n        return float4(0.0);\n    }\n    float4 _1512 = float4(world_pos, 1.0);\n    float _1518 = dot(_485.fa_cl_vpw, _1512);\n    if (!(_1518 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1540 = float2(dot(_485.fa_cl_vpx, _1512), dot(_485.fa_cl_vpy, _1512)) / float2(_1518);\n    int _1544 = int(_485.fa_cl_grid.x);\n    int _1548 = int(_485.fa_cl_grid.y);\n    int param = (int(_485.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_485.fa_cl_fwd.xyz, world_pos) + _485.fa_cl_fwd.w, _485.fa_cl_grid.w) / _485.fa_cl_grid.w) * _485.fa_cl_grid.z)), 0, int(_485.fa_cl_info.y) - 1) * _1548) + clamp(int(floor(((_1540.y * 0.5) + 0.5) * _485.fa_cl_grid.y)), 0, _1548 - 1)) * _1544)) + clamp(int(floor(((_1540.x * 0.5) + 0.5) * _485.fa_cl_grid.x)), 0, _1544 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1624 = fa_cluster_texel(param, _485, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1624.x), int(_1624.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_485.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4317 = fa_cluster_lookup(param, _485, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _4317.x;\n    fa_cl_local = _4317.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _5410 = fa_linear_to_srgb(param);\n        c = _5410;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _5418 = fa_srgb_to_linear(param_1);\n            c = _5418;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _417;\n    if (bool(i.front_facing))\n    {\n        _417 = i.world_normal;\n    }\n    else\n    {\n        _417 = -i.world_normal;\n    }\n    float3 _441 = fast::normalize(i.world_tangent.xyz - (_417 * dot(_417, i.world_tangent.xyz)));\n    float3 _469 = fast::normalize(((_441 * m.x) + ((cross(_417, _441) * i.world_tangent.w) * m.y)) + (_417 * m.z));\n    float3 _472;\n    if (bool(i.front_facing))\n    {\n        _472 = _469;\n    }\n    else\n    {\n        _472 = -_469;\n    }\n    return _472;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _485, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _485.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5449 = fa_tex_fix(param_2, param_3);\n    float4 _6864 = base_t;\n    _6864.x = _5449.x;\n    _6864.y = _5449.y;\n    _6864.z = _5449.z;\n    base_t = _6864;\n    float4 _5463 = (_6864 * _485.fa_base_color) * i.vertex_color;\n    float3 _6702 = i.world_normal;\n    if (_485.fa_maps.z > 0.5)\n    {\n        float param_4 = _485.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5495 = fa_tex_fix(param_6, param_7);\n        float3 _5498 = (_5495 * 2.0) - float3(1.0);\n        float2 _5503 = _5498.xy * _485.fa_maps.x;\n        float3 _6872 = _5498;\n        _6872.x = _5503.x;\n        _6872.y = _5503.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6872;\n        _6702 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _485.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5531 = fa_tex_fix(param_12, param_13);\n    float4 _6875 = mrt;\n    _6875.x = _5531.x;\n    _6875.y = _5531.y;\n    _6875.z = _5531.z;\n    mrt = _6875;\n    float4 _5559 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _485.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _5559.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5570 = fa_tex_fix(param_16, param_17);\n    float param_18 = _485.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5600 = fa_tex_fix(param_20, param_21);\n    float _6707 = _485.fa_layers_a.x;\n    float _6708 = _485.fa_layers_a.y;\n    float _6711 = _485.fa_layers_a.z;\n    float _6710 = _485.fa_layers_b.w;\n    float _6713 = _485.fa_layers_c.x;\n    if (_485.fa_layers_c.z > 0.5)\n    {\n        if (mod(_485.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _6707 *= _5570.y;\n            _6708 *= _5570.z;\n            _6710 *= _5559.w;\n        }\n        if (_485.fa_layers_c.z > 1.5)\n        {\n            _6711 *= mrt.x;\n            _6713 *= mrt.w;\n        }\n    }\n    return Surface{ _5463.xyz, _5463.w, _6702, fast::clamp(_485.fa_pbr.x * _5531.z, 0.0, 1.0), fast::clamp(_485.fa_pbr.y * _5531.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_485.fa_maps.y * (_5570.x - 1.0)), _485.fa_emissive.xyz + (_485.fa_model_emissive.xyz * _5600), _6707, _6708, _485.fa_layers_b.xyz, _6710, _6711, _485.fa_layers_a.w, _6713, _485.fa_layers_c.y, _485.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, const device fa_points_buf& points)\n{\n    s.emission += (i.vertex_color.xyz * ((device float*)&points.data[0].tint)[3u]);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1704 = rect.zw - rect.xy;\n    float2 _1708 = _1704 * atlas;\n    float2 _1712 = ddx * _1708;\n    float2 _1716 = ddy * _1708;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1704)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1712, _1712), dot(_1716, _1716)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1749 = _485.fa_counts.y < 0.5;\n    bool _1756;\n    if (!_1749)\n    {\n        _1756 = _485.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1756 = _1749;\n    }\n    if (_1756)\n    {\n        return;\n    }\n    float3 _1762 = dfdx(world_pos);\n    float3 _1765 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1769 = fa_cluster_texel(param, _485, fa_light_tex, fa_shadow_smp);\n    int _1773 = int(_1769.w);\n    if (_1773 < 1)\n    {\n        return;\n    }\n    int _1783 = int(_485.fa_counts.y + 0.5);\n    int param_1 = _1783;\n    float4 _1787 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1790 = _1787.yz;\n    int _1794 = int(_1787.w);\n    int param_2 = _1783 + 1;\n    float4 _1799 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1800 = _1799.x;\n    int _1806 = int(_485.fa_counts.w + 0.5) - 1;\n    int _1810 = int(_1769.z);\n    float3 _2075;\n    for (int k = 0; k < _1773; k++)\n    {\n        int _1823 = _1810 + k;\n        int param_3 = _1794 + (_1823 >> 2);\n        int _1840 = (_1783 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1823 & 3]) * 7);\n        int param_4 = _1840 + 6;\n        float4 _1845 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1845.w + 0.5) >> _1806) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1840;\n        float4 _1860 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1840 + 1;\n        float4 _1865 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1840 + 2;\n        float4 _1870 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1873 = _1860.xyz;\n        float _1878 = dot(_1873, world_pos) + _1860.w;\n        float3 _1880 = _1865.xyz;\n        float _1885 = dot(_1880, world_pos) + _1865.w;\n        float3 _1887 = _1870.xyz;\n        float _1892 = dot(_1887, world_pos) + _1870.w;\n        bool _1897 = abs(_1878) > 0.5;\n        bool _1905;\n        if (!_1897)\n        {\n            _1905 = abs(_1885) > 0.5;\n        }\n        else\n        {\n            _1905 = _1897;\n        }\n        bool _1913;\n        if (!_1905)\n        {\n            _1913 = abs(_1892) > 0.5;\n        }\n        else\n        {\n            _1913 = _1905;\n        }\n        if (_1913)\n        {\n            continue;\n        }\n        float _1928 = fast::clamp(dot(geo_normal, fast::normalize(_1887)) * _1845.z, 0.0, 1.0);\n        if (_1928 <= 0.0)\n        {\n            continue;\n        }\n        float _1948 = (fast::clamp((0.5 - abs(_1892)) * 10.0, 0.0, 1.0) * _1928) * _1845.x;\n        float2 _1956 = float2(_1878 + 0.5, 0.5 - _1885);\n        float2 _1966 = float2(dot(_1873, _1762), dot(_1880, _1762));\n        float2 _1976 = float2(dot(_1873, _1765), dot(_1880, _1765));\n        int param_8 = _1840 + 5;\n        float4 _1981 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1840 + 3;\n        float4 _1986 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1840 + 4;\n        float4 _1991 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1981.xyz;\n        bool _2001 = _1986.z > _1986.x;\n        if (_2001)\n        {\n            float4 param_11 = _1986;\n            float2 param_12 = _1956;\n            float2 param_13 = _1790;\n            float2 param_14 = _1966;\n            float2 param_15 = _1976;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1800 > 0.5) && (_1800 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2027 = fa_dc_to_linear(param_16);\n                float4 _6782 = tx;\n                _6782.x = _2027.x;\n                _6782.y = _2027.y;\n                _6782.z = _2027.z;\n                tx = _6782;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1948 * tex_a) * _1981.w, 0.0, 1.0)));\n        if (_1991.z > _1991.x)\n        {\n            float4 param_17 = _1991;\n            float2 param_18 = _1956;\n            float2 param_19 = _1790;\n            float2 param_20 = _1966;\n            float2 param_21 = _1976;\n            float4 _2071 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1800 > 1.5)\n            {\n                float3 param_22 = _2071.xyz;\n                float3 _2081 = fa_dc_to_srgb(param_22);\n                _2075 = _2081;\n            }\n            else\n            {\n                _2075 = _2071.xyz;\n            }\n            float3 _2090 = (_2075 * 2.0) - float3(1.0);\n            float2 _2095 = _2090.xy * _1845.y;\n            float3 _2117 = (fast::normalize(_1873) * _2095.x) + (fast::normalize(_1880) * _2095.y);\n            float3 _2120 = fast::normalize(normal);\n            normal = fast::normalize(mix(_2120, fast::normalize((_2120 * fast::max(_2090.z, 0.0500000007450580596923828125)) + (_2117 - (_2120 * dot(_2120, _2117)))), float3(fast::clamp(_1948 * (_2001 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _3421 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3429 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3432 = int(_3421);\n    int _3435 = int(_3429);\n    float _3445 = _3429 - float(_3435);\n    int _3501 = (_3432 * 9) + _3435;\n    int _3521 = ((_3432 + 1) * 9) + _3435;\n    return mix(mix(_3496[_3501], _3496[_3501 + 1], _3445), mix(_3496[_3521], _3496[_3521 + 1], _3445), _3421 - float(_3432));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _6625 = false;\n    float _6626 = 1.0;\n    float _6627 = 1.0;\n    float _6628 = 1.0;\n    float _6629 = 0.0;\n    float _6630 = 0.0;\n    float _6631 = 0.0;\n    float _6632 = 0.0;\n    float _6634 = 1.0;\n    bool _6635 = false;\n    float3 _6636 = float3(0.0);\n    float _6637 = 1.0;\n    float _6638 = 1.0;\n    float _6639 = 1.0;\n    float _6640 = 0.0;\n    float _6641 = 0.0;\n    float3 _6642 = float3(1.0, 0.0, 0.0);\n    float3 _6643 = float3(0.0, 0.0, 1.0);\n    float _6644 = 1.0;\n    float _6645 = 1.0;\n    float _3572 = fast::clamp(s.specular, 0.0, 1.0);\n    float _3576 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _3581 = (_3572 != 1.0) || (_3576 != 1.5);\n    bool _3590;\n    if (!_3581)\n    {\n        _3590 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _3590 = _3581;\n    }\n    if (_3590)\n    {\n        float _3598 = (_3576 - 1.0) / (_3576 + 1.0);\n        f0 = mix(fast::min(float3(_3598 * _3598) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _3572, s.albedo, float3(metallic));\n        _6626 = mix(_3572, 1.0, metallic);\n        _6625 = true;\n    }\n    float _3625 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_3625 > 0.0)\n    {\n        float _3633 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6629 = _3625;\n        _6630 = _3633;\n        float _3640 = _3633 * _3633;\n        _6631 = _3640;\n        _6632 = _3640 * _3640;\n        float _3652 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6634 = _3652;\n        _6627 = 1.0 - (_3625 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _3652, 0.0, 1.0), 5.0))));\n        _6625 = true;\n    }\n    float3 _3672 = fast::max(s.sheen_color, float3(0.0));\n    float _3681 = fast::max(_3672.x, fast::max(_3672.y, _3672.z));\n    if (_3681 > 0.0)\n    {\n        float _3689 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6635 = true;\n        _6636 = _3672;\n        _6637 = _3689;\n        _6638 = _3689 * _3689;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3689;\n        float _3706 = fa_sheen_albedo(param, param_1);\n        _6640 = _3706;\n        _6639 = 1.0 - fast::min(_3681 * _3706, 1.0);\n        _6625 = true;\n    }\n    _6628 = _6627 * _6639;\n    float _3725 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_3725 != 0.0)\n    {\n        float3 _3740 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3740;\n        if (dot(_3740, _3740) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _3756 = t;\n        float3 _3757 = fast::normalize(_3756);\n        t = _3757;\n        float3 _3782 = fast::normalize((_3757 * cos(s.anisotropy_rotation)) + ((cross(n, _3757) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6642 = _3782;\n        _6643 = cross(n, _3782);\n        float _3792 = roughness * roughness;\n        float _3798 = mix(_3792, 1.0, _3725 * _3725);\n        bool _3800 = _3725 > 0.0;\n        _6644 = _3800 ? _3798 : _3792;\n        _6645 = _3800 ? _3792 : _3798;\n        _6641 = _3725;\n        _6625 = true;\n    }\n    return FaLayers{ short(_6625), _6626, _6627, _6628, _6629, _6630, _6631, _6632, i.world_normal, _6634, short(_6635), _6636, _6637, _6638, _6639, _6640, _6641, _6642, _6643, _6644, _6645 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _485, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_485.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _485.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _485, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _485, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_485.fa_cl_info.x) + int(_485.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _485, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _485)\n{\n    return li * ((_485.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _485) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _485) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _722 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _735 = (c - (ru * hx)) - p;\n        float3 _741 = ru * (2.0 * hx);\n        float _747 = fast::max(dot(_741, _741), 9.9999999392252902907785028219223e-09);\n        float _751 = dot(_735, _741);\n        float t = fast::clamp((-_751) / _747, 0.0, 1.0);\n        if (_722)\n        {\n            float _766 = dot(r, _741);\n            float _772 = _747 - (_766 * _766);\n            if (abs(_772) > (9.9999997473787516355514526367188e-06 * _747))\n            {\n                t = fast::clamp(((dot(r, _735) * _766) - _751) / _772, 0.0, 1.0);\n            }\n        }\n        return (p + _735) + (_741 * t);\n    }\n    float3 q = p;\n    float _804 = dot(r, axis);\n    bool _812;\n    if (_722)\n    {\n        _812 = abs(_804) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _812 = _722;\n    }\n    if (_812)\n    {\n        float _822 = dot(c - p, axis) / _804;\n        if (_822 > 0.0)\n        {\n            q = p + (r * _822);\n        }\n    }\n    float3 _835 = q - c;\n    float2 xy = float2(dot(_835, ru), dot(_835, uu));\n    if (shape > 0.5)\n    {\n        float _850 = length(xy);\n        if (_850 > hx)\n        {\n            xy *= (hx / _850);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _643 = abs(d);\n    float _645 = _643.x;\n    float _647 = _643.y;\n    bool _648 = _645 >= _647;\n    bool _656;\n    if (_648)\n    {\n        _656 = _645 >= _643.z;\n    }\n    else\n    {\n        _656 = _648;\n    }\n    int _657;\n    if (_656)\n    {\n        _657 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _670;\n        if (_647 >= _643.z)\n        {\n            _670 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _670 = (d.z > 0.0) ? 4 : 5;\n        }\n        _657 = _670;\n    }\n    return _657;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _596 = dot(d, right);\n    float _600 = dot(d, up);\n    float _611;\n    if (((_596 * _596) + (_600 * _600)) > 1.0000000133514319600180897396058e-10)\n    {\n        _611 = precise::atan2(_600, _596) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _611 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_611 - floor(_611)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _888 = fa_light_base(param, _485);\n    bool _892 = _485.fa_ambient.w > 4.5;\n    int param_1 = _888;\n    float4 _896 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _888 + 1;\n    float4 _901 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _904 = _901.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _916 = _892 && (_904 > 2.5);\n    fa_light_is_area = _916;\n    bool _918 = _904 < 0.5;\n    float3 l;\n    if (_918)\n    {\n        l = fast::normalize(_896.xyz);\n        if (_892)\n        {\n            int param_3 = _888 + 6;\n            float4 _932 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_932.z > 0.5)\n            {\n                int param_4 = _888 + 4;\n                float4 _942 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _888 + 5;\n                float4 _947 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _932.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _942.xyz) * _942.w, (-dot(world_pos, _947.xyz)) * _947.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _977 = _896.xyz;\n        float3 _979 = _977 - world_pos;\n        float3 to_light = _979;\n        float _982 = length(_979);\n        float reach = _982;\n        bool front = true;\n        if (_916)\n        {\n            int param_8 = _888 + 7;\n            reach = fast::max(_982 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _888 + 4;\n            float4 _1006 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _888 + 5;\n            float4 _1011 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _888 + 6;\n            float4 _1016 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _1017 = _1016.w;\n            int param_12 = _888 + 2;\n            float3 _1024 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _1026 = _1017 > 1.5;\n            bool _1034;\n            if (!_1026)\n            {\n                _1034 = dot(_1024, to_light) < 0.0;\n            }\n            else\n            {\n                _1034 = _1026;\n            }\n            front = _1034;\n            float3 r = float3(0.0);\n            float3 _1043 = _485.fa_camera_pos.xyz - world_pos;\n            bool _1047 = dot(n, n) > 0.5;\n            bool _1055;\n            if (_1047)\n            {\n                _1055 = dot(_1043, _1043) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1055 = _1047;\n            }\n            if (_1055)\n            {\n                r = reflect(-fast::normalize(_1043), fast::normalize(n));\n            }\n            float3 param_13 = _977;\n            float3 param_14 = _1024;\n            float3 param_15 = _1006.xyz;\n            float3 param_16 = _1011.xyz;\n            float param_17 = _1006.w;\n            float param_18 = _1011.w;\n            float param_19 = _1017;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1091 = length(to_light);\n        dist = _1091;\n        l = to_light / float3(fast::max(_1091, 9.9999997473787516355514526367188e-05));\n        float _1105 = reach / fast::max(_896.w, 0.001000000047497451305389404296875);\n        float _1111 = fast::clamp(1.0 - (_1105 * _1105), 0.0, 1.0);\n        float _1113;\n        if (front)\n        {\n            _1113 = _1111 * _1111;\n        }\n        else\n        {\n            _1113 = 0.0;\n        }\n        atten = _1113;\n        bool _1124 = _904 < 2.5;\n        if ((_904 > 1.5) && _1124)\n        {\n            int param_22 = _888 + 2;\n            float4 _1132 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _1142 = _1132.w;\n            int param_23 = _888 + 3;\n            float4 _1147 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _1148 = _1147.x;\n            float cos_inner = _1148;\n            if (_1148 > 1.5)\n            {\n                cos_inner = mix(_1142, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1142, cos_inner, dot(-l, fast::normalize(_1132.xyz)));\n        }\n        if (_892 && (_904 < 1.5))\n        {\n            int param_24 = _888 + 6;\n            float4 _1172 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1172.z > 0.5)\n            {\n                float3 _1180 = -to_light;\n                int param_25 = _888 + 4;\n                int param_26 = _888 + 5;\n                float3 _1194 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1198 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1207 = float3(dot(_1180, _1194), dot(_1180, _1198), dot(_1180, cross(_1194, _1198)));\n                float3 param_27 = _1207;\n                int _1211 = fa_cube_face(param_27);\n                int param_28 = _1211;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1238 = float2(dot(_1207, cross(param_29, param_30)), dot(_1207, param_30)) / float2(fast::max(dot(_1207, param_29), 9.9999997473787516355514526367188e-05));\n                int _1242 = _1211 / 3;\n                float2 param_31 = _1172.xy + (float2(float(_1211 - (_1242 * 3)), float(_1242)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1238.x), 0.5 - (0.5 * _1238.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _888 + 7;\n            float4 _1272 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1272.z > 0.5)\n            {\n                int param_34 = _888 + 2;\n                int param_35 = _888 + 4;\n                int param_36 = _888 + 5;\n                float2 param_37 = _1272.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_892 && _1124)\n            {\n                int param_42 = _888 + 6;\n                float4 _1319 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _888 + 7;\n                float4 _1324 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1327 = _1319.z > 0.5;\n                bool _1334;\n                if (!_1327)\n                {\n                    _1334 = _1324.z > 0.5;\n                }\n                else\n                {\n                    _1334 = _1327;\n                }\n                if (_1334)\n                {\n                    int param_44 = _888 + 2;\n                    float4 _1341 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1345 = fast::normalize(_1341.xyz);\n                    int param_45 = _888 + 4;\n                    float4 _1350 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _888 + 5;\n                    float4 _1355 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1327)\n                    {\n                        float3 _1363 = -to_light;\n                        float _1370 = _1341.w;\n                        float _1386 = 0.5 / fast::max(dot(_1363, _1345) * (sqrt(fast::max(1.0 - (_1370 * _1370), 0.0)) / fast::max(_1370, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1319.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1363, _1350.xyz) * _1386), 0.5 - (dot(_1363, _1355.xyz) * _1386));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1324.z > 0.5)\n                    {\n                        float2 param_49 = _1324.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1345;\n                        float3 param_52 = _1350.xyz;\n                        float3 param_53 = _1355.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6613 = _901.xyz * atten;\n    if (_892)\n    {\n        _6613 *= fa_light_tint;\n    }\n    int _1455;\n    if (_918)\n    {\n        _1455 = 0;\n    }\n    else\n    {\n        _1455 = ((_904 > 1.5) && (_904 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _6613, atten, 1.0, dist, _1455 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2202)\n{\n    float _2192;\n    if (i == 0)\n    {\n        _2192 = _2202.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2208;\n        if (i == 1)\n        {\n            _2208 = _2202.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2216;\n            if (i == 2)\n            {\n                _2216 = _2202.fa_shadow_split.z;\n            }\n            else\n            {\n                _2216 = _2202.fa_shadow_split.w;\n            }\n            _2208 = _2216;\n        }\n        _2192 = _2208;\n    }\n    return _2192;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2249 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2253;\n    if (conv.x < 0.5)\n    {\n        _2253 = _2249;\n    }\n    else\n    {\n        _2253 = (conv.y * conv.z) / (conv.z - (_2249 * (conv.z - conv.y)));\n    }\n    return _2253;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2180 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2180), sin(_2180)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2202, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2299 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2308;\n        if (k < 0.0)\n        {\n            _2308 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2308 = k;\n        }\n        float _2328 = fast::clamp((_2308 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2299;\n            float2 _2347 = fa_shadow_vogel(param_3, param_4, param_5) * _2328;\n            float2 param_6 = uv + (_2347 * _2202.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2359 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2359 < (zr - (length(_2347) * plane)))\n            {\n                sum += _2359;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2385 = sum / cnt;\n        float _2395;\n        if (k < 0.0)\n        {\n            _2395 = (-k) / fast::max(_2385, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2395 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2385, 0.0) * unit) * _2395) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2417 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2417; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2417;\n        float param_11 = _2299;\n        float2 _2436 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2436 * _2202.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2436) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2417);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2202, texture2d<float> fa_shadow_tex)\n{\n    float _2478 = fast::max(_2202.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2483 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2489 = sqrt(1.0 - (_2483 * _2483));\n    float _2496 = fast::min(_2489 / fast::max(_2483, 0.20000000298023223876953125), 4.0);\n    float _2501;\n    if (_2202.fa_shadow_bias.y > 0.0)\n    {\n        _2501 = _2202.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2501 = 1.5 * _2202.fa_shadow_info[ci].x;\n    }\n    float4 _2526 = _2202.fa_shadow_mat[ci] * float4(world + (n * (_2501 * _2489)), 1.0);\n    float _2533 = _2526.x;\n    bool _2536 = _2533 < _2202.fa_shadow_rect[ci].x;\n    bool _2545;\n    if (!_2536)\n    {\n        _2545 = _2533 > _2202.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2545 = _2536;\n    }\n    bool _2554;\n    if (!_2545)\n    {\n        _2554 = _2526.y < _2202.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2554 = _2545;\n    }\n    bool _2563;\n    if (!_2554)\n    {\n        _2563 = _2526.y > _2202.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2563 = _2554;\n    }\n    bool _2570;\n    if (!_2563)\n    {\n        _2570 = _2526.z > 1.0;\n    }\n    else\n    {\n        _2570 = _2563;\n    }\n    if (_2570)\n    {\n        return -1.0;\n    }\n    float _2578;\n    if (_2202.fa_shadow_bias.x > 0.0)\n    {\n        _2578 = _2202.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2578 = 1.5 * _2202.fa_shadow_info[ci].x;\n    }\n    float2 param = _2526.xy;\n    float4 param_1 = _2202.fa_shadow_rect[ci];\n    float param_2 = _2526.z - ((_2578 * (1.0 + (0.5 * _2496))) / _2478);\n    float param_3 = _2202.fa_shadow_info[ci].x;\n    float param_4 = _2478;\n    float param_5 = _2478 * 0.25;\n    float param_6 = ((_2202.fa_shadow_info[ci].x * fast::min(_2496, 3.0)) * 0.5) / _2478;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2202.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2202.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2202, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _485, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2202, texture2d<float> fa_shadow_tex)\n{\n    if (_485.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2966 = int(_2202.fa_shadow_cfg.x + 0.5);\n    if (_2966 < 1)\n    {\n        return 1.0;\n    }\n    float _2981 = dot(world - _2202.fa_shadow_eye.xyz, _2202.fa_shadow_fwd.xyz);\n    int param = _2966 - 1;\n    if (_2981 > fa_shadow_split_at(param, _2202))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2993 = _2966 > 1;\n    bool _3000;\n    if (_2993)\n    {\n        _3000 = _2981 > _2202.fa_shadow_split.x;\n    }\n    else\n    {\n        _3000 = _2993;\n    }\n    if (_3000)\n    {\n        ci = 1;\n    }\n    bool _3004 = _2966 > 2;\n    bool _3011;\n    if (_3004)\n    {\n        _3011 = _2981 > _2202.fa_shadow_split.y;\n    }\n    else\n    {\n        _3011 = _3004;\n    }\n    if (_3011)\n    {\n        ci = 2;\n    }\n    bool _3015 = _2966 > 3;\n    bool _3022;\n    if (_3015)\n    {\n        _3022 = _2981 > _2202.fa_shadow_split.z;\n    }\n    else\n    {\n        _3022 = _3015;\n    }\n    if (_3022)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2966)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3048 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2202, fa_shadow_tex);\n        s = _3048;\n        if (_3048 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2202.fa_shadow_cfg.y > 0.0)\n    {\n        float _3073;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3073 = fa_shadow_split_at(param_5, _2202);\n        }\n        else\n        {\n            _3073 = _2202.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3092 = _2202.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2202) - _3073, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3103 = fast::clamp((_2981 - (fa_shadow_split_at(param_7, _2202) - _3092)) / _3092, 0.0, 1.0);\n        if (_3103 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2966)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3124 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2202, fa_shadow_tex);\n                s2 = _3124;\n                if (_3124 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3103);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _485, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2202, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _485, fa_shadow_smp, gl_FragCoord, _2202, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2202, texture2d<float> fa_shadow_tex)\n{\n    bool _2636 = _485.fa_pbr.z < 0.5;\n    bool _2643;\n    if (!_2636)\n    {\n        _2643 = _2202.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2643 = _2636;\n    }\n    if (_2643)\n    {\n        return 1.0;\n    }\n    int param = (int(_2202.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2656 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2657 = _2656.x;\n    if (_2657 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2666 = int(_2657 + 0.5);\n    int param_1 = _2666;\n    float4 _2670 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2666 + 1;\n    float4 _2675 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2678 = _2670.y;\n    if (_2678 > 0.0)\n    {\n        float _2695 = 1.0 - smoothstep(0.75 * _2678, _2678, length(world - _2202.fa_shadow_eye.xyz));\n        fade = _2695;\n        if (_2695 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2670.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3, _485);\n        float3 param_5 = world - fa_light_texel(param_4, fa_light_tex, fa_shadow_smp).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2724 = (_2666 + 2) + (face * 6);\n    int param_6 = _2724;\n    int param_7 = _2724 + 1;\n    int param_8 = _2724 + 3;\n    float4 _2738 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    int param_9 = _2724 + 4;\n    float4 _2743 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n    int param_10 = _2724 + 5;\n    float4 _2748 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n    float _2760 = _2748.x * fast::max(dot(_2738, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2765 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2788 = fast::clamp(dot(n, _2738.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11, _485);\n    float _2812 = fast::min(sqrt(1.0 - (_2788 * _2788)) / fast::max(abs(dot(n, world - fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_2738, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2815 = _2675.y;\n    float _2817;\n    if (_2815 > 0.0)\n    {\n        _2817 = _2815;\n    }\n    else\n    {\n        _2817 = 1.5 * _2760;\n    }\n    float4 _2837 = float4(world + (n * (_2817 * sqrt(1.0 - (_2765 * _2765)))), 1.0);\n    float _2841 = dot(_2738, _2837);\n    float _2844 = _2748.y;\n    if (_2841 < _2844)\n    {\n        return 1.0;\n    }\n    float2 _2859 = float2(dot(fa_light_texel(param_6, fa_light_tex, fa_shadow_smp), _2837), dot(fa_light_texel(param_7, fa_light_tex, fa_shadow_smp), _2837)) / float2(_2841);\n    float _2861 = _2859.x;\n    bool _2864 = _2861 < _2743.x;\n    bool _2873;\n    if (!_2864)\n    {\n        _2873 = _2861 > _2743.z;\n    }\n    else\n    {\n        _2873 = _2864;\n    }\n    bool _2882;\n    if (!_2873)\n    {\n        _2882 = _2859.y < _2743.y;\n    }\n    else\n    {\n        _2882 = _2873;\n    }\n    bool _2891;\n    if (!_2882)\n    {\n        _2891 = _2859.y > _2743.w;\n    }\n    else\n    {\n        _2891 = _2882;\n    }\n    if (_2891)\n    {\n        return 1.0;\n    }\n    float _2897 = _2675.x;\n    float _2899;\n    if (_2897 > 0.0)\n    {\n        _2899 = _2897;\n    }\n    else\n    {\n        _2899 = 1.5 * _2760;\n    }\n    float2 param_13 = _2859;\n    float4 param_14 = _2743;\n    float param_15 = _2841 - (_2899 * (1.0 + (0.5 * _2812)));\n    float param_16 = _2760;\n    float param_17 = 1.0;\n    float param_18 = _2748.z * 0.25;\n    float param_19 = (_2760 * fast::min(_2812, 3.0)) * 0.5;\n    float3 param_20 = float3(1.0, _2844, _2748.z);\n    int param_21 = int(_2670.z + 0.5);\n    float param_22 = _2670.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, fa_shadow_smp, gl_FragCoord, _2202, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2202, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _4344 = fa_lm.z > 0.5;\n    bool _4350;\n    if (_4344)\n    {\n        int param = li;\n        _4350 = fa_light_baked(param, _485, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _4350 = _4344;\n    }\n    if (_4350)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _485, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4374 = fa_light_sample_n(param_2, param_3, param_4, _485, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _6682 = _4374.color;\n    float _6684 = _4374.shadow;\n    if ((_4374.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4374.direction;\n        float _4388 = fa_shadow_factor(param_5, param_6, _485, fa_shadow_smp, gl_FragCoord, _2202, fa_shadow_tex, fa_world_pos);\n        _6684 = _4388;\n        _6682 *= _4388;\n    }\n    else\n    {\n        bool _4399 = _4374.type != 0;\n        bool _4405;\n        if (_4399)\n        {\n            _4405 = _4374.attenuation > 0.0;\n        }\n        else\n        {\n            _4405 = _4399;\n        }\n        if (_4405)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _4374.direction;\n            float _4417 = fa_shadow_local(param_7, param_8, param_9, param_10, _485, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2202, fa_shadow_tex);\n            _6684 = _4417;\n            _6682 *= _4417;\n        }\n    }\n    return LightSample{ _4374.direction, _6682, _4374.attenuation, _6684, _4374._distance, _4374.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ltc_tangent(thread const float3& n, thread const float3& v)\n{\n    float3 _4457 = v - (n * dot(v, n));\n    float3 t = _4457;\n    float _4461 = dot(_4457, _4457);\n    float l2 = _4461;\n    if (_4461 < 1.0000000133514319600180897396058e-10)\n    {\n        float3 _4471;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _4471 = cross(n, float3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _4471 = cross(n, float3(1.0, 0.0, 0.0));\n        }\n        t = _4471;\n        l2 = dot(_4471, _4471);\n    }\n    return t * rsqrt(l2);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ltc_local(thread const float3& t1, thread const float3& n, thread const float3& p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ltc_edge_vector(thread const float3& a, thread const float3& b)\n{\n    float _4506 = dot(a, a);\n    float _4510 = dot(b, b);\n    if ((_4506 < 1.0000000195414813782625560981111e-24) || (_4510 < 1.0000000195414813782625560981111e-24))\n    {\n        return float3(0.0);\n    }\n    float3 _4524 = a * rsqrt(_4506);\n    float3 _4529 = b * rsqrt(_4510);\n    float _4533 = dot(_4524, _4529);\n    float _4536 = abs(_4533);\n    float g = (((((((((((0.0416471660137176513671875 * _4536) - 0.1924748718738555908203125) * _4536) + 0.4179156124591827392578125) * _4536) - 0.616057217121124267578125) * _4536) + 0.777722418308258056640625) * _4536) - 0.999542415142059326171875) * _4536) + 1.570791721343994140625;\n    if (_4533 < 0.0)\n    {\n        g = (3.1415927410125732421875 * rsqrt(fast::max(1.0 - (_4533 * _4533), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_4524, _4529) * g;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_ltc_clip_edge(thread const float3& a, thread const float3& b, thread float3& sum, thread float3& leave, thread float3& enter, thread float2& seen)\n{\n    bool _4593 = a.z > 0.0;\n    bool _4597 = b.z > 0.0;\n    if (_4593 && _4597)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_4593 != _4597)\n        {\n            float3 _4632 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _4632.z = 0.0;\n            if (_4593)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _4632;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _4632;\n                seen.x = 1.0;\n            }\n            else\n            {\n                float3 param_4 = _4632;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _4632;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ltc_quad(thread const float4& abcd, thread const float3& p0, thread const float3& p1, thread const float3& p2, thread const float3& p3)\n{\n    float3 _4681 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _4707 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _4733 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _4759 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = float3(0.0);\n    float3 leave = float3(0.0);\n    float3 enter = float3(0.0);\n    float3 param = _4681;\n    float3 param_1 = _4707;\n    float3 param_2 = float3(0.0);\n    float3 param_3 = float3(0.0);\n    float3 param_4 = float3(0.0);\n    float2 param_5 = float2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _4707;\n    float3 param_7 = _4733;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _4733;\n    float3 param_13 = _4759;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _4759;\n    float3 param_19 = _4681;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ltc_rect(thread const float4& abcd, thread const float3& center, thread const float3& ex, thread const float3& ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_area_form(thread const float4& m, thread const float& shape, thread const float3& pc, thread const float3& ex, thread const float3& ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _4909 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    float3 _4933 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    float3 _4949 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    float4 param_4 = m;\n    float3 param_5 = _4909;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    float3 param_8 = _4933;\n    float4 param_9 = m;\n    float3 param_10 = _4909;\n    float3 param_11 = _4933;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    float3 param_13 = _4949;\n    float4 param_14 = m;\n    float3 param_15 = _4909;\n    float3 param_16 = _4949;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_ltc_uv(thread const float& roughness, thread const float& ndv)\n{\n    return ((float2(fast::clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(fast::clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + float2(0.5)) * float2(0.015625);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_shade(thread const int& li, thread const float3& world_pos, thread const float3& n, thread const float3& v, thread const float3& diffuse_color, thread const float3& f0, thread const float& f90, thread const float& roughness, thread const float& ndv, thread const float& window, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    int param = li;\n    int _5007 = fa_light_base(param, _485);\n    int param_1 = _5007;\n    int param_2 = _5007 + 1;\n    int param_3 = _5007 + 2;\n    int param_4 = _5007 + 4;\n    float4 _5029 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n    int param_5 = _5007 + 5;\n    float4 _5034 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n    int param_6 = _5007 + 6;\n    float4 _5039 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    float _5040 = _5039.w;\n    float3 _5045 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).xyz - world_pos;\n    bool _5047 = _5040 < 1.5;\n    bool _5054;\n    if (_5047)\n    {\n        _5054 = dot(fast::normalize(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz), _5045) >= 0.0;\n    }\n    else\n    {\n        _5054 = _5047;\n    }\n    if (_5054)\n    {\n        return float3(0.0);\n    }\n    bool _5063 = (_5040 > 0.5) && _5047;\n    float _5067 = _5063 ? 1.0539000034332275390625 : 1.0;\n    float3 _5070 = _5029.xyz;\n    float _5072 = _5029.w;\n    float3 _5078 = _5034.xyz;\n    float _5080 = _5034.w;\n    float3 up = _5078 * (_5080 * _5067);\n    float _5086;\n    if (_5063)\n    {\n        _5086 = (3.1415927410125732421875 * _5072) * _5072;\n    }\n    else\n    {\n        _5086 = (4.0 * _5072) * _5080;\n    }\n    if (_5040 > 1.5)\n    {\n        float3 _5112 = cross(_5070, -_5045);\n        float3 perp = _5112;\n        float _5116 = dot(_5112, _5112);\n        float3 _5119;\n        if (_5116 > 1.0000000133514319600180897396058e-10)\n        {\n            _5119 = perp * rsqrt(_5116);\n        }\n        else\n        {\n            _5119 = _5078;\n        }\n        perp = _5119;\n        up = _5119 * _5080;\n    }\n    float _5140 = fast::max(_5086, 9.9999999747524270787835121154785e-07);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _5150 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _5150;\n    float3 param_10 = n;\n    float3 param_11 = _5045;\n    float3 _5158 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _5150;\n    float3 param_13 = n;\n    float3 param_14 = _5070 * (_5072 * _5067);\n    float3 _5166 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _5150;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _5174 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5040;\n    float3 param_20 = _5158;\n    float3 param_21 = _5166;\n    float3 param_22 = _5174;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _5193 = fa_ltc_uv(param_23, param_24) * 64.0;\n    float2 param_25 = _5193;\n    float2 param_26 = _5193 + float2(64.0, 0.0);\n    float4 _5203 = fa_atlas_fetch(param_26, fa_light_atlas, fa_env_smp);\n    float4 param_27 = fa_atlas_fetch(param_25, fa_light_atlas, fa_env_smp);\n    float param_28 = _5040;\n    float3 param_29 = _5158;\n    float3 param_30 = _5166;\n    float3 param_31 = _5174;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5203.x) + ((float3(f90) - f0) * _5203.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2, fa_light_tex, fa_shadow_smp).xyz) * ((((3.1415927410125732421875 * dot(_5045, _5045)) + _5140) / _5140) * window);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _485) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _4047 = 1.0 / alpha;\n    return ((2.0 + _4047) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4047)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_layers_coat(thread const FaLayers& L, thread const float3& l, thread const float3& h, thread const float& vdh)\n{\n    float _4082 = fast::max(dot(L.nc, l), 0.0);\n    float _4088 = fast::max(dot(L.nc, h), 0.0);\n    float _4097 = ((_4088 * _4088) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4097) * _4097)) * (0.5 / fast::max(mix((2.0 * _4082) * L.coat_ndv, _4082 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4082)) * _4082;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_layers(thread const FaLayers& L, thread const int& li, thread const float3& world_pos, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& diffuse_color, thread const float3& f0, thread const float& roughness, thread const float& ndv, thread const float& window, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5271;\n    if (bool(L.sheen_on))\n    {\n        _5271 = L.sheen_scale;\n    }\n    else\n    {\n        _5271 = 1.0;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, _485, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp) * (L.keep * _5271);\n    float3 _5284 = fast::normalize(l + v);\n    int param_10 = li;\n    float3 _5295 = fa_light_rgb(param_10, _485, fa_light_tex, fa_shadow_smp) * window;\n    if (bool(L.sheen_on))\n    {\n        float _5304 = fast::max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = fast::max(dot(n, _5284), 0.0);\n        float param_13 = _5304;\n        float param_14 = ndv;\n        result += ((L.sheen * _5295) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _5304)) * _5304) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _5284;\n        float param_18 = fast::max(dot(v, _5284), 0.0);\n        result += (_5295 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _3950 = tdh / at;\n    float _3954 = bdh / ab;\n    float _3966 = ((_3950 * _3950) + (_3954 * _3954)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3966) * _3966);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _4146 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4225 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4225) * _4225);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4146);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4146));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += float3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _3353 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3356 = _3353.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_3356 * _3356, exp2((-9.27999973297119140625) * ndv)) * _3356) + _3353.y)) + _3353.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _485, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_485.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _485.fa_env_horizon.w)).xyz;\n    }\n    float _3259 = rough * rough;\n    float _3289 = 0.60000002384185791015625 * _3259;\n    return mix(mix(_485.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_485.fa_env_horizon.xyz, _485.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _3259)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _3289, 0.0500000007450580596923828125 + _3289, d.y))), ((_485.fa_env_sky.xyz + _485.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_3259 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _485, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _3833;\n        if (L.aniso >= 0.0)\n        {\n            _3833 = L.b;\n        }\n        else\n        {\n            _3833 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_3833, v), _3833), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3866 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _485, fa_env_smp, fa_env_tex) * ((f0 * _3866.x) + (float3(L.f90) * _3866.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _485, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3921 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _485, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _3921.x) + _3921.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _485, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3395 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _485, fa_env_smp, fa_env_tex) * ((f0 * _3395.x) + float3(_3395.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2202)\n{\n    if (_2202.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _3148 = int(_2202.fa_shadow_cfg.x + 0.5);\n    float _3158 = dot(world - _2202.fa_shadow_eye.xyz, _2202.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _3163 = _3148 > 0;\n    bool _3172;\n    if (_3163)\n    {\n        int param = _3148 - 1;\n        _3172 = _3158 <= fa_shadow_split_at(param, _2202);\n    }\n    else\n    {\n        _3172 = _3163;\n    }\n    if (_3172)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3178 = _3148 > 1;\n        bool _3185;\n        if (_3178)\n        {\n            _3185 = _3158 > _2202.fa_shadow_split.x;\n        }\n        else\n        {\n            _3185 = _3178;\n        }\n        if (_3185)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3191 = _3148 > 2;\n        bool _3198;\n        if (_3191)\n        {\n            _3198 = _3158 > _2202.fa_shadow_split.y;\n        }\n        else\n        {\n            _3198 = _3191;\n        }\n        if (_3198)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3204 = _3148 > 3;\n        bool _3211;\n        if (_3204)\n        {\n            _3211 = _3158 > _2202.fa_shadow_split.z;\n        }\n        else\n        {\n            _3211 = _3204;\n        }\n        if (_3211)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _485 [[buffer(1)]], constant fa_shadows& _2202 [[buffer(7)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_light_atlas [[texture(9)]], texture2d<float> fa_lightmap [[texture(10)]], texture2d<float> fa_decal_tex [[texture(11)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _6382 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _6382 = -_6382;\n    }\n    float3 _5740 = fast::normalize(_485.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _485, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _6382, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _5740, short(gl_FrontFacing) };\n    Surface _5748 = fa_standard_surface(param_1, _485, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _6413 = _5748.albedo;\n    float _6414 = _5748.alpha;\n    float3 _6415 = _5748.normal;\n    float _6416 = _5748.metallic;\n    float _6417 = _5748.roughness;\n    float _6418 = _5748.occlusion;\n    float3 _6419 = _5748.emission;\n    float _6420 = _5748.clearcoat;\n    float _6421 = _5748.clearcoat_roughness;\n    float3 _6422 = _5748.sheen_color;\n    float _6423 = _5748.sheen_roughness;\n    float _6424 = _5748.anisotropy;\n    float _6425 = _5748.anisotropy_rotation;\n    float _6426 = _5748.specular;\n    float _6427 = _5748.ior;\n    float3 _6428 = _5748.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _6382, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _5740, short(gl_FrontFacing) };\n    Surface param_3 = _5748;\n    surface(param_2, param_3, points);\n    _6413 = param_3.albedo;\n    _6414 = param_3.alpha;\n    _6415 = param_3.normal;\n    _6416 = param_3.metallic;\n    _6417 = param_3.roughness;\n    _6418 = param_3.occlusion;\n    _6419 = param_3.emission;\n    _6420 = param_3.clearcoat;\n    _6421 = param_3.clearcoat_roughness;\n    _6422 = param_3.sheen_color;\n    _6423 = param_3.sheen_roughness;\n    _6424 = param_3.anisotropy;\n    _6425 = param_3.anisotropy_rotation;\n    _6426 = param_3.specular;\n    _6427 = param_3.ior;\n    _6428 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _6382;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _485, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _6413 = param_6;\n    _6415 = param_7;\n    float3 result;\n    if (_485.fa_emissive.w > 0.5)\n    {\n        result = _6413;\n    }\n    else\n    {\n        float3 _5787 = fast::normalize(_6415);\n        float _5794 = fast::clamp(_6416, 0.0, 1.0);\n        float _5798 = fast::clamp(_6417, 0.0500000007450580596923828125, 1.0);\n        float _5802 = _5798 * _5798;\n        float _5806 = _5802 * _5802;\n        float _5811 = fast::max(dot(_5787, _5740), 9.9999997473787516355514526367188e-05);\n        float3 _5817 = _6413 * (1.0 - _5794);\n        float3 _5824 = mix(float3(0.039999999105930328369140625), _6413, float3(_5794));\n        float3 f0 = _5824;\n        SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _6382, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _5740, short(gl_FrontFacing) };\n        Surface param_9 = Surface{ _6413, _6414, _6415, _6416, _6417, _6418, _6419, _6420, _6421, _6422, _6423, _6424, _6425, _6426, _6427, _6428 };\n        float3 param_10 = _5787;\n        float3 param_11 = _5740;\n        float param_12 = _5794;\n        float param_13 = _5798;\n        float3 param_14 = _5824;\n        FaLayers _5840 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _5787;\n        float3 lit = (fa_indirect_diffuse(param_15, _485, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap) * _5817) * _6418;\n        if (_5840.on)\n        {\n            lit *= _5840.base_scale;\n        }\n        int _5862 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5862; ln++)\n        {\n            int param_16 = ln;\n            int _5875 = fa_cl_light(param_16, _485, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            bool _5878 = in.fa_lm.z > 0.5;\n            bool _5884;\n            if (_5878)\n            {\n                int param_17 = _5875;\n                _5884 = fa_light_baked(param_17, _485, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _5884 = _5878;\n            }\n            if (_5884)\n            {\n                continue;\n            }\n            int param_18 = _5875;\n            float3 param_19 = in.fa_world_pos;\n            float3 param_20 = _6382;\n            LightSample _5896 = fa_light_shadowed(param_18, param_19, param_20, _485, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2202, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            float _5904 = fast::max(dot(_5787, _5896.direction), 0.0);\n            float _5910 = _5896.attenuation * _5896.shadow;\n            float3 _5915 = fast::normalize(_5896.direction + _5740);\n            float _5920 = fast::max(dot(_5787, _5915), 0.0);\n            float _5925 = fast::max(dot(_5740, _5915), 0.0);\n            bool _5932;\n            if (fa_light_is_area)\n            {\n                _5932 = !_5840.on;\n            }\n            else\n            {\n                _5932 = fa_light_is_area;\n            }\n            if (_5932)\n            {\n                int param_21 = _5875;\n                float3 param_22 = in.fa_world_pos;\n                float3 param_23 = _5787;\n                float3 param_24 = _5740;\n                float3 param_25 = _5817;\n                float3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _5798;\n                float param_29 = _5811;\n                float param_30 = _5910;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, _485, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _5840;\n                    int param_32 = _5875;\n                    float3 param_33 = in.fa_world_pos;\n                    float3 param_34 = _5787;\n                    float3 param_35 = _5740;\n                    float3 param_36 = _5896.direction;\n                    float3 param_37 = _5817;\n                    float3 param_38 = f0;\n                    float param_39 = _5798;\n                    float param_40 = _5811;\n                    float param_41 = _5910;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41, _485, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp);\n                }\n                else\n                {\n                    if (_5840.on)\n                    {\n                        FaLayers param_42 = _5840;\n                        float3 param_43 = _5817;\n                        float3 param_44 = f0;\n                        float3 param_45 = _5787;\n                        float3 param_46 = _5740;\n                        float3 param_47 = _5896.direction;\n                        float3 param_48 = _5915;\n                        float param_49 = _5904;\n                        float param_50 = _5811;\n                        float param_51 = _5920;\n                        float param_52 = _5925;\n                        float param_53 = _5802;\n                        float param_54 = _5806;\n                        int param_55 = _5875;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55, _485, fa_light_tex, fa_shadow_smp) * fa_light_tint) * _5910));\n                    }\n                    else\n                    {\n                        float _6038 = ((_5920 * _5920) * (_5806 - 1.0)) + 1.0;\n                        int param_56 = _5875;\n                        lit += (((_5817 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _5925, 5.0))) * (((_5806 / ((3.1415927410125732421875 * _6038) * _6038)) * (0.5 / fast::max(mix((2.0 * _5904) * _5811, _5904 + _5811, _5802), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5904))) * (fa_light_rgb(param_56, _485, fa_light_tex, fa_shadow_smp) * fa_light_tint)) * (_5904 * _5910));\n                    }\n                }\n            }\n        }\n        if (_5840.on)\n        {\n            FaLayers param_57 = _5840;\n            float3 param_58 = _5787;\n            float3 param_59 = _5740;\n            float3 param_60 = f0;\n            float param_61 = _5798;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61, _485, fa_env_smp, fa_env_tex) * _6418);\n        }\n        else\n        {\n            float3 param_62 = _5787;\n            float3 param_63 = _5740;\n            float3 param_64 = f0;\n            float param_65 = _5798;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65, _485, fa_env_smp, fa_env_tex) * _6418);\n        }\n        result = lit;\n    }\n    float3 _6133 = result;\n    float3 _6134 = _6133 + _6419;\n    result = _6134;\n    float3 param_66 = _6134;\n    float3 param_67 = in.fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67, _2202);\n    bool _6143 = _485.fa_fog.w > 0.0;\n    bool _6150;\n    if (!_6143)\n    {\n        _6150 = _485.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _6150 = _6143;\n    }\n    if (_6150)\n    {\n        float3 _6159 = in.fa_world_pos - _485.fa_camera_pos.xyz;\n        float _6165 = dot(_6159, _485.fa_fog_c.xyz);\n        bool _6169 = _485.fa_fog_c.w > 0.5;\n        float _6170;\n        if (_6169)\n        {\n            _6170 = _6165;\n        }\n        else\n        {\n            _6170 = length(_6159);\n        }\n        float _6182 = _6170 - _485.fa_fog_b.x;\n        if (_6182 > 0.0)\n        {\n            float _6191 = _485.fa_fog.w * _6182;\n            float tau = _6191 * _6191;\n            if (_485.fa_fog_b.y > 0.0)\n            {\n                float _6207;\n                if (_6169)\n                {\n                    _6207 = in.fa_world_pos.y - (_485.fa_fog_c.y * _6165);\n                }\n                else\n                {\n                    _6207 = _485.fa_camera_pos.y;\n                }\n                float _6228 = mix(_6207, in.fa_world_pos.y, fast::clamp(_485.fa_fog_b.x / _6170, 0.0, 1.0));\n                float _6232 = in.fa_world_pos.y - _6228;\n                float _6237 = _6228 - _485.fa_fog_b.z;\n                float _6242 = in.fa_world_pos.y - _485.fa_fog_b.z;\n                bool _6245 = _6237 <= 0.0;\n                bool _6246 = !_6245;\n                bool _6252;\n                if (_6246)\n                {\n                    _6252 = _485.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6252 = _6245;\n                }\n                float _6253;\n                if (_6252)\n                {\n                    _6253 = _485.fa_fog_b.y;\n                }\n                else\n                {\n                    _6253 = _485.fa_fog_b.y * exp(-fast::min(_485.fa_fog_b.w * _6237, 80.0));\n                }\n                bool _6280;\n                if (_6246)\n                {\n                    _6280 = _485.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6280 = _6245;\n                }\n                float _6281;\n                if (_6280)\n                {\n                    _6281 = _485.fa_fog_b.y * _6237;\n                }\n                else\n                {\n                    _6281 = (_485.fa_fog_b.y * (1.0 - exp(-fast::min(_485.fa_fog_b.w * _6237, 80.0)))) / _485.fa_fog_b.w;\n                }\n                bool _6306 = _6242 <= 0.0;\n                bool _6313;\n                if (!_6306)\n                {\n                    _6313 = _485.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6313 = _6306;\n                }\n                float _6314;\n                if (_6313)\n                {\n                    _6314 = _485.fa_fog_b.y * _6242;\n                }\n                else\n                {\n                    _6314 = (_485.fa_fog_b.y * (1.0 - exp(-fast::min(_485.fa_fog_b.w * _6242, 80.0)))) / _485.fa_fog_b.w;\n                }\n                float _6341;\n                if (abs(_6232) < 0.001000000047497451305389404296875)\n                {\n                    _6341 = _6253;\n                }\n                else\n                {\n                    _6341 = (_6314 - _6281) / _6232;\n                }\n                tau += (_6182 * fast::max(_6341, 0.0));\n            }\n            result = mix(result, _485.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _6414);\n    return out;\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_485",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2202",
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
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 9
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
              "msl_texture_n": 10
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
              "msl_texture_n": 11
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
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
          },
          {
            "slot": 11,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _217)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _208 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_217.fa_joint_rows[_208] * weights[i]);\n        r1 += (_217.fa_joint_rows[_208 + 1] * weights[i]);\n        r2 += (_217.fa_joint_rows[_208 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _173)\n{\n    float3 _114 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _114) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_114 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * _173.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex)\n{\n    if (fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, constant fa_mesh_vs_params& _173, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _173);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _173.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _173 [[buffer(0)]], constant fa_skin& _217 [[buffer(3)]], constant fa_inst_base& _350 [[buffer(6)]], const device fa_vs_points_buf& fa_vs_points [[buffer(8)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = _350.fa_base_model * fa_skin_matrix(param, param_1, _217);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, fa_vs_points, gl_InstanceIndex, _173, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nconstant spvUnsafeArray<float, 63> _3496 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1473 = _485.fa_cl_info.x < 0.0;\n    bool _1480;\n    if (!_1473)\n    {\n        _1480 = _485.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1480 = _1473;\n    }\n    bool _1488;\n    if (!_1480)\n    {\n        _1488 = _485.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1488 = _1480;\n    }\n    bool _1495;\n    if (!_1488)\n    {\n        _1495 = _485.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1495 = _1488;\n    }\n    bool _1502;\n    if (!_1495)\n    {\n        _1502 = _485.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1502 = _1495;\n    }\n    if (_1502)\n    {\n        return float4(0.0);\n    }\n    float4 _1512 = float4(world_pos, 1.0);\n    float _1518 = dot(_485.fa_cl_vpw, _1512);\n    if (!(_1518 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1540 = float2(dot(_485.fa_cl_vpx, _1512), dot(_485.fa_cl_vpy, _1512)) / float2(_1518);\n    int _1544 = int(_485.fa_cl_grid.x);\n    int _1548 = int(_485.fa_cl_grid.y);\n    int param = (int(_485.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_485.fa_cl_fwd.xyz, world_pos) + _485.fa_cl_fwd.w, _485.fa_cl_grid.w) / _485.fa_cl_grid.w) * _485.fa_cl_grid.z)), 0, int(_485.fa_cl_info.y) - 1) * _1548) + clamp(int(floor(((_1540.y * 0.5) + 0.5) * _485.fa_cl_grid.y)), 0, _1548 - 1)) * _1544)) + clamp(int(floor(((_1540.x * 0.5) + 0.5) * _485.fa_cl_grid.x)), 0, _1544 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1624 = fa_cluster_texel(param, _485, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1624.x), int(_1624.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_485.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4317 = fa_cluster_lookup(param, _485, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _4317.x;\n    fa_cl_local = _4317.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _5410 = fa_linear_to_srgb(param);\n        c = _5410;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _5418 = fa_srgb_to_linear(param_1);\n            c = _5418;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _417;\n    if (bool(i.front_facing))\n    {\n        _417 = i.world_normal;\n    }\n    else\n    {\n        _417 = -i.world_normal;\n    }\n    float3 _441 = fast::normalize(i.world_tangent.xyz - (_417 * dot(_417, i.world_tangent.xyz)));\n    float3 _469 = fast::normalize(((_441 * m.x) + ((cross(_417, _441) * i.world_tangent.w) * m.y)) + (_417 * m.z));\n    float3 _472;\n    if (bool(i.front_facing))\n    {\n        _472 = _469;\n    }\n    else\n    {\n        _472 = -_469;\n    }\n    return _472;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _485, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _485.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5449 = fa_tex_fix(param_2, param_3);\n    float4 _6864 = base_t;\n    _6864.x = _5449.x;\n    _6864.y = _5449.y;\n    _6864.z = _5449.z;\n    base_t = _6864;\n    float4 _5463 = (_6864 * _485.fa_base_color) * i.vertex_color;\n    float3 _6702 = i.world_normal;\n    if (_485.fa_maps.z > 0.5)\n    {\n        float param_4 = _485.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5495 = fa_tex_fix(param_6, param_7);\n        float3 _5498 = (_5495 * 2.0) - float3(1.0);\n        float2 _5503 = _5498.xy * _485.fa_maps.x;\n        float3 _6872 = _5498;\n        _6872.x = _5503.x;\n        _6872.y = _5503.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6872;\n        _6702 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _485.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5531 = fa_tex_fix(param_12, param_13);\n    float4 _6875 = mrt;\n    _6875.x = _5531.x;\n    _6875.y = _5531.y;\n    _6875.z = _5531.z;\n    mrt = _6875;\n    float4 _5559 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _485.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _5559.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5570 = fa_tex_fix(param_16, param_17);\n    float param_18 = _485.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5600 = fa_tex_fix(param_20, param_21);\n    float _6707 = _485.fa_layers_a.x;\n    float _6708 = _485.fa_layers_a.y;\n    float _6711 = _485.fa_layers_a.z;\n    float _6710 = _485.fa_layers_b.w;\n    float _6713 = _485.fa_layers_c.x;\n    if (_485.fa_layers_c.z > 0.5)\n    {\n        if (mod(_485.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _6707 *= _5570.y;\n            _6708 *= _5570.z;\n            _6710 *= _5559.w;\n        }\n        if (_485.fa_layers_c.z > 1.5)\n        {\n            _6711 *= mrt.x;\n            _6713 *= mrt.w;\n        }\n    }\n    return Surface{ _5463.xyz, _5463.w, _6702, fast::clamp(_485.fa_pbr.x * _5531.z, 0.0, 1.0), fast::clamp(_485.fa_pbr.y * _5531.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_485.fa_maps.y * (_5570.x - 1.0)), _485.fa_emissive.xyz + (_485.fa_model_emissive.xyz * _5600), _6707, _6708, _485.fa_layers_b.xyz, _6710, _6711, _485.fa_layers_a.w, _6713, _485.fa_layers_c.y, _485.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, const device fa_points_buf& points)\n{\n    s.emission += (i.vertex_color.xyz * ((device float*)&points.data[0].tint)[3u]);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1704 = rect.zw - rect.xy;\n    float2 _1708 = _1704 * atlas;\n    float2 _1712 = ddx * _1708;\n    float2 _1716 = ddy * _1708;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1704)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1712, _1712), dot(_1716, _1716)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1749 = _485.fa_counts.y < 0.5;\n    bool _1756;\n    if (!_1749)\n    {\n        _1756 = _485.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1756 = _1749;\n    }\n    if (_1756)\n    {\n        return;\n    }\n    float3 _1762 = dfdx(world_pos);\n    float3 _1765 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1769 = fa_cluster_texel(param, _485, fa_light_tex, fa_shadow_smp);\n    int _1773 = int(_1769.w);\n    if (_1773 < 1)\n    {\n        return;\n    }\n    int _1783 = int(_485.fa_counts.y + 0.5);\n    int param_1 = _1783;\n    float4 _1787 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1790 = _1787.yz;\n    int _1794 = int(_1787.w);\n    int param_2 = _1783 + 1;\n    float4 _1799 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1800 = _1799.x;\n    int _1806 = int(_485.fa_counts.w + 0.5) - 1;\n    int _1810 = int(_1769.z);\n    float3 _2075;\n    for (int k = 0; k < _1773; k++)\n    {\n        int _1823 = _1810 + k;\n        int param_3 = _1794 + (_1823 >> 2);\n        int _1840 = (_1783 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1823 & 3]) * 7);\n        int param_4 = _1840 + 6;\n        float4 _1845 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1845.w + 0.5) >> _1806) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1840;\n        float4 _1860 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1840 + 1;\n        float4 _1865 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1840 + 2;\n        float4 _1870 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1873 = _1860.xyz;\n        float _1878 = dot(_1873, world_pos) + _1860.w;\n        float3 _1880 = _1865.xyz;\n        float _1885 = dot(_1880, world_pos) + _1865.w;\n        float3 _1887 = _1870.xyz;\n        float _1892 = dot(_1887, world_pos) + _1870.w;\n        bool _1897 = abs(_1878) > 0.5;\n        bool _1905;\n        if (!_1897)\n        {\n            _1905 = abs(_1885) > 0.5;\n        }\n        else\n        {\n            _1905 = _1897;\n        }\n        bool _1913;\n        if (!_1905)\n        {\n            _1913 = abs(_1892) > 0.5;\n        }\n        else\n        {\n            _1913 = _1905;\n        }\n        if (_1913)\n        {\n            continue;\n        }\n        float _1928 = fast::clamp(dot(geo_normal, fast::normalize(_1887)) * _1845.z, 0.0, 1.0);\n        if (_1928 <= 0.0)\n        {\n            continue;\n        }\n        float _1948 = (fast::clamp((0.5 - abs(_1892)) * 10.0, 0.0, 1.0) * _1928) * _1845.x;\n        float2 _1956 = float2(_1878 + 0.5, 0.5 - _1885);\n        float2 _1966 = float2(dot(_1873, _1762), dot(_1880, _1762));\n        float2 _1976 = float2(dot(_1873, _1765), dot(_1880, _1765));\n        int param_8 = _1840 + 5;\n        float4 _1981 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1840 + 3;\n        float4 _1986 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1840 + 4;\n        float4 _1991 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1981.xyz;\n        bool _2001 = _1986.z > _1986.x;\n        if (_2001)\n        {\n            float4 param_11 = _1986;\n            float2 param_12 = _1956;\n            float2 param_13 = _1790;\n            float2 param_14 = _1966;\n            float2 param_15 = _1976;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1800 > 0.5) && (_1800 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2027 = fa_dc_to_linear(param_16);\n                float4 _6782 = tx;\n                _6782.x = _2027.x;\n                _6782.y = _2027.y;\n                _6782.z = _2027.z;\n                tx = _6782;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1948 * tex_a) * _1981.w, 0.0, 1.0)));\n        if (_1991.z > _1991.x)\n        {\n            float4 param_17 = _1991;\n            float2 param_18 = _1956;\n            float2 param_19 = _1790;\n            float2 param_20 = _1966;\n            float2 param_21 = _1976;\n            float4 _2071 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1800 > 1.5)\n            {\n                float3 param_22 = _2071.xyz;\n                float3 _2081 = fa_dc_to_srgb(param_22);\n                _2075 = _2081;\n            }\n            else\n            {\n                _2075 = _2071.xyz;\n            }\n            float3 _2090 = (_2075 * 2.0) - float3(1.0);\n            float2 _2095 = _2090.xy * _1845.y;\n            float3 _2117 = (fast::normalize(_1873) * _2095.x) + (fast::normalize(_1880) * _2095.y);\n            float3 _2120 = fast::normalize(normal);\n            normal = fast::normalize(mix(_2120, fast::normalize((_2120 * fast::max(_2090.z, 0.0500000007450580596923828125)) + (_2117 - (_2120 * dot(_2120, _2117)))), float3(fast::clamp(_1948 * (_2001 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _3421 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3429 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3432 = int(_3421);\n    int _3435 = int(_3429);\n    float _3445 = _3429 - float(_3435);\n    int _3501 = (_3432 * 9) + _3435;\n    int _3521 = ((_3432 + 1) * 9) + _3435;\n    return mix(mix(_3496[_3501], _3496[_3501 + 1], _3445), mix(_3496[_3521], _3496[_3521 + 1], _3445), _3421 - float(_3432));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _6625 = false;\n    float _6626 = 1.0;\n    float _6627 = 1.0;\n    float _6628 = 1.0;\n    float _6629 = 0.0;\n    float _6630 = 0.0;\n    float _6631 = 0.0;\n    float _6632 = 0.0;\n    float _6634 = 1.0;\n    bool _6635 = false;\n    float3 _6636 = float3(0.0);\n    float _6637 = 1.0;\n    float _6638 = 1.0;\n    float _6639 = 1.0;\n    float _6640 = 0.0;\n    float _6641 = 0.0;\n    float3 _6642 = float3(1.0, 0.0, 0.0);\n    float3 _6643 = float3(0.0, 0.0, 1.0);\n    float _6644 = 1.0;\n    float _6645 = 1.0;\n    float _3572 = fast::clamp(s.specular, 0.0, 1.0);\n    float _3576 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _3581 = (_3572 != 1.0) || (_3576 != 1.5);\n    bool _3590;\n    if (!_3581)\n    {\n        _3590 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _3590 = _3581;\n    }\n    if (_3590)\n    {\n        float _3598 = (_3576 - 1.0) / (_3576 + 1.0);\n        f0 = mix(fast::min(float3(_3598 * _3598) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _3572, s.albedo, float3(metallic));\n        _6626 = mix(_3572, 1.0, metallic);\n        _6625 = true;\n    }\n    float _3625 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_3625 > 0.0)\n    {\n        float _3633 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6629 = _3625;\n        _6630 = _3633;\n        float _3640 = _3633 * _3633;\n        _6631 = _3640;\n        _6632 = _3640 * _3640;\n        float _3652 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6634 = _3652;\n        _6627 = 1.0 - (_3625 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _3652, 0.0, 1.0), 5.0))));\n        _6625 = true;\n    }\n    float3 _3672 = fast::max(s.sheen_color, float3(0.0));\n    float _3681 = fast::max(_3672.x, fast::max(_3672.y, _3672.z));\n    if (_3681 > 0.0)\n    {\n        float _3689 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6635 = true;\n        _6636 = _3672;\n        _6637 = _3689;\n        _6638 = _3689 * _3689;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3689;\n        float _3706 = fa_sheen_albedo(param, param_1);\n        _6640 = _3706;\n        _6639 = 1.0 - fast::min(_3681 * _3706, 1.0);\n        _6625 = true;\n    }\n    _6628 = _6627 * _6639;\n    float _3725 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_3725 != 0.0)\n    {\n        float3 _3740 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3740;\n        if (dot(_3740, _3740) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _3756 = t;\n        float3 _3757 = fast::normalize(_3756);\n        t = _3757;\n        float3 _3782 = fast::normalize((_3757 * cos(s.anisotropy_rotation)) + ((cross(n, _3757) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6642 = _3782;\n        _6643 = cross(n, _3782);\n        float _3792 = roughness * roughness;\n        float _3798 = mix(_3792, 1.0, _3725 * _3725);\n        bool _3800 = _3725 > 0.0;\n        _6644 = _3800 ? _3798 : _3792;\n        _6645 = _3800 ? _3792 : _3798;\n        _6641 = _3725;\n        _6625 = true;\n    }\n    return FaLayers{ short(_6625), _6626, _6627, _6628, _6629, _6630, _6631, _6632, i.world_normal, _6634, short(_6635), _6636, _6637, _6638, _6639, _6640, _6641, _6642, _6643, _6644, _6645 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _485, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_485.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _485.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _485, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _485, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_485.fa_cl_info.x) + int(_485.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _485, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _485)\n{\n    return li * ((_485.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _485) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _485) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _722 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _735 = (c - (ru * hx)) - p;\n        float3 _741 = ru * (2.0 * hx);\n        float _747 = fast::max(dot(_741, _741), 9.9999999392252902907785028219223e-09);\n        float _751 = dot(_735, _741);\n        float t = fast::clamp((-_751) / _747, 0.0, 1.0);\n        if (_722)\n        {\n            float _766 = dot(r, _741);\n            float _772 = _747 - (_766 * _766);\n            if (abs(_772) > (9.9999997473787516355514526367188e-06 * _747))\n            {\n                t = fast::clamp(((dot(r, _735) * _766) - _751) / _772, 0.0, 1.0);\n            }\n        }\n        return (p + _735) + (_741 * t);\n    }\n    float3 q = p;\n    float _804 = dot(r, axis);\n    bool _812;\n    if (_722)\n    {\n        _812 = abs(_804) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _812 = _722;\n    }\n    if (_812)\n    {\n        float _822 = dot(c - p, axis) / _804;\n        if (_822 > 0.0)\n        {\n            q = p + (r * _822);\n        }\n    }\n    float3 _835 = q - c;\n    float2 xy = float2(dot(_835, ru), dot(_835, uu));\n    if (shape > 0.5)\n    {\n        float _850 = length(xy);\n        if (_850 > hx)\n        {\n            xy *= (hx / _850);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _643 = abs(d);\n    float _645 = _643.x;\n    float _647 = _643.y;\n    bool _648 = _645 >= _647;\n    bool _656;\n    if (_648)\n    {\n        _656 = _645 >= _643.z;\n    }\n    else\n    {\n        _656 = _648;\n    }\n    int _657;\n    if (_656)\n    {\n        _657 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _670;\n        if (_647 >= _643.z)\n        {\n            _670 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _670 = (d.z > 0.0) ? 4 : 5;\n        }\n        _657 = _670;\n    }\n    return _657;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _596 = dot(d, right);\n    float _600 = dot(d, up);\n    float _611;\n    if (((_596 * _596) + (_600 * _600)) > 1.0000000133514319600180897396058e-10)\n    {\n        _611 = precise::atan2(_600, _596) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _611 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_611 - floor(_611)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _888 = fa_light_base(param, _485);\n    bool _892 = _485.fa_ambient.w > 4.5;\n    int param_1 = _888;\n    float4 _896 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _888 + 1;\n    float4 _901 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _904 = _901.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _916 = _892 && (_904 > 2.5);\n    fa_light_is_area = _916;\n    bool _918 = _904 < 0.5;\n    float3 l;\n    if (_918)\n    {\n        l = fast::normalize(_896.xyz);\n        if (_892)\n        {\n            int param_3 = _888 + 6;\n            float4 _932 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_932.z > 0.5)\n            {\n                int param_4 = _888 + 4;\n                float4 _942 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _888 + 5;\n                float4 _947 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _932.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _942.xyz) * _942.w, (-dot(world_pos, _947.xyz)) * _947.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _977 = _896.xyz;\n        float3 _979 = _977 - world_pos;\n        float3 to_light = _979;\n        float _982 = length(_979);\n        float reach = _982;\n        bool front = true;\n        if (_916)\n        {\n            int param_8 = _888 + 7;\n            reach = fast::max(_982 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _888 + 4;\n            float4 _1006 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _888 + 5;\n            float4 _1011 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _888 + 6;\n            float4 _1016 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _1017 = _1016.w;\n            int param_12 = _888 + 2;\n            float3 _1024 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _1026 = _1017 > 1.5;\n            bool _1034;\n            if (!_1026)\n            {\n                _1034 = dot(_1024, to_light) < 0.0;\n            }\n            else\n            {\n                _1034 = _1026;\n            }\n            front = _1034;\n            float3 r = float3(0.0);\n            float3 _1043 = _485.fa_camera_pos.xyz - world_pos;\n            bool _1047 = dot(n, n) > 0.5;\n            bool _1055;\n            if (_1047)\n            {\n                _1055 = dot(_1043, _1043) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1055 = _1047;\n            }\n            if (_1055)\n            {\n                r = reflect(-fast::normalize(_1043), fast::normalize(n));\n            }\n            float3 param_13 = _977;\n            float3 param_14 = _1024;\n            float3 param_15 = _1006.xyz;\n            float3 param_16 = _1011.xyz;\n            float param_17 = _1006.w;\n            float param_18 = _1011.w;\n            float param_19 = _1017;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1091 = length(to_light);\n        dist = _1091;\n        l = to_light / float3(fast::max(_1091, 9.9999997473787516355514526367188e-05));\n        float _1105 = reach / fast::max(_896.w, 0.001000000047497451305389404296875);\n        float _1111 = fast::clamp(1.0 - (_1105 * _1105), 0.0, 1.0);\n        float _1113;\n        if (front)\n        {\n            _1113 = _1111 * _1111;\n        }\n        else\n        {\n            _1113 = 0.0;\n        }\n        atten = _1113;\n        bool _1124 = _904 < 2.5;\n        if ((_904 > 1.5) && _1124)\n        {\n            int param_22 = _888 + 2;\n            float4 _1132 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _1142 = _1132.w;\n            int param_23 = _888 + 3;\n            float4 _1147 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _1148 = _1147.x;\n            float cos_inner = _1148;\n            if (_1148 > 1.5)\n            {\n                cos_inner = mix(_1142, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1142, cos_inner, dot(-l, fast::normalize(_1132.xyz)));\n        }\n        if (_892 && (_904 < 1.5))\n        {\n            int param_24 = _888 + 6;\n            float4 _1172 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1172.z > 0.5)\n            {\n                float3 _1180 = -to_light;\n                int param_25 = _888 + 4;\n                int param_26 = _888 + 5;\n                float3 _1194 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1198 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1207 = float3(dot(_1180, _1194), dot(_1180, _1198), dot(_1180, cross(_1194, _1198)));\n                float3 param_27 = _1207;\n                int _1211 = fa_cube_face(param_27);\n                int param_28 = _1211;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1238 = float2(dot(_1207, cross(param_29, param_30)), dot(_1207, param_30)) / float2(fast::max(dot(_1207, param_29), 9.9999997473787516355514526367188e-05));\n                int _1242 = _1211 / 3;\n                float2 param_31 = _1172.xy + (float2(float(_1211 - (_1242 * 3)), float(_1242)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1238.x), 0.5 - (0.5 * _1238.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _888 + 7;\n            float4 _1272 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1272.z > 0.5)\n            {\n                int param_34 = _888 + 2;\n                int param_35 = _888 + 4;\n                int param_36 = _888 + 5;\n                float2 param_37 = _1272.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_892 && _1124)\n            {\n                int param_42 = _888 + 6;\n                float4 _1319 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _888 + 7;\n                float4 _1324 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1327 = _1319.z > 0.5;\n                bool _1334;\n                if (!_1327)\n                {\n                    _1334 = _1324.z > 0.5;\n                }\n                else\n                {\n                    _1334 = _1327;\n                }\n                if (_1334)\n                {\n                    int param_44 = _888 + 2;\n                    float4 _1341 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1345 = fast::normalize(_1341.xyz);\n                    int param_45 = _888 + 4;\n                    float4 _1350 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _888 + 5;\n                    float4 _1355 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1327)\n                    {\n                        float3 _1363 = -to_light;\n                        float _1370 = _1341.w;\n                        float _1386 = 0.5 / fast::max(dot(_1363, _1345) * (sqrt(fast::max(1.0 - (_1370 * _1370), 0.0)) / fast::max(_1370, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1319.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1363, _1350.xyz) * _1386), 0.5 - (dot(_1363, _1355.xyz) * _1386));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1324.z > 0.5)\n                    {\n                        float2 param_49 = _1324.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1345;\n                        float3 param_52 = _1350.xyz;\n                        float3 param_53 = _1355.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6613 = _901.xyz * atten;\n    if (_892)\n    {\n        _6613 *= fa_light_tint;\n    }\n    int _1455;\n    if (_918)\n    {\n        _1455 = 0;\n    }\n    else\n    {\n        _1455 = ((_904 > 1.5) && (_904 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _6613, atten, 1.0, dist, _1455 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2202)\n{\n    float _2192;\n    if (i == 0)\n    {\n        _2192 = _2202.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2208;\n        if (i == 1)\n        {\n            _2208 = _2202.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2216;\n            if (i == 2)\n            {\n                _2216 = _2202.fa_shadow_split.z;\n            }\n            else\n            {\n                _2216 = _2202.fa_shadow_split.w;\n            }\n            _2208 = _2216;\n        }\n        _2192 = _2208;\n    }\n    return _2192;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2249 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2253;\n    if (conv.x < 0.5)\n    {\n        _2253 = _2249;\n    }\n    else\n    {\n        _2253 = (conv.y * conv.z) / (conv.z - (_2249 * (conv.z - conv.y)));\n    }\n    return _2253;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2180 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2180), sin(_2180)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2202, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2299 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2308;\n        if (k < 0.0)\n        {\n            _2308 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2308 = k;\n        }\n        float _2328 = fast::clamp((_2308 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2299;\n            float2 _2347 = fa_shadow_vogel(param_3, param_4, param_5) * _2328;\n            float2 param_6 = uv + (_2347 * _2202.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2359 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2359 < (zr - (length(_2347) * plane)))\n            {\n                sum += _2359;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2385 = sum / cnt;\n        float _2395;\n        if (k < 0.0)\n        {\n            _2395 = (-k) / fast::max(_2385, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2395 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2385, 0.0) * unit) * _2395) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2417 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2417; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2417;\n        float param_11 = _2299;\n        float2 _2436 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2436 * _2202.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2436) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2417);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2202, texture2d<float> fa_shadow_tex)\n{\n    float _2478 = fast::max(_2202.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2483 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2489 = sqrt(1.0 - (_2483 * _2483));\n    float _2496 = fast::min(_2489 / fast::max(_2483, 0.20000000298023223876953125), 4.0);\n    float _2501;\n    if (_2202.fa_shadow_bias.y > 0.0)\n    {\n        _2501 = _2202.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2501 = 1.5 * _2202.fa_shadow_info[ci].x;\n    }\n    float4 _2526 = _2202.fa_shadow_mat[ci] * float4(world + (n * (_2501 * _2489)), 1.0);\n    float _2533 = _2526.x;\n    bool _2536 = _2533 < _2202.fa_shadow_rect[ci].x;\n    bool _2545;\n    if (!_2536)\n    {\n        _2545 = _2533 > _2202.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2545 = _2536;\n    }\n    bool _2554;\n    if (!_2545)\n    {\n        _2554 = _2526.y < _2202.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2554 = _2545;\n    }\n    bool _2563;\n    if (!_2554)\n    {\n        _2563 = _2526.y > _2202.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2563 = _2554;\n    }\n    bool _2570;\n    if (!_2563)\n    {\n        _2570 = _2526.z > 1.0;\n    }\n    else\n    {\n        _2570 = _2563;\n    }\n    if (_2570)\n    {\n        return -1.0;\n    }\n    float _2578;\n    if (_2202.fa_shadow_bias.x > 0.0)\n    {\n        _2578 = _2202.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2578 = 1.5 * _2202.fa_shadow_info[ci].x;\n    }\n    float2 param = _2526.xy;\n    float4 param_1 = _2202.fa_shadow_rect[ci];\n    float param_2 = _2526.z - ((_2578 * (1.0 + (0.5 * _2496))) / _2478);\n    float param_3 = _2202.fa_shadow_info[ci].x;\n    float param_4 = _2478;\n    float param_5 = _2478 * 0.25;\n    float param_6 = ((_2202.fa_shadow_info[ci].x * fast::min(_2496, 3.0)) * 0.5) / _2478;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2202.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2202.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2202, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _485, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2202, texture2d<float> fa_shadow_tex)\n{\n    if (_485.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2966 = int(_2202.fa_shadow_cfg.x + 0.5);\n    if (_2966 < 1)\n    {\n        return 1.0;\n    }\n    float _2981 = dot(world - _2202.fa_shadow_eye.xyz, _2202.fa_shadow_fwd.xyz);\n    int param = _2966 - 1;\n    if (_2981 > fa_shadow_split_at(param, _2202))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2993 = _2966 > 1;\n    bool _3000;\n    if (_2993)\n    {\n        _3000 = _2981 > _2202.fa_shadow_split.x;\n    }\n    else\n    {\n        _3000 = _2993;\n    }\n    if (_3000)\n    {\n        ci = 1;\n    }\n    bool _3004 = _2966 > 2;\n    bool _3011;\n    if (_3004)\n    {\n        _3011 = _2981 > _2202.fa_shadow_split.y;\n    }\n    else\n    {\n        _3011 = _3004;\n    }\n    if (_3011)\n    {\n        ci = 2;\n    }\n    bool _3015 = _2966 > 3;\n    bool _3022;\n    if (_3015)\n    {\n        _3022 = _2981 > _2202.fa_shadow_split.z;\n    }\n    else\n    {\n        _3022 = _3015;\n    }\n    if (_3022)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2966)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3048 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2202, fa_shadow_tex);\n        s = _3048;\n        if (_3048 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2202.fa_shadow_cfg.y > 0.0)\n    {\n        float _3073;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3073 = fa_shadow_split_at(param_5, _2202);\n        }\n        else\n        {\n            _3073 = _2202.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3092 = _2202.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2202) - _3073, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3103 = fast::clamp((_2981 - (fa_shadow_split_at(param_7, _2202) - _3092)) / _3092, 0.0, 1.0);\n        if (_3103 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2966)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3124 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2202, fa_shadow_tex);\n                s2 = _3124;\n                if (_3124 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3103);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _485, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2202, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _485, fa_shadow_smp, gl_FragCoord, _2202, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2202, texture2d<float> fa_shadow_tex)\n{\n    bool _2636 = _485.fa_pbr.z < 0.5;\n    bool _2643;\n    if (!_2636)\n    {\n        _2643 = _2202.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2643 = _2636;\n    }\n    if (_2643)\n    {\n        return 1.0;\n    }\n    int param = (int(_2202.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2656 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2657 = _2656.x;\n    if (_2657 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2666 = int(_2657 + 0.5);\n    int param_1 = _2666;\n    float4 _2670 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2666 + 1;\n    float4 _2675 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2678 = _2670.y;\n    if (_2678 > 0.0)\n    {\n        float _2695 = 1.0 - smoothstep(0.75 * _2678, _2678, length(world - _2202.fa_shadow_eye.xyz));\n        fade = _2695;\n        if (_2695 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2670.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3, _485);\n        float3 param_5 = world - fa_light_texel(param_4, fa_light_tex, fa_shadow_smp).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2724 = (_2666 + 2) + (face * 6);\n    int param_6 = _2724;\n    int param_7 = _2724 + 1;\n    int param_8 = _2724 + 3;\n    float4 _2738 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    int param_9 = _2724 + 4;\n    float4 _2743 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n    int param_10 = _2724 + 5;\n    float4 _2748 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n    float _2760 = _2748.x * fast::max(dot(_2738, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2765 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2788 = fast::clamp(dot(n, _2738.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11, _485);\n    float _2812 = fast::min(sqrt(1.0 - (_2788 * _2788)) / fast::max(abs(dot(n, world - fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_2738, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2815 = _2675.y;\n    float _2817;\n    if (_2815 > 0.0)\n    {\n        _2817 = _2815;\n    }\n    else\n    {\n        _2817 = 1.5 * _2760;\n    }\n    float4 _2837 = float4(world + (n * (_2817 * sqrt(1.0 - (_2765 * _2765)))), 1.0);\n    float _2841 = dot(_2738, _2837);\n    float _2844 = _2748.y;\n    if (_2841 < _2844)\n    {\n        return 1.0;\n    }\n    float2 _2859 = float2(dot(fa_light_texel(param_6, fa_light_tex, fa_shadow_smp), _2837), dot(fa_light_texel(param_7, fa_light_tex, fa_shadow_smp), _2837)) / float2(_2841);\n    float _2861 = _2859.x;\n    bool _2864 = _2861 < _2743.x;\n    bool _2873;\n    if (!_2864)\n    {\n        _2873 = _2861 > _2743.z;\n    }\n    else\n    {\n        _2873 = _2864;\n    }\n    bool _2882;\n    if (!_2873)\n    {\n        _2882 = _2859.y < _2743.y;\n    }\n    else\n    {\n        _2882 = _2873;\n    }\n    bool _2891;\n    if (!_2882)\n    {\n        _2891 = _2859.y > _2743.w;\n    }\n    else\n    {\n        _2891 = _2882;\n    }\n    if (_2891)\n    {\n        return 1.0;\n    }\n    float _2897 = _2675.x;\n    float _2899;\n    if (_2897 > 0.0)\n    {\n        _2899 = _2897;\n    }\n    else\n    {\n        _2899 = 1.5 * _2760;\n    }\n    float2 param_13 = _2859;\n    float4 param_14 = _2743;\n    float param_15 = _2841 - (_2899 * (1.0 + (0.5 * _2812)));\n    float param_16 = _2760;\n    float param_17 = 1.0;\n    float param_18 = _2748.z * 0.25;\n    float param_19 = (_2760 * fast::min(_2812, 3.0)) * 0.5;\n    float3 param_20 = float3(1.0, _2844, _2748.z);\n    int param_21 = int(_2670.z + 0.5);\n    float param_22 = _2670.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, fa_shadow_smp, gl_FragCoord, _2202, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2202, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _4344 = fa_lm.z > 0.5;\n    bool _4350;\n    if (_4344)\n    {\n        int param = li;\n        _4350 = fa_light_baked(param, _485, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _4350 = _4344;\n    }\n    if (_4350)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _485, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4374 = fa_light_sample_n(param_2, param_3, param_4, _485, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _6682 = _4374.color;\n    float _6684 = _4374.shadow;\n    if ((_4374.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4374.direction;\n        float _4388 = fa_shadow_factor(param_5, param_6, _485, fa_shadow_smp, gl_FragCoord, _2202, fa_shadow_tex, fa_world_pos);\n        _6684 = _4388;\n        _6682 *= _4388;\n    }\n    else\n    {\n        bool _4399 = _4374.type != 0;\n        bool _4405;\n        if (_4399)\n        {\n            _4405 = _4374.attenuation > 0.0;\n        }\n        else\n        {\n            _4405 = _4399;\n        }\n        if (_4405)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _4374.direction;\n            float _4417 = fa_shadow_local(param_7, param_8, param_9, param_10, _485, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2202, fa_shadow_tex);\n            _6684 = _4417;\n            _6682 *= _4417;\n        }\n    }\n    return LightSample{ _4374.direction, _6682, _4374.attenuation, _6684, _4374._distance, _4374.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ltc_tangent(thread const float3& n, thread const float3& v)\n{\n    float3 _4457 = v - (n * dot(v, n));\n    float3 t = _4457;\n    float _4461 = dot(_4457, _4457);\n    float l2 = _4461;\n    if (_4461 < 1.0000000133514319600180897396058e-10)\n    {\n        float3 _4471;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _4471 = cross(n, float3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _4471 = cross(n, float3(1.0, 0.0, 0.0));\n        }\n        t = _4471;\n        l2 = dot(_4471, _4471);\n    }\n    return t * rsqrt(l2);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ltc_local(thread const float3& t1, thread const float3& n, thread const float3& p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ltc_edge_vector(thread const float3& a, thread const float3& b)\n{\n    float _4506 = dot(a, a);\n    float _4510 = dot(b, b);\n    if ((_4506 < 1.0000000195414813782625560981111e-24) || (_4510 < 1.0000000195414813782625560981111e-24))\n    {\n        return float3(0.0);\n    }\n    float3 _4524 = a * rsqrt(_4506);\n    float3 _4529 = b * rsqrt(_4510);\n    float _4533 = dot(_4524, _4529);\n    float _4536 = abs(_4533);\n    float g = (((((((((((0.0416471660137176513671875 * _4536) - 0.1924748718738555908203125) * _4536) + 0.4179156124591827392578125) * _4536) - 0.616057217121124267578125) * _4536) + 0.777722418308258056640625) * _4536) - 0.999542415142059326171875) * _4536) + 1.570791721343994140625;\n    if (_4533 < 0.0)\n    {\n        g = (3.1415927410125732421875 * rsqrt(fast::max(1.0 - (_4533 * _4533), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_4524, _4529) * g;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_ltc_clip_edge(thread const float3& a, thread const float3& b, thread float3& sum, thread float3& leave, thread float3& enter, thread float2& seen)\n{\n    bool _4593 = a.z > 0.0;\n    bool _4597 = b.z > 0.0;\n    if (_4593 && _4597)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_4593 != _4597)\n        {\n            float3 _4632 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _4632.z = 0.0;\n            if (_4593)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _4632;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _4632;\n                seen.x = 1.0;\n            }\n            else\n            {\n                float3 param_4 = _4632;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _4632;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ltc_quad(thread const float4& abcd, thread const float3& p0, thread const float3& p1, thread const float3& p2, thread const float3& p3)\n{\n    float3 _4681 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _4707 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _4733 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _4759 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = float3(0.0);\n    float3 leave = float3(0.0);\n    float3 enter = float3(0.0);\n    float3 param = _4681;\n    float3 param_1 = _4707;\n    float3 param_2 = float3(0.0);\n    float3 param_3 = float3(0.0);\n    float3 param_4 = float3(0.0);\n    float2 param_5 = float2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _4707;\n    float3 param_7 = _4733;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _4733;\n    float3 param_13 = _4759;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _4759;\n    float3 param_19 = _4681;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ltc_rect(thread const float4& abcd, thread const float3& center, thread const float3& ex, thread const float3& ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_area_form(thread const float4& m, thread const float& shape, thread const float3& pc, thread const float3& ex, thread const float3& ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _4909 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    float3 _4933 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    float3 _4949 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    float4 param_4 = m;\n    float3 param_5 = _4909;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    float3 param_8 = _4933;\n    float4 param_9 = m;\n    float3 param_10 = _4909;\n    float3 param_11 = _4933;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    float3 param_13 = _4949;\n    float4 param_14 = m;\n    float3 param_15 = _4909;\n    float3 param_16 = _4949;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_ltc_uv(thread const float& roughness, thread const float& ndv)\n{\n    return ((float2(fast::clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(fast::clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + float2(0.5)) * float2(0.015625);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_shade(thread const int& li, thread const float3& world_pos, thread const float3& n, thread const float3& v, thread const float3& diffuse_color, thread const float3& f0, thread const float& f90, thread const float& roughness, thread const float& ndv, thread const float& window, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    int param = li;\n    int _5007 = fa_light_base(param, _485);\n    int param_1 = _5007;\n    int param_2 = _5007 + 1;\n    int param_3 = _5007 + 2;\n    int param_4 = _5007 + 4;\n    float4 _5029 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n    int param_5 = _5007 + 5;\n    float4 _5034 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n    int param_6 = _5007 + 6;\n    float4 _5039 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    float _5040 = _5039.w;\n    float3 _5045 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).xyz - world_pos;\n    bool _5047 = _5040 < 1.5;\n    bool _5054;\n    if (_5047)\n    {\n        _5054 = dot(fast::normalize(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz), _5045) >= 0.0;\n    }\n    else\n    {\n        _5054 = _5047;\n    }\n    if (_5054)\n    {\n        return float3(0.0);\n    }\n    bool _5063 = (_5040 > 0.5) && _5047;\n    float _5067 = _5063 ? 1.0539000034332275390625 : 1.0;\n    float3 _5070 = _5029.xyz;\n    float _5072 = _5029.w;\n    float3 _5078 = _5034.xyz;\n    float _5080 = _5034.w;\n    float3 up = _5078 * (_5080 * _5067);\n    float _5086;\n    if (_5063)\n    {\n        _5086 = (3.1415927410125732421875 * _5072) * _5072;\n    }\n    else\n    {\n        _5086 = (4.0 * _5072) * _5080;\n    }\n    if (_5040 > 1.5)\n    {\n        float3 _5112 = cross(_5070, -_5045);\n        float3 perp = _5112;\n        float _5116 = dot(_5112, _5112);\n        float3 _5119;\n        if (_5116 > 1.0000000133514319600180897396058e-10)\n        {\n            _5119 = perp * rsqrt(_5116);\n        }\n        else\n        {\n            _5119 = _5078;\n        }\n        perp = _5119;\n        up = _5119 * _5080;\n    }\n    float _5140 = fast::max(_5086, 9.9999999747524270787835121154785e-07);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _5150 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _5150;\n    float3 param_10 = n;\n    float3 param_11 = _5045;\n    float3 _5158 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _5150;\n    float3 param_13 = n;\n    float3 param_14 = _5070 * (_5072 * _5067);\n    float3 _5166 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _5150;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _5174 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5040;\n    float3 param_20 = _5158;\n    float3 param_21 = _5166;\n    float3 param_22 = _5174;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _5193 = fa_ltc_uv(param_23, param_24) * 64.0;\n    float2 param_25 = _5193;\n    float2 param_26 = _5193 + float2(64.0, 0.0);\n    float4 _5203 = fa_atlas_fetch(param_26, fa_light_atlas, fa_env_smp);\n    float4 param_27 = fa_atlas_fetch(param_25, fa_light_atlas, fa_env_smp);\n    float param_28 = _5040;\n    float3 param_29 = _5158;\n    float3 param_30 = _5166;\n    float3 param_31 = _5174;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5203.x) + ((float3(f90) - f0) * _5203.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2, fa_light_tex, fa_shadow_smp).xyz) * ((((3.1415927410125732421875 * dot(_5045, _5045)) + _5140) / _5140) * window);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _485) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _4047 = 1.0 / alpha;\n    return ((2.0 + _4047) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4047)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_layers_coat(thread const FaLayers& L, thread const float3& l, thread const float3& h, thread const float& vdh)\n{\n    float _4082 = fast::max(dot(L.nc, l), 0.0);\n    float _4088 = fast::max(dot(L.nc, h), 0.0);\n    float _4097 = ((_4088 * _4088) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4097) * _4097)) * (0.5 / fast::max(mix((2.0 * _4082) * L.coat_ndv, _4082 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4082)) * _4082;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_layers(thread const FaLayers& L, thread const int& li, thread const float3& world_pos, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& diffuse_color, thread const float3& f0, thread const float& roughness, thread const float& ndv, thread const float& window, constant fa_mesh_fs_params& _485, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5271;\n    if (bool(L.sheen_on))\n    {\n        _5271 = L.sheen_scale;\n    }\n    else\n    {\n        _5271 = 1.0;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, _485, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp) * (L.keep * _5271);\n    float3 _5284 = fast::normalize(l + v);\n    int param_10 = li;\n    float3 _5295 = fa_light_rgb(param_10, _485, fa_light_tex, fa_shadow_smp) * window;\n    if (bool(L.sheen_on))\n    {\n        float _5304 = fast::max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = fast::max(dot(n, _5284), 0.0);\n        float param_13 = _5304;\n        float param_14 = ndv;\n        result += ((L.sheen * _5295) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _5304)) * _5304) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _5284;\n        float param_18 = fast::max(dot(v, _5284), 0.0);\n        result += (_5295 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _3950 = tdh / at;\n    float _3954 = bdh / ab;\n    float _3966 = ((_3950 * _3950) + (_3954 * _3954)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3966) * _3966);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _4146 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4225 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4225) * _4225);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4146);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4146));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += float3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _3353 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3356 = _3353.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_3356 * _3356, exp2((-9.27999973297119140625) * ndv)) * _3356) + _3353.y)) + _3353.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _485, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_485.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _485.fa_env_horizon.w)).xyz;\n    }\n    float _3259 = rough * rough;\n    float _3289 = 0.60000002384185791015625 * _3259;\n    return mix(mix(_485.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_485.fa_env_horizon.xyz, _485.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _3259)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _3289, 0.0500000007450580596923828125 + _3289, d.y))), ((_485.fa_env_sky.xyz + _485.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_3259 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _485, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _3833;\n        if (L.aniso >= 0.0)\n        {\n            _3833 = L.b;\n        }\n        else\n        {\n            _3833 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_3833, v), _3833), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3866 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _485, fa_env_smp, fa_env_tex) * ((f0 * _3866.x) + (float3(L.f90) * _3866.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _485, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3921 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _485, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _3921.x) + _3921.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _485, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3395 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _485, fa_env_smp, fa_env_tex) * ((f0 * _3395.x) + float3(_3395.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2202)\n{\n    if (_2202.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _3148 = int(_2202.fa_shadow_cfg.x + 0.5);\n    float _3158 = dot(world - _2202.fa_shadow_eye.xyz, _2202.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _3163 = _3148 > 0;\n    bool _3172;\n    if (_3163)\n    {\n        int param = _3148 - 1;\n        _3172 = _3158 <= fa_shadow_split_at(param, _2202);\n    }\n    else\n    {\n        _3172 = _3163;\n    }\n    if (_3172)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3178 = _3148 > 1;\n        bool _3185;\n        if (_3178)\n        {\n            _3185 = _3158 > _2202.fa_shadow_split.x;\n        }\n        else\n        {\n            _3185 = _3178;\n        }\n        if (_3185)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3191 = _3148 > 2;\n        bool _3198;\n        if (_3191)\n        {\n            _3198 = _3158 > _2202.fa_shadow_split.y;\n        }\n        else\n        {\n            _3198 = _3191;\n        }\n        if (_3198)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3204 = _3148 > 3;\n        bool _3211;\n        if (_3204)\n        {\n            _3211 = _3158 > _2202.fa_shadow_split.z;\n        }\n        else\n        {\n            _3211 = _3204;\n        }\n        if (_3211)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _485 [[buffer(1)]], constant fa_shadows& _2202 [[buffer(7)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_light_atlas [[texture(9)]], texture2d<float> fa_lightmap [[texture(10)]], texture2d<float> fa_decal_tex [[texture(11)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _6382 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _6382 = -_6382;\n    }\n    float3 _5740 = fast::normalize(_485.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _485, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _6382, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _5740, short(gl_FrontFacing) };\n    Surface _5748 = fa_standard_surface(param_1, _485, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _6413 = _5748.albedo;\n    float _6414 = _5748.alpha;\n    float3 _6415 = _5748.normal;\n    float _6416 = _5748.metallic;\n    float _6417 = _5748.roughness;\n    float _6418 = _5748.occlusion;\n    float3 _6419 = _5748.emission;\n    float _6420 = _5748.clearcoat;\n    float _6421 = _5748.clearcoat_roughness;\n    float3 _6422 = _5748.sheen_color;\n    float _6423 = _5748.sheen_roughness;\n    float _6424 = _5748.anisotropy;\n    float _6425 = _5748.anisotropy_rotation;\n    float _6426 = _5748.specular;\n    float _6427 = _5748.ior;\n    float3 _6428 = _5748.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _6382, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _5740, short(gl_FrontFacing) };\n    Surface param_3 = _5748;\n    surface(param_2, param_3, points);\n    _6413 = param_3.albedo;\n    _6414 = param_3.alpha;\n    _6415 = param_3.normal;\n    _6416 = param_3.metallic;\n    _6417 = param_3.roughness;\n    _6418 = param_3.occlusion;\n    _6419 = param_3.emission;\n    _6420 = param_3.clearcoat;\n    _6421 = param_3.clearcoat_roughness;\n    _6422 = param_3.sheen_color;\n    _6423 = param_3.sheen_roughness;\n    _6424 = param_3.anisotropy;\n    _6425 = param_3.anisotropy_rotation;\n    _6426 = param_3.specular;\n    _6427 = param_3.ior;\n    _6428 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _6382;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _485, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _6413 = param_6;\n    _6415 = param_7;\n    float3 result;\n    if (_485.fa_emissive.w > 0.5)\n    {\n        result = _6413;\n    }\n    else\n    {\n        float3 _5787 = fast::normalize(_6415);\n        float _5794 = fast::clamp(_6416, 0.0, 1.0);\n        float _5798 = fast::clamp(_6417, 0.0500000007450580596923828125, 1.0);\n        float _5802 = _5798 * _5798;\n        float _5806 = _5802 * _5802;\n        float _5811 = fast::max(dot(_5787, _5740), 9.9999997473787516355514526367188e-05);\n        float3 _5817 = _6413 * (1.0 - _5794);\n        float3 _5824 = mix(float3(0.039999999105930328369140625), _6413, float3(_5794));\n        float3 f0 = _5824;\n        SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _6382, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _5740, short(gl_FrontFacing) };\n        Surface param_9 = Surface{ _6413, _6414, _6415, _6416, _6417, _6418, _6419, _6420, _6421, _6422, _6423, _6424, _6425, _6426, _6427, _6428 };\n        float3 param_10 = _5787;\n        float3 param_11 = _5740;\n        float param_12 = _5794;\n        float param_13 = _5798;\n        float3 param_14 = _5824;\n        FaLayers _5840 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _5787;\n        float3 lit = (fa_indirect_diffuse(param_15, _485, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap) * _5817) * _6418;\n        if (_5840.on)\n        {\n            lit *= _5840.base_scale;\n        }\n        int _5862 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5862; ln++)\n        {\n            int param_16 = ln;\n            int _5875 = fa_cl_light(param_16, _485, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            bool _5878 = in.fa_lm.z > 0.5;\n            bool _5884;\n            if (_5878)\n            {\n                int param_17 = _5875;\n                _5884 = fa_light_baked(param_17, _485, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _5884 = _5878;\n            }\n            if (_5884)\n            {\n                continue;\n            }\n            int param_18 = _5875;\n            float3 param_19 = in.fa_world_pos;\n            float3 param_20 = _6382;\n            LightSample _5896 = fa_light_shadowed(param_18, param_19, param_20, _485, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2202, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            float _5904 = fast::max(dot(_5787, _5896.direction), 0.0);\n            float _5910 = _5896.attenuation * _5896.shadow;\n            float3 _5915 = fast::normalize(_5896.direction + _5740);\n            float _5920 = fast::max(dot(_5787, _5915), 0.0);\n            float _5925 = fast::max(dot(_5740, _5915), 0.0);\n            bool _5932;\n            if (fa_light_is_area)\n            {\n                _5932 = !_5840.on;\n            }\n            else\n            {\n                _5932 = fa_light_is_area;\n            }\n            if (_5932)\n            {\n                int param_21 = _5875;\n                float3 param_22 = in.fa_world_pos;\n                float3 param_23 = _5787;\n                float3 param_24 = _5740;\n                float3 param_25 = _5817;\n                float3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _5798;\n                float param_29 = _5811;\n                float param_30 = _5910;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, _485, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _5840;\n                    int param_32 = _5875;\n                    float3 param_33 = in.fa_world_pos;\n                    float3 param_34 = _5787;\n                    float3 param_35 = _5740;\n                    float3 param_36 = _5896.direction;\n                    float3 param_37 = _5817;\n                    float3 param_38 = f0;\n                    float param_39 = _5798;\n                    float param_40 = _5811;\n                    float param_41 = _5910;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41, _485, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp);\n                }\n                else\n                {\n                    if (_5840.on)\n                    {\n                        FaLayers param_42 = _5840;\n                        float3 param_43 = _5817;\n                        float3 param_44 = f0;\n                        float3 param_45 = _5787;\n                        float3 param_46 = _5740;\n                        float3 param_47 = _5896.direction;\n                        float3 param_48 = _5915;\n                        float param_49 = _5904;\n                        float param_50 = _5811;\n                        float param_51 = _5920;\n                        float param_52 = _5925;\n                        float param_53 = _5802;\n                        float param_54 = _5806;\n                        int param_55 = _5875;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55, _485, fa_light_tex, fa_shadow_smp) * fa_light_tint) * _5910));\n                    }\n                    else\n                    {\n                        float _6038 = ((_5920 * _5920) * (_5806 - 1.0)) + 1.0;\n                        int param_56 = _5875;\n                        lit += (((_5817 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _5925, 5.0))) * (((_5806 / ((3.1415927410125732421875 * _6038) * _6038)) * (0.5 / fast::max(mix((2.0 * _5904) * _5811, _5904 + _5811, _5802), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5904))) * (fa_light_rgb(param_56, _485, fa_light_tex, fa_shadow_smp) * fa_light_tint)) * (_5904 * _5910));\n                    }\n                }\n            }\n        }\n        if (_5840.on)\n        {\n            FaLayers param_57 = _5840;\n            float3 param_58 = _5787;\n            float3 param_59 = _5740;\n            float3 param_60 = f0;\n            float param_61 = _5798;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61, _485, fa_env_smp, fa_env_tex) * _6418);\n        }\n        else\n        {\n            float3 param_62 = _5787;\n            float3 param_63 = _5740;\n            float3 param_64 = f0;\n            float param_65 = _5798;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65, _485, fa_env_smp, fa_env_tex) * _6418);\n        }\n        result = lit;\n    }\n    float3 _6133 = result;\n    float3 _6134 = _6133 + _6419;\n    result = _6134;\n    float3 param_66 = _6134;\n    float3 param_67 = in.fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67, _2202);\n    bool _6143 = _485.fa_fog.w > 0.0;\n    bool _6150;\n    if (!_6143)\n    {\n        _6150 = _485.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _6150 = _6143;\n    }\n    if (_6150)\n    {\n        float3 _6159 = in.fa_world_pos - _485.fa_camera_pos.xyz;\n        float _6165 = dot(_6159, _485.fa_fog_c.xyz);\n        bool _6169 = _485.fa_fog_c.w > 0.5;\n        float _6170;\n        if (_6169)\n        {\n            _6170 = _6165;\n        }\n        else\n        {\n            _6170 = length(_6159);\n        }\n        float _6182 = _6170 - _485.fa_fog_b.x;\n        if (_6182 > 0.0)\n        {\n            float _6191 = _485.fa_fog.w * _6182;\n            float tau = _6191 * _6191;\n            if (_485.fa_fog_b.y > 0.0)\n            {\n                float _6207;\n                if (_6169)\n                {\n                    _6207 = in.fa_world_pos.y - (_485.fa_fog_c.y * _6165);\n                }\n                else\n                {\n                    _6207 = _485.fa_camera_pos.y;\n                }\n                float _6228 = mix(_6207, in.fa_world_pos.y, fast::clamp(_485.fa_fog_b.x / _6170, 0.0, 1.0));\n                float _6232 = in.fa_world_pos.y - _6228;\n                float _6237 = _6228 - _485.fa_fog_b.z;\n                float _6242 = in.fa_world_pos.y - _485.fa_fog_b.z;\n                bool _6245 = _6237 <= 0.0;\n                bool _6246 = !_6245;\n                bool _6252;\n                if (_6246)\n                {\n                    _6252 = _485.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6252 = _6245;\n                }\n                float _6253;\n                if (_6252)\n                {\n                    _6253 = _485.fa_fog_b.y;\n                }\n                else\n                {\n                    _6253 = _485.fa_fog_b.y * exp(-fast::min(_485.fa_fog_b.w * _6237, 80.0));\n                }\n                bool _6280;\n                if (_6246)\n                {\n                    _6280 = _485.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6280 = _6245;\n                }\n                float _6281;\n                if (_6280)\n                {\n                    _6281 = _485.fa_fog_b.y * _6237;\n                }\n                else\n                {\n                    _6281 = (_485.fa_fog_b.y * (1.0 - exp(-fast::min(_485.fa_fog_b.w * _6237, 80.0)))) / _485.fa_fog_b.w;\n                }\n                bool _6306 = _6242 <= 0.0;\n                bool _6313;\n                if (!_6306)\n                {\n                    _6313 = _485.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6313 = _6306;\n                }\n                float _6314;\n                if (_6313)\n                {\n                    _6314 = _485.fa_fog_b.y * _6242;\n                }\n                else\n                {\n                    _6314 = (_485.fa_fog_b.y * (1.0 - exp(-fast::min(_485.fa_fog_b.w * _6242, 80.0)))) / _485.fa_fog_b.w;\n                }\n                float _6341;\n                if (abs(_6232) < 0.001000000047497451305389404296875)\n                {\n                    _6341 = _6253;\n                }\n                else\n                {\n                    _6341 = (_6314 - _6281) / _6232;\n                }\n                tau += (_6182 * fast::max(_6341, 0.0));\n            }\n            result = mix(result, _485.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _6414);\n    return out;\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_485",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2202",
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
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 9
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
              "msl_texture_n": 10
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
              "msl_texture_n": 11
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
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
          },
          {
            "slot": 11,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _168)\n{\n    float3 _109 = cross(model[1].xyz, model[2].xyz);\n    float _114 = (dot(model[0].xyz, _109) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_109 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _114, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _114), texcoord0 * _168.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex)\n{\n    if (fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, constant fa_mesh_vs_params& _168, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _168);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex);\n    float4 _210 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_168.fa_light_vp * _210).z;\n    fa_pre_r0 = float3(_168.fa_light_vp[0].x, _168.fa_light_vp[1].x, _168.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_168.fa_light_vp[0].y, _168.fa_light_vp[1].y, _168.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_168.fa_light_vp[0].z, _168.fa_light_vp[1].z, _168.fa_light_vp[2].z);\n    gl_Position = _168.fa_view_proj * _210;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _168 [[buffer(0)]], constant fa_inst_base& _272 [[buffer(6)]], const device fa_vs_points_buf& fa_vs_points [[buffer(8)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = _272.fa_base_model;\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, fa_vs_points, gl_InstanceIndex, _168, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _231, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _231.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _750 = base_t;\n    _750.x = _242.x;\n    _750.y = _242.y;\n    _750.z = _242.z;\n    base_t = _750;\n    float4 _257 = (_750 * _231.fa_base_color) * i.vertex_color;\n    float3 _713 = i.world_normal;\n    if (_231.fa_maps.z > 0.5)\n    {\n        float param_4 = _231.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _290 = fa_tex_fix(param_6, param_7);\n        float3 _294 = (_290 * 2.0) - float3(1.0);\n        float2 _299 = _294.xy * _231.fa_maps.x;\n        float3 _758 = _294;\n        _758.x = _299.x;\n        _758.y = _299.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _758;\n        _713 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _231.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _328 = fa_tex_fix(param_12, param_13);\n    float4 _761 = mrt;\n    _761.x = _328.x;\n    _761.y = _328.y;\n    _761.z = _328.z;\n    mrt = _761;\n    float4 _358 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _231.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = _231.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _400 = fa_tex_fix(param_20, param_21);\n    float _718 = _231.fa_layers_a.x;\n    float _719 = _231.fa_layers_a.y;\n    float _722 = _231.fa_layers_a.z;\n    float _721 = _231.fa_layers_b.w;\n    float _724 = _231.fa_layers_c.x;\n    if (_231.fa_layers_c.z > 0.5)\n    {\n        if (mod(_231.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _718 *= _370.y;\n            _719 *= _370.z;\n            _721 *= _358.w;\n        }\n        if (_231.fa_layers_c.z > 1.5)\n        {\n            _722 *= mrt.x;\n            _724 *= mrt.w;\n        }\n    }\n    return Surface{ _257.xyz, _257.w, _713, fast::clamp(_231.fa_pbr.x * _328.z, 0.0, 1.0), fast::clamp(_231.fa_pbr.y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_231.fa_maps.y * (_370.x - 1.0)), _231.fa_emissive.xyz + (_231.fa_model_emissive.xyz * _400), _718, _719, _231.fa_layers_b.xyz, _721, _722, _231.fa_layers_a.w, _724, _231.fa_layers_c.y, _231.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, const device fa_points_buf& points)\n{\n    s.emission += (i.vertex_color.xyz * ((device float*)&points.data[0].tint)[3u]);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _231 [[buffer(1)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _624 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _624 = -_624;\n    }\n    float3 _534 = fast::normalize(_231.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _624, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _534, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _624, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _534, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _231, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, points);\n    float3 _549 = fast::normalize(param_2.normal);\n    float3 _564 = fast::normalize(float3(dot(in.fa_pre_r0, _549), dot(in.fa_pre_r1, _549), dot(in.fa_pre_r2, _549)));\n    float _576 = _564.z;\n    float2 e = _564.xy / float2((abs(_564.x) + abs(_564.y)) + abs(_576));\n    if (_576 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct fa_inst_base\n{\n    float4x4 fa_base_model;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _217)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _208 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_217.fa_joint_rows[_208] * weights[i]);\n        r1 += (_217.fa_joint_rows[_208 + 1] * weights[i]);\n        r2 += (_217.fa_joint_rows[_208 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _173)\n{\n    float3 _114 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _114) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_114 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * _173.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex)\n{\n    if (fa_vs_points.data[int(gl_InstanceIndex)].pos.w < 0.5)\n    {\n        v.world_pos = float3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[int(gl_InstanceIndex)].pos.xyz;\n    v.color = fa_vs_points.data[int(gl_InstanceIndex)].tint;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, constant fa_mesh_vs_params& _173, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _173);\n    vertex0(param_6, fa_vs_points, gl_InstanceIndex);\n    float4 _322 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_173.fa_light_vp * _322).z;\n    fa_pre_r0 = float3(_173.fa_light_vp[0].x, _173.fa_light_vp[1].x, _173.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_173.fa_light_vp[0].y, _173.fa_light_vp[1].y, _173.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_173.fa_light_vp[0].z, _173.fa_light_vp[1].z, _173.fa_light_vp[2].z);\n    gl_Position = _173.fa_view_proj * _322;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _173 [[buffer(0)]], constant fa_skin& _217 [[buffer(3)]], constant fa_inst_base& _384 [[buffer(6)]], const device fa_vs_points_buf& fa_vs_points [[buffer(8)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = _384.fa_base_model * fa_skin_matrix(param, param_1, _217);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, fa_vs_points, gl_InstanceIndex, _173, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _231, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _231.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _750 = base_t;\n    _750.x = _242.x;\n    _750.y = _242.y;\n    _750.z = _242.z;\n    base_t = _750;\n    float4 _257 = (_750 * _231.fa_base_color) * i.vertex_color;\n    float3 _713 = i.world_normal;\n    if (_231.fa_maps.z > 0.5)\n    {\n        float param_4 = _231.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _290 = fa_tex_fix(param_6, param_7);\n        float3 _294 = (_290 * 2.0) - float3(1.0);\n        float2 _299 = _294.xy * _231.fa_maps.x;\n        float3 _758 = _294;\n        _758.x = _299.x;\n        _758.y = _299.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _758;\n        _713 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _231.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _328 = fa_tex_fix(param_12, param_13);\n    float4 _761 = mrt;\n    _761.x = _328.x;\n    _761.y = _328.y;\n    _761.z = _328.z;\n    mrt = _761;\n    float4 _358 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _231.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = _231.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _400 = fa_tex_fix(param_20, param_21);\n    float _718 = _231.fa_layers_a.x;\n    float _719 = _231.fa_layers_a.y;\n    float _722 = _231.fa_layers_a.z;\n    float _721 = _231.fa_layers_b.w;\n    float _724 = _231.fa_layers_c.x;\n    if (_231.fa_layers_c.z > 0.5)\n    {\n        if (mod(_231.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _718 *= _370.y;\n            _719 *= _370.z;\n            _721 *= _358.w;\n        }\n        if (_231.fa_layers_c.z > 1.5)\n        {\n            _722 *= mrt.x;\n            _724 *= mrt.w;\n        }\n    }\n    return Surface{ _257.xyz, _257.w, _713, fast::clamp(_231.fa_pbr.x * _328.z, 0.0, 1.0), fast::clamp(_231.fa_pbr.y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_231.fa_maps.y * (_370.x - 1.0)), _231.fa_emissive.xyz + (_231.fa_model_emissive.xyz * _400), _718, _719, _231.fa_layers_b.xyz, _721, _722, _231.fa_layers_a.w, _724, _231.fa_layers_c.y, _231.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, const device fa_points_buf& points)\n{\n    s.emission += (i.vertex_color.xyz * ((device float*)&points.data[0].tint)[3u]);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _231 [[buffer(1)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _624 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _624 = -_624;\n    }\n    float3 _534 = fast::normalize(_231.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _624, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _534, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _624, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _534, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _231, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, points);\n    float3 _549 = fast::normalize(param_2.normal);\n    float3 _564 = fast::normalize(float3(dot(in.fa_pre_r0, _549), dot(in.fa_pre_r1, _549), dot(in.fa_pre_r2, _549)));\n    float _576 = _564.z;\n    float2 e = _564.xy / float2((abs(_564.x) + abs(_564.y)) + abs(_576));\n    if (_576 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
