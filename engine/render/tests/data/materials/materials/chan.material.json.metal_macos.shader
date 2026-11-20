{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5c278b25d8ce4341984c8bf2a53e1ca7890b6a924713889b53c089df056597d0",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "vertexAttributes": [
    "color1",
    "uv1"
  ],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float2 fa_attr_uv1 [[attribute(9)]];\n    float4 fa_attr_color1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float4& vertex_color1, thread float2& vertex_uv1, thread float2& fa_attr_uv1, thread float4& fa_attr_color1)\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _144)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _144.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float4& vertex_color1, thread float2& vertex_uv1)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float4& vertex_color1, thread float2& vertex_uv1, constant fa_mesh_vs_params& _144, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _144);\n    vertex0(param_6, vertex_color1, vertex_uv1);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _144.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _144 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 vertex_color1;\n    float2 vertex_uv1;\n    fa_inst_begin(vertex_color1, vertex_uv1, in.fa_attr_uv1, in.fa_attr_color1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, vertex_color1, vertex_uv1, _144, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3((in.fa_attr_uv1 * _144.fa_lm_so.xy) + _144.fa_lm_so.zw, float(_144.fa_lm_so.x > 0.0));\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nconstant spvUnsafeArray<float, 63> _2739 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _547)\n{\n    bool _552 = _547.fa_cl_info.x < 0.0;\n    bool _559;\n    if (!_552)\n    {\n        _559 = _547.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _559 = _552;\n    }\n    bool _567;\n    if (!_559)\n    {\n        _567 = _547.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _567 = _559;\n    }\n    bool _574;\n    if (!_567)\n    {\n        _574 = _547.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _574 = _567;\n    }\n    bool _581;\n    if (!_574)\n    {\n        _581 = _547.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _581 = _574;\n    }\n    if (_581)\n    {\n        return float4(0.0);\n    }\n    float4 _591 = float4(world_pos, 1.0);\n    float _598 = dot(_547.fa_cl_vpw, _591);\n    if (!(_598 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _620 = float2(dot(_547.fa_cl_vpx, _591), dot(_547.fa_cl_vpy, _591)) / float2(_598);\n    int _624 = int(_547.fa_cl_grid.x);\n    int _628 = int(_547.fa_cl_grid.y);\n    int param = (int(_547.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_547.fa_cl_fwd.xyz, world_pos) + _547.fa_cl_fwd.w, _547.fa_cl_grid.w) / _547.fa_cl_grid.w) * _547.fa_cl_grid.z)), 0, int(_547.fa_cl_info.y) - 1) * _628) + clamp(int(floor(((_620.y * 0.5) + 0.5) * _547.fa_cl_grid.y)), 0, _628 - 1)) * _624)) + clamp(int(floor(((_620.x * 0.5) + 0.5) * _547.fa_cl_grid.x)), 0, _624 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _547)\n{\n    float3 param = world_pos;\n    float4 _704 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _547);\n    return int2(int(_704.x), int(_704.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _547, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_547.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3552 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _547);\n    fa_cl_slot = _3552.x;\n    fa_cl_local = _3552.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3708 = fa_linear_to_srgb(param);\n        c = _3708;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3716 = fa_srgb_to_linear(param_1);\n            c = _3716;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _303;\n    if (bool(i.front_facing))\n    {\n        _303 = i.world_normal;\n    }\n    else\n    {\n        _303 = -i.world_normal;\n    }\n    float3 _327 = fast::normalize(i.world_tangent.xyz - (_303 * dot(_303, i.world_tangent.xyz)));\n    float3 _354 = fast::normalize(((_327 * m.x) + ((cross(_303, _327) * i.world_tangent.w) * m.y)) + (_303 * m.z));\n    float3 _357;\n    if (bool(i.front_facing))\n    {\n        _357 = _354;\n    }\n    else\n    {\n        _357 = -_354;\n    }\n    return _357;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _547, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _547.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3747 = fa_tex_fix(param_2, param_3);\n    float4 _5046 = base_t;\n    _5046.x = _3747.x;\n    _5046.y = _3747.y;\n    _5046.z = _3747.z;\n    base_t = _5046;\n    float4 _3761 = (_5046 * _547.fa_base_color) * i.vertex_color;\n    float3 _4913 = i.world_normal;\n    if (_547.fa_maps.z > 0.5)\n    {\n        float param_4 = _547.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3793 = fa_tex_fix(param_6, param_7);\n        float3 _3796 = (_3793 * 2.0) - float3(1.0);\n        float2 _3801 = _3796.xy * _547.fa_maps.x;\n        float3 _5054 = _3796;\n        _5054.x = _3801.x;\n        _5054.y = _3801.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5054;\n        _4913 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _547.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3830 = fa_tex_fix(param_12, param_13);\n    float4 _5057 = mrt;\n    _5057.x = _3830.x;\n    _5057.y = _3830.y;\n    _5057.z = _3830.z;\n    mrt = _5057;\n    float4 _3858 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _547.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3858.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3870 = fa_tex_fix(param_16, param_17);\n    float param_18 = _547.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3900 = fa_tex_fix(param_20, param_21);\n    float _4918 = _547.fa_layers_a.x;\n    float _4919 = _547.fa_layers_a.y;\n    float _4922 = _547.fa_layers_a.z;\n    float _4921 = _547.fa_layers_b.w;\n    float _4924 = _547.fa_layers_c.x;\n    if (_547.fa_layers_c.z > 0.5)\n    {\n        if (mod(_547.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4918 *= _3870.y;\n            _4919 *= _3870.z;\n            _4921 *= _3858.w;\n        }\n        if (_547.fa_layers_c.z > 1.5)\n        {\n            _4922 *= mrt.x;\n            _4924 *= mrt.w;\n        }\n    }\n    return Surface{ _3761.xyz, _3761.w, _4913, fast::clamp(_547.fa_pbr.x * _3830.z, 0.0, 1.0), fast::clamp(_547.fa_pbr.y * _3830.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_547.fa_maps.y * (_3870.x - 1.0)), _547.fa_emissive.xyz + (_547.fa_model_emissive.xyz * _3900), _4918, _4919, _547.fa_layers_b.xyz, _4921, _4922, _547.fa_layers_a.w, _4924, _547.fa_layers_c.y, _547.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _785 = rect.zw - rect.xy;\n    float2 _789 = _785 * atlas;\n    float2 _793 = ddx * _789;\n    float2 _797 = ddy * _789;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _785)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_793, _793), dot(_797, _797)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _547, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _832 = _547.fa_counts.y < 0.5;\n    bool _839;\n    if (!_832)\n    {\n        _839 = _547.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _839 = _832;\n    }\n    if (_839)\n    {\n        return;\n    }\n    float3 _845 = dfdx(world_pos);\n    float3 _848 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _852 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _547);\n    int _856 = int(_852.w);\n    if (_856 < 1)\n    {\n        return;\n    }\n    int _866 = int(_547.fa_counts.y + 0.5);\n    int param_1 = _866;\n    float4 _870 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _873 = _870.yz;\n    int _877 = int(_870.w);\n    int param_2 = _866 + 1;\n    float4 _882 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _883 = _882.x;\n    int _889 = int(_547.fa_counts.w + 0.5) - 1;\n    int _893 = int(_852.z);\n    float3 _1159;\n    for (int k = 0; k < _856; k++)\n    {\n        int _906 = _893 + k;\n        int param_3 = _877 + (_906 >> 2);\n        int _924 = (_866 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_906 & 3]) * 7);\n        int param_4 = _924 + 6;\n        float4 _929 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_929.w + 0.5) >> _889) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _924;\n        float4 _944 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _924 + 1;\n        float4 _949 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _924 + 2;\n        float4 _954 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _957 = _944.xyz;\n        float _962 = dot(_957, world_pos) + _944.w;\n        float3 _964 = _949.xyz;\n        float _969 = dot(_964, world_pos) + _949.w;\n        float3 _971 = _954.xyz;\n        float _976 = dot(_971, world_pos) + _954.w;\n        bool _981 = abs(_962) > 0.5;\n        bool _989;\n        if (!_981)\n        {\n            _989 = abs(_969) > 0.5;\n        }\n        else\n        {\n            _989 = _981;\n        }\n        bool _997;\n        if (!_989)\n        {\n            _997 = abs(_976) > 0.5;\n        }\n        else\n        {\n            _997 = _989;\n        }\n        if (_997)\n        {\n            continue;\n        }\n        float _1012 = fast::clamp(dot(geo_normal, fast::normalize(_971)) * _929.z, 0.0, 1.0);\n        if (_1012 <= 0.0)\n        {\n            continue;\n        }\n        float _1032 = (fast::clamp((0.5 - abs(_976)) * 10.0, 0.0, 1.0) * _1012) * _929.x;\n        float2 _1040 = float2(_962 + 0.5, 0.5 - _969);\n        float2 _1050 = float2(dot(_957, _845), dot(_964, _845));\n        float2 _1060 = float2(dot(_957, _848), dot(_964, _848));\n        int param_8 = _924 + 5;\n        float4 _1065 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _924 + 3;\n        float4 _1070 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _924 + 4;\n        float4 _1075 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1065.xyz;\n        bool _1085 = _1070.z > _1070.x;\n        if (_1085)\n        {\n            float4 param_11 = _1070;\n            float2 param_12 = _1040;\n            float2 param_13 = _873;\n            float2 param_14 = _1050;\n            float2 param_15 = _1060;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_883 > 0.5) && (_883 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1111 = fa_dc_to_linear(param_16);\n                float4 _4969 = tx;\n                _4969.x = _1111.x;\n                _4969.y = _1111.y;\n                _4969.z = _1111.z;\n                tx = _4969;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1032 * tex_a) * _1065.w, 0.0, 1.0)));\n        if (_1075.z > _1075.x)\n        {\n            float4 param_17 = _1075;\n            float2 param_18 = _1040;\n            float2 param_19 = _873;\n            float2 param_20 = _1050;\n            float2 param_21 = _1060;\n            float4 _1155 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_883 > 1.5)\n            {\n                float3 param_22 = _1155.xyz;\n                float3 _1165 = fa_dc_to_srgb(param_22);\n                _1159 = _1165;\n            }\n            else\n            {\n                _1159 = _1155.xyz;\n            }\n            float3 _1175 = (_1159 * 2.0) - float3(1.0);\n            float2 _1180 = _1175.xy * _929.y;\n            float3 _1202 = (fast::normalize(_957) * _1180.x) + (fast::normalize(_964) * _1180.y);\n            float3 _1205 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1205, fast::normalize((_1205 * fast::max(_1175.z, 0.0500000007450580596923828125)) + (_1202 - (_1205 * dot(_1205, _1202)))), float3(fast::clamp(_1032 * (_1085 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _2665 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2672 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2675 = int(_2665);\n    int _2678 = int(_2672);\n    float _2688 = _2672 - float(_2678);\n    int _2743 = (_2675 * 9) + _2678;\n    int _2763 = ((_2675 + 1) * 9) + _2678;\n    return mix(mix(_2739[_2743], _2739[_2743 + 1], _2688), mix(_2739[_2763], _2739[_2763 + 1], _2688), _2665 - float(_2675));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4836 = false;\n    float _4837 = 1.0;\n    float _4838 = 1.0;\n    float _4839 = 1.0;\n    float _4840 = 0.0;\n    float _4841 = 0.0;\n    float _4842 = 0.0;\n    float _4843 = 0.0;\n    float _4845 = 1.0;\n    bool _4846 = false;\n    float3 _4847 = float3(0.0);\n    float _4848 = 1.0;\n    float _4849 = 1.0;\n    float _4850 = 1.0;\n    float _4851 = 0.0;\n    float _4852 = 0.0;\n    float3 _4853 = float3(1.0, 0.0, 0.0);\n    float3 _4854 = float3(0.0, 0.0, 1.0);\n    float _4855 = 1.0;\n    float _4856 = 1.0;\n    float _2816 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2820 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2825 = (_2816 != 1.0) || (_2820 != 1.5);\n    bool _2835;\n    if (!_2825)\n    {\n        _2835 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2835 = _2825;\n    }\n    if (_2835)\n    {\n        float _2843 = (_2820 - 1.0) / (_2820 + 1.0);\n        f0 = mix(fast::min(float3(_2843 * _2843) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2816, s.albedo, float3(metallic));\n        _4837 = mix(_2816, 1.0, metallic);\n        _4836 = true;\n    }\n    float _2871 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2871 > 0.0)\n    {\n        float _2879 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4840 = _2871;\n        _4841 = _2879;\n        float _2886 = _2879 * _2879;\n        _4842 = _2886;\n        _4843 = _2886 * _2886;\n        float _2898 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4845 = _2898;\n        _4838 = 1.0 - (_2871 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2898, 0.0, 1.0), 5.0))));\n        _4836 = true;\n    }\n    float3 _2917 = fast::max(s.sheen_color, float3(0.0));\n    float _2926 = fast::max(_2917.x, fast::max(_2917.y, _2917.z));\n    if (_2926 > 0.0)\n    {\n        float _2934 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4846 = true;\n        _4847 = _2917;\n        _4848 = _2934;\n        _4849 = _2934 * _2934;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2934;\n        float _2951 = fa_sheen_albedo(param, param_1);\n        _4851 = _2951;\n        _4850 = 1.0 - fast::min(_2926 * _2951, 1.0);\n        _4836 = true;\n    }\n    _4839 = _4838 * _4850;\n    float _2970 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2970 != 0.0)\n    {\n        float3 _2985 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2985;\n        if (dot(_2985, _2985) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _3002 = t;\n        float3 _3003 = fast::normalize(_3002);\n        t = _3003;\n        float3 _3028 = fast::normalize((_3003 * cos(s.anisotropy_rotation)) + ((cross(n, _3003) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4853 = _3028;\n        _4854 = cross(n, _3028);\n        float _3038 = roughness * roughness;\n        float _3044 = mix(_3038, 1.0, _2970 * _2970);\n        bool _3046 = _2970 > 0.0;\n        _4855 = _3046 ? _3044 : _3038;\n        _4856 = _3046 ? _3038 : _3044;\n        _4852 = _2970;\n        _4836 = true;\n    }\n    return FaLayers{ short(_4836), _4837, _4838, _4839, _4840, _4841, _4842, _4843, i.world_normal, _4845, short(_4846), _4847, _4848, _4849, _4850, _4851, _4852, _4853, _4854, _4855, _4856 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _547, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_547.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _2422 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _2422;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _547, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_547.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _547, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _547.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _547, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _547, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _547)\n{\n    int param = (int(_547.fa_cl_info.x) + int(_547.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _547, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _547);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _421 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _427 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _430 = _427.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _436 = _430 < 0.5;\n    float3 l;\n    if (_436)\n    {\n        l = fast::normalize(_421.xyz);\n    }\n    else\n    {\n        float3 _448 = _421.xyz - world_pos;\n        float _450 = length(_448);\n        dist = _450;\n        l = _448 / float3(fast::max(_450, 9.9999997473787516355514526367188e-05));\n        float _465 = _450 / fast::max(_421.w, 0.001000000047497451305389404296875);\n        float _471 = fast::clamp(1.0 - (_465 * _465), 0.0, 1.0);\n        atten = _471 * _471;\n        if (_430 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _485 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _495 = _485.w;\n            int param_3 = (li * 4) + 3;\n            float4 _501 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _502 = _501.x;\n            float cos_inner = _502;\n            if (_502 > 1.5)\n            {\n                cos_inner = mix(_495, 1.0, 0.25);\n            }\n            atten *= smoothstep(_495, cos_inner, dot(-l, fast::normalize(_485.xyz)));\n        }\n    }\n    int _533;\n    if (_436)\n    {\n        _533 = 0;\n    }\n    else\n    {\n        _533 = (_430 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _427.xyz * atten, atten, 1.0, dist, _533 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1287)\n{\n    float _1277;\n    if (i == 0)\n    {\n        _1277 = _1287.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1293;\n        if (i == 1)\n        {\n            _1293 = _1287.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1301;\n            if (i == 2)\n            {\n                _1301 = _1287.fa_shadow_split.z;\n            }\n            else\n            {\n                _1301 = _1287.fa_shadow_split.w;\n            }\n            _1293 = _1301;\n        }\n        _1277 = _1293;\n    }\n    return _1277;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1334 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1338;\n    if (conv.x < 0.5)\n    {\n        _1338 = _1334;\n    }\n    else\n    {\n        _1338 = (conv.y * conv.z) / (conv.z - (_1334 * (conv.z - conv.y)));\n    }\n    return _1338;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1265 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1265), sin(_1265)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1287, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1384 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1398 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1384;\n            float2 _1417 = fa_shadow_vogel(param_3, param_4, param_5) * _1398;\n            float2 param_6 = uv + (_1417 * _1287.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1429 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1429 < (zr - (length(_1417) * plane)))\n            {\n                sum += _1429;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1473 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1473; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1473;\n        float param_11 = _1384;\n        float2 _1492 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1492 * _1287.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1492) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1473);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1287, texture2d<float> fa_shadow_tex)\n{\n    float _1534 = fast::max(_1287.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1539 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1545 = sqrt(1.0 - (_1539 * _1539));\n    float _1552 = fast::min(_1545 / fast::max(_1539, 0.20000000298023223876953125), 4.0);\n    float _1557;\n    if (_1287.fa_shadow_bias.y > 0.0)\n    {\n        _1557 = _1287.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1557 = 1.5 * _1287.fa_shadow_info[ci].x;\n    }\n    float4 _1582 = _1287.fa_shadow_mat[ci] * float4(world + (n * (_1557 * _1545)), 1.0);\n    float _1589 = _1582.x;\n    bool _1592 = _1589 < _1287.fa_shadow_rect[ci].x;\n    bool _1601;\n    if (!_1592)\n    {\n        _1601 = _1589 > _1287.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1601 = _1592;\n    }\n    bool _1610;\n    if (!_1601)\n    {\n        _1610 = _1582.y < _1287.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1610 = _1601;\n    }\n    bool _1619;\n    if (!_1610)\n    {\n        _1619 = _1582.y > _1287.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1619 = _1610;\n    }\n    bool _1626;\n    if (!_1619)\n    {\n        _1626 = _1582.z > 1.0;\n    }\n    else\n    {\n        _1626 = _1619;\n    }\n    if (_1626)\n    {\n        return -1.0;\n    }\n    float _1635;\n    if (_1287.fa_shadow_bias.x > 0.0)\n    {\n        _1635 = _1287.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1635 = 1.5 * _1287.fa_shadow_info[ci].x;\n    }\n    float2 param = _1582.xy;\n    float4 param_1 = _1287.fa_shadow_rect[ci];\n    float param_2 = _1582.z - ((_1635 * (1.0 + (0.5 * _1552))) / _1534);\n    float param_3 = _1287.fa_shadow_info[ci].x;\n    float param_4 = _1534;\n    float param_5 = _1534 * 0.25;\n    float param_6 = ((_1287.fa_shadow_info[ci].x * fast::min(_1552, 3.0)) * 0.5) / _1534;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1287.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1287.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1287, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _547, thread float4& gl_FragCoord, constant fa_shadows& _1287, texture2d<float> fa_shadow_tex)\n{\n    if (_547.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2062 = int(_1287.fa_shadow_cfg.x + 0.5);\n    if (_2062 < 1)\n    {\n        return 1.0;\n    }\n    float _2077 = dot(world - _1287.fa_shadow_eye.xyz, _1287.fa_shadow_fwd.xyz);\n    int param = _2062 - 1;\n    if (_2077 > fa_shadow_split_at(param, _1287))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2089 = _2062 > 1;\n    bool _2096;\n    if (_2089)\n    {\n        _2096 = _2077 > _1287.fa_shadow_split.x;\n    }\n    else\n    {\n        _2096 = _2089;\n    }\n    if (_2096)\n    {\n        ci = 1;\n    }\n    bool _2100 = _2062 > 2;\n    bool _2107;\n    if (_2100)\n    {\n        _2107 = _2077 > _1287.fa_shadow_split.y;\n    }\n    else\n    {\n        _2107 = _2100;\n    }\n    if (_2107)\n    {\n        ci = 2;\n    }\n    bool _2111 = _2062 > 3;\n    bool _2118;\n    if (_2111)\n    {\n        _2118 = _2077 > _1287.fa_shadow_split.z;\n    }\n    else\n    {\n        _2118 = _2111;\n    }\n    if (_2118)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2062)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2144 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1287, fa_shadow_tex);\n        s = _2144;\n        if (_2144 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1287.fa_shadow_cfg.y > 0.0)\n    {\n        float _2169;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2169 = fa_shadow_split_at(param_5, _1287);\n        }\n        else\n        {\n            _2169 = _1287.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2188 = _1287.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1287) - _2169, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2199 = fast::clamp((_2077 - (fa_shadow_split_at(param_7, _1287) - _2188)) / _2188, 0.0, 1.0);\n        if (_2199 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2062)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2220 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1287, fa_shadow_tex);\n                s2 = _2220;\n                if (_2220 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2199);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _547, thread float4& gl_FragCoord, constant fa_shadows& _1287, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _547, gl_FragCoord, _1287, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _547, thread float4& gl_FragCoord, constant fa_shadows& _1287, texture2d<float> fa_shadow_tex)\n{\n    bool _1693 = _547.fa_pbr.z < 0.5;\n    bool _1701;\n    if (!_1693)\n    {\n        _1701 = _1287.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1701 = _1693;\n    }\n    if (_1701)\n    {\n        return 1.0;\n    }\n    int param = (int(_1287.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1714 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1715 = _1714.x;\n    if (_1715 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1724 = int(_1715 + 0.5);\n    int param_1 = _1724;\n    float4 _1728 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1724 + 1;\n    float4 _1733 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1736 = _1728.y;\n    if (_1736 > 0.0)\n    {\n        float _1753 = 1.0 - smoothstep(0.75 * _1736, _1736, length(world - _1287.fa_shadow_eye.xyz));\n        fade = _1753;\n        if (_1753 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1728.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1772 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1775 = abs(_1772);\n        float _1777 = _1775.x;\n        float _1779 = _1775.y;\n        bool _1780 = _1777 >= _1779;\n        bool _1788;\n        if (_1780)\n        {\n            _1788 = _1777 >= _1775.z;\n        }\n        else\n        {\n            _1788 = _1780;\n        }\n        int _1789;\n        if (_1788)\n        {\n            _1789 = (_1772.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1802;\n            if (_1779 >= _1775.z)\n            {\n                _1802 = (_1772.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1802 = (_1772.z > 0.0) ? 4 : 5;\n            }\n            _1789 = _1802;\n        }\n        face = _1789;\n    }\n    int _1821 = (_1724 + 2) + (face * 6);\n    int param_4 = _1821;\n    int param_5 = _1821 + 1;\n    int param_6 = _1821 + 3;\n    float4 _1835 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1821 + 4;\n    float4 _1840 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1821 + 5;\n    float4 _1845 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1857 = _1845.x * fast::max(dot(_1835, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1862 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1885 = fast::clamp(dot(n, _1835.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1908 = fast::min(sqrt(1.0 - (_1885 * _1885)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1835, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1911 = _1733.y;\n    float _1913;\n    if (_1911 > 0.0)\n    {\n        _1913 = _1911;\n    }\n    else\n    {\n        _1913 = 1.5 * _1857;\n    }\n    float4 _1933 = float4(world + (n * (_1913 * sqrt(1.0 - (_1862 * _1862)))), 1.0);\n    float _1937 = dot(_1835, _1933);\n    float _1940 = _1845.y;\n    if (_1937 < _1940)\n    {\n        return 1.0;\n    }\n    float2 _1955 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1933), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1933)) / float2(_1937);\n    float _1957 = _1955.x;\n    bool _1960 = _1957 < _1840.x;\n    bool _1969;\n    if (!_1960)\n    {\n        _1969 = _1957 > _1840.z;\n    }\n    else\n    {\n        _1969 = _1960;\n    }\n    bool _1978;\n    if (!_1969)\n    {\n        _1978 = _1955.y < _1840.y;\n    }\n    else\n    {\n        _1978 = _1969;\n    }\n    bool _1987;\n    if (!_1978)\n    {\n        _1987 = _1955.y > _1840.w;\n    }\n    else\n    {\n        _1987 = _1978;\n    }\n    if (_1987)\n    {\n        return 1.0;\n    }\n    float _1993 = _1733.x;\n    float _1995;\n    if (_1993 > 0.0)\n    {\n        _1995 = _1993;\n    }\n    else\n    {\n        _1995 = 1.5 * _1857;\n    }\n    float2 param_10 = _1955;\n    float4 param_11 = _1840;\n    float param_12 = _1937 - (_1995 * (1.0 + (0.5 * _1908)));\n    float param_13 = _1857;\n    float param_14 = 1.0;\n    float param_15 = _1845.z * 0.25;\n    float param_16 = (_1857 * fast::min(_1908, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1940, _1845.z);\n    int param_18 = int(_1728.z + 0.5);\n    float param_19 = _1728.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1287, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _547, thread float4& gl_FragCoord, constant fa_shadows& _1287, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3579 = fa_lm.z > 0.5;\n    bool _3585;\n    if (_3579)\n    {\n        int param = li;\n        _3585 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3585 = _3579;\n    }\n    if (_3585)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3607 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _4898 = _3607.direction;\n    float3 _4893 = _3607.color;\n    float _4900 = _3607.attenuation;\n    float _4895 = _3607.shadow;\n    int _4903 = _3607.type;\n    if ((_4903 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4898;\n        float _3621 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _547, gl_FragCoord, _1287, fa_shadow_tex, fa_world_pos);\n        _4895 = _3621;\n        _4893 *= _3621;\n    }\n    else\n    {\n        bool _3632 = _4903 != 0;\n        bool _3638;\n        if (_3632)\n        {\n            _3638 = _4900 > 0.0;\n        }\n        else\n        {\n            _3638 = _3632;\n        }\n        if (_3638)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4898;\n            float _3650 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _547, gl_FragCoord, _1287, fa_shadow_tex);\n            _4895 = _3650;\n            _4893 *= _3650;\n        }\n    }\n    return LightSample{ _4898, _4893, _4900, _4895, _3607._distance, _4903 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _3196 = tdh / at;\n    float _3200 = bdh / ab;\n    float _3212 = ((_3196 * _3196) + (_3200 * _3200)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3212) * _3212);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _3293 = 1.0 / alpha;\n    return ((2.0 + _3293) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3293)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _3325 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3404 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3404) * _3404);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3325);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3325));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3477 = fast::max(dot(L.nc, l), 0.0);\n        float _3483 = fast::max(dot(L.nc, h), 0.0);\n        float _3492 = ((_3483 * _3483) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3492) * _3492)) * (0.5 / fast::max(mix((2.0 * _3477) * L.coat_ndv, _3477 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3477)) * _3477);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _2597 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2600 = _2597.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_2600 * _2600, exp2((-9.27999973297119140625) * ndv)) * _2600) + _2597.y)) + _2597.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _547, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_547.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _547.fa_env_horizon.w)).xyz;\n    }\n    float _2451 = rough * rough;\n    float _2481 = 0.60000002384185791015625 * _2451;\n    return mix(mix(_547.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_547.fa_env_horizon.xyz, _547.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _2451)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _2481, 0.0500000007450580596923828125 + _2481, d.y))), ((_547.fa_env_sky.xyz + _547.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_2451 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _547, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _3079;\n        if (L.aniso >= 0.0)\n        {\n            _3079 = L.b;\n        }\n        else\n        {\n            _3079 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_3079, v), _3079), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3112 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _547, fa_env_smp, fa_env_tex) * ((f0 * _3112.x) + (float3(L.f90) * _3112.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _547, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3167 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _547, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _3167.x) + _3167.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _547, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2639 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _547, fa_env_smp, fa_env_tex) * ((f0 * _2639.x) + float3(_2639.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1287)\n{\n    if (_1287.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2244 = int(_1287.fa_shadow_cfg.x + 0.5);\n    float _2254 = dot(world - _1287.fa_shadow_eye.xyz, _1287.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2259 = _2244 > 0;\n    bool _2268;\n    if (_2259)\n    {\n        int param = _2244 - 1;\n        _2268 = _2254 <= fa_shadow_split_at(param, _1287);\n    }\n    else\n    {\n        _2268 = _2259;\n    }\n    if (_2268)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2275 = _2244 > 1;\n        bool _2282;\n        if (_2275)\n        {\n            _2282 = _2254 > _1287.fa_shadow_split.x;\n        }\n        else\n        {\n            _2282 = _2275;\n        }\n        if (_2282)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2288 = _2244 > 2;\n        bool _2295;\n        if (_2288)\n        {\n            _2295 = _2254 > _1287.fa_shadow_split.y;\n        }\n        else\n        {\n            _2295 = _2288;\n        }\n        if (_2295)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2301 = _2244 > 3;\n        bool _2308;\n        if (_2301)\n        {\n            _2308 = _2254 > _1287.fa_shadow_split.z;\n        }\n        else\n        {\n            _2308 = _2301;\n        }\n        if (_2308)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _547 [[buffer(1)]], constant fa_shadows& _1287 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4615 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4615 = -_4615;\n    }\n    float3 _4040 = fast::normalize(_547.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _547, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4615, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4040, short(gl_FrontFacing) };\n    Surface _4048 = fa_standard_surface(param_1, _547, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4646 = _4048.albedo;\n    float _4647 = _4048.alpha;\n    float3 _4648 = _4048.normal;\n    float _4649 = _4048.metallic;\n    float _4650 = _4048.roughness;\n    float _4651 = _4048.occlusion;\n    float3 _4652 = _4048.emission;\n    float _4653 = _4048.clearcoat;\n    float _4654 = _4048.clearcoat_roughness;\n    float3 _4655 = _4048.sheen_color;\n    float _4656 = _4048.sheen_roughness;\n    float _4657 = _4048.anisotropy;\n    float _4658 = _4048.anisotropy_rotation;\n    float _4659 = _4048.specular;\n    float _4660 = _4048.ior;\n    float3 _4661 = _4048.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4615, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4040, short(gl_FrontFacing) };\n    Surface param_3 = _4048;\n    surface(param_2, param_3);\n    _4646 = param_3.albedo;\n    _4647 = param_3.alpha;\n    _4648 = param_3.normal;\n    _4649 = param_3.metallic;\n    _4650 = param_3.roughness;\n    _4651 = param_3.occlusion;\n    _4652 = param_3.emission;\n    _4653 = param_3.clearcoat;\n    _4654 = param_3.clearcoat_roughness;\n    _4655 = param_3.sheen_color;\n    _4656 = param_3.sheen_roughness;\n    _4657 = param_3.anisotropy;\n    _4658 = param_3.anisotropy_rotation;\n    _4659 = param_3.specular;\n    _4660 = param_3.ior;\n    _4661 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4615;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _547, fa_decal_tex, fa_env_smp);\n    _4646 = param_6;\n    _4648 = param_7;\n    float3 result;\n    if (_547.fa_emissive.w > 0.5)\n    {\n        result = _4646;\n    }\n    else\n    {\n        float3 _4087 = fast::normalize(_4648);\n        float _4094 = fast::clamp(_4649, 0.0, 1.0);\n        float _4098 = fast::clamp(_4650, 0.0500000007450580596923828125, 1.0);\n        float _4102 = _4098 * _4098;\n        float _4106 = _4102 * _4102;\n        float _4111 = fast::max(dot(_4087, _4040), 9.9999997473787516355514526367188e-05);\n        float3 _4117 = _4646 * (1.0 - _4094);\n        float3 _4124 = mix(float3(0.039999999105930328369140625), _4646, float3(_4094));\n        float3 f0 = _4124;\n        SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _4615, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4040, short(gl_FrontFacing) };\n        Surface param_9 = Surface{ _4646, _4647, _4648, _4649, _4650, _4651, _4652, _4653, _4654, _4655, _4656, _4657, _4658, _4659, _4660, _4661 };\n        float3 param_10 = _4087;\n        float3 param_11 = _4040;\n        float param_12 = _4094;\n        float param_13 = _4098;\n        float3 param_14 = _4124;\n        FaLayers _4140 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _4087;\n        float3 lit = (fa_indirect_diffuse(param_15, _547, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap) * _4117) * _4651;\n        if (_4140.on)\n        {\n            lit *= _4140.base_scale;\n        }\n        int _4162 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4162; ln++)\n        {\n            int param_16 = ln;\n            int _4175 = fa_cl_light(param_16, fa_light_tex, fa_shadow_smp, _547, fa_cl_ndir, fa_cl_slot);\n            bool _4178 = in.fa_lm.z > 0.5;\n            bool _4184;\n            if (_4178)\n            {\n                int param_17 = _4175;\n                _4184 = fa_light_baked(param_17, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _4184 = _4178;\n            }\n            if (_4184)\n            {\n                continue;\n            }\n            int param_18 = _4175;\n            float3 param_19 = in.fa_world_pos;\n            float3 param_20 = _4615;\n            LightSample _4196 = fa_light_shadowed(param_18, param_19, param_20, fa_light_tex, fa_shadow_smp, _547, gl_FragCoord, _1287, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            float3 _4820 = _4196.direction;\n            float _4204 = fast::max(dot(_4087, _4820), 0.0);\n            float _4210 = _4196.attenuation * _4196.shadow;\n            float3 _4215 = fast::normalize(_4820 + _4040);\n            float _4220 = fast::max(dot(_4087, _4215), 0.0);\n            float _4225 = fast::max(dot(_4040, _4215), 0.0);\n            if (_4140.on)\n            {\n                FaLayers param_21 = _4140;\n                float3 param_22 = _4117;\n                float3 param_23 = f0;\n                float3 param_24 = _4087;\n                float3 param_25 = _4040;\n                float3 param_26 = _4820;\n                float3 param_27 = _4215;\n                float param_28 = _4204;\n                float param_29 = _4111;\n                float param_30 = _4220;\n                float param_31 = _4225;\n                float param_32 = _4102;\n                float param_33 = _4106;\n                int param_34 = _4175;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34, fa_light_tex, fa_shadow_smp) * _4210));\n            }\n            else\n            {\n                float _4273 = ((_4220 * _4220) * (_4106 - 1.0)) + 1.0;\n                int param_35 = _4175;\n                lit += (((_4117 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _4225, 5.0))) * (((_4106 / ((3.1415927410125732421875 * _4273) * _4273)) * (0.5 / fast::max(mix((2.0 * _4204) * _4111, _4204 + _4111, _4102), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4204))) * fa_light_rgb(param_35, fa_light_tex, fa_shadow_smp)) * (_4204 * _4210));\n            }\n        }\n        if (_4140.on)\n        {\n            FaLayers param_36 = _4140;\n            float3 param_37 = _4087;\n            float3 param_38 = _4040;\n            float3 param_39 = f0;\n            float param_40 = _4098;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40, _547, fa_env_smp, fa_env_tex) * _4651);\n        }\n        else\n        {\n            float3 param_41 = _4087;\n            float3 param_42 = _4040;\n            float3 param_43 = f0;\n            float param_44 = _4098;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44, _547, fa_env_smp, fa_env_tex) * _4651);\n        }\n        result = lit;\n    }\n    float3 _4366 = result;\n    float3 _4367 = _4366 + _4652;\n    result = _4367;\n    float3 param_45 = _4367;\n    float3 param_46 = in.fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46, _1287);\n    bool _4376 = _547.fa_fog.w > 0.0;\n    bool _4383;\n    if (!_4376)\n    {\n        _4383 = _547.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4383 = _4376;\n    }\n    if (_4383)\n    {\n        float3 _4392 = in.fa_world_pos - _547.fa_camera_pos.xyz;\n        float _4398 = dot(_4392, _547.fa_fog_c.xyz);\n        bool _4402 = _547.fa_fog_c.w > 0.5;\n        float _4403;\n        if (_4402)\n        {\n            _4403 = _4398;\n        }\n        else\n        {\n            _4403 = length(_4392);\n        }\n        float _4415 = _4403 - _547.fa_fog_b.x;\n        if (_4415 > 0.0)\n        {\n            float _4424 = _547.fa_fog.w * _4415;\n            float tau = _4424 * _4424;\n            if (_547.fa_fog_b.y > 0.0)\n            {\n                float _4440;\n                if (_4402)\n                {\n                    _4440 = in.fa_world_pos.y - (_547.fa_fog_c.y * _4398);\n                }\n                else\n                {\n                    _4440 = _547.fa_camera_pos.y;\n                }\n                float _4461 = mix(_4440, in.fa_world_pos.y, fast::clamp(_547.fa_fog_b.x / _4403, 0.0, 1.0));\n                float _4465 = in.fa_world_pos.y - _4461;\n                float _4470 = _4461 - _547.fa_fog_b.z;\n                float _4475 = in.fa_world_pos.y - _547.fa_fog_b.z;\n                bool _4478 = _4470 <= 0.0;\n                bool _4479 = !_4478;\n                bool _4485;\n                if (_4479)\n                {\n                    _4485 = _547.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4485 = _4478;\n                }\n                float _4486;\n                if (_4485)\n                {\n                    _4486 = _547.fa_fog_b.y;\n                }\n                else\n                {\n                    _4486 = _547.fa_fog_b.y * exp(-fast::min(_547.fa_fog_b.w * _4470, 80.0));\n                }\n                bool _4513;\n                if (_4479)\n                {\n                    _4513 = _547.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4513 = _4478;\n                }\n                float _4514;\n                if (_4513)\n                {\n                    _4514 = _547.fa_fog_b.y * _4470;\n                }\n                else\n                {\n                    _4514 = (_547.fa_fog_b.y * (1.0 - exp(-fast::min(_547.fa_fog_b.w * _4470, 80.0)))) / _547.fa_fog_b.w;\n                }\n                bool _4539 = _4475 <= 0.0;\n                bool _4546;\n                if (!_4539)\n                {\n                    _4546 = _547.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4546 = _4539;\n                }\n                float _4547;\n                if (_4546)\n                {\n                    _4547 = _547.fa_fog_b.y * _4475;\n                }\n                else\n                {\n                    _4547 = (_547.fa_fog_b.y * (1.0 - exp(-fast::min(_547.fa_fog_b.w * _4475, 80.0)))) / _547.fa_fog_b.w;\n                }\n                float _4574;\n                if (abs(_4465) < 0.001000000047497451305389404296875)\n                {\n                    _4574 = _4486;\n                }\n                else\n                {\n                    _4574 = (_4547 - _4514) / _4465;\n                }\n                tau += (_4415 * fast::max(_4574, 0.0));\n            }\n            result = mix(result, _547.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4647);\n    return out;\n}\n\n",
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
            "type": "vec2",
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
            "inst_name": "_144",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_547",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1287",
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n    float2 fa_attr_uv1 [[attribute(11)]];\n    float4 fa_attr_color1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float4& vertex_color1, thread float2& vertex_uv1, thread float2& fa_attr_uv1, thread float4& fa_attr_color1)\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _195)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _186 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_195.fa_joint_rows[_186] * weights[i]);\n        r1 += (_195.fa_joint_rows[_186 + 1] * weights[i]);\n        r2 += (_195.fa_joint_rows[_186 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _149)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _149.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float4& vertex_color1, thread float2& vertex_uv1)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float4& vertex_color1, thread float2& vertex_uv1, constant fa_mesh_vs_params& _149, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _149);\n    vertex0(param_6, vertex_color1, vertex_uv1);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _149.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _149 [[buffer(0)]], constant fa_skin& _195 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 vertex_color1;\n    float2 vertex_uv1;\n    fa_inst_begin(vertex_color1, vertex_uv1, in.fa_attr_uv1, in.fa_attr_color1);\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _195);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, vertex_color1, vertex_uv1, _149, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nconstant spvUnsafeArray<float, 63> _2739 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _547)\n{\n    bool _552 = _547.fa_cl_info.x < 0.0;\n    bool _559;\n    if (!_552)\n    {\n        _559 = _547.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _559 = _552;\n    }\n    bool _567;\n    if (!_559)\n    {\n        _567 = _547.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _567 = _559;\n    }\n    bool _574;\n    if (!_567)\n    {\n        _574 = _547.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _574 = _567;\n    }\n    bool _581;\n    if (!_574)\n    {\n        _581 = _547.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _581 = _574;\n    }\n    if (_581)\n    {\n        return float4(0.0);\n    }\n    float4 _591 = float4(world_pos, 1.0);\n    float _598 = dot(_547.fa_cl_vpw, _591);\n    if (!(_598 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _620 = float2(dot(_547.fa_cl_vpx, _591), dot(_547.fa_cl_vpy, _591)) / float2(_598);\n    int _624 = int(_547.fa_cl_grid.x);\n    int _628 = int(_547.fa_cl_grid.y);\n    int param = (int(_547.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_547.fa_cl_fwd.xyz, world_pos) + _547.fa_cl_fwd.w, _547.fa_cl_grid.w) / _547.fa_cl_grid.w) * _547.fa_cl_grid.z)), 0, int(_547.fa_cl_info.y) - 1) * _628) + clamp(int(floor(((_620.y * 0.5) + 0.5) * _547.fa_cl_grid.y)), 0, _628 - 1)) * _624)) + clamp(int(floor(((_620.x * 0.5) + 0.5) * _547.fa_cl_grid.x)), 0, _624 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _547)\n{\n    float3 param = world_pos;\n    float4 _704 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _547);\n    return int2(int(_704.x), int(_704.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _547, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_547.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3552 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _547);\n    fa_cl_slot = _3552.x;\n    fa_cl_local = _3552.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3708 = fa_linear_to_srgb(param);\n        c = _3708;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3716 = fa_srgb_to_linear(param_1);\n            c = _3716;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _303;\n    if (bool(i.front_facing))\n    {\n        _303 = i.world_normal;\n    }\n    else\n    {\n        _303 = -i.world_normal;\n    }\n    float3 _327 = fast::normalize(i.world_tangent.xyz - (_303 * dot(_303, i.world_tangent.xyz)));\n    float3 _354 = fast::normalize(((_327 * m.x) + ((cross(_303, _327) * i.world_tangent.w) * m.y)) + (_303 * m.z));\n    float3 _357;\n    if (bool(i.front_facing))\n    {\n        _357 = _354;\n    }\n    else\n    {\n        _357 = -_354;\n    }\n    return _357;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _547, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _547.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3747 = fa_tex_fix(param_2, param_3);\n    float4 _5046 = base_t;\n    _5046.x = _3747.x;\n    _5046.y = _3747.y;\n    _5046.z = _3747.z;\n    base_t = _5046;\n    float4 _3761 = (_5046 * _547.fa_base_color) * i.vertex_color;\n    float3 _4913 = i.world_normal;\n    if (_547.fa_maps.z > 0.5)\n    {\n        float param_4 = _547.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3793 = fa_tex_fix(param_6, param_7);\n        float3 _3796 = (_3793 * 2.0) - float3(1.0);\n        float2 _3801 = _3796.xy * _547.fa_maps.x;\n        float3 _5054 = _3796;\n        _5054.x = _3801.x;\n        _5054.y = _3801.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5054;\n        _4913 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _547.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3830 = fa_tex_fix(param_12, param_13);\n    float4 _5057 = mrt;\n    _5057.x = _3830.x;\n    _5057.y = _3830.y;\n    _5057.z = _3830.z;\n    mrt = _5057;\n    float4 _3858 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _547.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3858.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3870 = fa_tex_fix(param_16, param_17);\n    float param_18 = _547.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3900 = fa_tex_fix(param_20, param_21);\n    float _4918 = _547.fa_layers_a.x;\n    float _4919 = _547.fa_layers_a.y;\n    float _4922 = _547.fa_layers_a.z;\n    float _4921 = _547.fa_layers_b.w;\n    float _4924 = _547.fa_layers_c.x;\n    if (_547.fa_layers_c.z > 0.5)\n    {\n        if (mod(_547.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4918 *= _3870.y;\n            _4919 *= _3870.z;\n            _4921 *= _3858.w;\n        }\n        if (_547.fa_layers_c.z > 1.5)\n        {\n            _4922 *= mrt.x;\n            _4924 *= mrt.w;\n        }\n    }\n    return Surface{ _3761.xyz, _3761.w, _4913, fast::clamp(_547.fa_pbr.x * _3830.z, 0.0, 1.0), fast::clamp(_547.fa_pbr.y * _3830.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_547.fa_maps.y * (_3870.x - 1.0)), _547.fa_emissive.xyz + (_547.fa_model_emissive.xyz * _3900), _4918, _4919, _547.fa_layers_b.xyz, _4921, _4922, _547.fa_layers_a.w, _4924, _547.fa_layers_c.y, _547.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    float2 _785 = rect.zw - rect.xy;\n    float2 _789 = _785 * atlas;\n    float2 _793 = ddx * _789;\n    float2 _797 = ddy * _789;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _785)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_793, _793), dot(_797, _797)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _547, texture2d<float> fa_decal_tex, sampler fa_env_smp)\n{\n    bool _832 = _547.fa_counts.y < 0.5;\n    bool _839;\n    if (!_832)\n    {\n        _839 = _547.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _839 = _832;\n    }\n    if (_839)\n    {\n        return;\n    }\n    float3 _845 = dfdx(world_pos);\n    float3 _848 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _852 = fa_cluster_texel(param, fa_light_tex, fa_shadow_smp, _547);\n    int _856 = int(_852.w);\n    if (_856 < 1)\n    {\n        return;\n    }\n    int _866 = int(_547.fa_counts.y + 0.5);\n    int param_1 = _866;\n    float4 _870 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _873 = _870.yz;\n    int _877 = int(_870.w);\n    int param_2 = _866 + 1;\n    float4 _882 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _883 = _882.x;\n    int _889 = int(_547.fa_counts.w + 0.5) - 1;\n    int _893 = int(_852.z);\n    float3 _1159;\n    for (int k = 0; k < _856; k++)\n    {\n        int _906 = _893 + k;\n        int param_3 = _877 + (_906 >> 2);\n        int _924 = (_866 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_906 & 3]) * 7);\n        int param_4 = _924 + 6;\n        float4 _929 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_929.w + 0.5) >> _889) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _924;\n        float4 _944 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _924 + 1;\n        float4 _949 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _924 + 2;\n        float4 _954 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _957 = _944.xyz;\n        float _962 = dot(_957, world_pos) + _944.w;\n        float3 _964 = _949.xyz;\n        float _969 = dot(_964, world_pos) + _949.w;\n        float3 _971 = _954.xyz;\n        float _976 = dot(_971, world_pos) + _954.w;\n        bool _981 = abs(_962) > 0.5;\n        bool _989;\n        if (!_981)\n        {\n            _989 = abs(_969) > 0.5;\n        }\n        else\n        {\n            _989 = _981;\n        }\n        bool _997;\n        if (!_989)\n        {\n            _997 = abs(_976) > 0.5;\n        }\n        else\n        {\n            _997 = _989;\n        }\n        if (_997)\n        {\n            continue;\n        }\n        float _1012 = fast::clamp(dot(geo_normal, fast::normalize(_971)) * _929.z, 0.0, 1.0);\n        if (_1012 <= 0.0)\n        {\n            continue;\n        }\n        float _1032 = (fast::clamp((0.5 - abs(_976)) * 10.0, 0.0, 1.0) * _1012) * _929.x;\n        float2 _1040 = float2(_962 + 0.5, 0.5 - _969);\n        float2 _1050 = float2(dot(_957, _845), dot(_964, _845));\n        float2 _1060 = float2(dot(_957, _848), dot(_964, _848));\n        int param_8 = _924 + 5;\n        float4 _1065 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _924 + 3;\n        float4 _1070 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _924 + 4;\n        float4 _1075 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1065.xyz;\n        bool _1085 = _1070.z > _1070.x;\n        if (_1085)\n        {\n            float4 param_11 = _1070;\n            float2 param_12 = _1040;\n            float2 param_13 = _873;\n            float2 param_14 = _1050;\n            float2 param_15 = _1060;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_decal_tex, fa_env_smp);\n            if ((_883 > 0.5) && (_883 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1111 = fa_dc_to_linear(param_16);\n                float4 _4969 = tx;\n                _4969.x = _1111.x;\n                _4969.y = _1111.y;\n                _4969.z = _1111.z;\n                tx = _4969;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1032 * tex_a) * _1065.w, 0.0, 1.0)));\n        if (_1075.z > _1075.x)\n        {\n            float4 param_17 = _1075;\n            float2 param_18 = _1040;\n            float2 param_19 = _873;\n            float2 param_20 = _1050;\n            float2 param_21 = _1060;\n            float4 _1155 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_decal_tex, fa_env_smp);\n            if (_883 > 1.5)\n            {\n                float3 param_22 = _1155.xyz;\n                float3 _1165 = fa_dc_to_srgb(param_22);\n                _1159 = _1165;\n            }\n            else\n            {\n                _1159 = _1155.xyz;\n            }\n            float3 _1175 = (_1159 * 2.0) - float3(1.0);\n            float2 _1180 = _1175.xy * _929.y;\n            float3 _1202 = (fast::normalize(_957) * _1180.x) + (fast::normalize(_964) * _1180.y);\n            float3 _1205 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1205, fast::normalize((_1205 * fast::max(_1175.z, 0.0500000007450580596923828125)) + (_1202 - (_1205 * dot(_1205, _1202)))), float3(fast::clamp(_1032 * (_1085 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _2665 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2672 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2675 = int(_2665);\n    int _2678 = int(_2672);\n    float _2688 = _2672 - float(_2678);\n    int _2743 = (_2675 * 9) + _2678;\n    int _2763 = ((_2675 + 1) * 9) + _2678;\n    return mix(mix(_2739[_2743], _2739[_2743 + 1], _2688), mix(_2739[_2763], _2739[_2763 + 1], _2688), _2665 - float(_2675));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4836 = false;\n    float _4837 = 1.0;\n    float _4838 = 1.0;\n    float _4839 = 1.0;\n    float _4840 = 0.0;\n    float _4841 = 0.0;\n    float _4842 = 0.0;\n    float _4843 = 0.0;\n    float _4845 = 1.0;\n    bool _4846 = false;\n    float3 _4847 = float3(0.0);\n    float _4848 = 1.0;\n    float _4849 = 1.0;\n    float _4850 = 1.0;\n    float _4851 = 0.0;\n    float _4852 = 0.0;\n    float3 _4853 = float3(1.0, 0.0, 0.0);\n    float3 _4854 = float3(0.0, 0.0, 1.0);\n    float _4855 = 1.0;\n    float _4856 = 1.0;\n    float _2816 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2820 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2825 = (_2816 != 1.0) || (_2820 != 1.5);\n    bool _2835;\n    if (!_2825)\n    {\n        _2835 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2835 = _2825;\n    }\n    if (_2835)\n    {\n        float _2843 = (_2820 - 1.0) / (_2820 + 1.0);\n        f0 = mix(fast::min(float3(_2843 * _2843) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2816, s.albedo, float3(metallic));\n        _4837 = mix(_2816, 1.0, metallic);\n        _4836 = true;\n    }\n    float _2871 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2871 > 0.0)\n    {\n        float _2879 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4840 = _2871;\n        _4841 = _2879;\n        float _2886 = _2879 * _2879;\n        _4842 = _2886;\n        _4843 = _2886 * _2886;\n        float _2898 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4845 = _2898;\n        _4838 = 1.0 - (_2871 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2898, 0.0, 1.0), 5.0))));\n        _4836 = true;\n    }\n    float3 _2917 = fast::max(s.sheen_color, float3(0.0));\n    float _2926 = fast::max(_2917.x, fast::max(_2917.y, _2917.z));\n    if (_2926 > 0.0)\n    {\n        float _2934 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4846 = true;\n        _4847 = _2917;\n        _4848 = _2934;\n        _4849 = _2934 * _2934;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2934;\n        float _2951 = fa_sheen_albedo(param, param_1);\n        _4851 = _2951;\n        _4850 = 1.0 - fast::min(_2926 * _2951, 1.0);\n        _4836 = true;\n    }\n    _4839 = _4838 * _4850;\n    float _2970 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2970 != 0.0)\n    {\n        float3 _2985 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2985;\n        if (dot(_2985, _2985) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _3002 = t;\n        float3 _3003 = fast::normalize(_3002);\n        t = _3003;\n        float3 _3028 = fast::normalize((_3003 * cos(s.anisotropy_rotation)) + ((cross(n, _3003) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4853 = _3028;\n        _4854 = cross(n, _3028);\n        float _3038 = roughness * roughness;\n        float _3044 = mix(_3038, 1.0, _2970 * _2970);\n        bool _3046 = _2970 > 0.0;\n        _4855 = _3046 ? _3044 : _3038;\n        _4856 = _3046 ? _3038 : _3044;\n        _4852 = _2970;\n        _4836 = true;\n    }\n    return FaLayers{ short(_4836), _4837, _4838, _4839, _4840, _4841, _4842, _4843, i.world_normal, _4845, short(_4846), _4847, _4848, _4849, _4850, _4851, _4852, _4853, _4854, _4855, _4856 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _547, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_547.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _2422 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _2422;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _547, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_547.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _547, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _547.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _547, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _547, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _547)\n{\n    int param = (int(_547.fa_cl_info.x) + int(_547.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _547, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _547);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _421 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _427 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _430 = _427.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _436 = _430 < 0.5;\n    float3 l;\n    if (_436)\n    {\n        l = fast::normalize(_421.xyz);\n    }\n    else\n    {\n        float3 _448 = _421.xyz - world_pos;\n        float _450 = length(_448);\n        dist = _450;\n        l = _448 / float3(fast::max(_450, 9.9999997473787516355514526367188e-05));\n        float _465 = _450 / fast::max(_421.w, 0.001000000047497451305389404296875);\n        float _471 = fast::clamp(1.0 - (_465 * _465), 0.0, 1.0);\n        atten = _471 * _471;\n        if (_430 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _485 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _495 = _485.w;\n            int param_3 = (li * 4) + 3;\n            float4 _501 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _502 = _501.x;\n            float cos_inner = _502;\n            if (_502 > 1.5)\n            {\n                cos_inner = mix(_495, 1.0, 0.25);\n            }\n            atten *= smoothstep(_495, cos_inner, dot(-l, fast::normalize(_485.xyz)));\n        }\n    }\n    int _533;\n    if (_436)\n    {\n        _533 = 0;\n    }\n    else\n    {\n        _533 = (_430 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _427.xyz * atten, atten, 1.0, dist, _533 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1287)\n{\n    float _1277;\n    if (i == 0)\n    {\n        _1277 = _1287.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1293;\n        if (i == 1)\n        {\n            _1293 = _1287.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1301;\n            if (i == 2)\n            {\n                _1301 = _1287.fa_shadow_split.z;\n            }\n            else\n            {\n                _1301 = _1287.fa_shadow_split.w;\n            }\n            _1293 = _1301;\n        }\n        _1277 = _1293;\n    }\n    return _1277;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1334 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _1338;\n    if (conv.x < 0.5)\n    {\n        _1338 = _1334;\n    }\n    else\n    {\n        _1338 = (conv.y * conv.z) / (conv.z - (_1334 * (conv.z - conv.y)));\n    }\n    return _1338;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1265 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1265), sin(_1265)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1287, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _1384 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1398 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1384;\n            float2 _1417 = fa_shadow_vogel(param_3, param_4, param_5) * _1398;\n            float2 param_6 = uv + (_1417 * _1287.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1429 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_1429 < (zr - (length(_1417) * plane)))\n            {\n                sum += _1429;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1473 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1473; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1473;\n        float param_11 = _1384;\n        float2 _1492 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1492 * _1287.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1492) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_1473);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1287, texture2d<float> fa_shadow_tex)\n{\n    float _1534 = fast::max(_1287.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1539 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1545 = sqrt(1.0 - (_1539 * _1539));\n    float _1552 = fast::min(_1545 / fast::max(_1539, 0.20000000298023223876953125), 4.0);\n    float _1557;\n    if (_1287.fa_shadow_bias.y > 0.0)\n    {\n        _1557 = _1287.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1557 = 1.5 * _1287.fa_shadow_info[ci].x;\n    }\n    float4 _1582 = _1287.fa_shadow_mat[ci] * float4(world + (n * (_1557 * _1545)), 1.0);\n    float _1589 = _1582.x;\n    bool _1592 = _1589 < _1287.fa_shadow_rect[ci].x;\n    bool _1601;\n    if (!_1592)\n    {\n        _1601 = _1589 > _1287.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1601 = _1592;\n    }\n    bool _1610;\n    if (!_1601)\n    {\n        _1610 = _1582.y < _1287.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1610 = _1601;\n    }\n    bool _1619;\n    if (!_1610)\n    {\n        _1619 = _1582.y > _1287.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1619 = _1610;\n    }\n    bool _1626;\n    if (!_1619)\n    {\n        _1626 = _1582.z > 1.0;\n    }\n    else\n    {\n        _1626 = _1619;\n    }\n    if (_1626)\n    {\n        return -1.0;\n    }\n    float _1635;\n    if (_1287.fa_shadow_bias.x > 0.0)\n    {\n        _1635 = _1287.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1635 = 1.5 * _1287.fa_shadow_info[ci].x;\n    }\n    float2 param = _1582.xy;\n    float4 param_1 = _1287.fa_shadow_rect[ci];\n    float param_2 = _1582.z - ((_1635 * (1.0 + (0.5 * _1552))) / _1534);\n    float param_3 = _1287.fa_shadow_info[ci].x;\n    float param_4 = _1534;\n    float param_5 = _1534 * 0.25;\n    float param_6 = ((_1287.fa_shadow_info[ci].x * fast::min(_1552, 3.0)) * 0.5) / _1534;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_1287.fa_shadow_cfg.z + 0.5);\n    float param_9 = _1287.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _1287, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _547, thread float4& gl_FragCoord, constant fa_shadows& _1287, texture2d<float> fa_shadow_tex)\n{\n    if (_547.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2062 = int(_1287.fa_shadow_cfg.x + 0.5);\n    if (_2062 < 1)\n    {\n        return 1.0;\n    }\n    float _2077 = dot(world - _1287.fa_shadow_eye.xyz, _1287.fa_shadow_fwd.xyz);\n    int param = _2062 - 1;\n    if (_2077 > fa_shadow_split_at(param, _1287))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2089 = _2062 > 1;\n    bool _2096;\n    if (_2089)\n    {\n        _2096 = _2077 > _1287.fa_shadow_split.x;\n    }\n    else\n    {\n        _2096 = _2089;\n    }\n    if (_2096)\n    {\n        ci = 1;\n    }\n    bool _2100 = _2062 > 2;\n    bool _2107;\n    if (_2100)\n    {\n        _2107 = _2077 > _1287.fa_shadow_split.y;\n    }\n    else\n    {\n        _2107 = _2100;\n    }\n    if (_2107)\n    {\n        ci = 2;\n    }\n    bool _2111 = _2062 > 3;\n    bool _2118;\n    if (_2111)\n    {\n        _2118 = _2077 > _1287.fa_shadow_split.z;\n    }\n    else\n    {\n        _2118 = _2111;\n    }\n    if (_2118)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2062)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2144 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1287, fa_shadow_tex);\n        s = _2144;\n        if (_2144 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1287.fa_shadow_cfg.y > 0.0)\n    {\n        float _2169;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2169 = fa_shadow_split_at(param_5, _1287);\n        }\n        else\n        {\n            _2169 = _1287.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2188 = _1287.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1287) - _2169, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2199 = fast::clamp((_2077 - (fa_shadow_split_at(param_7, _1287) - _2188)) / _2188, 0.0, 1.0);\n        if (_2199 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2062)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2220 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1287, fa_shadow_tex);\n                s2 = _2220;\n                if (_2220 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2199);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _547, thread float4& gl_FragCoord, constant fa_shadows& _1287, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _547, gl_FragCoord, _1287, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _547, thread float4& gl_FragCoord, constant fa_shadows& _1287, texture2d<float> fa_shadow_tex)\n{\n    bool _1693 = _547.fa_pbr.z < 0.5;\n    bool _1701;\n    if (!_1693)\n    {\n        _1701 = _1287.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1701 = _1693;\n    }\n    if (_1701)\n    {\n        return 1.0;\n    }\n    int param = (int(_1287.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1714 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1715 = _1714.x;\n    if (_1715 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1724 = int(_1715 + 0.5);\n    int param_1 = _1724;\n    float4 _1728 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1724 + 1;\n    float4 _1733 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1736 = _1728.y;\n    if (_1736 > 0.0)\n    {\n        float _1753 = 1.0 - smoothstep(0.75 * _1736, _1736, length(world - _1287.fa_shadow_eye.xyz));\n        fade = _1753;\n        if (_1753 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1728.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1772 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1775 = abs(_1772);\n        float _1777 = _1775.x;\n        float _1779 = _1775.y;\n        bool _1780 = _1777 >= _1779;\n        bool _1788;\n        if (_1780)\n        {\n            _1788 = _1777 >= _1775.z;\n        }\n        else\n        {\n            _1788 = _1780;\n        }\n        int _1789;\n        if (_1788)\n        {\n            _1789 = (_1772.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1802;\n            if (_1779 >= _1775.z)\n            {\n                _1802 = (_1772.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1802 = (_1772.z > 0.0) ? 4 : 5;\n            }\n            _1789 = _1802;\n        }\n        face = _1789;\n    }\n    int _1821 = (_1724 + 2) + (face * 6);\n    int param_4 = _1821;\n    int param_5 = _1821 + 1;\n    int param_6 = _1821 + 3;\n    float4 _1835 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1821 + 4;\n    float4 _1840 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1821 + 5;\n    float4 _1845 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1857 = _1845.x * fast::max(dot(_1835, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1862 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1885 = fast::clamp(dot(n, _1835.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1908 = fast::min(sqrt(1.0 - (_1885 * _1885)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1835, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1911 = _1733.y;\n    float _1913;\n    if (_1911 > 0.0)\n    {\n        _1913 = _1911;\n    }\n    else\n    {\n        _1913 = 1.5 * _1857;\n    }\n    float4 _1933 = float4(world + (n * (_1913 * sqrt(1.0 - (_1862 * _1862)))), 1.0);\n    float _1937 = dot(_1835, _1933);\n    float _1940 = _1845.y;\n    if (_1937 < _1940)\n    {\n        return 1.0;\n    }\n    float2 _1955 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1933), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1933)) / float2(_1937);\n    float _1957 = _1955.x;\n    bool _1960 = _1957 < _1840.x;\n    bool _1969;\n    if (!_1960)\n    {\n        _1969 = _1957 > _1840.z;\n    }\n    else\n    {\n        _1969 = _1960;\n    }\n    bool _1978;\n    if (!_1969)\n    {\n        _1978 = _1955.y < _1840.y;\n    }\n    else\n    {\n        _1978 = _1969;\n    }\n    bool _1987;\n    if (!_1978)\n    {\n        _1987 = _1955.y > _1840.w;\n    }\n    else\n    {\n        _1987 = _1978;\n    }\n    if (_1987)\n    {\n        return 1.0;\n    }\n    float _1993 = _1733.x;\n    float _1995;\n    if (_1993 > 0.0)\n    {\n        _1995 = _1993;\n    }\n    else\n    {\n        _1995 = 1.5 * _1857;\n    }\n    float2 param_10 = _1955;\n    float4 param_11 = _1840;\n    float param_12 = _1937 - (_1995 * (1.0 + (0.5 * _1908)));\n    float param_13 = _1857;\n    float param_14 = 1.0;\n    float param_15 = _1845.z * 0.25;\n    float param_16 = (_1857 * fast::min(_1908, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1940, _1845.z);\n    int param_18 = int(_1728.z + 0.5);\n    float param_19 = _1728.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _1287, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _547, thread float4& gl_FragCoord, constant fa_shadows& _1287, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3579 = fa_lm.z > 0.5;\n    bool _3585;\n    if (_3579)\n    {\n        int param = li;\n        _3585 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3585 = _3579;\n    }\n    if (_3585)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3607 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _4898 = _3607.direction;\n    float3 _4893 = _3607.color;\n    float _4900 = _3607.attenuation;\n    float _4895 = _3607.shadow;\n    int _4903 = _3607.type;\n    if ((_4903 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4898;\n        float _3621 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _547, gl_FragCoord, _1287, fa_shadow_tex, fa_world_pos);\n        _4895 = _3621;\n        _4893 *= _3621;\n    }\n    else\n    {\n        bool _3632 = _4903 != 0;\n        bool _3638;\n        if (_3632)\n        {\n            _3638 = _4900 > 0.0;\n        }\n        else\n        {\n            _3638 = _3632;\n        }\n        if (_3638)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4898;\n            float _3650 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _547, gl_FragCoord, _1287, fa_shadow_tex);\n            _4895 = _3650;\n            _4893 *= _3650;\n        }\n    }\n    return LightSample{ _4898, _4893, _4900, _4895, _3607._distance, _4903 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _3196 = tdh / at;\n    float _3200 = bdh / ab;\n    float _3212 = ((_3196 * _3196) + (_3200 * _3200)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3212) * _3212);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _3293 = 1.0 / alpha;\n    return ((2.0 + _3293) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3293)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _3325 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3404 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3404) * _3404);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3325);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3325));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3477 = fast::max(dot(L.nc, l), 0.0);\n        float _3483 = fast::max(dot(L.nc, h), 0.0);\n        float _3492 = ((_3483 * _3483) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3492) * _3492)) * (0.5 / fast::max(mix((2.0 * _3477) * L.coat_ndv, _3477 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3477)) * _3477);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _2597 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2600 = _2597.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_2600 * _2600, exp2((-9.27999973297119140625) * ndv)) * _2600) + _2597.y)) + _2597.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _547, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_547.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _547.fa_env_horizon.w)).xyz;\n    }\n    float _2451 = rough * rough;\n    float _2481 = 0.60000002384185791015625 * _2451;\n    return mix(mix(_547.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_547.fa_env_horizon.xyz, _547.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _2451)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _2481, 0.0500000007450580596923828125 + _2481, d.y))), ((_547.fa_env_sky.xyz + _547.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_2451 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _547, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _3079;\n        if (L.aniso >= 0.0)\n        {\n            _3079 = L.b;\n        }\n        else\n        {\n            _3079 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_3079, v), _3079), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3112 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _547, fa_env_smp, fa_env_tex) * ((f0 * _3112.x) + (float3(L.f90) * _3112.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _547, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3167 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _547, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _3167.x) + _3167.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _547, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2639 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _547, fa_env_smp, fa_env_tex) * ((f0 * _2639.x) + float3(_2639.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1287)\n{\n    if (_1287.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2244 = int(_1287.fa_shadow_cfg.x + 0.5);\n    float _2254 = dot(world - _1287.fa_shadow_eye.xyz, _1287.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2259 = _2244 > 0;\n    bool _2268;\n    if (_2259)\n    {\n        int param = _2244 - 1;\n        _2268 = _2254 <= fa_shadow_split_at(param, _1287);\n    }\n    else\n    {\n        _2268 = _2259;\n    }\n    if (_2268)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2275 = _2244 > 1;\n        bool _2282;\n        if (_2275)\n        {\n            _2282 = _2254 > _1287.fa_shadow_split.x;\n        }\n        else\n        {\n            _2282 = _2275;\n        }\n        if (_2282)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2288 = _2244 > 2;\n        bool _2295;\n        if (_2288)\n        {\n            _2295 = _2254 > _1287.fa_shadow_split.y;\n        }\n        else\n        {\n            _2295 = _2288;\n        }\n        if (_2295)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2301 = _2244 > 3;\n        bool _2308;\n        if (_2301)\n        {\n            _2308 = _2254 > _1287.fa_shadow_split.z;\n        }\n        else\n        {\n            _2308 = _2301;\n        }\n        if (_2308)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _547 [[buffer(1)]], constant fa_shadows& _1287 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], texture2d<float> fa_decal_tex [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4615 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4615 = -_4615;\n    }\n    float3 _4040 = fast::normalize(_547.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _547, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4615, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4040, short(gl_FrontFacing) };\n    Surface _4048 = fa_standard_surface(param_1, _547, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4646 = _4048.albedo;\n    float _4647 = _4048.alpha;\n    float3 _4648 = _4048.normal;\n    float _4649 = _4048.metallic;\n    float _4650 = _4048.roughness;\n    float _4651 = _4048.occlusion;\n    float3 _4652 = _4048.emission;\n    float _4653 = _4048.clearcoat;\n    float _4654 = _4048.clearcoat_roughness;\n    float3 _4655 = _4048.sheen_color;\n    float _4656 = _4048.sheen_roughness;\n    float _4657 = _4048.anisotropy;\n    float _4658 = _4048.anisotropy_rotation;\n    float _4659 = _4048.specular;\n    float _4660 = _4048.ior;\n    float3 _4661 = _4048.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4615, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4040, short(gl_FrontFacing) };\n    Surface param_3 = _4048;\n    surface(param_2, param_3);\n    _4646 = param_3.albedo;\n    _4647 = param_3.alpha;\n    _4648 = param_3.normal;\n    _4649 = param_3.metallic;\n    _4650 = param_3.roughness;\n    _4651 = param_3.occlusion;\n    _4652 = param_3.emission;\n    _4653 = param_3.clearcoat;\n    _4654 = param_3.clearcoat_roughness;\n    _4655 = param_3.sheen_color;\n    _4656 = param_3.sheen_roughness;\n    _4657 = param_3.anisotropy;\n    _4658 = param_3.anisotropy_rotation;\n    _4659 = param_3.specular;\n    _4660 = param_3.ior;\n    _4661 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4615;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _547, fa_decal_tex, fa_env_smp);\n    _4646 = param_6;\n    _4648 = param_7;\n    float3 result;\n    if (_547.fa_emissive.w > 0.5)\n    {\n        result = _4646;\n    }\n    else\n    {\n        float3 _4087 = fast::normalize(_4648);\n        float _4094 = fast::clamp(_4649, 0.0, 1.0);\n        float _4098 = fast::clamp(_4650, 0.0500000007450580596923828125, 1.0);\n        float _4102 = _4098 * _4098;\n        float _4106 = _4102 * _4102;\n        float _4111 = fast::max(dot(_4087, _4040), 9.9999997473787516355514526367188e-05);\n        float3 _4117 = _4646 * (1.0 - _4094);\n        float3 _4124 = mix(float3(0.039999999105930328369140625), _4646, float3(_4094));\n        float3 f0 = _4124;\n        SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _4615, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4040, short(gl_FrontFacing) };\n        Surface param_9 = Surface{ _4646, _4647, _4648, _4649, _4650, _4651, _4652, _4653, _4654, _4655, _4656, _4657, _4658, _4659, _4660, _4661 };\n        float3 param_10 = _4087;\n        float3 param_11 = _4040;\n        float param_12 = _4094;\n        float param_13 = _4098;\n        float3 param_14 = _4124;\n        FaLayers _4140 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _4087;\n        float3 lit = (fa_indirect_diffuse(param_15, _547, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap) * _4117) * _4651;\n        if (_4140.on)\n        {\n            lit *= _4140.base_scale;\n        }\n        int _4162 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4162; ln++)\n        {\n            int param_16 = ln;\n            int _4175 = fa_cl_light(param_16, fa_light_tex, fa_shadow_smp, _547, fa_cl_ndir, fa_cl_slot);\n            bool _4178 = in.fa_lm.z > 0.5;\n            bool _4184;\n            if (_4178)\n            {\n                int param_17 = _4175;\n                _4184 = fa_light_baked(param_17, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _4184 = _4178;\n            }\n            if (_4184)\n            {\n                continue;\n            }\n            int param_18 = _4175;\n            float3 param_19 = in.fa_world_pos;\n            float3 param_20 = _4615;\n            LightSample _4196 = fa_light_shadowed(param_18, param_19, param_20, fa_light_tex, fa_shadow_smp, _547, gl_FragCoord, _1287, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            float3 _4820 = _4196.direction;\n            float _4204 = fast::max(dot(_4087, _4820), 0.0);\n            float _4210 = _4196.attenuation * _4196.shadow;\n            float3 _4215 = fast::normalize(_4820 + _4040);\n            float _4220 = fast::max(dot(_4087, _4215), 0.0);\n            float _4225 = fast::max(dot(_4040, _4215), 0.0);\n            if (_4140.on)\n            {\n                FaLayers param_21 = _4140;\n                float3 param_22 = _4117;\n                float3 param_23 = f0;\n                float3 param_24 = _4087;\n                float3 param_25 = _4040;\n                float3 param_26 = _4820;\n                float3 param_27 = _4215;\n                float param_28 = _4204;\n                float param_29 = _4111;\n                float param_30 = _4220;\n                float param_31 = _4225;\n                float param_32 = _4102;\n                float param_33 = _4106;\n                int param_34 = _4175;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34, fa_light_tex, fa_shadow_smp) * _4210));\n            }\n            else\n            {\n                float _4273 = ((_4220 * _4220) * (_4106 - 1.0)) + 1.0;\n                int param_35 = _4175;\n                lit += (((_4117 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _4225, 5.0))) * (((_4106 / ((3.1415927410125732421875 * _4273) * _4273)) * (0.5 / fast::max(mix((2.0 * _4204) * _4111, _4204 + _4111, _4102), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4204))) * fa_light_rgb(param_35, fa_light_tex, fa_shadow_smp)) * (_4204 * _4210));\n            }\n        }\n        if (_4140.on)\n        {\n            FaLayers param_36 = _4140;\n            float3 param_37 = _4087;\n            float3 param_38 = _4040;\n            float3 param_39 = f0;\n            float param_40 = _4098;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40, _547, fa_env_smp, fa_env_tex) * _4651);\n        }\n        else\n        {\n            float3 param_41 = _4087;\n            float3 param_42 = _4040;\n            float3 param_43 = f0;\n            float param_44 = _4098;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44, _547, fa_env_smp, fa_env_tex) * _4651);\n        }\n        result = lit;\n    }\n    float3 _4366 = result;\n    float3 _4367 = _4366 + _4652;\n    result = _4367;\n    float3 param_45 = _4367;\n    float3 param_46 = in.fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46, _1287);\n    bool _4376 = _547.fa_fog.w > 0.0;\n    bool _4383;\n    if (!_4376)\n    {\n        _4383 = _547.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4383 = _4376;\n    }\n    if (_4383)\n    {\n        float3 _4392 = in.fa_world_pos - _547.fa_camera_pos.xyz;\n        float _4398 = dot(_4392, _547.fa_fog_c.xyz);\n        bool _4402 = _547.fa_fog_c.w > 0.5;\n        float _4403;\n        if (_4402)\n        {\n            _4403 = _4398;\n        }\n        else\n        {\n            _4403 = length(_4392);\n        }\n        float _4415 = _4403 - _547.fa_fog_b.x;\n        if (_4415 > 0.0)\n        {\n            float _4424 = _547.fa_fog.w * _4415;\n            float tau = _4424 * _4424;\n            if (_547.fa_fog_b.y > 0.0)\n            {\n                float _4440;\n                if (_4402)\n                {\n                    _4440 = in.fa_world_pos.y - (_547.fa_fog_c.y * _4398);\n                }\n                else\n                {\n                    _4440 = _547.fa_camera_pos.y;\n                }\n                float _4461 = mix(_4440, in.fa_world_pos.y, fast::clamp(_547.fa_fog_b.x / _4403, 0.0, 1.0));\n                float _4465 = in.fa_world_pos.y - _4461;\n                float _4470 = _4461 - _547.fa_fog_b.z;\n                float _4475 = in.fa_world_pos.y - _547.fa_fog_b.z;\n                bool _4478 = _4470 <= 0.0;\n                bool _4479 = !_4478;\n                bool _4485;\n                if (_4479)\n                {\n                    _4485 = _547.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4485 = _4478;\n                }\n                float _4486;\n                if (_4485)\n                {\n                    _4486 = _547.fa_fog_b.y;\n                }\n                else\n                {\n                    _4486 = _547.fa_fog_b.y * exp(-fast::min(_547.fa_fog_b.w * _4470, 80.0));\n                }\n                bool _4513;\n                if (_4479)\n                {\n                    _4513 = _547.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4513 = _4478;\n                }\n                float _4514;\n                if (_4513)\n                {\n                    _4514 = _547.fa_fog_b.y * _4470;\n                }\n                else\n                {\n                    _4514 = (_547.fa_fog_b.y * (1.0 - exp(-fast::min(_547.fa_fog_b.w * _4470, 80.0)))) / _547.fa_fog_b.w;\n                }\n                bool _4539 = _4475 <= 0.0;\n                bool _4546;\n                if (!_4539)\n                {\n                    _4546 = _547.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4546 = _4539;\n                }\n                float _4547;\n                if (_4546)\n                {\n                    _4547 = _547.fa_fog_b.y * _4475;\n                }\n                else\n                {\n                    _4547 = (_547.fa_fog_b.y * (1.0 - exp(-fast::min(_547.fa_fog_b.w * _4475, 80.0)))) / _547.fa_fog_b.w;\n                }\n                float _4574;\n                if (abs(_4465) < 0.001000000047497451305389404296875)\n                {\n                    _4574 = _4486;\n                }\n                else\n                {\n                    _4574 = (_4547 - _4514) / _4465;\n                }\n                tau += (_4415 * fast::max(_4574, 0.0));\n            }\n            result = mix(result, _547.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4647);\n    return out;\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 12,
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
            "inst_name": "_149",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_195",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_547",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1287",
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float2 fa_attr_uv1 [[attribute(9)]];\n    float4 fa_attr_color1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float4& vertex_color1, thread float2& vertex_uv1, thread float2& fa_attr_uv1, thread float4& fa_attr_color1)\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _144)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _144.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float4& vertex_color1, thread float2& vertex_uv1)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float4& vertex_color1, thread float2& vertex_uv1, constant fa_mesh_vs_params& _144, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _144);\n    vertex0(param_6, vertex_color1, vertex_uv1);\n    float4 _187 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_144.fa_light_vp * _187).z;\n    fa_pre_r0 = float3(_144.fa_light_vp[0].x, _144.fa_light_vp[1].x, _144.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_144.fa_light_vp[0].y, _144.fa_light_vp[1].y, _144.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_144.fa_light_vp[0].z, _144.fa_light_vp[1].z, _144.fa_light_vp[2].z);\n    gl_Position = _144.fa_view_proj * _187;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _144 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 vertex_color1;\n    float2 vertex_uv1;\n    fa_inst_begin(vertex_color1, vertex_uv1, in.fa_attr_uv1, in.fa_attr_color1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, vertex_color1, vertex_uv1, _144, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _186 = fa_linear_to_srgb(param);\n        c = _186;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _195 = fa_srgb_to_linear(param_1);\n            c = _195;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _226, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _226.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _238 = fa_tex_fix(param_2, param_3);\n    float4 _744 = base_t;\n    _744.x = _238.x;\n    _744.y = _238.y;\n    _744.z = _238.z;\n    base_t = _744;\n    float4 _253 = (_744 * _226.fa_base_color) * i.vertex_color;\n    float3 _707 = i.world_normal;\n    if (_226.fa_maps.z > 0.5)\n    {\n        float param_4 = _226.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0) - float3(1.0);\n        float2 _295 = _290.xy * _226.fa_maps.x;\n        float3 _752 = _290;\n        _752.x = _295.x;\n        _752.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _752;\n        _707 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _226.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _755 = mrt;\n    _755.x = _324.x;\n    _755.y = _324.y;\n    _755.z = _324.z;\n    mrt = _755;\n    float4 _354 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _226.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _226.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _712 = _226.fa_layers_a.x;\n    float _713 = _226.fa_layers_a.y;\n    float _716 = _226.fa_layers_a.z;\n    float _715 = _226.fa_layers_b.w;\n    float _718 = _226.fa_layers_c.x;\n    if (_226.fa_layers_c.z > 0.5)\n    {\n        if (mod(_226.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _712 *= _366.y;\n            _713 *= _366.z;\n            _715 *= _354.w;\n        }\n        if (_226.fa_layers_c.z > 1.5)\n        {\n            _716 *= mrt.x;\n            _718 *= mrt.w;\n        }\n    }\n    return Surface{ _253.xyz, _253.w, _707, fast::clamp(_226.fa_pbr.x * _324.z, 0.0, 1.0), fast::clamp(_226.fa_pbr.y * _324.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_226.fa_maps.y * (_366.x - 1.0)), _226.fa_emissive.xyz + (_226.fa_model_emissive.xyz * _396), _712, _713, _226.fa_layers_b.xyz, _715, _716, _226.fa_layers_a.w, _718, _226.fa_layers_c.y, _226.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _226 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _618 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _618 = -_618;\n    }\n    float3 _530 = fast::normalize(_226.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _618, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _618, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _226, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _545 = fast::normalize(param_2.normal);\n    float3 _560 = fast::normalize(float3(dot(in.fa_pre_r0, _545), dot(in.fa_pre_r1, _545), dot(in.fa_pre_r2, _545)));\n    float _572 = _560.z;\n    float2 e = _560.xy / float2((abs(_560.x) + abs(_560.y)) + abs(_572));\n    if (_572 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "type": "vec2",
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
            "inst_name": "_144",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_226",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n    float2 fa_attr_uv1 [[attribute(11)]];\n    float4 fa_attr_color1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float4& vertex_color1, thread float2& vertex_uv1, thread float2& fa_attr_uv1, thread float4& fa_attr_color1)\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _195)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _186 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_195.fa_joint_rows[_186] * weights[i]);\n        r1 += (_195.fa_joint_rows[_186 + 1] * weights[i]);\n        r2 += (_195.fa_joint_rows[_186 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _149)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _149.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float4& vertex_color1, thread float2& vertex_uv1)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float4& vertex_color1, thread float2& vertex_uv1, constant fa_mesh_vs_params& _149, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _149);\n    vertex0(param_6, vertex_color1, vertex_uv1);\n    float4 _300 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_149.fa_light_vp * _300).z;\n    fa_pre_r0 = float3(_149.fa_light_vp[0].x, _149.fa_light_vp[1].x, _149.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_149.fa_light_vp[0].y, _149.fa_light_vp[1].y, _149.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_149.fa_light_vp[0].z, _149.fa_light_vp[1].z, _149.fa_light_vp[2].z);\n    gl_Position = _149.fa_view_proj * _300;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _149 [[buffer(0)]], constant fa_skin& _195 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 vertex_color1;\n    float2 vertex_uv1;\n    fa_inst_begin(vertex_color1, vertex_uv1, in.fa_attr_uv1, in.fa_attr_color1);\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _195);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, vertex_color1, vertex_uv1, _149, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _186 = fa_linear_to_srgb(param);\n        c = _186;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _195 = fa_srgb_to_linear(param_1);\n            c = _195;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _226, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _226.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _238 = fa_tex_fix(param_2, param_3);\n    float4 _744 = base_t;\n    _744.x = _238.x;\n    _744.y = _238.y;\n    _744.z = _238.z;\n    base_t = _744;\n    float4 _253 = (_744 * _226.fa_base_color) * i.vertex_color;\n    float3 _707 = i.world_normal;\n    if (_226.fa_maps.z > 0.5)\n    {\n        float param_4 = _226.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0) - float3(1.0);\n        float2 _295 = _290.xy * _226.fa_maps.x;\n        float3 _752 = _290;\n        _752.x = _295.x;\n        _752.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _752;\n        _707 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _226.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _755 = mrt;\n    _755.x = _324.x;\n    _755.y = _324.y;\n    _755.z = _324.z;\n    mrt = _755;\n    float4 _354 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _226.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _226.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _712 = _226.fa_layers_a.x;\n    float _713 = _226.fa_layers_a.y;\n    float _716 = _226.fa_layers_a.z;\n    float _715 = _226.fa_layers_b.w;\n    float _718 = _226.fa_layers_c.x;\n    if (_226.fa_layers_c.z > 0.5)\n    {\n        if (mod(_226.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _712 *= _366.y;\n            _713 *= _366.z;\n            _715 *= _354.w;\n        }\n        if (_226.fa_layers_c.z > 1.5)\n        {\n            _716 *= mrt.x;\n            _718 *= mrt.w;\n        }\n    }\n    return Surface{ _253.xyz, _253.w, _707, fast::clamp(_226.fa_pbr.x * _324.z, 0.0, 1.0), fast::clamp(_226.fa_pbr.y * _324.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_226.fa_maps.y * (_366.x - 1.0)), _226.fa_emissive.xyz + (_226.fa_model_emissive.xyz * _396), _712, _713, _226.fa_layers_b.xyz, _715, _716, _226.fa_layers_a.w, _718, _226.fa_layers_c.y, _226.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _226 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _618 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _618 = -_618;\n    }\n    float3 _530 = fast::normalize(_226.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _618, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _618, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _226, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _545 = fast::normalize(param_2.normal);\n    float3 _560 = fast::normalize(float3(dot(in.fa_pre_r0, _545), dot(in.fa_pre_r1, _545), dot(in.fa_pre_r2, _545)));\n    float _572 = _560.z;\n    float2 e = _560.xy / float2((abs(_560.x) + abs(_560.y)) + abs(_572));\n    if (_572 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 12,
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
            "inst_name": "_149",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_195",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_226",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float3 fa_normal [[attribute(5)]];\n    float2 fa_texcoord0 [[attribute(6)]];\n    float4 fa_tangent [[attribute(7)]];\n    float4 fa_color [[attribute(8)]];\n    float2 fa_attr_uv1 [[attribute(9)]];\n    float4 fa_attr_color1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float4& vertex_color1, thread float2& vertex_uv1, thread float2& fa_attr_uv1, thread float4& fa_attr_color1)\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _135)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _135.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float4& vertex_color1, thread float2& vertex_uv1)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _135 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 vertex_color1;\n    float2 vertex_uv1;\n    fa_inst_begin(vertex_color1, vertex_uv1, in.fa_attr_uv1, in.fa_attr_color1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _135);\n    vertex0(param_6, vertex_color1, vertex_uv1);\n    out.gl_Position = _135.fa_light_vp * float4(param_6.world_pos, 1.0);\n    return out;\n}\n\n",
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
          },
          {
            "slot": 9,
            "type": "vec2",
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
            "inst_name": "_135",
            "msl_buffer_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float4 fa_joints [[attribute(5)]];\n    float4 fa_weights [[attribute(6)]];\n    float3 fa_normal [[attribute(7)]];\n    float2 fa_texcoord0 [[attribute(8)]];\n    float4 fa_tangent [[attribute(9)]];\n    float4 fa_color [[attribute(10)]];\n    float2 fa_attr_uv1 [[attribute(11)]];\n    float4 fa_attr_color1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _186)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _177 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_186.fa_joint_rows[_177] * weights[i]);\n        r1 += (_186.fa_joint_rows[_177 + 1] * weights[i]);\n        r2 += (_186.fa_joint_rows[_177 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float4& vertex_color1, thread float2& vertex_uv1, thread float2& fa_attr_uv1, thread float4& fa_attr_color1)\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _140)\n{\n    float3 _79 = cross(model[1].xyz, model[2].xyz);\n    float _85 = (dot(model[0].xyz, _79) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_79 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _85, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _85), texcoord0 * _140.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float4& vertex_color1, thread float2& vertex_uv1)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _140 [[buffer(0)]], constant fa_skin& _186 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4 vertex_color1;\n    float2 vertex_uv1;\n    fa_inst_begin(vertex_color1, vertex_uv1, in.fa_attr_uv1, in.fa_attr_color1);\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _186);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7, _140);\n    vertex0(param_8, vertex_color1, vertex_uv1);\n    out.gl_Position = _140.fa_light_vp * float4(param_8.world_pos, 1.0);\n    return out;\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 12,
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
            "inst_name": "_140",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_186",
            "msl_buffer_n": 3
          }
        ]
      }
    }
  }
}
