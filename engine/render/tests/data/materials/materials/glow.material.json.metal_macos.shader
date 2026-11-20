{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "cdeb0668828214c74f0c30d588a05ff792b9d23c1a6a8d04f213c29c73527515",
  "slang": "metal_macos",
  "params": [
    "glow"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_270, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float4 glow;\n};\n\nconstant spvUnsafeArray<float, 63> _2747 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555)\n{\n    bool _560 = _555.fa_cl_info.x < 0.0;\n    bool _567;\n    if (!_560)\n    {\n        _567 = _555.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _567 = _560;\n    }\n    bool _575;\n    if (!_567)\n    {\n        _575 = _555.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _575 = _567;\n    }\n    bool _582;\n    if (!_575)\n    {\n        _582 = _555.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _582 = _575;\n    }\n    bool _589;\n    if (!_582)\n    {\n        _589 = _555.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _589 = _582;\n    }\n    if (_589)\n    {\n        return float4(0.0);\n    }\n    float4 _599 = float4(world_pos, 1.0);\n    float _606 = dot(_555.fa_cl_vpw, _599);\n    if (!(_606 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _628 = float2(dot(_555.fa_cl_vpx, _599), dot(_555.fa_cl_vpy, _599)) / float2(_606);\n    int _632 = int(_555.fa_cl_grid.x);\n    int _636 = int(_555.fa_cl_grid.y);\n    int param = (int(_555.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_555.fa_cl_fwd.xyz, world_pos) + _555.fa_cl_fwd.w, _555.fa_cl_grid.w) / _555.fa_cl_grid.w) * _555.fa_cl_grid.z)), 0, int(_555.fa_cl_info.y) - 1) * _636) + clamp(int(floor(((_628.y * 0.5) + 0.5) * _555.fa_cl_grid.y)), 0, _636 - 1)) * _632)) + clamp(int(floor(((_628.x * 0.5) + 0.5) * _555.fa_cl_grid.x)), 0, _632 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555)\n{\n    float3 param = world_pos;\n    float4 _712 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _555);\n    return int2(int(_712.x), int(_712.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_555.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3811 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _555);\n    fa_cl_slot = _3811.x;\n    fa_cl_local = _3811.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _4013 = fa_linear_to_srgb(param);\n        c = _4013;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _4021 = fa_srgb_to_linear(param_1);\n            c = _4021;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _311;\n    if (bool(i.front_facing))\n    {\n        _311 = i.world_normal;\n    }\n    else\n    {\n        _311 = -i.world_normal;\n    }\n    float3 _335 = fast::normalize(i.world_tangent.xyz - (_311 * dot(_311, i.world_tangent.xyz)));\n    float3 _362 = fast::normalize(((_335 * m.x) + ((cross(_311, _335) * i.world_tangent.w) * m.y)) + (_311 * m.z));\n    float3 _365;\n    if (bool(i.front_facing))\n    {\n        _365 = _362;\n    }\n    else\n    {\n        _365 = -_362;\n    }\n    return _365;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _555, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _555.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4052 = fa_tex_fix(param_2, param_3);\n    float4 _5364 = base_t;\n    _5364.x = _4052.x;\n    _5364.y = _4052.y;\n    _5364.z = _4052.z;\n    base_t = _5364;\n    float4 _4066 = (_5364 * _555.fa_base_color) * i.vertex_color;\n    float3 _5218 = i.world_normal;\n    if (_555.fa_maps.z > 0.5)\n    {\n        float param_4 = _555.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4098 = fa_tex_fix(param_6, param_7);\n        float3 _4101 = (_4098 * 2.0) - float3(1.0);\n        float2 _4106 = _4101.xy * _555.fa_maps.x;\n        float3 _5372 = _4101;\n        _5372.x = _4106.x;\n        _5372.y = _4106.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5372;\n        _5218 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _555.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4135 = fa_tex_fix(param_12, param_13);\n    float4 _5375 = mrt;\n    _5375.x = _4135.x;\n    _5375.y = _4135.y;\n    _5375.z = _4135.z;\n    mrt = _5375;\n    float4 _4163 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _555.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _4163.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4175 = fa_tex_fix(param_16, param_17);\n    float param_18 = _555.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4205 = fa_tex_fix(param_20, param_21);\n    float _5223 = _555.fa_layers_a.x;\n    float _5224 = _555.fa_layers_a.y;\n    float _5227 = _555.fa_layers_a.z;\n    float _5226 = _555.fa_layers_b.w;\n    float _5229 = _555.fa_layers_c.x;\n    if (_555.fa_layers_c.z > 0.5)\n    {\n        if (mod(_555.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _5223 *= _4175.y;\n            _5224 *= _4175.z;\n            _5226 *= _4163.w;\n        }\n        if (_555.fa_layers_c.z > 1.5)\n        {\n            _5227 *= mrt.x;\n            _5229 *= mrt.w;\n        }\n    }\n    return Surface{ _4066.xyz, _4066.w, _5218, fast::clamp(_555.fa_pbr.x * _4135.z, 0.0, 1.0), fast::clamp(_555.fa_pbr.y * _4135.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_555.fa_maps.y * (_4175.x - 1.0)), _555.fa_emissive.xyz + (_555.fa_model_emissive.xyz * _4205), _5223, _5224, _555.fa_layers_b.xyz, _5226, _5227, _555.fa_layers_a.w, _5229, _555.fa_layers_c.y, _555.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, constant fa_material& _3966)\n{\n    s.emission += (_3966.glow.xyz * _3966.glow.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _793 = rect.zw - rect.xy;\n    float2 _797 = _793 * atlas;\n    float2 _801 = ddx * _797;\n    float2 _805 = ddy * _797;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _793)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_801, _801), dot(_805, _805)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _840 = _555.fa_counts.y < 0.5;\n    bool _847;\n    if (!_840)\n    {\n        _847 = _555.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _847 = _840;\n    }\n    if (_847)\n    {\n        return;\n    }\n    float3 _853 = dfdx(world_pos);\n    float3 _856 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _860 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _555);\n    int _864 = int(_860.w);\n    if (_864 < 1)\n    {\n        return;\n    }\n    int _874 = int(_555.fa_counts.y + 0.5);\n    int param_1 = _874;\n    float4 _878 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _881 = _878.yz;\n    int _885 = int(_878.w);\n    int param_2 = _874 + 1;\n    float4 _890 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _891 = _890.x;\n    int _897 = int(_555.fa_counts.w + 0.5) - 1;\n    int _901 = int(_860.z);\n    float3 _1167;\n    for (int k = 0; k < _864; k++)\n    {\n        int _914 = _901 + k;\n        int param_3 = _885 + (_914 >> 2);\n        int _932 = (_874 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_914 & 3]) * 7);\n        int param_4 = _932 + 6;\n        float4 _937 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_937.w + 0.5) >> _897) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _932;\n        float4 _952 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _932 + 1;\n        float4 _957 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _932 + 2;\n        float4 _962 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _965 = _952.xyz;\n        float _970 = dot(_965, world_pos) + _952.w;\n        float3 _972 = _957.xyz;\n        float _977 = dot(_972, world_pos) + _957.w;\n        float3 _979 = _962.xyz;\n        float _984 = dot(_979, world_pos) + _962.w;\n        bool _989 = abs(_970) > 0.5;\n        bool _997;\n        if (!_989)\n        {\n            _997 = abs(_977) > 0.5;\n        }\n        else\n        {\n            _997 = _989;\n        }\n        bool _1005;\n        if (!_997)\n        {\n            _1005 = abs(_984) > 0.5;\n        }\n        else\n        {\n            _1005 = _997;\n        }\n        if (_1005)\n        {\n            continue;\n        }\n        float _1020 = fast::clamp(dot(geo_normal, fast::normalize(_979)) * _937.z, 0.0, 1.0);\n        if (_1020 <= 0.0)\n        {\n            continue;\n        }\n        float _1040 = (fast::clamp((0.5 - abs(_984)) * 10.0, 0.0, 1.0) * _1020) * _937.x;\n        float2 _1048 = float2(_970 + 0.5, 0.5 - _977);\n        float2 _1058 = float2(dot(_965, _853), dot(_972, _853));\n        float2 _1068 = float2(dot(_965, _856), dot(_972, _856));\n        int param_8 = _932 + 5;\n        float4 _1073 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _932 + 3;\n        float4 _1078 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _932 + 4;\n        float4 _1083 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1073.xyz;\n        bool _1093 = _1078.z > _1078.x;\n        if (_1093)\n        {\n            float4 param_11 = _1078;\n            float2 param_12 = _1048;\n            float2 param_13 = _881;\n            float2 param_14 = _1058;\n            float2 param_15 = _1068;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_891 > 0.5) && (_891 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1119 = fa_dc_to_linear(param_16);\n                float4 _5274 = tx;\n                _5274.x = _1119.x;\n                _5274.y = _1119.y;\n                _5274.z = _1119.z;\n                tx = _5274;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1040 * tex_a) * _1073.w, 0.0, 1.0)));\n        if (_1083.z > _1083.x)\n        {\n            float4 param_17 = _1083;\n            float2 param_18 = _1048;\n            float2 param_19 = _881;\n            float2 param_20 = _1058;\n            float2 param_21 = _1068;\n            float4 _1163 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_891 > 1.5)\n            {\n                float3 param_22 = _1163.xyz;\n                float3 _1173 = fa_dc_to_srgb(param_22);\n                _1167 = _1173;\n            }\n            else\n            {\n                _1167 = _1163.xyz;\n            }\n            float3 _1183 = (_1167 * 2.0) - float3(1.0);\n            float2 _1188 = _1183.xy * _937.y;\n            float3 _1210 = (fast::normalize(_965) * _1188.x) + (fast::normalize(_972) * _1188.y);\n            float3 _1213 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1213, fast::normalize((_1213 * fast::max(_1183.z, 0.0500000007450580596923828125)) + (_1210 - (_1213 * dot(_1213, _1210)))), float3(fast::clamp(_1040 * (_1093 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _2673 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2680 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2683 = int(_2673);\n    int _2686 = int(_2680);\n    float _2696 = _2680 - float(_2686);\n    int _2751 = (_2683 * 9) + _2686;\n    int _2771 = ((_2683 + 1) * 9) + _2686;\n    return mix(mix(_2747[_2751], _2747[_2751 + 1], _2696), mix(_2747[_2771], _2747[_2771 + 1], _2696), _2673 - float(_2683));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _5141 = false;\n    float _5142 = 1.0;\n    float _5143 = 1.0;\n    float _5144 = 1.0;\n    float _5145 = 0.0;\n    float _5146 = 0.0;\n    float _5147 = 0.0;\n    float _5148 = 0.0;\n    float _5150 = 1.0;\n    bool _5151 = false;\n    float3 _5152 = float3(0.0);\n    float _5153 = 1.0;\n    float _5154 = 1.0;\n    float _5155 = 1.0;\n    float _5156 = 0.0;\n    float _5157 = 0.0;\n    float3 _5158 = float3(1.0, 0.0, 0.0);\n    float3 _5159 = float3(0.0, 0.0, 1.0);\n    float _5160 = 1.0;\n    float _5161 = 1.0;\n    float _2824 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2828 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2833 = (_2824 != 1.0) || (_2828 != 1.5);\n    bool _2843;\n    if (!_2833)\n    {\n        _2843 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2843 = _2833;\n    }\n    if (_2843)\n    {\n        float _2851 = (_2828 - 1.0) / (_2828 + 1.0);\n        f0 = mix(fast::min(float3(_2851 * _2851) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2824, s.albedo, float3(metallic));\n        _5142 = mix(_2824, 1.0, metallic);\n        _5141 = true;\n    }\n    float _2879 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2879 > 0.0)\n    {\n        float _2887 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5145 = _2879;\n        _5146 = _2887;\n        float _2894 = _2887 * _2887;\n        _5147 = _2894;\n        _5148 = _2894 * _2894;\n        float _2906 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5150 = _2906;\n        _5143 = 1.0 - (_2879 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2906, 0.0, 1.0), 5.0))));\n        _5141 = true;\n    }\n    float3 _2925 = fast::max(s.sheen_color, float3(0.0));\n    float _2934 = fast::max(_2925.x, fast::max(_2925.y, _2925.z));\n    if (_2934 > 0.0)\n    {\n        float _2942 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5151 = true;\n        _5152 = _2925;\n        _5153 = _2942;\n        _5154 = _2942 * _2942;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2942;\n        float _2959 = fa_sheen_albedo(param, param_1);\n        _5156 = _2959;\n        _5155 = 1.0 - fast::min(_2934 * _2959, 1.0);\n        _5141 = true;\n    }\n    _5144 = _5143 * _5155;\n    float _2978 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2978 != 0.0)\n    {\n        float3 _2993 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2993;\n        if (dot(_2993, _2993) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _3010 = t;\n        float3 _3011 = fast::normalize(_3010);\n        t = _3011;\n        float3 _3036 = fast::normalize((_3011 * cos(s.anisotropy_rotation)) + ((cross(n, _3011) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5158 = _3036;\n        _5159 = cross(n, _3036);\n        float _3046 = roughness * roughness;\n        float _3052 = mix(_3046, 1.0, _2978 * _2978);\n        bool _3054 = _2978 > 0.0;\n        _5160 = _3054 ? _3052 : _3046;\n        _5161 = _3054 ? _3046 : _3052;\n        _5157 = _2978;\n        _5141 = true;\n    }\n    return FaLayers{ short(_5141), _5142, _5143, _5144, _5145, _5146, _5147, _5148, i.world_normal, _5150, short(_5151), _5152, _5153, _5154, _5155, _5156, _5157, _5158, _5159, _5160, _5161 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_555.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _2430 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _2430;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_555.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _555, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _555.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _555, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555)\n{\n    int param = (int(_555.fa_cl_info.x) + int(_555.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _555);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _429 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _435 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _438 = _435.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _444 = _438 < 0.5;\n    float3 l;\n    if (_444)\n    {\n        l = fast::normalize(_429.xyz);\n    }\n    else\n    {\n        float3 _456 = _429.xyz - world_pos;\n        float _458 = length(_456);\n        dist = _458;\n        l = _456 / float3(fast::max(_458, 9.9999997473787516355514526367188e-05));\n        float _473 = _458 / fast::max(_429.w, 0.001000000047497451305389404296875);\n        float _479 = fast::clamp(1.0 - (_473 * _473), 0.0, 1.0);\n        atten = _479 * _479;\n        if (_438 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _493 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _503 = _493.w;\n            int param_3 = (li * 4) + 3;\n            float4 _509 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _510 = _509.x;\n            float cos_inner = _510;\n            if (_510 > 1.5)\n            {\n                cos_inner = mix(_503, 1.0, 0.25);\n            }\n            atten *= smoothstep(_503, cos_inner, dot(-l, fast::normalize(_493.xyz)));\n        }\n    }\n    int _541;\n    if (_444)\n    {\n        _541 = 0;\n    }\n    else\n    {\n        _541 = (_438 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _435.xyz * atten, atten, 1.0, dist, _541 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1295)\n{\n    float _1285;\n    if (i == 0)\n    {\n        _1285 = _1295.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1301;\n        if (i == 1)\n        {\n            _1301 = _1295.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1309;\n            if (i == 2)\n            {\n                _1309 = _1295.fa_shadow_split.z;\n            }\n            else\n            {\n                _1309 = _1295.fa_shadow_split.w;\n            }\n            _1301 = _1309;\n        }\n        _1285 = _1301;\n    }\n    return _1285;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1342 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1346;\n    if (conv.x < 0.5)\n    {\n        _1346 = _1342;\n    }\n    else\n    {\n        _1346 = (conv.y * conv.z) / (conv.z - (_1342 * (conv.z - conv.y)));\n    }\n    return _1346;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1273 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1273), sin(_1273)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1392 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1406 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1392;\n            float2 _1425 = fa_shadow_vogel(param_3, param_4, param_5) * _1406;\n            float2 param_6 = uv + (_1425 * _1295.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1437 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1437 < (zr - (length(_1425) * plane)))\n            {\n                sum += _1437;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1481 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1481; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1481;\n        float param_11 = _1392;\n        float2 _1500 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1500 * _1295.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1500) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1481);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex)\n{\n    float _1542 = fast::max(_1295.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1547 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1553 = sqrt(1.0 - (_1547 * _1547));\n    float _1560 = fast::min(_1553 / fast::max(_1547, 0.20000000298023223876953125), 4.0);\n    float _1565;\n    if (_1295.fa_shadow_bias.y > 0.0)\n    {\n        _1565 = _1295.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1565 = 1.5 * _1295.fa_shadow_info[ci].x;\n    }\n    float4 _1590 = _1295.fa_shadow_mat[ci] * float4(world + (n * (_1565 * _1553)), 1.0);\n    float _1597 = _1590.x;\n    bool _1600 = _1597 < _1295.fa_shadow_rect[ci].x;\n    bool _1609;\n    if (!_1600)\n    {\n        _1609 = _1597 > _1295.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1609 = _1600;\n    }\n    bool _1618;\n    if (!_1609)\n    {\n        _1618 = _1590.y < _1295.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1618 = _1609;\n    }\n    bool _1627;\n    if (!_1618)\n    {\n        _1627 = _1590.y > _1295.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1627 = _1618;\n    }\n    bool _1634;\n    if (!_1627)\n    {\n        _1634 = _1590.z > 1.0;\n    }\n    else\n    {\n        _1634 = _1627;\n    }\n    if (_1634)\n    {\n        return -1.0;\n    }\n    float _1643;\n    if (_1295.fa_shadow_bias.x > 0.0)\n    {\n        _1643 = _1295.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1643 = 1.5 * _1295.fa_shadow_info[ci].x;\n    }\n    float2 param = _1590.xy;\n    float4 param_1 = _1295.fa_shadow_rect[ci];\n    float param_2 = _1590.z - ((_1643 * (1.0 + (0.5 * _1560))) / _1542);\n    float param_3 = _1295.fa_shadow_info[ci].x;\n    float param_4 = _1542;\n    float param_5 = _1542 * 0.25;\n    float param_6 = ((_1295.fa_shadow_info[ci].x * fast::min(_1560, 3.0)) * 0.5) / _1542;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1295.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1295.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1295, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex)\n{\n    if (_555.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2070 = int(_1295.fa_shadow_cfg.x + 0.5);\n    if (_2070 < 1)\n    {\n        return 1.0;\n    }\n    float _2085 = dot(world - _1295.fa_shadow_eye.xyz, _1295.fa_shadow_fwd.xyz);\n    int param = _2070 - 1;\n    if (_2085 > fa_shadow_split_at(param, _1295))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2097 = _2070 > 1;\n    bool _2104;\n    if (_2097)\n    {\n        _2104 = _2085 > _1295.fa_shadow_split.x;\n    }\n    else\n    {\n        _2104 = _2097;\n    }\n    if (_2104)\n    {\n        ci = 1;\n    }\n    bool _2108 = _2070 > 2;\n    bool _2115;\n    if (_2108)\n    {\n        _2115 = _2085 > _1295.fa_shadow_split.y;\n    }\n    else\n    {\n        _2115 = _2108;\n    }\n    if (_2115)\n    {\n        ci = 2;\n    }\n    bool _2119 = _2070 > 3;\n    bool _2126;\n    if (_2119)\n    {\n        _2126 = _2085 > _1295.fa_shadow_split.z;\n    }\n    else\n    {\n        _2126 = _2119;\n    }\n    if (_2126)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2070)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2152 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1295, fa_shadow_tex);\n        s = _2152;\n        if (_2152 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1295.fa_shadow_cfg.y > 0.0)\n    {\n        float _2177;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2177 = fa_shadow_split_at(param_5, _1295);\n        }\n        else\n        {\n            _2177 = _1295.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2196 = _1295.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1295) - _2177, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2207 = fast::clamp((_2085 - (fa_shadow_split_at(param_7, _1295) - _2196)) / _2196, 0.0, 1.0);\n        if (_2207 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2070)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2228 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1295, fa_shadow_tex);\n                s2 = _2228;\n                if (_2228 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2207);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _555, gl_FragCoord, _1295, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex)\n{\n    bool _1701 = _555.fa_pbr.z < 0.5;\n    bool _1709;\n    if (!_1701)\n    {\n        _1709 = _1295.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1709 = _1701;\n    }\n    if (_1709)\n    {\n        return 1.0;\n    }\n    int param = (int(_1295.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1722 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1723 = _1722.x;\n    if (_1723 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1732 = int(_1723 + 0.5);\n    int param_1 = _1732;\n    float4 _1736 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1732 + 1;\n    float4 _1741 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1744 = _1736.y;\n    if (_1744 > 0.0)\n    {\n        float _1761 = 1.0 - smoothstep(0.75 * _1744, _1744, length(world - _1295.fa_shadow_eye.xyz));\n        fade = _1761;\n        if (_1761 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1736.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1780 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1783 = abs(_1780);\n        float _1785 = _1783.x;\n        float _1787 = _1783.y;\n        bool _1788 = _1785 >= _1787;\n        bool _1796;\n        if (_1788)\n        {\n            _1796 = _1785 >= _1783.z;\n        }\n        else\n        {\n            _1796 = _1788;\n        }\n        int _1797;\n        if (_1796)\n        {\n            _1797 = (_1780.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1810;\n            if (_1787 >= _1783.z)\n            {\n                _1810 = (_1780.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1810 = (_1780.z > 0.0) ? 4 : 5;\n            }\n            _1797 = _1810;\n        }\n        face = _1797;\n    }\n    int _1829 = (_1732 + 2) + (face * 6);\n    int param_4 = _1829;\n    int param_5 = _1829 + 1;\n    int param_6 = _1829 + 3;\n    float4 _1843 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1829 + 4;\n    float4 _1848 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1829 + 5;\n    float4 _1853 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1865 = _1853.x * fast::max(dot(_1843, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1870 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1893 = fast::clamp(dot(n, _1843.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1916 = fast::min(sqrt(1.0 - (_1893 * _1893)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1843, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1919 = _1741.y;\n    float _1921;\n    if (_1919 > 0.0)\n    {\n        _1921 = _1919;\n    }\n    else\n    {\n        _1921 = 1.5 * _1865;\n    }\n    float4 _1941 = float4(world + (n * (_1921 * sqrt(1.0 - (_1870 * _1870)))), 1.0);\n    float _1945 = dot(_1843, _1941);\n    float _1948 = _1853.y;\n    if (_1945 < _1948)\n    {\n        return 1.0;\n    }\n    float2 _1963 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1941), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1941)) / float2(_1945);\n    float _1965 = _1963.x;\n    bool _1968 = _1965 < _1848.x;\n    bool _1977;\n    if (!_1968)\n    {\n        _1977 = _1965 > _1848.z;\n    }\n    else\n    {\n        _1977 = _1968;\n    }\n    bool _1986;\n    if (!_1977)\n    {\n        _1986 = _1963.y < _1848.y;\n    }\n    else\n    {\n        _1986 = _1977;\n    }\n    bool _1995;\n    if (!_1986)\n    {\n        _1995 = _1963.y > _1848.w;\n    }\n    else\n    {\n        _1995 = _1986;\n    }\n    if (_1995)\n    {\n        return 1.0;\n    }\n    float _2001 = _1741.x;\n    float _2003;\n    if (_2001 > 0.0)\n    {\n        _2003 = _2001;\n    }\n    else\n    {\n        _2003 = 1.5 * _1865;\n    }\n    float2 param_10 = _1963;\n    float4 param_11 = _1848;\n    float param_12 = _1945 - (_2003 * (1.0 + (0.5 * _1916)));\n    float param_13 = _1865;\n    float param_14 = 1.0;\n    float param_15 = _1853.z * 0.25;\n    float param_16 = (_1865 * fast::min(_1916, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1948, _1853.z);\n    int param_18 = int(_1736.z + 0.5);\n    float param_19 = _1736.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1295, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_contact_shadow(thread const int& li, thread const float3& world, thread const float3& gn, thread const float3& l, thread const float& dist, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_screen_tex)\n{\n    bool _3553 = _555.fa_ct_a.x < 0.5;\n    bool _3560;\n    if (!_3553)\n    {\n        _3560 = _1295.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _3560 = _3553;\n    }\n    if (_3560)\n    {\n        return 1.0;\n    }\n    int param = (int(_1295.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _3573 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _3574 = _3573.y;\n    float len = _3574;\n    if (_3574 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3586 = length(world - _555.fa_camera_pos.xyz);\n    float _3596 = 1.0 - smoothstep(0.5 * _555.fa_ct_b.x, _555.fa_ct_b.x, _3586);\n    if (_3596 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3602 = len;\n    float _3605 = fast::min(_3602, 0.89999997615814208984375 * dist);\n    len = _3605;\n    float _3610 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3586);\n    float _3615 = _3610 + (0.5 * _3605);\n    float3 _3621 = world + (gn * _3610);\n    float _3623 = fa_shadow_noise(gl_FragCoord);\n    float occ = 0.0;\n    float _3687;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3638 = (float(k) + _3623) * 0.083333335816860198974609375;\n        float3 _3646 = _3621 + (l * (_3638 * len));\n        float4 _3652 = float4(_3646, 1.0);\n        float _3658 = dot(_555.fa_ct_vpw, _3652);\n        if (_3658 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        float2 _3678 = float2(dot(_555.fa_ct_vpx, _3652), dot(_555.fa_ct_vpy, _3652)) / float2(_3658);\n        float _3682 = _3678.x * 0.5;\n        float _3683 = _3682 + 0.5;\n        if (_555.fa_ct_a.y > 0.5)\n        {\n            _3687 = (_3678.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3687 = 0.5 - (_3678.y * 0.5);\n        }\n        bool _3703 = _3683 < 0.0;\n        bool _3710;\n        if (!_3703)\n        {\n            _3710 = _3683 >= 1.0;\n        }\n        else\n        {\n            _3710 = _3703;\n        }\n        bool _3717;\n        if (!_3710)\n        {\n            _3717 = _3687 < 0.0;\n        }\n        else\n        {\n            _3717 = _3710;\n        }\n        bool _3724;\n        if (!_3717)\n        {\n            _3724 = _3687 >= 1.0;\n        }\n        else\n        {\n            _3724 = _3717;\n        }\n        if (_3724)\n        {\n            break;\n        }\n        float4 _3743 = fa_screen_tex.read(uint2(int2(float2(_3683, _3687) * _555.fa_ct_a.zw)), 0);\n        if (_3743.w < 0.5)\n        {\n            continue;\n        }\n        float _3762 = (dot(_555.fa_ct_fwd.xyz, _3646) + _555.fa_ct_fwd.w) - _3743.x;\n        if ((_3762 > _3610) && (_3762 < _3615))\n        {\n            occ = fast::max(occ, (1.0 - (_3638 * _3638)) * smoothstep(0.0, 0.0500000007450580596923828125, fast::min(fast::min(_3683, 0.5 - _3682), fast::min(_3687, 1.0 - _3687))));\n        }\n    }\n    return 1.0 - (occ * _3596);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread float3& fa_lm)\n{\n    bool _3838 = fa_lm.z > 0.5;\n    bool _3844;\n    if (_3838)\n    {\n        int param = li;\n        _3844 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3844 = _3838;\n    }\n    if (_3844)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3866 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _5203 = _3866.direction;\n    float3 _5198 = _3866.color;\n    float _5205 = _3866.attenuation;\n    float _5200 = _3866.shadow;\n    float _5207 = _3866._distance;\n    int _5208 = _3866.type;\n    bool _3869 = _5208 == 0;\n    if (_3869 && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _5203;\n        float _3880 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _555, gl_FragCoord, _1295, fa_shadow_tex, fa_world_pos);\n        _5200 = _3880;\n        _5198 *= _3880;\n    }\n    else\n    {\n        bool _3891 = _5208 != 0;\n        bool _3897;\n        if (_3891)\n        {\n            _3897 = _5205 > 0.0;\n        }\n        else\n        {\n            _3897 = _3891;\n        }\n        if (_3897)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _5203;\n            float _3909 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _555, gl_FragCoord, _1295, fa_shadow_tex);\n            _5200 = _3909;\n            _5198 *= _3909;\n        }\n    }\n    bool _3919 = _555.fa_ct_a.x > 0.5;\n    bool _3925;\n    if (_3919)\n    {\n        _3925 = _5205 > 0.0;\n    }\n    else\n    {\n        _3925 = _3919;\n    }\n    if (_3925)\n    {\n        float _3932;\n        if (_3869)\n        {\n            _3932 = 1000000000.0;\n        }\n        else\n        {\n            _3932 = _5207;\n        }\n        int param_10 = li;\n        float3 param_11 = world_pos;\n        float3 param_12 = gn;\n        float3 param_13 = _5203;\n        float param_14 = _3932;\n        float _3950 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14, fa_light_tex, fa_shadow_smp, _555, gl_FragCoord, _1295, fa_screen_tex);\n        _5200 *= _3950;\n        _5198 *= _3950;\n    }\n    return LightSample{ _5203, _5198, _5205, _5200, _5207, _5208 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _3204 = tdh / at;\n    float _3208 = bdh / ab;\n    float _3220 = ((_3204 * _3204) + (_3208 * _3208)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3220) * _3220);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _3301 = 1.0 / alpha;\n    return ((2.0 + _3301) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3301)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _3333 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3412 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3412) * _3412);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3333);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3333));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3485 = fast::max(dot(L.nc, l), 0.0);\n        float _3491 = fast::max(dot(L.nc, h), 0.0);\n        float _3500 = ((_3491 * _3491) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3500) * _3500)) * (0.5 / fast::max(mix((2.0 * _3485) * L.coat_ndv, _3485 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3485)) * _3485);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _2605 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2608 = _2605.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_2608 * _2608, exp2((-9.27999973297119140625) * ndv)) * _2608) + _2605.y)) + _2605.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_555.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _555.fa_env_horizon.w)).xyz;\n    }\n    float _2459 = rough * rough;\n    float _2489 = 0.60000002384185791015625 * _2459;\n    return mix(mix(_555.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_555.fa_env_horizon.xyz, _555.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _2459)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _2489, 0.0500000007450580596923828125 + _2489, d.y))), ((_555.fa_env_sky.xyz + _555.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_2459 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _3087;\n        if (L.aniso >= 0.0)\n        {\n            _3087 = L.b;\n        }\n        else\n        {\n            _3087 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_3087, v), _3087), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3120 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _555, fa_env_smp, fa_env_tex) * ((f0 * _3120.x) + (float3(L.f90) * _3120.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _555, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3175 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _555, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _3175.x) + _3175.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2647 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _555, fa_env_smp, fa_env_tex) * ((f0 * _2647.x) + float3(_2647.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1295)\n{\n    if (_1295.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2252 = int(_1295.fa_shadow_cfg.x + 0.5);\n    float _2262 = dot(world - _1295.fa_shadow_eye.xyz, _1295.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2267 = _2252 > 0;\n    bool _2276;\n    if (_2267)\n    {\n        int param = _2252 - 1;\n        _2276 = _2262 <= fa_shadow_split_at(param, _1295);\n    }\n    else\n    {\n        _2276 = _2267;\n    }\n    if (_2276)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2283 = _2252 > 1;\n        bool _2290;\n        if (_2283)\n        {\n            _2290 = _2262 > _1295.fa_shadow_split.x;\n        }\n        else\n        {\n            _2290 = _2283;\n        }\n        if (_2290)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2296 = _2252 > 2;\n        bool _2303;\n        if (_2296)\n        {\n            _2303 = _2262 > _1295.fa_shadow_split.y;\n        }\n        else\n        {\n            _2303 = _2296;\n        }\n        if (_2303)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2309 = _2252 > 3;\n        bool _2316;\n        if (_2309)\n        {\n            _2316 = _2262 > _1295.fa_shadow_split.z;\n        }\n        else\n        {\n            _2316 = _2309;\n        }\n        if (_2316)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _555 [[buffer(1)]], constant fa_material& _3966 [[buffer(5)]], constant fa_shadows& _1295 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], texture2d<float> fa_screen_tex [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4920 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4920 = -_4920;\n    }\n    float3 _4345 = fast::normalize(_555.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _555, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4920, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4345, short(gl_FrontFacing) };\n    Surface _4353 = fa_standard_surface(param_1, _555, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4951 = _4353.albedo;\n    float _4952 = _4353.alpha;\n    float3 _4953 = _4353.normal;\n    float _4954 = _4353.metallic;\n    float _4955 = _4353.roughness;\n    float _4956 = _4353.occlusion;\n    float3 _4957 = _4353.emission;\n    float _4958 = _4353.clearcoat;\n    float _4959 = _4353.clearcoat_roughness;\n    float3 _4960 = _4353.sheen_color;\n    float _4961 = _4353.sheen_roughness;\n    float _4962 = _4353.anisotropy;\n    float _4963 = _4353.anisotropy_rotation;\n    float _4964 = _4353.specular;\n    float _4965 = _4353.ior;\n    float3 _4966 = _4353.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4920, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4345, short(gl_FrontFacing) };\n    Surface param_3 = _4353;\n    surface(param_2, param_3, _3966);\n    _4951 = param_3.albedo;\n    _4952 = param_3.alpha;\n    _4953 = param_3.normal;\n    _4954 = param_3.metallic;\n    _4955 = param_3.roughness;\n    _4956 = param_3.occlusion;\n    _4957 = param_3.emission;\n    _4958 = param_3.clearcoat;\n    _4959 = param_3.clearcoat_roughness;\n    _4960 = param_3.sheen_color;\n    _4961 = param_3.sheen_roughness;\n    _4962 = param_3.anisotropy;\n    _4963 = param_3.anisotropy_rotation;\n    _4964 = param_3.specular;\n    _4965 = param_3.ior;\n    _4966 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4920;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _555, fa_decal_tex, fa_env_smp);\n    _4951 = param_6;\n    _4953 = param_7;\n    float3 result;\n    if (_555.fa_emissive.w > 0.5)\n    {\n        result = _4951;\n    }\n    else\n    {\n        float3 _4392 = fast::normalize(_4953);\n        float _4399 = fast::clamp(_4954, 0.0, 1.0);\n        float _4403 = fast::clamp(_4955, 0.0500000007450580596923828125, 1.0);\n        float _4407 = _4403 * _4403;\n        float _4411 = _4407 * _4407;\n        float _4416 = fast::max(dot(_4392, _4345), 9.9999997473787516355514526367188e-05);\n        float3 _4422 = _4951 * (1.0 - _4399);\n        float3 _4429 = mix(float3(0.039999999105930328369140625), _4951, float3(_4399));\n        float3 f0 = _4429;\n        SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _4920, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4345, short(gl_FrontFacing) };\n        Surface param_9 = Surface{ _4951, _4952, _4953, _4954, _4955, _4956, _4957, _4958, _4959, _4960, _4961, _4962, _4963, _4964, _4965, _4966 };\n        float3 param_10 = _4392;\n        float3 param_11 = _4345;\n        float param_12 = _4399;\n        float param_13 = _4403;\n        float3 param_14 = _4429;\n        FaLayers _4445 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _4392;\n        float3 lit = (fa_indirect_diffuse(param_15, _555, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap) * _4422) * _4956;\n        if (_4445.on)\n        {\n            lit *= _4445.base_scale;\n        }\n        int _4467 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4467; ln++)\n        {\n            int param_16 = ln;\n            int _4480 = fa_cl_light(param_16, fa_light_tex, fa_shadow_smp, _555, fa_cl_ndir, fa_cl_slot);\n            bool _4483 = in.fa_lm.z > 0.5;\n            bool _4489;\n            if (_4483)\n            {\n                int param_17 = _4480;\n                _4489 = fa_light_baked(param_17, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _4489 = _4483;\n            }\n            if (_4489)\n            {\n                continue;\n            }\n            int param_18 = _4480;\n            float3 param_19 = in.fa_world_pos;\n            float3 param_20 = _4920;\n            LightSample _4501 = fa_light_shadowed(param_18, param_19, param_20, fa_light_tex, fa_shadow_smp, _555, gl_FragCoord, _1295, fa_shadow_tex, in.fa_world_pos, fa_screen_tex, in.fa_lm);\n            float3 _5125 = _4501.direction;\n            float _4509 = fast::max(dot(_4392, _5125), 0.0);\n            float _4515 = _4501.attenuation * _4501.shadow;\n            float3 _4520 = fast::normalize(_5125 + _4345);\n            float _4525 = fast::max(dot(_4392, _4520), 0.0);\n            float _4530 = fast::max(dot(_4345, _4520), 0.0);\n            if (_4445.on)\n            {\n                FaLayers param_21 = _4445;\n                float3 param_22 = _4422;\n                float3 param_23 = f0;\n                float3 param_24 = _4392;\n                float3 param_25 = _4345;\n                float3 param_26 = _5125;\n                float3 param_27 = _4520;\n                float param_28 = _4509;\n                float param_29 = _4416;\n                float param_30 = _4525;\n                float param_31 = _4530;\n                float param_32 = _4407;\n                float param_33 = _4411;\n                int param_34 = _4480;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34, fa_light_tex, fa_shadow_smp) * _4515));\n            }\n            else\n            {\n                float _4578 = ((_4525 * _4525) * (_4411 - 1.0)) + 1.0;\n                int param_35 = _4480;\n                lit += (((_4422 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _4530, 5.0))) * (((_4411 / ((3.1415927410125732421875 * _4578) * _4578)) * (0.5 / fast::max(mix((2.0 * _4509) * _4416, _4509 + _4416, _4407), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4509))) * fa_light_rgb(param_35, fa_light_tex, fa_shadow_smp)) * (_4509 * _4515));\n            }\n        }\n        if (_4445.on)\n        {\n            FaLayers param_36 = _4445;\n            float3 param_37 = _4392;\n            float3 param_38 = _4345;\n            float3 param_39 = f0;\n            float param_40 = _4403;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40, _555, fa_env_smp, fa_env_tex) * _4956);\n        }\n        else\n        {\n            float3 param_41 = _4392;\n            float3 param_42 = _4345;\n            float3 param_43 = f0;\n            float param_44 = _4403;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44, _555, fa_env_smp, fa_env_tex) * _4956);\n        }\n        result = lit;\n    }\n    float3 _4671 = result;\n    float3 _4672 = _4671 + _4957;\n    result = _4672;\n    float3 param_45 = _4672;\n    float3 param_46 = in.fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46, _1295);\n    bool _4681 = _555.fa_fog.w > 0.0;\n    bool _4688;\n    if (!_4681)\n    {\n        _4688 = _555.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4688 = _4681;\n    }\n    if (_4688)\n    {\n        float3 _4697 = in.fa_world_pos - _555.fa_camera_pos.xyz;\n        float _4703 = dot(_4697, _555.fa_fog_c.xyz);\n        bool _4707 = _555.fa_fog_c.w > 0.5;\n        float _4708;\n        if (_4707)\n        {\n            _4708 = _4703;\n        }\n        else\n        {\n            _4708 = length(_4697);\n        }\n        float _4720 = _4708 - _555.fa_fog_b.x;\n        if (_4720 > 0.0)\n        {\n            float _4729 = _555.fa_fog.w * _4720;\n            float tau = _4729 * _4729;\n            if (_555.fa_fog_b.y > 0.0)\n            {\n                float _4745;\n                if (_4707)\n                {\n                    _4745 = in.fa_world_pos.y - (_555.fa_fog_c.y * _4703);\n                }\n                else\n                {\n                    _4745 = _555.fa_camera_pos.y;\n                }\n                float _4766 = mix(_4745, in.fa_world_pos.y, fast::clamp(_555.fa_fog_b.x / _4708, 0.0, 1.0));\n                float _4770 = in.fa_world_pos.y - _4766;\n                float _4775 = _4766 - _555.fa_fog_b.z;\n                float _4780 = in.fa_world_pos.y - _555.fa_fog_b.z;\n                bool _4783 = _4775 <= 0.0;\n                bool _4784 = !_4783;\n                bool _4790;\n                if (_4784)\n                {\n                    _4790 = _555.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4790 = _4783;\n                }\n                float _4791;\n                if (_4790)\n                {\n                    _4791 = _555.fa_fog_b.y;\n                }\n                else\n                {\n                    _4791 = _555.fa_fog_b.y * exp(-fast::min(_555.fa_fog_b.w * _4775, 80.0));\n                }\n                bool _4818;\n                if (_4784)\n                {\n                    _4818 = _555.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4818 = _4783;\n                }\n                float _4819;\n                if (_4818)\n                {\n                    _4819 = _555.fa_fog_b.y * _4775;\n                }\n                else\n                {\n                    _4819 = (_555.fa_fog_b.y * (1.0 - exp(-fast::min(_555.fa_fog_b.w * _4775, 80.0)))) / _555.fa_fog_b.w;\n                }\n                bool _4844 = _4780 <= 0.0;\n                bool _4851;\n                if (!_4844)\n                {\n                    _4851 = _555.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4851 = _4844;\n                }\n                float _4852;\n                if (_4851)\n                {\n                    _4852 = _555.fa_fog_b.y * _4780;\n                }\n                else\n                {\n                    _4852 = (_555.fa_fog_b.y * (1.0 - exp(-fast::min(_555.fa_fog_b.w * _4780, 80.0)))) / _555.fa_fog_b.w;\n                }\n                float _4879;\n                if (abs(_4770) < 0.001000000047497451305389404296875)\n                {\n                    _4879 = _4791;\n                }\n                else\n                {\n                    _4879 = (_4852 - _4819) / _4770;\n                }\n                tau += (_4720 * fast::max(_4879, 0.0));\n            }\n            result = mix(result, _555.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4952);\n    return out;\n}\n\n",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3966",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_391, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float4 glow;\n};\n\nconstant spvUnsafeArray<float, 63> _2747 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555)\n{\n    bool _560 = _555.fa_cl_info.x < 0.0;\n    bool _567;\n    if (!_560)\n    {\n        _567 = _555.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _567 = _560;\n    }\n    bool _575;\n    if (!_567)\n    {\n        _575 = _555.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _575 = _567;\n    }\n    bool _582;\n    if (!_575)\n    {\n        _582 = _555.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _582 = _575;\n    }\n    bool _589;\n    if (!_582)\n    {\n        _589 = _555.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _589 = _582;\n    }\n    if (_589)\n    {\n        return float4(0.0);\n    }\n    float4 _599 = float4(world_pos, 1.0);\n    float _606 = dot(_555.fa_cl_vpw, _599);\n    if (!(_606 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _628 = float2(dot(_555.fa_cl_vpx, _599), dot(_555.fa_cl_vpy, _599)) / float2(_606);\n    int _632 = int(_555.fa_cl_grid.x);\n    int _636 = int(_555.fa_cl_grid.y);\n    int param = (int(_555.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_555.fa_cl_fwd.xyz, world_pos) + _555.fa_cl_fwd.w, _555.fa_cl_grid.w) / _555.fa_cl_grid.w) * _555.fa_cl_grid.z)), 0, int(_555.fa_cl_info.y) - 1) * _636) + clamp(int(floor(((_628.y * 0.5) + 0.5) * _555.fa_cl_grid.y)), 0, _636 - 1)) * _632)) + clamp(int(floor(((_628.x * 0.5) + 0.5) * _555.fa_cl_grid.x)), 0, _632 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555)\n{\n    float3 param = world_pos;\n    float4 _712 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _555);\n    return int2(int(_712.x), int(_712.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_555.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3811 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _555);\n    fa_cl_slot = _3811.x;\n    fa_cl_local = _3811.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _4013 = fa_linear_to_srgb(param);\n        c = _4013;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _4021 = fa_srgb_to_linear(param_1);\n            c = _4021;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _311;\n    if (bool(i.front_facing))\n    {\n        _311 = i.world_normal;\n    }\n    else\n    {\n        _311 = -i.world_normal;\n    }\n    float3 _335 = fast::normalize(i.world_tangent.xyz - (_311 * dot(_311, i.world_tangent.xyz)));\n    float3 _362 = fast::normalize(((_335 * m.x) + ((cross(_311, _335) * i.world_tangent.w) * m.y)) + (_311 * m.z));\n    float3 _365;\n    if (bool(i.front_facing))\n    {\n        _365 = _362;\n    }\n    else\n    {\n        _365 = -_362;\n    }\n    return _365;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _555, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _555.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4052 = fa_tex_fix(param_2, param_3);\n    float4 _5364 = base_t;\n    _5364.x = _4052.x;\n    _5364.y = _4052.y;\n    _5364.z = _4052.z;\n    base_t = _5364;\n    float4 _4066 = (_5364 * _555.fa_base_color) * i.vertex_color;\n    float3 _5218 = i.world_normal;\n    if (_555.fa_maps.z > 0.5)\n    {\n        float param_4 = _555.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4098 = fa_tex_fix(param_6, param_7);\n        float3 _4101 = (_4098 * 2.0) - float3(1.0);\n        float2 _4106 = _4101.xy * _555.fa_maps.x;\n        float3 _5372 = _4101;\n        _5372.x = _4106.x;\n        _5372.y = _4106.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5372;\n        _5218 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _555.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4135 = fa_tex_fix(param_12, param_13);\n    float4 _5375 = mrt;\n    _5375.x = _4135.x;\n    _5375.y = _4135.y;\n    _5375.z = _4135.z;\n    mrt = _5375;\n    float4 _4163 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _555.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _4163.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4175 = fa_tex_fix(param_16, param_17);\n    float param_18 = _555.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4205 = fa_tex_fix(param_20, param_21);\n    float _5223 = _555.fa_layers_a.x;\n    float _5224 = _555.fa_layers_a.y;\n    float _5227 = _555.fa_layers_a.z;\n    float _5226 = _555.fa_layers_b.w;\n    float _5229 = _555.fa_layers_c.x;\n    if (_555.fa_layers_c.z > 0.5)\n    {\n        if (mod(_555.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _5223 *= _4175.y;\n            _5224 *= _4175.z;\n            _5226 *= _4163.w;\n        }\n        if (_555.fa_layers_c.z > 1.5)\n        {\n            _5227 *= mrt.x;\n            _5229 *= mrt.w;\n        }\n    }\n    return Surface{ _4066.xyz, _4066.w, _5218, fast::clamp(_555.fa_pbr.x * _4135.z, 0.0, 1.0), fast::clamp(_555.fa_pbr.y * _4135.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_555.fa_maps.y * (_4175.x - 1.0)), _555.fa_emissive.xyz + (_555.fa_model_emissive.xyz * _4205), _5223, _5224, _555.fa_layers_b.xyz, _5226, _5227, _555.fa_layers_a.w, _5229, _555.fa_layers_c.y, _555.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, constant fa_material& _3966)\n{\n    s.emission += (_3966.glow.xyz * _3966.glow.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _793 = rect.zw - rect.xy;\n    float2 _797 = _793 * atlas;\n    float2 _801 = ddx * _797;\n    float2 _805 = ddy * _797;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _793)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_801, _801), dot(_805, _805)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _840 = _555.fa_counts.y < 0.5;\n    bool _847;\n    if (!_840)\n    {\n        _847 = _555.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _847 = _840;\n    }\n    if (_847)\n    {\n        return;\n    }\n    float3 _853 = dfdx(world_pos);\n    float3 _856 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _860 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _555);\n    int _864 = int(_860.w);\n    if (_864 < 1)\n    {\n        return;\n    }\n    int _874 = int(_555.fa_counts.y + 0.5);\n    int param_1 = _874;\n    float4 _878 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _881 = _878.yz;\n    int _885 = int(_878.w);\n    int param_2 = _874 + 1;\n    float4 _890 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _891 = _890.x;\n    int _897 = int(_555.fa_counts.w + 0.5) - 1;\n    int _901 = int(_860.z);\n    float3 _1167;\n    for (int k = 0; k < _864; k++)\n    {\n        int _914 = _901 + k;\n        int param_3 = _885 + (_914 >> 2);\n        int _932 = (_874 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_914 & 3]) * 7);\n        int param_4 = _932 + 6;\n        float4 _937 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_937.w + 0.5) >> _897) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _932;\n        float4 _952 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _932 + 1;\n        float4 _957 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _932 + 2;\n        float4 _962 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _965 = _952.xyz;\n        float _970 = dot(_965, world_pos) + _952.w;\n        float3 _972 = _957.xyz;\n        float _977 = dot(_972, world_pos) + _957.w;\n        float3 _979 = _962.xyz;\n        float _984 = dot(_979, world_pos) + _962.w;\n        bool _989 = abs(_970) > 0.5;\n        bool _997;\n        if (!_989)\n        {\n            _997 = abs(_977) > 0.5;\n        }\n        else\n        {\n            _997 = _989;\n        }\n        bool _1005;\n        if (!_997)\n        {\n            _1005 = abs(_984) > 0.5;\n        }\n        else\n        {\n            _1005 = _997;\n        }\n        if (_1005)\n        {\n            continue;\n        }\n        float _1020 = fast::clamp(dot(geo_normal, fast::normalize(_979)) * _937.z, 0.0, 1.0);\n        if (_1020 <= 0.0)\n        {\n            continue;\n        }\n        float _1040 = (fast::clamp((0.5 - abs(_984)) * 10.0, 0.0, 1.0) * _1020) * _937.x;\n        float2 _1048 = float2(_970 + 0.5, 0.5 - _977);\n        float2 _1058 = float2(dot(_965, _853), dot(_972, _853));\n        float2 _1068 = float2(dot(_965, _856), dot(_972, _856));\n        int param_8 = _932 + 5;\n        float4 _1073 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _932 + 3;\n        float4 _1078 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _932 + 4;\n        float4 _1083 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1073.xyz;\n        bool _1093 = _1078.z > _1078.x;\n        if (_1093)\n        {\n            float4 param_11 = _1078;\n            float2 param_12 = _1048;\n            float2 param_13 = _881;\n            float2 param_14 = _1058;\n            float2 param_15 = _1068;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_891 > 0.5) && (_891 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1119 = fa_dc_to_linear(param_16);\n                float4 _5274 = tx;\n                _5274.x = _1119.x;\n                _5274.y = _1119.y;\n                _5274.z = _1119.z;\n                tx = _5274;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1040 * tex_a) * _1073.w, 0.0, 1.0)));\n        if (_1083.z > _1083.x)\n        {\n            float4 param_17 = _1083;\n            float2 param_18 = _1048;\n            float2 param_19 = _881;\n            float2 param_20 = _1058;\n            float2 param_21 = _1068;\n            float4 _1163 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_891 > 1.5)\n            {\n                float3 param_22 = _1163.xyz;\n                float3 _1173 = fa_dc_to_srgb(param_22);\n                _1167 = _1173;\n            }\n            else\n            {\n                _1167 = _1163.xyz;\n            }\n            float3 _1183 = (_1167 * 2.0) - float3(1.0);\n            float2 _1188 = _1183.xy * _937.y;\n            float3 _1210 = (fast::normalize(_965) * _1188.x) + (fast::normalize(_972) * _1188.y);\n            float3 _1213 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1213, fast::normalize((_1213 * fast::max(_1183.z, 0.0500000007450580596923828125)) + (_1210 - (_1213 * dot(_1213, _1210)))), float3(fast::clamp(_1040 * (_1093 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _2673 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2680 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2683 = int(_2673);\n    int _2686 = int(_2680);\n    float _2696 = _2680 - float(_2686);\n    int _2751 = (_2683 * 9) + _2686;\n    int _2771 = ((_2683 + 1) * 9) + _2686;\n    return mix(mix(_2747[_2751], _2747[_2751 + 1], _2696), mix(_2747[_2771], _2747[_2771 + 1], _2696), _2673 - float(_2683));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _5141 = false;\n    float _5142 = 1.0;\n    float _5143 = 1.0;\n    float _5144 = 1.0;\n    float _5145 = 0.0;\n    float _5146 = 0.0;\n    float _5147 = 0.0;\n    float _5148 = 0.0;\n    float _5150 = 1.0;\n    bool _5151 = false;\n    float3 _5152 = float3(0.0);\n    float _5153 = 1.0;\n    float _5154 = 1.0;\n    float _5155 = 1.0;\n    float _5156 = 0.0;\n    float _5157 = 0.0;\n    float3 _5158 = float3(1.0, 0.0, 0.0);\n    float3 _5159 = float3(0.0, 0.0, 1.0);\n    float _5160 = 1.0;\n    float _5161 = 1.0;\n    float _2824 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2828 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2833 = (_2824 != 1.0) || (_2828 != 1.5);\n    bool _2843;\n    if (!_2833)\n    {\n        _2843 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2843 = _2833;\n    }\n    if (_2843)\n    {\n        float _2851 = (_2828 - 1.0) / (_2828 + 1.0);\n        f0 = mix(fast::min(float3(_2851 * _2851) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2824, s.albedo, float3(metallic));\n        _5142 = mix(_2824, 1.0, metallic);\n        _5141 = true;\n    }\n    float _2879 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2879 > 0.0)\n    {\n        float _2887 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5145 = _2879;\n        _5146 = _2887;\n        float _2894 = _2887 * _2887;\n        _5147 = _2894;\n        _5148 = _2894 * _2894;\n        float _2906 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5150 = _2906;\n        _5143 = 1.0 - (_2879 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2906, 0.0, 1.0), 5.0))));\n        _5141 = true;\n    }\n    float3 _2925 = fast::max(s.sheen_color, float3(0.0));\n    float _2934 = fast::max(_2925.x, fast::max(_2925.y, _2925.z));\n    if (_2934 > 0.0)\n    {\n        float _2942 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5151 = true;\n        _5152 = _2925;\n        _5153 = _2942;\n        _5154 = _2942 * _2942;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2942;\n        float _2959 = fa_sheen_albedo(param, param_1);\n        _5156 = _2959;\n        _5155 = 1.0 - fast::min(_2934 * _2959, 1.0);\n        _5141 = true;\n    }\n    _5144 = _5143 * _5155;\n    float _2978 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2978 != 0.0)\n    {\n        float3 _2993 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2993;\n        if (dot(_2993, _2993) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _3010 = t;\n        float3 _3011 = fast::normalize(_3010);\n        t = _3011;\n        float3 _3036 = fast::normalize((_3011 * cos(s.anisotropy_rotation)) + ((cross(n, _3011) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5158 = _3036;\n        _5159 = cross(n, _3036);\n        float _3046 = roughness * roughness;\n        float _3052 = mix(_3046, 1.0, _2978 * _2978);\n        bool _3054 = _2978 > 0.0;\n        _5160 = _3054 ? _3052 : _3046;\n        _5161 = _3054 ? _3046 : _3052;\n        _5157 = _2978;\n        _5141 = true;\n    }\n    return FaLayers{ short(_5141), _5142, _5143, _5144, _5145, _5146, _5147, _5148, i.world_normal, _5150, short(_5151), _5152, _5153, _5154, _5155, _5156, _5157, _5158, _5159, _5160, _5161 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_555.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _2430 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _2430;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_555.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _555, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _555.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _555, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555)\n{\n    int param = (int(_555.fa_cl_info.x) + int(_555.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _555);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _429 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _435 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _438 = _435.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _444 = _438 < 0.5;\n    float3 l;\n    if (_444)\n    {\n        l = fast::normalize(_429.xyz);\n    }\n    else\n    {\n        float3 _456 = _429.xyz - world_pos;\n        float _458 = length(_456);\n        dist = _458;\n        l = _456 / float3(fast::max(_458, 9.9999997473787516355514526367188e-05));\n        float _473 = _458 / fast::max(_429.w, 0.001000000047497451305389404296875);\n        float _479 = fast::clamp(1.0 - (_473 * _473), 0.0, 1.0);\n        atten = _479 * _479;\n        if (_438 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _493 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _503 = _493.w;\n            int param_3 = (li * 4) + 3;\n            float4 _509 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _510 = _509.x;\n            float cos_inner = _510;\n            if (_510 > 1.5)\n            {\n                cos_inner = mix(_503, 1.0, 0.25);\n            }\n            atten *= smoothstep(_503, cos_inner, dot(-l, fast::normalize(_493.xyz)));\n        }\n    }\n    int _541;\n    if (_444)\n    {\n        _541 = 0;\n    }\n    else\n    {\n        _541 = (_438 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _435.xyz * atten, atten, 1.0, dist, _541 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1295)\n{\n    float _1285;\n    if (i == 0)\n    {\n        _1285 = _1295.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1301;\n        if (i == 1)\n        {\n            _1301 = _1295.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1309;\n            if (i == 2)\n            {\n                _1309 = _1295.fa_shadow_split.z;\n            }\n            else\n            {\n                _1309 = _1295.fa_shadow_split.w;\n            }\n            _1301 = _1309;\n        }\n        _1285 = _1301;\n    }\n    return _1285;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1342 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1346;\n    if (conv.x < 0.5)\n    {\n        _1346 = _1342;\n    }\n    else\n    {\n        _1346 = (conv.y * conv.z) / (conv.z - (_1342 * (conv.z - conv.y)));\n    }\n    return _1346;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1273 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1273), sin(_1273)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1392 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1406 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1392;\n            float2 _1425 = fa_shadow_vogel(param_3, param_4, param_5) * _1406;\n            float2 param_6 = uv + (_1425 * _1295.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1437 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1437 < (zr - (length(_1425) * plane)))\n            {\n                sum += _1437;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1481 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1481; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1481;\n        float param_11 = _1392;\n        float2 _1500 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1500 * _1295.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1500) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1481);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex)\n{\n    float _1542 = fast::max(_1295.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1547 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1553 = sqrt(1.0 - (_1547 * _1547));\n    float _1560 = fast::min(_1553 / fast::max(_1547, 0.20000000298023223876953125), 4.0);\n    float _1565;\n    if (_1295.fa_shadow_bias.y > 0.0)\n    {\n        _1565 = _1295.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1565 = 1.5 * _1295.fa_shadow_info[ci].x;\n    }\n    float4 _1590 = _1295.fa_shadow_mat[ci] * float4(world + (n * (_1565 * _1553)), 1.0);\n    float _1597 = _1590.x;\n    bool _1600 = _1597 < _1295.fa_shadow_rect[ci].x;\n    bool _1609;\n    if (!_1600)\n    {\n        _1609 = _1597 > _1295.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1609 = _1600;\n    }\n    bool _1618;\n    if (!_1609)\n    {\n        _1618 = _1590.y < _1295.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1618 = _1609;\n    }\n    bool _1627;\n    if (!_1618)\n    {\n        _1627 = _1590.y > _1295.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1627 = _1618;\n    }\n    bool _1634;\n    if (!_1627)\n    {\n        _1634 = _1590.z > 1.0;\n    }\n    else\n    {\n        _1634 = _1627;\n    }\n    if (_1634)\n    {\n        return -1.0;\n    }\n    float _1643;\n    if (_1295.fa_shadow_bias.x > 0.0)\n    {\n        _1643 = _1295.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1643 = 1.5 * _1295.fa_shadow_info[ci].x;\n    }\n    float2 param = _1590.xy;\n    float4 param_1 = _1295.fa_shadow_rect[ci];\n    float param_2 = _1590.z - ((_1643 * (1.0 + (0.5 * _1560))) / _1542);\n    float param_3 = _1295.fa_shadow_info[ci].x;\n    float param_4 = _1542;\n    float param_5 = _1542 * 0.25;\n    float param_6 = ((_1295.fa_shadow_info[ci].x * fast::min(_1560, 3.0)) * 0.5) / _1542;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1295.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1295.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1295, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex)\n{\n    if (_555.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2070 = int(_1295.fa_shadow_cfg.x + 0.5);\n    if (_2070 < 1)\n    {\n        return 1.0;\n    }\n    float _2085 = dot(world - _1295.fa_shadow_eye.xyz, _1295.fa_shadow_fwd.xyz);\n    int param = _2070 - 1;\n    if (_2085 > fa_shadow_split_at(param, _1295))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2097 = _2070 > 1;\n    bool _2104;\n    if (_2097)\n    {\n        _2104 = _2085 > _1295.fa_shadow_split.x;\n    }\n    else\n    {\n        _2104 = _2097;\n    }\n    if (_2104)\n    {\n        ci = 1;\n    }\n    bool _2108 = _2070 > 2;\n    bool _2115;\n    if (_2108)\n    {\n        _2115 = _2085 > _1295.fa_shadow_split.y;\n    }\n    else\n    {\n        _2115 = _2108;\n    }\n    if (_2115)\n    {\n        ci = 2;\n    }\n    bool _2119 = _2070 > 3;\n    bool _2126;\n    if (_2119)\n    {\n        _2126 = _2085 > _1295.fa_shadow_split.z;\n    }\n    else\n    {\n        _2126 = _2119;\n    }\n    if (_2126)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2070)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2152 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1295, fa_shadow_tex);\n        s = _2152;\n        if (_2152 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1295.fa_shadow_cfg.y > 0.0)\n    {\n        float _2177;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2177 = fa_shadow_split_at(param_5, _1295);\n        }\n        else\n        {\n            _2177 = _1295.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2196 = _1295.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1295) - _2177, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2207 = fast::clamp((_2085 - (fa_shadow_split_at(param_7, _1295) - _2196)) / _2196, 0.0, 1.0);\n        if (_2207 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2070)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2228 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1295, fa_shadow_tex);\n                s2 = _2228;\n                if (_2228 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2207);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _555, gl_FragCoord, _1295, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex)\n{\n    bool _1701 = _555.fa_pbr.z < 0.5;\n    bool _1709;\n    if (!_1701)\n    {\n        _1709 = _1295.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1709 = _1701;\n    }\n    if (_1709)\n    {\n        return 1.0;\n    }\n    int param = (int(_1295.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1722 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1723 = _1722.x;\n    if (_1723 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1732 = int(_1723 + 0.5);\n    int param_1 = _1732;\n    float4 _1736 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1732 + 1;\n    float4 _1741 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1744 = _1736.y;\n    if (_1744 > 0.0)\n    {\n        float _1761 = 1.0 - smoothstep(0.75 * _1744, _1744, length(world - _1295.fa_shadow_eye.xyz));\n        fade = _1761;\n        if (_1761 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1736.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1780 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1783 = abs(_1780);\n        float _1785 = _1783.x;\n        float _1787 = _1783.y;\n        bool _1788 = _1785 >= _1787;\n        bool _1796;\n        if (_1788)\n        {\n            _1796 = _1785 >= _1783.z;\n        }\n        else\n        {\n            _1796 = _1788;\n        }\n        int _1797;\n        if (_1796)\n        {\n            _1797 = (_1780.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1810;\n            if (_1787 >= _1783.z)\n            {\n                _1810 = (_1780.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1810 = (_1780.z > 0.0) ? 4 : 5;\n            }\n            _1797 = _1810;\n        }\n        face = _1797;\n    }\n    int _1829 = (_1732 + 2) + (face * 6);\n    int param_4 = _1829;\n    int param_5 = _1829 + 1;\n    int param_6 = _1829 + 3;\n    float4 _1843 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1829 + 4;\n    float4 _1848 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1829 + 5;\n    float4 _1853 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1865 = _1853.x * fast::max(dot(_1843, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1870 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1893 = fast::clamp(dot(n, _1843.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1916 = fast::min(sqrt(1.0 - (_1893 * _1893)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1843, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1919 = _1741.y;\n    float _1921;\n    if (_1919 > 0.0)\n    {\n        _1921 = _1919;\n    }\n    else\n    {\n        _1921 = 1.5 * _1865;\n    }\n    float4 _1941 = float4(world + (n * (_1921 * sqrt(1.0 - (_1870 * _1870)))), 1.0);\n    float _1945 = dot(_1843, _1941);\n    float _1948 = _1853.y;\n    if (_1945 < _1948)\n    {\n        return 1.0;\n    }\n    float2 _1963 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1941), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1941)) / float2(_1945);\n    float _1965 = _1963.x;\n    bool _1968 = _1965 < _1848.x;\n    bool _1977;\n    if (!_1968)\n    {\n        _1977 = _1965 > _1848.z;\n    }\n    else\n    {\n        _1977 = _1968;\n    }\n    bool _1986;\n    if (!_1977)\n    {\n        _1986 = _1963.y < _1848.y;\n    }\n    else\n    {\n        _1986 = _1977;\n    }\n    bool _1995;\n    if (!_1986)\n    {\n        _1995 = _1963.y > _1848.w;\n    }\n    else\n    {\n        _1995 = _1986;\n    }\n    if (_1995)\n    {\n        return 1.0;\n    }\n    float _2001 = _1741.x;\n    float _2003;\n    if (_2001 > 0.0)\n    {\n        _2003 = _2001;\n    }\n    else\n    {\n        _2003 = 1.5 * _1865;\n    }\n    float2 param_10 = _1963;\n    float4 param_11 = _1848;\n    float param_12 = _1945 - (_2003 * (1.0 + (0.5 * _1916)));\n    float param_13 = _1865;\n    float param_14 = 1.0;\n    float param_15 = _1853.z * 0.25;\n    float param_16 = (_1865 * fast::min(_1916, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1948, _1853.z);\n    int param_18 = int(_1736.z + 0.5);\n    float param_19 = _1736.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1295, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_contact_shadow(thread const int& li, thread const float3& world, thread const float3& gn, thread const float3& l, thread const float& dist, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_screen_tex)\n{\n    bool _3553 = _555.fa_ct_a.x < 0.5;\n    bool _3560;\n    if (!_3553)\n    {\n        _3560 = _1295.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _3560 = _3553;\n    }\n    if (_3560)\n    {\n        return 1.0;\n    }\n    int param = (int(_1295.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _3573 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _3574 = _3573.y;\n    float len = _3574;\n    if (_3574 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3586 = length(world - _555.fa_camera_pos.xyz);\n    float _3596 = 1.0 - smoothstep(0.5 * _555.fa_ct_b.x, _555.fa_ct_b.x, _3586);\n    if (_3596 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3602 = len;\n    float _3605 = fast::min(_3602, 0.89999997615814208984375 * dist);\n    len = _3605;\n    float _3610 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3586);\n    float _3615 = _3610 + (0.5 * _3605);\n    float3 _3621 = world + (gn * _3610);\n    float _3623 = fa_shadow_noise(gl_FragCoord);\n    float occ = 0.0;\n    float _3687;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3638 = (float(k) + _3623) * 0.083333335816860198974609375;\n        float3 _3646 = _3621 + (l * (_3638 * len));\n        float4 _3652 = float4(_3646, 1.0);\n        float _3658 = dot(_555.fa_ct_vpw, _3652);\n        if (_3658 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        float2 _3678 = float2(dot(_555.fa_ct_vpx, _3652), dot(_555.fa_ct_vpy, _3652)) / float2(_3658);\n        float _3682 = _3678.x * 0.5;\n        float _3683 = _3682 + 0.5;\n        if (_555.fa_ct_a.y > 0.5)\n        {\n            _3687 = (_3678.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3687 = 0.5 - (_3678.y * 0.5);\n        }\n        bool _3703 = _3683 < 0.0;\n        bool _3710;\n        if (!_3703)\n        {\n            _3710 = _3683 >= 1.0;\n        }\n        else\n        {\n            _3710 = _3703;\n        }\n        bool _3717;\n        if (!_3710)\n        {\n            _3717 = _3687 < 0.0;\n        }\n        else\n        {\n            _3717 = _3710;\n        }\n        bool _3724;\n        if (!_3717)\n        {\n            _3724 = _3687 >= 1.0;\n        }\n        else\n        {\n            _3724 = _3717;\n        }\n        if (_3724)\n        {\n            break;\n        }\n        float4 _3743 = fa_screen_tex.read(uint2(int2(float2(_3683, _3687) * _555.fa_ct_a.zw)), 0);\n        if (_3743.w < 0.5)\n        {\n            continue;\n        }\n        float _3762 = (dot(_555.fa_ct_fwd.xyz, _3646) + _555.fa_ct_fwd.w) - _3743.x;\n        if ((_3762 > _3610) && (_3762 < _3615))\n        {\n            occ = fast::max(occ, (1.0 - (_3638 * _3638)) * smoothstep(0.0, 0.0500000007450580596923828125, fast::min(fast::min(_3683, 0.5 - _3682), fast::min(_3687, 1.0 - _3687))));\n        }\n    }\n    return 1.0 - (occ * _3596);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _555, thread float4& gl_FragCoord, constant fa_shadows& _1295, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread float3& fa_lm)\n{\n    bool _3838 = fa_lm.z > 0.5;\n    bool _3844;\n    if (_3838)\n    {\n        int param = li;\n        _3844 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3844 = _3838;\n    }\n    if (_3844)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3866 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _5203 = _3866.direction;\n    float3 _5198 = _3866.color;\n    float _5205 = _3866.attenuation;\n    float _5200 = _3866.shadow;\n    float _5207 = _3866._distance;\n    int _5208 = _3866.type;\n    bool _3869 = _5208 == 0;\n    if (_3869 && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _5203;\n        float _3880 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _555, gl_FragCoord, _1295, fa_shadow_tex, fa_world_pos);\n        _5200 = _3880;\n        _5198 *= _3880;\n    }\n    else\n    {\n        bool _3891 = _5208 != 0;\n        bool _3897;\n        if (_3891)\n        {\n            _3897 = _5205 > 0.0;\n        }\n        else\n        {\n            _3897 = _3891;\n        }\n        if (_3897)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _5203;\n            float _3909 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _555, gl_FragCoord, _1295, fa_shadow_tex);\n            _5200 = _3909;\n            _5198 *= _3909;\n        }\n    }\n    bool _3919 = _555.fa_ct_a.x > 0.5;\n    bool _3925;\n    if (_3919)\n    {\n        _3925 = _5205 > 0.0;\n    }\n    else\n    {\n        _3925 = _3919;\n    }\n    if (_3925)\n    {\n        float _3932;\n        if (_3869)\n        {\n            _3932 = 1000000000.0;\n        }\n        else\n        {\n            _3932 = _5207;\n        }\n        int param_10 = li;\n        float3 param_11 = world_pos;\n        float3 param_12 = gn;\n        float3 param_13 = _5203;\n        float param_14 = _3932;\n        float _3950 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14, fa_light_tex, fa_shadow_smp, _555, gl_FragCoord, _1295, fa_screen_tex);\n        _5200 *= _3950;\n        _5198 *= _3950;\n    }\n    return LightSample{ _5203, _5198, _5205, _5200, _5207, _5208 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _3204 = tdh / at;\n    float _3208 = bdh / ab;\n    float _3220 = ((_3204 * _3204) + (_3208 * _3208)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3220) * _3220);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _3301 = 1.0 / alpha;\n    return ((2.0 + _3301) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3301)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _3333 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3412 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3412) * _3412);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3333);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3333));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3485 = fast::max(dot(L.nc, l), 0.0);\n        float _3491 = fast::max(dot(L.nc, h), 0.0);\n        float _3500 = ((_3491 * _3491) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3500) * _3500)) * (0.5 / fast::max(mix((2.0 * _3485) * L.coat_ndv, _3485 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3485)) * _3485);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _2605 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2608 = _2605.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_2608 * _2608, exp2((-9.27999973297119140625) * ndv)) * _2608) + _2605.y)) + _2605.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_555.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _555.fa_env_horizon.w)).xyz;\n    }\n    float _2459 = rough * rough;\n    float _2489 = 0.60000002384185791015625 * _2459;\n    return mix(mix(_555.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_555.fa_env_horizon.xyz, _555.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _2459)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _2489, 0.0500000007450580596923828125 + _2489, d.y))), ((_555.fa_env_sky.xyz + _555.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_2459 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _3087;\n        if (L.aniso >= 0.0)\n        {\n            _3087 = L.b;\n        }\n        else\n        {\n            _3087 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_3087, v), _3087), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3120 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _555, fa_env_smp, fa_env_tex) * ((f0 * _3120.x) + (float3(L.f90) * _3120.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _555, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3175 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _555, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _3175.x) + _3175.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _555, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2647 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _555, fa_env_smp, fa_env_tex) * ((f0 * _2647.x) + float3(_2647.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1295)\n{\n    if (_1295.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2252 = int(_1295.fa_shadow_cfg.x + 0.5);\n    float _2262 = dot(world - _1295.fa_shadow_eye.xyz, _1295.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2267 = _2252 > 0;\n    bool _2276;\n    if (_2267)\n    {\n        int param = _2252 - 1;\n        _2276 = _2262 <= fa_shadow_split_at(param, _1295);\n    }\n    else\n    {\n        _2276 = _2267;\n    }\n    if (_2276)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2283 = _2252 > 1;\n        bool _2290;\n        if (_2283)\n        {\n            _2290 = _2262 > _1295.fa_shadow_split.x;\n        }\n        else\n        {\n            _2290 = _2283;\n        }\n        if (_2290)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2296 = _2252 > 2;\n        bool _2303;\n        if (_2296)\n        {\n            _2303 = _2262 > _1295.fa_shadow_split.y;\n        }\n        else\n        {\n            _2303 = _2296;\n        }\n        if (_2303)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2309 = _2252 > 3;\n        bool _2316;\n        if (_2309)\n        {\n            _2316 = _2262 > _1295.fa_shadow_split.z;\n        }\n        else\n        {\n            _2316 = _2309;\n        }\n        if (_2316)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _555 [[buffer(1)]], constant fa_material& _3966 [[buffer(5)]], constant fa_shadows& _1295 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], texture2d<float> fa_screen_tex [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4920 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4920 = -_4920;\n    }\n    float3 _4345 = fast::normalize(_555.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _555, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4920, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4345, short(gl_FrontFacing) };\n    Surface _4353 = fa_standard_surface(param_1, _555, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4951 = _4353.albedo;\n    float _4952 = _4353.alpha;\n    float3 _4953 = _4353.normal;\n    float _4954 = _4353.metallic;\n    float _4955 = _4353.roughness;\n    float _4956 = _4353.occlusion;\n    float3 _4957 = _4353.emission;\n    float _4958 = _4353.clearcoat;\n    float _4959 = _4353.clearcoat_roughness;\n    float3 _4960 = _4353.sheen_color;\n    float _4961 = _4353.sheen_roughness;\n    float _4962 = _4353.anisotropy;\n    float _4963 = _4353.anisotropy_rotation;\n    float _4964 = _4353.specular;\n    float _4965 = _4353.ior;\n    float3 _4966 = _4353.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4920, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4345, short(gl_FrontFacing) };\n    Surface param_3 = _4353;\n    surface(param_2, param_3, _3966);\n    _4951 = param_3.albedo;\n    _4952 = param_3.alpha;\n    _4953 = param_3.normal;\n    _4954 = param_3.metallic;\n    _4955 = param_3.roughness;\n    _4956 = param_3.occlusion;\n    _4957 = param_3.emission;\n    _4958 = param_3.clearcoat;\n    _4959 = param_3.clearcoat_roughness;\n    _4960 = param_3.sheen_color;\n    _4961 = param_3.sheen_roughness;\n    _4962 = param_3.anisotropy;\n    _4963 = param_3.anisotropy_rotation;\n    _4964 = param_3.specular;\n    _4965 = param_3.ior;\n    _4966 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4920;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _555, fa_decal_tex, fa_env_smp);\n    _4951 = param_6;\n    _4953 = param_7;\n    float3 result;\n    if (_555.fa_emissive.w > 0.5)\n    {\n        result = _4951;\n    }\n    else\n    {\n        float3 _4392 = fast::normalize(_4953);\n        float _4399 = fast::clamp(_4954, 0.0, 1.0);\n        float _4403 = fast::clamp(_4955, 0.0500000007450580596923828125, 1.0);\n        float _4407 = _4403 * _4403;\n        float _4411 = _4407 * _4407;\n        float _4416 = fast::max(dot(_4392, _4345), 9.9999997473787516355514526367188e-05);\n        float3 _4422 = _4951 * (1.0 - _4399);\n        float3 _4429 = mix(float3(0.039999999105930328369140625), _4951, float3(_4399));\n        float3 f0 = _4429;\n        SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _4920, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4345, short(gl_FrontFacing) };\n        Surface param_9 = Surface{ _4951, _4952, _4953, _4954, _4955, _4956, _4957, _4958, _4959, _4960, _4961, _4962, _4963, _4964, _4965, _4966 };\n        float3 param_10 = _4392;\n        float3 param_11 = _4345;\n        float param_12 = _4399;\n        float param_13 = _4403;\n        float3 param_14 = _4429;\n        FaLayers _4445 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _4392;\n        float3 lit = (fa_indirect_diffuse(param_15, _555, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap) * _4422) * _4956;\n        if (_4445.on)\n        {\n            lit *= _4445.base_scale;\n        }\n        int _4467 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4467; ln++)\n        {\n            int param_16 = ln;\n            int _4480 = fa_cl_light(param_16, fa_light_tex, fa_shadow_smp, _555, fa_cl_ndir, fa_cl_slot);\n            bool _4483 = in.fa_lm.z > 0.5;\n            bool _4489;\n            if (_4483)\n            {\n                int param_17 = _4480;\n                _4489 = fa_light_baked(param_17, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _4489 = _4483;\n            }\n            if (_4489)\n            {\n                continue;\n            }\n            int param_18 = _4480;\n            float3 param_19 = in.fa_world_pos;\n            float3 param_20 = _4920;\n            LightSample _4501 = fa_light_shadowed(param_18, param_19, param_20, fa_light_tex, fa_shadow_smp, _555, gl_FragCoord, _1295, fa_shadow_tex, in.fa_world_pos, fa_screen_tex, in.fa_lm);\n            float3 _5125 = _4501.direction;\n            float _4509 = fast::max(dot(_4392, _5125), 0.0);\n            float _4515 = _4501.attenuation * _4501.shadow;\n            float3 _4520 = fast::normalize(_5125 + _4345);\n            float _4525 = fast::max(dot(_4392, _4520), 0.0);\n            float _4530 = fast::max(dot(_4345, _4520), 0.0);\n            if (_4445.on)\n            {\n                FaLayers param_21 = _4445;\n                float3 param_22 = _4422;\n                float3 param_23 = f0;\n                float3 param_24 = _4392;\n                float3 param_25 = _4345;\n                float3 param_26 = _5125;\n                float3 param_27 = _4520;\n                float param_28 = _4509;\n                float param_29 = _4416;\n                float param_30 = _4525;\n                float param_31 = _4530;\n                float param_32 = _4407;\n                float param_33 = _4411;\n                int param_34 = _4480;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34, fa_light_tex, fa_shadow_smp) * _4515));\n            }\n            else\n            {\n                float _4578 = ((_4525 * _4525) * (_4411 - 1.0)) + 1.0;\n                int param_35 = _4480;\n                lit += (((_4422 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _4530, 5.0))) * (((_4411 / ((3.1415927410125732421875 * _4578) * _4578)) * (0.5 / fast::max(mix((2.0 * _4509) * _4416, _4509 + _4416, _4407), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4509))) * fa_light_rgb(param_35, fa_light_tex, fa_shadow_smp)) * (_4509 * _4515));\n            }\n        }\n        if (_4445.on)\n        {\n            FaLayers param_36 = _4445;\n            float3 param_37 = _4392;\n            float3 param_38 = _4345;\n            float3 param_39 = f0;\n            float param_40 = _4403;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40, _555, fa_env_smp, fa_env_tex) * _4956);\n        }\n        else\n        {\n            float3 param_41 = _4392;\n            float3 param_42 = _4345;\n            float3 param_43 = f0;\n            float param_44 = _4403;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44, _555, fa_env_smp, fa_env_tex) * _4956);\n        }\n        result = lit;\n    }\n    float3 _4671 = result;\n    float3 _4672 = _4671 + _4957;\n    result = _4672;\n    float3 param_45 = _4672;\n    float3 param_46 = in.fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46, _1295);\n    bool _4681 = _555.fa_fog.w > 0.0;\n    bool _4688;\n    if (!_4681)\n    {\n        _4688 = _555.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4688 = _4681;\n    }\n    if (_4688)\n    {\n        float3 _4697 = in.fa_world_pos - _555.fa_camera_pos.xyz;\n        float _4703 = dot(_4697, _555.fa_fog_c.xyz);\n        bool _4707 = _555.fa_fog_c.w > 0.5;\n        float _4708;\n        if (_4707)\n        {\n            _4708 = _4703;\n        }\n        else\n        {\n            _4708 = length(_4697);\n        }\n        float _4720 = _4708 - _555.fa_fog_b.x;\n        if (_4720 > 0.0)\n        {\n            float _4729 = _555.fa_fog.w * _4720;\n            float tau = _4729 * _4729;\n            if (_555.fa_fog_b.y > 0.0)\n            {\n                float _4745;\n                if (_4707)\n                {\n                    _4745 = in.fa_world_pos.y - (_555.fa_fog_c.y * _4703);\n                }\n                else\n                {\n                    _4745 = _555.fa_camera_pos.y;\n                }\n                float _4766 = mix(_4745, in.fa_world_pos.y, fast::clamp(_555.fa_fog_b.x / _4708, 0.0, 1.0));\n                float _4770 = in.fa_world_pos.y - _4766;\n                float _4775 = _4766 - _555.fa_fog_b.z;\n                float _4780 = in.fa_world_pos.y - _555.fa_fog_b.z;\n                bool _4783 = _4775 <= 0.0;\n                bool _4784 = !_4783;\n                bool _4790;\n                if (_4784)\n                {\n                    _4790 = _555.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4790 = _4783;\n                }\n                float _4791;\n                if (_4790)\n                {\n                    _4791 = _555.fa_fog_b.y;\n                }\n                else\n                {\n                    _4791 = _555.fa_fog_b.y * exp(-fast::min(_555.fa_fog_b.w * _4775, 80.0));\n                }\n                bool _4818;\n                if (_4784)\n                {\n                    _4818 = _555.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4818 = _4783;\n                }\n                float _4819;\n                if (_4818)\n                {\n                    _4819 = _555.fa_fog_b.y * _4775;\n                }\n                else\n                {\n                    _4819 = (_555.fa_fog_b.y * (1.0 - exp(-fast::min(_555.fa_fog_b.w * _4775, 80.0)))) / _555.fa_fog_b.w;\n                }\n                bool _4844 = _4780 <= 0.0;\n                bool _4851;\n                if (!_4844)\n                {\n                    _4851 = _555.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4851 = _4844;\n                }\n                float _4852;\n                if (_4851)\n                {\n                    _4852 = _555.fa_fog_b.y * _4780;\n                }\n                else\n                {\n                    _4852 = (_555.fa_fog_b.y * (1.0 - exp(-fast::min(_555.fa_fog_b.w * _4780, 80.0)))) / _555.fa_fog_b.w;\n                }\n                float _4879;\n                if (abs(_4770) < 0.001000000047497451305389404296875)\n                {\n                    _4879 = _4791;\n                }\n                else\n                {\n                    _4879 = (_4852 - _4819) / _4770;\n                }\n                tau += (_4720 * fast::max(_4879, 0.0));\n            }\n            result = mix(result, _555.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4952);\n    return out;\n}\n\n",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3966",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_material\n{\n    float4 glow;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _188 = fa_linear_to_srgb(param);\n        c = _188;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _197 = fa_srgb_to_linear(param_1);\n            c = _197;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _229, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _229.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _240 = fa_tex_fix(param_2, param_3);\n    float4 _747 = base_t;\n    _747.x = _240.x;\n    _747.y = _240.y;\n    _747.z = _240.z;\n    base_t = _747;\n    float4 _255 = (_747 * _229.fa_base_color) * i.vertex_color;\n    float3 _710 = i.world_normal;\n    if (_229.fa_maps.z > 0.5)\n    {\n        float param_4 = _229.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _288 = fa_tex_fix(param_6, param_7);\n        float3 _292 = (_288 * 2.0) - float3(1.0);\n        float2 _297 = _292.xy * _229.fa_maps.x;\n        float3 _755 = _292;\n        _755.x = _297.x;\n        _755.y = _297.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _755;\n        _710 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _229.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _326 = fa_tex_fix(param_12, param_13);\n    float4 _758 = mrt;\n    _758.x = _326.x;\n    _758.y = _326.y;\n    _758.z = _326.z;\n    mrt = _758;\n    float4 _356 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _229.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _356.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = _229.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _715 = _229.fa_layers_a.x;\n    float _716 = _229.fa_layers_a.y;\n    float _719 = _229.fa_layers_a.z;\n    float _718 = _229.fa_layers_b.w;\n    float _721 = _229.fa_layers_c.x;\n    if (_229.fa_layers_c.z > 0.5)\n    {\n        if (mod(_229.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _715 *= _368.y;\n            _716 *= _368.z;\n            _718 *= _356.w;\n        }\n        if (_229.fa_layers_c.z > 1.5)\n        {\n            _719 *= mrt.x;\n            _721 *= mrt.w;\n        }\n    }\n    return Surface{ _255.xyz, _255.w, _710, fast::clamp(_229.fa_pbr.x * _326.z, 0.0, 1.0), fast::clamp(_229.fa_pbr.y * _326.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_229.fa_maps.y * (_368.x - 1.0)), _229.fa_emissive.xyz + (_229.fa_model_emissive.xyz * _398), _715, _716, _229.fa_layers_b.xyz, _718, _719, _229.fa_layers_a.w, _721, _229.fa_layers_c.y, _229.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, constant fa_material& _124)\n{\n    s.emission += (_124.glow.xyz * _124.glow.w);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _229 [[buffer(1)]], constant fa_material& _124 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _621 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _621 = -_621;\n    }\n    float3 _532 = fast::normalize(_229.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _621, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _532, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _621, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _532, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _229, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, _124);\n    float3 _547 = fast::normalize(param_2.normal);\n    float3 _562 = fast::normalize(float3(dot(in.fa_pre_r0, _547), dot(in.fa_pre_r1, _547), dot(in.fa_pre_r2, _547)));\n    float _574 = _562.z;\n    float2 e = _562.xy / float2((abs(_562.x) + abs(_562.y)) + abs(_574));\n    if (_574 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_124",
            "msl_buffer_n": 5
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_229",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_material\n{\n    float4 glow;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _188 = fa_linear_to_srgb(param);\n        c = _188;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _197 = fa_srgb_to_linear(param_1);\n            c = _197;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _229, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _229.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _240 = fa_tex_fix(param_2, param_3);\n    float4 _747 = base_t;\n    _747.x = _240.x;\n    _747.y = _240.y;\n    _747.z = _240.z;\n    base_t = _747;\n    float4 _255 = (_747 * _229.fa_base_color) * i.vertex_color;\n    float3 _710 = i.world_normal;\n    if (_229.fa_maps.z > 0.5)\n    {\n        float param_4 = _229.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _288 = fa_tex_fix(param_6, param_7);\n        float3 _292 = (_288 * 2.0) - float3(1.0);\n        float2 _297 = _292.xy * _229.fa_maps.x;\n        float3 _755 = _292;\n        _755.x = _297.x;\n        _755.y = _297.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _755;\n        _710 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _229.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _326 = fa_tex_fix(param_12, param_13);\n    float4 _758 = mrt;\n    _758.x = _326.x;\n    _758.y = _326.y;\n    _758.z = _326.z;\n    mrt = _758;\n    float4 _356 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _229.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _356.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = _229.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _715 = _229.fa_layers_a.x;\n    float _716 = _229.fa_layers_a.y;\n    float _719 = _229.fa_layers_a.z;\n    float _718 = _229.fa_layers_b.w;\n    float _721 = _229.fa_layers_c.x;\n    if (_229.fa_layers_c.z > 0.5)\n    {\n        if (mod(_229.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _715 *= _368.y;\n            _716 *= _368.z;\n            _718 *= _356.w;\n        }\n        if (_229.fa_layers_c.z > 1.5)\n        {\n            _719 *= mrt.x;\n            _721 *= mrt.w;\n        }\n    }\n    return Surface{ _255.xyz, _255.w, _710, fast::clamp(_229.fa_pbr.x * _326.z, 0.0, 1.0), fast::clamp(_229.fa_pbr.y * _326.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_229.fa_maps.y * (_368.x - 1.0)), _229.fa_emissive.xyz + (_229.fa_model_emissive.xyz * _398), _715, _716, _229.fa_layers_b.xyz, _718, _719, _229.fa_layers_a.w, _721, _229.fa_layers_c.y, _229.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, constant fa_material& _124)\n{\n    s.emission += (_124.glow.xyz * _124.glow.w);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _229 [[buffer(1)]], constant fa_material& _124 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _621 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _621 = -_621;\n    }\n    float3 _532 = fast::normalize(_229.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _621, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _532, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _621, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _532, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _229, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, _124);\n    float3 _547 = fast::normalize(param_2.normal);\n    float3 _562 = fast::normalize(float3(dot(in.fa_pre_r0, _547), dot(in.fa_pre_r1, _547), dot(in.fa_pre_r2, _547)));\n    float _574 = _562.z;\n    float2 e = _562.xy / float2((abs(_562.x) + abs(_562.y)) + abs(_574));\n    if (_574 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_124",
            "msl_buffer_n": 5
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_229",
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
