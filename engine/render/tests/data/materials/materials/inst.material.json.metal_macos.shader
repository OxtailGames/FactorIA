{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "df130aaeb5c0790af276010723d2798f8fdace693dbde21948e5a037edff24ef",
  "slang": "metal_macos",
  "params": [
    "boost"
  ],
  "textures": [],
  "instanced": [
    {
      "name": "raise",
      "vec4": 0,
      "offset": 0,
      "components": 1
    },
    {
      "name": "tint",
      "vec4": 1,
      "offset": 0,
      "components": 4
    }
  ],
  "instanceVec4": 2,
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float3 fa_lm [[user(locn7)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_inst_d0 [[attribute(9)]];\n    float4 fa_inst_d1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _153)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _153, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _153);\n    vertex0(param_6, raise);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _153.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _153 [[buffer(0)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, raise, _153, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nconstant spvUnsafeArray<float, 63> _2064 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float3 fa_lm [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _517)\n{\n    bool _522 = _517.fa_cl_info.x < 0.0;\n    bool _529;\n    if (!_522)\n    {\n        _529 = _517.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _529 = _522;\n    }\n    bool _537;\n    if (!_529)\n    {\n        _537 = _517.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _537 = _529;\n    }\n    bool _544;\n    if (!_537)\n    {\n        _544 = _517.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _544 = _537;\n    }\n    bool _551;\n    if (!_544)\n    {\n        _551 = _517.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _551 = _544;\n    }\n    if (_551)\n    {\n        return int2(0);\n    }\n    float4 _561 = float4(world_pos, 1.0);\n    float _568 = dot(_517.fa_cl_vpw, _561);\n    if (!(_568 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _590 = float2(dot(_517.fa_cl_vpx, _561), dot(_517.fa_cl_vpy, _561)) / float2(_568);\n    int _594 = int(_517.fa_cl_grid.x);\n    int _598 = int(_517.fa_cl_grid.y);\n    int param = (int(_517.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_517.fa_cl_fwd.xyz, world_pos) + _517.fa_cl_fwd.w, _517.fa_cl_grid.w) / _517.fa_cl_grid.w) * _517.fa_cl_grid.z)), 0, int(_517.fa_cl_info.y) - 1) * _598) + clamp(int(floor(((_590.y * 0.5) + 0.5) * _517.fa_cl_grid.y)), 0, _598 - 1)) * _594)) + clamp(int(floor(((_590.x * 0.5) + 0.5) * _517.fa_cl_grid.x)), 0, _594 - 1);\n    float4 _669 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_669.x), int(_669.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _517, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_517.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2881 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _517);\n    fa_cl_slot = _2881.x;\n    fa_cl_local = _2881.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3068 = fa_linear_to_srgb(param);\n        c = _3068;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3076 = fa_srgb_to_linear(param_1);\n            c = _3076;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _272;\n    if (bool(i.front_facing))\n    {\n        _272 = i.world_normal;\n    }\n    else\n    {\n        _272 = -i.world_normal;\n    }\n    float3 _296 = fast::normalize(i.world_tangent.xyz - (_272 * dot(_272, i.world_tangent.xyz)));\n    float3 _324 = fast::normalize(((_296 * m.x) + ((cross(_272, _296) * i.world_tangent.w) * m.y)) + (_272 * m.z));\n    float3 _327;\n    if (bool(i.front_facing))\n    {\n        _327 = _324;\n    }\n    else\n    {\n        _327 = -_324;\n    }\n    return _327;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _517, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _517.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3107 = fa_tex_fix(param_2, param_3);\n    float4 _4354 = base_t;\n    _4354.x = _3107.x;\n    _4354.y = _3107.y;\n    _4354.z = _3107.z;\n    base_t = _4354;\n    float4 _3121 = (_4354 * _517.fa_base_color) * i.vertex_color;\n    float3 _4256 = i.world_normal;\n    if (_517.fa_maps.z > 0.5)\n    {\n        float param_4 = _517.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3153 = fa_tex_fix(param_6, param_7);\n        float3 _3156 = (_3153 * 2.0) - float3(1.0);\n        float2 _3161 = _3156.xy * _517.fa_maps.x;\n        float3 _4362 = _3156;\n        _4362.x = _3161.x;\n        _4362.y = _3161.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4362;\n        _4256 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _517.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3190 = fa_tex_fix(param_12, param_13);\n    float4 _4365 = mrt;\n    _4365.x = _3190.x;\n    _4365.y = _3190.y;\n    _4365.z = _3190.z;\n    mrt = _4365;\n    float4 _3218 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _517.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3218.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3230 = fa_tex_fix(param_16, param_17);\n    float param_18 = _517.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3260 = fa_tex_fix(param_20, param_21);\n    float _4261 = _517.fa_layers_a.x;\n    float _4262 = _517.fa_layers_a.y;\n    float _4265 = _517.fa_layers_a.z;\n    float _4264 = _517.fa_layers_b.w;\n    float _4267 = _517.fa_layers_c.x;\n    if (_517.fa_layers_c.z > 0.5)\n    {\n        if (mod(_517.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4261 *= _3230.y;\n            _4262 *= _3230.z;\n            _4264 *= _3218.w;\n        }\n        if (_517.fa_layers_c.z > 1.5)\n        {\n            _4265 *= mrt.x;\n            _4267 *= mrt.w;\n        }\n    }\n    return Surface{ _3121.xyz, _3121.w, _4256, fast::clamp(_517.fa_pbr.x * _3190.z, 0.0, 1.0), fast::clamp(_517.fa_pbr.y * _3190.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_517.fa_maps.y * (_3230.x - 1.0)), _517.fa_emissive.xyz + (_517.fa_model_emissive.xyz * _3260), _4261, _4262, _517.fa_layers_b.xyz, _4264, _4265, _517.fa_layers_a.w, _4267, _517.fa_layers_c.y, _517.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _3004)\n{\n    s.emission += ((tint.xyz * tint.w) * _3004.boost);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1989 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1997 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2000 = int(_1989);\n    int _2003 = int(_1997);\n    float _2013 = _1997 - float(_2003);\n    int _2069 = (_2000 * 9) + _2003;\n    int _2089 = ((_2000 + 1) * 9) + _2003;\n    return mix(mix(_2064[_2069], _2064[_2069 + 1], _2013), mix(_2064[_2089], _2064[_2089 + 1], _2013), _1989 - float(_2000));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4179 = false;\n    float _4180 = 1.0;\n    float _4181 = 1.0;\n    float _4182 = 1.0;\n    float _4183 = 0.0;\n    float _4184 = 0.0;\n    float _4185 = 0.0;\n    float _4186 = 0.0;\n    float _4188 = 1.0;\n    bool _4189 = false;\n    float3 _4190 = float3(0.0);\n    float _4191 = 1.0;\n    float _4192 = 1.0;\n    float _4193 = 1.0;\n    float _4194 = 0.0;\n    float _4195 = 0.0;\n    float3 _4196 = float3(1.0, 0.0, 0.0);\n    float3 _4197 = float3(0.0, 0.0, 1.0);\n    float _4198 = 1.0;\n    float _4199 = 1.0;\n    float _2142 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2146 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2151 = (_2142 != 1.0) || (_2146 != 1.5);\n    bool _2161;\n    if (!_2151)\n    {\n        _2161 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2161 = _2151;\n    }\n    if (_2161)\n    {\n        float _2169 = (_2146 - 1.0) / (_2146 + 1.0);\n        f0 = mix(fast::min(float3(_2169 * _2169) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2142, s.albedo, float3(metallic));\n        _4180 = mix(_2142, 1.0, metallic);\n        _4179 = true;\n    }\n    float _2197 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2197 > 0.0)\n    {\n        float _2205 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4183 = _2197;\n        _4184 = _2205;\n        float _2212 = _2205 * _2205;\n        _4185 = _2212;\n        _4186 = _2212 * _2212;\n        float _2224 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4188 = _2224;\n        _4181 = 1.0 - (_2197 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2224, 0.0, 1.0), 5.0))));\n        _4179 = true;\n    }\n    float3 _2244 = fast::max(s.sheen_color, float3(0.0));\n    float _2253 = fast::max(_2244.x, fast::max(_2244.y, _2244.z));\n    if (_2253 > 0.0)\n    {\n        float _2261 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4189 = true;\n        _4190 = _2244;\n        _4191 = _2261;\n        _4192 = _2261 * _2261;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2261;\n        float _2278 = fa_sheen_albedo(param, param_1);\n        _4194 = _2278;\n        _4193 = 1.0 - fast::min(_2253 * _2278, 1.0);\n        _4179 = true;\n    }\n    _4182 = _4181 * _4193;\n    float _2297 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2297 != 0.0)\n    {\n        float3 _2312 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2312;\n        if (dot(_2312, _2312) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2330 = t;\n        float3 _2331 = fast::normalize(_2330);\n        t = _2331;\n        float3 _2356 = fast::normalize((_2331 * cos(s.anisotropy_rotation)) + ((cross(n, _2331) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4196 = _2356;\n        _4197 = cross(n, _2356);\n        float _2366 = roughness * roughness;\n        float _2372 = mix(_2366, 1.0, _2297 * _2297);\n        bool _2374 = _2297 > 0.0;\n        _4198 = _2374 ? _2372 : _2366;\n        _4199 = _2374 ? _2366 : _2372;\n        _4195 = _2297;\n        _4179 = true;\n    }\n    return FaLayers{ short(_4179), _4180, _4181, _4182, _4183, _4184, _4185, _4186, i.world_normal, _4188, short(_4189), _4190, _4191, _4192, _4193, _4194, _4195, _4196, _4197, _4198, _4199 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _517, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_517.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _517.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _517, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _517, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _517)\n{\n    int param = (int(_517.fa_cl_info.x) + int(_517.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _517, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _517);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _391 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _397 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _400 = _397.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _406 = _400 < 0.5;\n    float3 l;\n    if (_406)\n    {\n        l = fast::normalize(_391.xyz);\n    }\n    else\n    {\n        float3 _418 = _391.xyz - world_pos;\n        float _420 = length(_418);\n        dist = _420;\n        l = _418 / float3(fast::max(_420, 9.9999997473787516355514526367188e-05));\n        float _435 = _420 / fast::max(_391.w, 0.001000000047497451305389404296875);\n        float _441 = fast::clamp(1.0 - (_435 * _435), 0.0, 1.0);\n        atten = _441 * _441;\n        if (_400 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _455 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _465 = _455.w;\n            int param_3 = (li * 4) + 3;\n            float4 _471 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _472 = _471.x;\n            float cos_inner = _472;\n            if (_472 > 1.5)\n            {\n                cos_inner = mix(_465, 1.0, 0.25);\n            }\n            atten *= smoothstep(_465, cos_inner, dot(-l, fast::normalize(_455.xyz)));\n        }\n    }\n    int _503;\n    if (_406)\n    {\n        _503 = 0;\n    }\n    else\n    {\n        _503 = (_400 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _397.xyz * atten, atten, 1.0, dist, _503 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _753)\n{\n    float _743;\n    if (i == 0)\n    {\n        _743 = _753.fa_shadow_split.x;\n    }\n    else\n    {\n        float _759;\n        if (i == 1)\n        {\n            _759 = _753.fa_shadow_split.y;\n        }\n        else\n        {\n            float _767;\n            if (i == 2)\n            {\n                _767 = _753.fa_shadow_split.z;\n            }\n            else\n            {\n                _767 = _753.fa_shadow_split.w;\n            }\n            _759 = _767;\n        }\n        _743 = _759;\n    }\n    return _743;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _800 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _804;\n    if (conv.x < 0.5)\n    {\n        _804 = _800;\n    }\n    else\n    {\n        _804 = (conv.y * conv.z) / (conv.z - (_800 * (conv.z - conv.y)));\n    }\n    return _804;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _731 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_731), sin(_731)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _753, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _850 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _864 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _850;\n            float2 _883 = fa_shadow_vogel(param_3, param_4, param_5) * _864;\n            float2 param_6 = uv + (_883 * _753.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _895 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_895 < (zr - (length(_883) * plane)))\n            {\n                sum += _895;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _939 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _939; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _939;\n        float param_11 = _850;\n        float2 _958 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_958 * _753.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_958) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_939);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _753, texture2d<float> fa_shadow_tex)\n{\n    float _1000 = fast::max(_753.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1005 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1011 = sqrt(1.0 - (_1005 * _1005));\n    float _1019 = fast::min(_1011 / fast::max(_1005, 0.20000000298023223876953125), 4.0);\n    float _1024;\n    if (_753.fa_shadow_bias.y > 0.0)\n    {\n        _1024 = _753.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1024 = 1.5 * _753.fa_shadow_info[ci].x;\n    }\n    float4 _1049 = _753.fa_shadow_mat[ci] * float4(world + (n * (_1024 * _1011)), 1.0);\n    float _1056 = _1049.x;\n    bool _1059 = _1056 < _753.fa_shadow_rect[ci].x;\n    bool _1068;\n    if (!_1059)\n    {\n        _1068 = _1056 > _753.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1068 = _1059;\n    }\n    bool _1077;\n    if (!_1068)\n    {\n        _1077 = _1049.y < _753.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1077 = _1068;\n    }\n    bool _1086;\n    if (!_1077)\n    {\n        _1086 = _1049.y > _753.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1086 = _1077;\n    }\n    bool _1093;\n    if (!_1086)\n    {\n        _1093 = _1049.z > 1.0;\n    }\n    else\n    {\n        _1093 = _1086;\n    }\n    if (_1093)\n    {\n        return -1.0;\n    }\n    float _1102;\n    if (_753.fa_shadow_bias.x > 0.0)\n    {\n        _1102 = _753.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1102 = 1.5 * _753.fa_shadow_info[ci].x;\n    }\n    float2 param = _1049.xy;\n    float4 param_1 = _753.fa_shadow_rect[ci];\n    float param_2 = _1049.z - ((_1102 * (1.0 + (0.5 * _1019))) / _1000);\n    float param_3 = _753.fa_shadow_info[ci].x;\n    float param_4 = _1000;\n    float param_5 = _1000 * 0.25;\n    float param_6 = ((_753.fa_shadow_info[ci].x * fast::min(_1019, 3.0)) * 0.5) / _1000;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_753.fa_shadow_cfg.z + 0.5);\n    float param_9 = _753.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _753, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _517, thread float4& gl_FragCoord, constant fa_shadows& _753, texture2d<float> fa_shadow_tex)\n{\n    if (_517.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1530 = int(_753.fa_shadow_cfg.x + 0.5);\n    if (_1530 < 1)\n    {\n        return 1.0;\n    }\n    float _1546 = dot(world - _753.fa_shadow_eye.xyz, _753.fa_shadow_fwd.xyz);\n    int param = _1530 - 1;\n    if (_1546 > fa_shadow_split_at(param, _753))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1558 = _1530 > 1;\n    bool _1565;\n    if (_1558)\n    {\n        _1565 = _1546 > _753.fa_shadow_split.x;\n    }\n    else\n    {\n        _1565 = _1558;\n    }\n    if (_1565)\n    {\n        ci = 1;\n    }\n    bool _1569 = _1530 > 2;\n    bool _1576;\n    if (_1569)\n    {\n        _1576 = _1546 > _753.fa_shadow_split.y;\n    }\n    else\n    {\n        _1576 = _1569;\n    }\n    if (_1576)\n    {\n        ci = 2;\n    }\n    bool _1580 = _1530 > 3;\n    bool _1587;\n    if (_1580)\n    {\n        _1587 = _1546 > _753.fa_shadow_split.z;\n    }\n    else\n    {\n        _1587 = _1580;\n    }\n    if (_1587)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1530)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1613 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _753, fa_shadow_tex);\n        s = _1613;\n        if (_1613 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_753.fa_shadow_cfg.y > 0.0)\n    {\n        float _1638;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1638 = fa_shadow_split_at(param_5, _753);\n        }\n        else\n        {\n            _1638 = _753.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1657 = _753.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _753) - _1638, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1668 = fast::clamp((_1546 - (fa_shadow_split_at(param_7, _753) - _1657)) / _1657, 0.0, 1.0);\n        if (_1668 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1530)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1689 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _753, fa_shadow_tex);\n                s2 = _1689;\n                if (_1689 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1668);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _517, thread float4& gl_FragCoord, constant fa_shadows& _753, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _517, gl_FragCoord, _753, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _517, thread float4& gl_FragCoord, constant fa_shadows& _753, texture2d<float> fa_shadow_tex)\n{\n    bool _1161 = _517.fa_pbr.z < 0.5;\n    bool _1169;\n    if (!_1161)\n    {\n        _1169 = _753.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1169 = _1161;\n    }\n    if (_1169)\n    {\n        return 1.0;\n    }\n    int param = (int(_753.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1182 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1183 = _1182.x;\n    if (_1183 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1192 = int(_1183 + 0.5);\n    int param_1 = _1192;\n    float4 _1196 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1192 + 1;\n    float4 _1201 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1204 = _1196.y;\n    if (_1204 > 0.0)\n    {\n        float _1221 = 1.0 - smoothstep(0.75 * _1204, _1204, length(world - _753.fa_shadow_eye.xyz));\n        fade = _1221;\n        if (_1221 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1196.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1240 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1243 = abs(_1240);\n        float _1245 = _1243.x;\n        float _1247 = _1243.y;\n        bool _1248 = _1245 >= _1247;\n        bool _1256;\n        if (_1248)\n        {\n            _1256 = _1245 >= _1243.z;\n        }\n        else\n        {\n            _1256 = _1248;\n        }\n        int _1257;\n        if (_1256)\n        {\n            _1257 = (_1240.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1270;\n            if (_1247 >= _1243.z)\n            {\n                _1270 = (_1240.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1270 = (_1240.z > 0.0) ? 4 : 5;\n            }\n            _1257 = _1270;\n        }\n        face = _1257;\n    }\n    int _1289 = (_1192 + 2) + (face * 6);\n    int param_4 = _1289;\n    int param_5 = _1289 + 1;\n    int param_6 = _1289 + 3;\n    float4 _1303 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1289 + 4;\n    float4 _1308 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1289 + 5;\n    float4 _1313 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1325 = _1313.x * fast::max(dot(_1303, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1330 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1353 = fast::clamp(dot(n, _1303.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1376 = fast::min(sqrt(1.0 - (_1353 * _1353)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1303, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1379 = _1201.y;\n    float _1381;\n    if (_1379 > 0.0)\n    {\n        _1381 = _1379;\n    }\n    else\n    {\n        _1381 = 1.5 * _1325;\n    }\n    float4 _1401 = float4(world + (n * (_1381 * sqrt(1.0 - (_1330 * _1330)))), 1.0);\n    float _1405 = dot(_1303, _1401);\n    float _1408 = _1313.y;\n    if (_1405 < _1408)\n    {\n        return 1.0;\n    }\n    float2 _1423 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1401), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1401)) / float2(_1405);\n    float _1425 = _1423.x;\n    bool _1428 = _1425 < _1308.x;\n    bool _1437;\n    if (!_1428)\n    {\n        _1437 = _1425 > _1308.z;\n    }\n    else\n    {\n        _1437 = _1428;\n    }\n    bool _1446;\n    if (!_1437)\n    {\n        _1446 = _1423.y < _1308.y;\n    }\n    else\n    {\n        _1446 = _1437;\n    }\n    bool _1455;\n    if (!_1446)\n    {\n        _1455 = _1423.y > _1308.w;\n    }\n    else\n    {\n        _1455 = _1446;\n    }\n    if (_1455)\n    {\n        return 1.0;\n    }\n    float _1461 = _1201.x;\n    float _1463;\n    if (_1461 > 0.0)\n    {\n        _1463 = _1461;\n    }\n    else\n    {\n        _1463 = 1.5 * _1325;\n    }\n    float2 param_10 = _1423;\n    float4 param_11 = _1308;\n    float param_12 = _1405 - (_1463 * (1.0 + (0.5 * _1376)));\n    float param_13 = _1325;\n    float param_14 = 1.0;\n    float param_15 = _1313.z * 0.25;\n    float param_16 = (_1325 * fast::min(_1376, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1408, _1313.z);\n    int param_18 = int(_1196.z + 0.5);\n    float param_19 = _1196.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _753, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _517, thread float4& gl_FragCoord, constant fa_shadows& _753, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _2908 = fa_lm.z > 0.5;\n    bool _2914;\n    if (_2908)\n    {\n        int param = li;\n        _2914 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2914 = _2908;\n    }\n    if (_2914)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2936 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _4241 = _2936.direction;\n    float3 _4236 = _2936.color;\n    float _4243 = _2936.attenuation;\n    float _4238 = _2936.shadow;\n    int _4246 = _2936.type;\n    if ((_4246 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4241;\n        float _2950 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _517, gl_FragCoord, _753, fa_shadow_tex, fa_world_pos);\n        _4238 = _2950;\n        _4236 *= _2950;\n    }\n    else\n    {\n        bool _2961 = _4246 != 0;\n        bool _2967;\n        if (_2961)\n        {\n            _2967 = _4243 > 0.0;\n        }\n        else\n        {\n            _2967 = _2961;\n        }\n        if (_2967)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4241;\n            float _2979 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _517, gl_FragCoord, _753, fa_shadow_tex);\n            _4238 = _2979;\n            _4236 *= _2979;\n        }\n    }\n    return LightSample{ _4241, _4236, _4243, _4238, _2936._distance, _4246 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _2524 = tdh / at;\n    float _2528 = bdh / ab;\n    float _2540 = ((_2524 * _2524) + (_2528 * _2528)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2540) * _2540);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _2621 = 1.0 / alpha;\n    return ((2.0 + _2621) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2621)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _2654 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2733 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2733) * _2733);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2654);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2654));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2806 = fast::max(dot(L.nc, l), 0.0);\n        float _2812 = fast::max(dot(L.nc, h), 0.0);\n        float _2821 = ((_2812 * _2812) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2821) * _2821)) * (0.5 / fast::max(mix((2.0 * _2806) * L.coat_ndv, _2806 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2806)) * _2806);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1921 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1924 = _1921.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1924 * _1924, exp2((-9.27999973297119140625) * ndv)) * _1924) + _1921.y)) + _1921.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _517, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_517.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _517.fa_env_horizon.w)).xyz;\n    }\n    float _1826 = rough * rough;\n    float _1856 = 0.60000002384185791015625 * _1826;\n    return mix(mix(_517.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_517.fa_env_horizon.xyz, _517.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1826)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1856, 0.0500000007450580596923828125 + _1856, d.y))), ((_517.fa_env_sky.xyz + _517.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1826 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _517, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2407;\n        if (L.aniso >= 0.0)\n        {\n            _2407 = L.b;\n        }\n        else\n        {\n            _2407 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2407, v), _2407), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2440 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _517, fa_env_tex, fa_env_smp) * ((f0 * _2440.x) + (float3(L.f90) * _2440.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _517, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2495 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _517, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _2495.x) + _2495.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _517, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1963 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _517, fa_env_tex, fa_env_smp) * ((f0 * _1963.x) + float3(_1963.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _753)\n{\n    if (_753.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1713 = int(_753.fa_shadow_cfg.x + 0.5);\n    float _1723 = dot(world - _753.fa_shadow_eye.xyz, _753.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1728 = _1713 > 0;\n    bool _1737;\n    if (_1728)\n    {\n        int param = _1713 - 1;\n        _1737 = _1723 <= fa_shadow_split_at(param, _753);\n    }\n    else\n    {\n        _1737 = _1728;\n    }\n    if (_1737)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1744 = _1713 > 1;\n        bool _1751;\n        if (_1744)\n        {\n            _1751 = _1723 > _753.fa_shadow_split.x;\n        }\n        else\n        {\n            _1751 = _1744;\n        }\n        if (_1751)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1757 = _1713 > 2;\n        bool _1764;\n        if (_1757)\n        {\n            _1764 = _1723 > _753.fa_shadow_split.y;\n        }\n        else\n        {\n            _1764 = _1757;\n        }\n        if (_1764)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1770 = _1713 > 3;\n        bool _1777;\n        if (_1770)\n        {\n            _1777 = _1723 > _753.fa_shadow_split.z;\n        }\n        else\n        {\n            _1777 = _1770;\n        }\n        if (_1777)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _517 [[buffer(1)]], constant fa_material& _3004 [[buffer(5)]], constant fa_shadows& _753 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _3958 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3958 = -_3958;\n    }\n    float3 _3400 = fast::normalize(_517.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _517, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3958, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3400, short(gl_FrontFacing) };\n    Surface _3408 = fa_standard_surface(param_1, _517, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3989 = _3408.albedo;\n    float _3990 = _3408.alpha;\n    float3 _3991 = _3408.normal;\n    float _3992 = _3408.metallic;\n    float _3993 = _3408.roughness;\n    float _3994 = _3408.occlusion;\n    float3 _3995 = _3408.emission;\n    float _3996 = _3408.clearcoat;\n    float _3997 = _3408.clearcoat_roughness;\n    float3 _3998 = _3408.sheen_color;\n    float _3999 = _3408.sheen_roughness;\n    float _4000 = _3408.anisotropy;\n    float _4001 = _3408.anisotropy_rotation;\n    float _4002 = _3408.specular;\n    float _4003 = _3408.ior;\n    float3 _4004 = _3408.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3958, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3400, short(gl_FrontFacing) };\n    Surface param_3 = _3408;\n    surface(param_2, param_3, tint, _3004);\n    _3989 = param_3.albedo;\n    _3990 = param_3.alpha;\n    _3991 = param_3.normal;\n    _3992 = param_3.metallic;\n    _3993 = param_3.roughness;\n    _3994 = param_3.occlusion;\n    _3995 = param_3.emission;\n    _3996 = param_3.clearcoat;\n    _3997 = param_3.clearcoat_roughness;\n    _3998 = param_3.sheen_color;\n    _3999 = param_3.sheen_roughness;\n    _4000 = param_3.anisotropy;\n    _4001 = param_3.anisotropy_rotation;\n    _4002 = param_3.specular;\n    _4003 = param_3.ior;\n    _4004 = param_3.specular_color;\n    float3 result;\n    if (_517.fa_emissive.w > 0.5)\n    {\n        result = _3989;\n    }\n    else\n    {\n        float3 _3430 = fast::normalize(_3991);\n        float _3437 = fast::clamp(_3992, 0.0, 1.0);\n        float _3441 = fast::clamp(_3993, 0.0500000007450580596923828125, 1.0);\n        float _3445 = _3441 * _3441;\n        float _3449 = _3445 * _3445;\n        float _3454 = fast::max(dot(_3430, _3400), 9.9999997473787516355514526367188e-05);\n        float3 _3460 = _3989 * (1.0 - _3437);\n        float3 _3467 = mix(float3(0.039999999105930328369140625), _3989, float3(_3437));\n        float3 f0 = _3467;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _3958, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3400, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _3989, _3990, _3991, _3992, _3993, _3994, _3995, _3996, _3997, _3998, _3999, _4000, _4001, _4002, _4003, _4004 };\n        float3 param_6 = _3430;\n        float3 param_7 = _3400;\n        float param_8 = _3437;\n        float param_9 = _3441;\n        float3 param_10 = _3467;\n        FaLayers _3483 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _3430;\n        float3 lit = (fa_indirect_diffuse(param_11, _517, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap) * _3460) * _3994;\n        if (_3483.on)\n        {\n            lit *= _3483.base_scale;\n        }\n        int _3505 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3505; ln++)\n        {\n            int param_12 = ln;\n            int _3518 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _517, fa_cl_ndir, fa_cl_slot);\n            bool _3521 = in.fa_lm.z > 0.5;\n            bool _3527;\n            if (_3521)\n            {\n                int param_13 = _3518;\n                _3527 = fa_light_baked(param_13, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _3527 = _3521;\n            }\n            if (_3527)\n            {\n                continue;\n            }\n            int param_14 = _3518;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _3958;\n            LightSample _3539 = fa_light_shadowed(param_14, param_15, param_16, fa_light_tex, fa_shadow_smp, _517, gl_FragCoord, _753, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            float3 _4163 = _3539.direction;\n            float _3547 = fast::max(dot(_3430, _4163), 0.0);\n            float _3553 = _3539.attenuation * _3539.shadow;\n            float3 _3558 = fast::normalize(_4163 + _3400);\n            float _3563 = fast::max(dot(_3430, _3558), 0.0);\n            float _3568 = fast::max(dot(_3400, _3558), 0.0);\n            if (_3483.on)\n            {\n                FaLayers param_17 = _3483;\n                float3 param_18 = _3460;\n                float3 param_19 = f0;\n                float3 param_20 = _3430;\n                float3 param_21 = _3400;\n                float3 param_22 = _4163;\n                float3 param_23 = _3558;\n                float param_24 = _3547;\n                float param_25 = _3454;\n                float param_26 = _3563;\n                float param_27 = _3568;\n                float param_28 = _3445;\n                float param_29 = _3449;\n                int param_30 = _3518;\n                lit += (fa_layers_light(param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29) * (fa_light_rgb(param_30, fa_light_tex, fa_shadow_smp) * _3553));\n            }\n            else\n            {\n                float _3616 = ((_3563 * _3563) * (_3449 - 1.0)) + 1.0;\n                int param_31 = _3518;\n                lit += (((_3460 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _3568, 5.0))) * (((_3449 / ((3.1415927410125732421875 * _3616) * _3616)) * (0.5 / fast::max(mix((2.0 * _3547) * _3454, _3547 + _3454, _3445), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3547))) * fa_light_rgb(param_31, fa_light_tex, fa_shadow_smp)) * (_3547 * _3553));\n            }\n        }\n        if (_3483.on)\n        {\n            FaLayers param_32 = _3483;\n            float3 param_33 = _3430;\n            float3 param_34 = _3400;\n            float3 param_35 = f0;\n            float param_36 = _3441;\n            lit += (fa_layers_ibl(param_32, param_33, param_34, param_35, param_36, _517, fa_env_tex, fa_env_smp) * _3994);\n        }\n        else\n        {\n            float3 param_37 = _3430;\n            float3 param_38 = _3400;\n            float3 param_39 = f0;\n            float param_40 = _3441;\n            lit += (fa_sky_reflection(param_37, param_38, param_39, param_40, _517, fa_env_tex, fa_env_smp) * _3994);\n        }\n        result = lit;\n    }\n    float3 _3709 = result;\n    float3 _3710 = _3709 + _3995;\n    result = _3710;\n    float3 param_41 = _3710;\n    float3 param_42 = in.fa_world_pos;\n    result = fa_shadow_debug(param_41, param_42, _753);\n    bool _3719 = _517.fa_fog.w > 0.0;\n    bool _3726;\n    if (!_3719)\n    {\n        _3726 = _517.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3726 = _3719;\n    }\n    if (_3726)\n    {\n        float3 _3735 = in.fa_world_pos - _517.fa_camera_pos.xyz;\n        float _3741 = dot(_3735, _517.fa_fog_c.xyz);\n        bool _3745 = _517.fa_fog_c.w > 0.5;\n        float _3746;\n        if (_3745)\n        {\n            _3746 = _3741;\n        }\n        else\n        {\n            _3746 = length(_3735);\n        }\n        float _3758 = _3746 - _517.fa_fog_b.x;\n        if (_3758 > 0.0)\n        {\n            float _3767 = _517.fa_fog.w * _3758;\n            float tau = _3767 * _3767;\n            if (_517.fa_fog_b.y > 0.0)\n            {\n                float _3783;\n                if (_3745)\n                {\n                    _3783 = in.fa_world_pos.y - (_517.fa_fog_c.y * _3741);\n                }\n                else\n                {\n                    _3783 = _517.fa_camera_pos.y;\n                }\n                float _3804 = mix(_3783, in.fa_world_pos.y, fast::clamp(_517.fa_fog_b.x / _3746, 0.0, 1.0));\n                float _3808 = in.fa_world_pos.y - _3804;\n                float _3813 = _3804 - _517.fa_fog_b.z;\n                float _3818 = in.fa_world_pos.y - _517.fa_fog_b.z;\n                bool _3821 = _3813 <= 0.0;\n                bool _3822 = !_3821;\n                bool _3828;\n                if (_3822)\n                {\n                    _3828 = _517.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3828 = _3821;\n                }\n                float _3829;\n                if (_3828)\n                {\n                    _3829 = _517.fa_fog_b.y;\n                }\n                else\n                {\n                    _3829 = _517.fa_fog_b.y * exp(-fast::min(_517.fa_fog_b.w * _3813, 80.0));\n                }\n                bool _3856;\n                if (_3822)\n                {\n                    _3856 = _517.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3856 = _3821;\n                }\n                float _3857;\n                if (_3856)\n                {\n                    _3857 = _517.fa_fog_b.y * _3813;\n                }\n                else\n                {\n                    _3857 = (_517.fa_fog_b.y * (1.0 - exp(-fast::min(_517.fa_fog_b.w * _3813, 80.0)))) / _517.fa_fog_b.w;\n                }\n                bool _3882 = _3818 <= 0.0;\n                bool _3889;\n                if (!_3882)\n                {\n                    _3889 = _517.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3889 = _3882;\n                }\n                float _3890;\n                if (_3889)\n                {\n                    _3890 = _517.fa_fog_b.y * _3818;\n                }\n                else\n                {\n                    _3890 = (_517.fa_fog_b.y * (1.0 - exp(-fast::min(_517.fa_fog_b.w * _3818, 80.0)))) / _517.fa_fog_b.w;\n                }\n                float _3917;\n                if (abs(_3808) < 0.001000000047497451305389404296875)\n                {\n                    _3917 = _3829;\n                }\n                else\n                {\n                    _3917 = (_3890 - _3857) / _3808;\n                }\n                tau += (_3758 * fast::max(_3917, 0.0));\n            }\n            result = mix(result, _517.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3990);\n    return out;\n}\n\n",
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
            "inst_name": "_153",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_517",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_753",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3004",
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 9,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float3 fa_lm [[user(locn7)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n    float4 fa_inst_d0 [[attribute(11)]];\n    float4 fa_inst_d1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _205)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_205.fa_joint_rows[_196] * weights[i]);\n        r1 += (_205.fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205.fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _158)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _158, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _158);\n    vertex0(param_6, raise);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = _158.fa_view_proj * float4(param_6.world_pos, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _158 [[buffer(0)]], constant fa_skin& _205 [[buffer(3)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _205);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, raise, _158, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nconstant spvUnsafeArray<float, 63> _2064 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float3 fa_lm [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _517)\n{\n    bool _522 = _517.fa_cl_info.x < 0.0;\n    bool _529;\n    if (!_522)\n    {\n        _529 = _517.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _529 = _522;\n    }\n    bool _537;\n    if (!_529)\n    {\n        _537 = _517.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _537 = _529;\n    }\n    bool _544;\n    if (!_537)\n    {\n        _544 = _517.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _544 = _537;\n    }\n    bool _551;\n    if (!_544)\n    {\n        _551 = _517.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _551 = _544;\n    }\n    if (_551)\n    {\n        return int2(0);\n    }\n    float4 _561 = float4(world_pos, 1.0);\n    float _568 = dot(_517.fa_cl_vpw, _561);\n    if (!(_568 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _590 = float2(dot(_517.fa_cl_vpx, _561), dot(_517.fa_cl_vpy, _561)) / float2(_568);\n    int _594 = int(_517.fa_cl_grid.x);\n    int _598 = int(_517.fa_cl_grid.y);\n    int param = (int(_517.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_517.fa_cl_fwd.xyz, world_pos) + _517.fa_cl_fwd.w, _517.fa_cl_grid.w) / _517.fa_cl_grid.w) * _517.fa_cl_grid.z)), 0, int(_517.fa_cl_info.y) - 1) * _598) + clamp(int(floor(((_590.y * 0.5) + 0.5) * _517.fa_cl_grid.y)), 0, _598 - 1)) * _594)) + clamp(int(floor(((_590.x * 0.5) + 0.5) * _517.fa_cl_grid.x)), 0, _594 - 1);\n    float4 _669 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_669.x), int(_669.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _517, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_517.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2881 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _517);\n    fa_cl_slot = _2881.x;\n    fa_cl_local = _2881.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3068 = fa_linear_to_srgb(param);\n        c = _3068;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3076 = fa_srgb_to_linear(param_1);\n            c = _3076;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _272;\n    if (bool(i.front_facing))\n    {\n        _272 = i.world_normal;\n    }\n    else\n    {\n        _272 = -i.world_normal;\n    }\n    float3 _296 = fast::normalize(i.world_tangent.xyz - (_272 * dot(_272, i.world_tangent.xyz)));\n    float3 _324 = fast::normalize(((_296 * m.x) + ((cross(_272, _296) * i.world_tangent.w) * m.y)) + (_272 * m.z));\n    float3 _327;\n    if (bool(i.front_facing))\n    {\n        _327 = _324;\n    }\n    else\n    {\n        _327 = -_324;\n    }\n    return _327;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _517, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _517.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3107 = fa_tex_fix(param_2, param_3);\n    float4 _4354 = base_t;\n    _4354.x = _3107.x;\n    _4354.y = _3107.y;\n    _4354.z = _3107.z;\n    base_t = _4354;\n    float4 _3121 = (_4354 * _517.fa_base_color) * i.vertex_color;\n    float3 _4256 = i.world_normal;\n    if (_517.fa_maps.z > 0.5)\n    {\n        float param_4 = _517.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3153 = fa_tex_fix(param_6, param_7);\n        float3 _3156 = (_3153 * 2.0) - float3(1.0);\n        float2 _3161 = _3156.xy * _517.fa_maps.x;\n        float3 _4362 = _3156;\n        _4362.x = _3161.x;\n        _4362.y = _3161.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4362;\n        _4256 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _517.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3190 = fa_tex_fix(param_12, param_13);\n    float4 _4365 = mrt;\n    _4365.x = _3190.x;\n    _4365.y = _3190.y;\n    _4365.z = _3190.z;\n    mrt = _4365;\n    float4 _3218 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _517.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3218.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3230 = fa_tex_fix(param_16, param_17);\n    float param_18 = _517.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3260 = fa_tex_fix(param_20, param_21);\n    float _4261 = _517.fa_layers_a.x;\n    float _4262 = _517.fa_layers_a.y;\n    float _4265 = _517.fa_layers_a.z;\n    float _4264 = _517.fa_layers_b.w;\n    float _4267 = _517.fa_layers_c.x;\n    if (_517.fa_layers_c.z > 0.5)\n    {\n        if (mod(_517.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4261 *= _3230.y;\n            _4262 *= _3230.z;\n            _4264 *= _3218.w;\n        }\n        if (_517.fa_layers_c.z > 1.5)\n        {\n            _4265 *= mrt.x;\n            _4267 *= mrt.w;\n        }\n    }\n    return Surface{ _3121.xyz, _3121.w, _4256, fast::clamp(_517.fa_pbr.x * _3190.z, 0.0, 1.0), fast::clamp(_517.fa_pbr.y * _3190.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_517.fa_maps.y * (_3230.x - 1.0)), _517.fa_emissive.xyz + (_517.fa_model_emissive.xyz * _3260), _4261, _4262, _517.fa_layers_b.xyz, _4264, _4265, _517.fa_layers_a.w, _4267, _517.fa_layers_c.y, _517.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _3004)\n{\n    s.emission += ((tint.xyz * tint.w) * _3004.boost);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1989 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1997 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2000 = int(_1989);\n    int _2003 = int(_1997);\n    float _2013 = _1997 - float(_2003);\n    int _2069 = (_2000 * 9) + _2003;\n    int _2089 = ((_2000 + 1) * 9) + _2003;\n    return mix(mix(_2064[_2069], _2064[_2069 + 1], _2013), mix(_2064[_2089], _2064[_2089 + 1], _2013), _1989 - float(_2000));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4179 = false;\n    float _4180 = 1.0;\n    float _4181 = 1.0;\n    float _4182 = 1.0;\n    float _4183 = 0.0;\n    float _4184 = 0.0;\n    float _4185 = 0.0;\n    float _4186 = 0.0;\n    float _4188 = 1.0;\n    bool _4189 = false;\n    float3 _4190 = float3(0.0);\n    float _4191 = 1.0;\n    float _4192 = 1.0;\n    float _4193 = 1.0;\n    float _4194 = 0.0;\n    float _4195 = 0.0;\n    float3 _4196 = float3(1.0, 0.0, 0.0);\n    float3 _4197 = float3(0.0, 0.0, 1.0);\n    float _4198 = 1.0;\n    float _4199 = 1.0;\n    float _2142 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2146 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2151 = (_2142 != 1.0) || (_2146 != 1.5);\n    bool _2161;\n    if (!_2151)\n    {\n        _2161 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2161 = _2151;\n    }\n    if (_2161)\n    {\n        float _2169 = (_2146 - 1.0) / (_2146 + 1.0);\n        f0 = mix(fast::min(float3(_2169 * _2169) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2142, s.albedo, float3(metallic));\n        _4180 = mix(_2142, 1.0, metallic);\n        _4179 = true;\n    }\n    float _2197 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2197 > 0.0)\n    {\n        float _2205 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4183 = _2197;\n        _4184 = _2205;\n        float _2212 = _2205 * _2205;\n        _4185 = _2212;\n        _4186 = _2212 * _2212;\n        float _2224 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4188 = _2224;\n        _4181 = 1.0 - (_2197 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2224, 0.0, 1.0), 5.0))));\n        _4179 = true;\n    }\n    float3 _2244 = fast::max(s.sheen_color, float3(0.0));\n    float _2253 = fast::max(_2244.x, fast::max(_2244.y, _2244.z));\n    if (_2253 > 0.0)\n    {\n        float _2261 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4189 = true;\n        _4190 = _2244;\n        _4191 = _2261;\n        _4192 = _2261 * _2261;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2261;\n        float _2278 = fa_sheen_albedo(param, param_1);\n        _4194 = _2278;\n        _4193 = 1.0 - fast::min(_2253 * _2278, 1.0);\n        _4179 = true;\n    }\n    _4182 = _4181 * _4193;\n    float _2297 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2297 != 0.0)\n    {\n        float3 _2312 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2312;\n        if (dot(_2312, _2312) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2330 = t;\n        float3 _2331 = fast::normalize(_2330);\n        t = _2331;\n        float3 _2356 = fast::normalize((_2331 * cos(s.anisotropy_rotation)) + ((cross(n, _2331) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4196 = _2356;\n        _4197 = cross(n, _2356);\n        float _2366 = roughness * roughness;\n        float _2372 = mix(_2366, 1.0, _2297 * _2297);\n        bool _2374 = _2297 > 0.0;\n        _4198 = _2374 ? _2372 : _2366;\n        _4199 = _2374 ? _2366 : _2372;\n        _4195 = _2297;\n        _4179 = true;\n    }\n    return FaLayers{ short(_4179), _4180, _4181, _4182, _4183, _4184, _4185, _4186, i.world_normal, _4188, short(_4189), _4190, _4191, _4192, _4193, _4194, _4195, _4196, _4197, _4198, _4199 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _517, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_517.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _517.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _517, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _517, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _517)\n{\n    int param = (int(_517.fa_cl_info.x) + int(_517.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _517, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _517);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _391 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _397 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _400 = _397.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _406 = _400 < 0.5;\n    float3 l;\n    if (_406)\n    {\n        l = fast::normalize(_391.xyz);\n    }\n    else\n    {\n        float3 _418 = _391.xyz - world_pos;\n        float _420 = length(_418);\n        dist = _420;\n        l = _418 / float3(fast::max(_420, 9.9999997473787516355514526367188e-05));\n        float _435 = _420 / fast::max(_391.w, 0.001000000047497451305389404296875);\n        float _441 = fast::clamp(1.0 - (_435 * _435), 0.0, 1.0);\n        atten = _441 * _441;\n        if (_400 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _455 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _465 = _455.w;\n            int param_3 = (li * 4) + 3;\n            float4 _471 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _472 = _471.x;\n            float cos_inner = _472;\n            if (_472 > 1.5)\n            {\n                cos_inner = mix(_465, 1.0, 0.25);\n            }\n            atten *= smoothstep(_465, cos_inner, dot(-l, fast::normalize(_455.xyz)));\n        }\n    }\n    int _503;\n    if (_406)\n    {\n        _503 = 0;\n    }\n    else\n    {\n        _503 = (_400 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _397.xyz * atten, atten, 1.0, dist, _503 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _753)\n{\n    float _743;\n    if (i == 0)\n    {\n        _743 = _753.fa_shadow_split.x;\n    }\n    else\n    {\n        float _759;\n        if (i == 1)\n        {\n            _759 = _753.fa_shadow_split.y;\n        }\n        else\n        {\n            float _767;\n            if (i == 2)\n            {\n                _767 = _753.fa_shadow_split.z;\n            }\n            else\n            {\n                _767 = _753.fa_shadow_split.w;\n            }\n            _759 = _767;\n        }\n        _743 = _759;\n    }\n    return _743;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _800 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _804;\n    if (conv.x < 0.5)\n    {\n        _804 = _800;\n    }\n    else\n    {\n        _804 = (conv.y * conv.z) / (conv.z - (_800 * (conv.z - conv.y)));\n    }\n    return _804;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _731 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_731), sin(_731)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _753, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _850 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _864 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _850;\n            float2 _883 = fa_shadow_vogel(param_3, param_4, param_5) * _864;\n            float2 param_6 = uv + (_883 * _753.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _895 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_895 < (zr - (length(_883) * plane)))\n            {\n                sum += _895;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _939 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _939; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _939;\n        float param_11 = _850;\n        float2 _958 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_958 * _753.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_958) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_939);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _753, texture2d<float> fa_shadow_tex)\n{\n    float _1000 = fast::max(_753.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1005 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1011 = sqrt(1.0 - (_1005 * _1005));\n    float _1019 = fast::min(_1011 / fast::max(_1005, 0.20000000298023223876953125), 4.0);\n    float _1024;\n    if (_753.fa_shadow_bias.y > 0.0)\n    {\n        _1024 = _753.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1024 = 1.5 * _753.fa_shadow_info[ci].x;\n    }\n    float4 _1049 = _753.fa_shadow_mat[ci] * float4(world + (n * (_1024 * _1011)), 1.0);\n    float _1056 = _1049.x;\n    bool _1059 = _1056 < _753.fa_shadow_rect[ci].x;\n    bool _1068;\n    if (!_1059)\n    {\n        _1068 = _1056 > _753.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1068 = _1059;\n    }\n    bool _1077;\n    if (!_1068)\n    {\n        _1077 = _1049.y < _753.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1077 = _1068;\n    }\n    bool _1086;\n    if (!_1077)\n    {\n        _1086 = _1049.y > _753.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1086 = _1077;\n    }\n    bool _1093;\n    if (!_1086)\n    {\n        _1093 = _1049.z > 1.0;\n    }\n    else\n    {\n        _1093 = _1086;\n    }\n    if (_1093)\n    {\n        return -1.0;\n    }\n    float _1102;\n    if (_753.fa_shadow_bias.x > 0.0)\n    {\n        _1102 = _753.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1102 = 1.5 * _753.fa_shadow_info[ci].x;\n    }\n    float2 param = _1049.xy;\n    float4 param_1 = _753.fa_shadow_rect[ci];\n    float param_2 = _1049.z - ((_1102 * (1.0 + (0.5 * _1019))) / _1000);\n    float param_3 = _753.fa_shadow_info[ci].x;\n    float param_4 = _1000;\n    float param_5 = _1000 * 0.25;\n    float param_6 = ((_753.fa_shadow_info[ci].x * fast::min(_1019, 3.0)) * 0.5) / _1000;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_753.fa_shadow_cfg.z + 0.5);\n    float param_9 = _753.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _753, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _517, thread float4& gl_FragCoord, constant fa_shadows& _753, texture2d<float> fa_shadow_tex)\n{\n    if (_517.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1530 = int(_753.fa_shadow_cfg.x + 0.5);\n    if (_1530 < 1)\n    {\n        return 1.0;\n    }\n    float _1546 = dot(world - _753.fa_shadow_eye.xyz, _753.fa_shadow_fwd.xyz);\n    int param = _1530 - 1;\n    if (_1546 > fa_shadow_split_at(param, _753))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1558 = _1530 > 1;\n    bool _1565;\n    if (_1558)\n    {\n        _1565 = _1546 > _753.fa_shadow_split.x;\n    }\n    else\n    {\n        _1565 = _1558;\n    }\n    if (_1565)\n    {\n        ci = 1;\n    }\n    bool _1569 = _1530 > 2;\n    bool _1576;\n    if (_1569)\n    {\n        _1576 = _1546 > _753.fa_shadow_split.y;\n    }\n    else\n    {\n        _1576 = _1569;\n    }\n    if (_1576)\n    {\n        ci = 2;\n    }\n    bool _1580 = _1530 > 3;\n    bool _1587;\n    if (_1580)\n    {\n        _1587 = _1546 > _753.fa_shadow_split.z;\n    }\n    else\n    {\n        _1587 = _1580;\n    }\n    if (_1587)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1530)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1613 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _753, fa_shadow_tex);\n        s = _1613;\n        if (_1613 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_753.fa_shadow_cfg.y > 0.0)\n    {\n        float _1638;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1638 = fa_shadow_split_at(param_5, _753);\n        }\n        else\n        {\n            _1638 = _753.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1657 = _753.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _753) - _1638, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1668 = fast::clamp((_1546 - (fa_shadow_split_at(param_7, _753) - _1657)) / _1657, 0.0, 1.0);\n        if (_1668 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1530)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1689 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _753, fa_shadow_tex);\n                s2 = _1689;\n                if (_1689 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1668);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _517, thread float4& gl_FragCoord, constant fa_shadows& _753, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _517, gl_FragCoord, _753, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _517, thread float4& gl_FragCoord, constant fa_shadows& _753, texture2d<float> fa_shadow_tex)\n{\n    bool _1161 = _517.fa_pbr.z < 0.5;\n    bool _1169;\n    if (!_1161)\n    {\n        _1169 = _753.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1169 = _1161;\n    }\n    if (_1169)\n    {\n        return 1.0;\n    }\n    int param = (int(_753.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1182 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1183 = _1182.x;\n    if (_1183 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1192 = int(_1183 + 0.5);\n    int param_1 = _1192;\n    float4 _1196 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1192 + 1;\n    float4 _1201 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1204 = _1196.y;\n    if (_1204 > 0.0)\n    {\n        float _1221 = 1.0 - smoothstep(0.75 * _1204, _1204, length(world - _753.fa_shadow_eye.xyz));\n        fade = _1221;\n        if (_1221 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1196.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1240 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1243 = abs(_1240);\n        float _1245 = _1243.x;\n        float _1247 = _1243.y;\n        bool _1248 = _1245 >= _1247;\n        bool _1256;\n        if (_1248)\n        {\n            _1256 = _1245 >= _1243.z;\n        }\n        else\n        {\n            _1256 = _1248;\n        }\n        int _1257;\n        if (_1256)\n        {\n            _1257 = (_1240.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1270;\n            if (_1247 >= _1243.z)\n            {\n                _1270 = (_1240.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1270 = (_1240.z > 0.0) ? 4 : 5;\n            }\n            _1257 = _1270;\n        }\n        face = _1257;\n    }\n    int _1289 = (_1192 + 2) + (face * 6);\n    int param_4 = _1289;\n    int param_5 = _1289 + 1;\n    int param_6 = _1289 + 3;\n    float4 _1303 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1289 + 4;\n    float4 _1308 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1289 + 5;\n    float4 _1313 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1325 = _1313.x * fast::max(dot(_1303, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1330 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1353 = fast::clamp(dot(n, _1303.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1376 = fast::min(sqrt(1.0 - (_1353 * _1353)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1303, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1379 = _1201.y;\n    float _1381;\n    if (_1379 > 0.0)\n    {\n        _1381 = _1379;\n    }\n    else\n    {\n        _1381 = 1.5 * _1325;\n    }\n    float4 _1401 = float4(world + (n * (_1381 * sqrt(1.0 - (_1330 * _1330)))), 1.0);\n    float _1405 = dot(_1303, _1401);\n    float _1408 = _1313.y;\n    if (_1405 < _1408)\n    {\n        return 1.0;\n    }\n    float2 _1423 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1401), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1401)) / float2(_1405);\n    float _1425 = _1423.x;\n    bool _1428 = _1425 < _1308.x;\n    bool _1437;\n    if (!_1428)\n    {\n        _1437 = _1425 > _1308.z;\n    }\n    else\n    {\n        _1437 = _1428;\n    }\n    bool _1446;\n    if (!_1437)\n    {\n        _1446 = _1423.y < _1308.y;\n    }\n    else\n    {\n        _1446 = _1437;\n    }\n    bool _1455;\n    if (!_1446)\n    {\n        _1455 = _1423.y > _1308.w;\n    }\n    else\n    {\n        _1455 = _1446;\n    }\n    if (_1455)\n    {\n        return 1.0;\n    }\n    float _1461 = _1201.x;\n    float _1463;\n    if (_1461 > 0.0)\n    {\n        _1463 = _1461;\n    }\n    else\n    {\n        _1463 = 1.5 * _1325;\n    }\n    float2 param_10 = _1423;\n    float4 param_11 = _1308;\n    float param_12 = _1405 - (_1463 * (1.0 + (0.5 * _1376)));\n    float param_13 = _1325;\n    float param_14 = 1.0;\n    float param_15 = _1313.z * 0.25;\n    float param_16 = (_1325 * fast::min(_1376, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1408, _1313.z);\n    int param_18 = int(_1196.z + 0.5);\n    float param_19 = _1196.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _753, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _517, thread float4& gl_FragCoord, constant fa_shadows& _753, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _2908 = fa_lm.z > 0.5;\n    bool _2914;\n    if (_2908)\n    {\n        int param = li;\n        _2914 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2914 = _2908;\n    }\n    if (_2914)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2936 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _4241 = _2936.direction;\n    float3 _4236 = _2936.color;\n    float _4243 = _2936.attenuation;\n    float _4238 = _2936.shadow;\n    int _4246 = _2936.type;\n    if ((_4246 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4241;\n        float _2950 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _517, gl_FragCoord, _753, fa_shadow_tex, fa_world_pos);\n        _4238 = _2950;\n        _4236 *= _2950;\n    }\n    else\n    {\n        bool _2961 = _4246 != 0;\n        bool _2967;\n        if (_2961)\n        {\n            _2967 = _4243 > 0.0;\n        }\n        else\n        {\n            _2967 = _2961;\n        }\n        if (_2967)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4241;\n            float _2979 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _517, gl_FragCoord, _753, fa_shadow_tex);\n            _4238 = _2979;\n            _4236 *= _2979;\n        }\n    }\n    return LightSample{ _4241, _4236, _4243, _4238, _2936._distance, _4246 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _2524 = tdh / at;\n    float _2528 = bdh / ab;\n    float _2540 = ((_2524 * _2524) + (_2528 * _2528)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2540) * _2540);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _2621 = 1.0 / alpha;\n    return ((2.0 + _2621) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2621)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _2654 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2733 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2733) * _2733);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2654);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2654));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2806 = fast::max(dot(L.nc, l), 0.0);\n        float _2812 = fast::max(dot(L.nc, h), 0.0);\n        float _2821 = ((_2812 * _2812) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2821) * _2821)) * (0.5 / fast::max(mix((2.0 * _2806) * L.coat_ndv, _2806 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2806)) * _2806);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1921 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1924 = _1921.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1924 * _1924, exp2((-9.27999973297119140625) * ndv)) * _1924) + _1921.y)) + _1921.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _517, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_517.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _517.fa_env_horizon.w)).xyz;\n    }\n    float _1826 = rough * rough;\n    float _1856 = 0.60000002384185791015625 * _1826;\n    return mix(mix(_517.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_517.fa_env_horizon.xyz, _517.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1826)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1856, 0.0500000007450580596923828125 + _1856, d.y))), ((_517.fa_env_sky.xyz + _517.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1826 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _517, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2407;\n        if (L.aniso >= 0.0)\n        {\n            _2407 = L.b;\n        }\n        else\n        {\n            _2407 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2407, v), _2407), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2440 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _517, fa_env_tex, fa_env_smp) * ((f0 * _2440.x) + (float3(L.f90) * _2440.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _517, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2495 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _517, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _2495.x) + _2495.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _517, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1963 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _517, fa_env_tex, fa_env_smp) * ((f0 * _1963.x) + float3(_1963.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _753)\n{\n    if (_753.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1713 = int(_753.fa_shadow_cfg.x + 0.5);\n    float _1723 = dot(world - _753.fa_shadow_eye.xyz, _753.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1728 = _1713 > 0;\n    bool _1737;\n    if (_1728)\n    {\n        int param = _1713 - 1;\n        _1737 = _1723 <= fa_shadow_split_at(param, _753);\n    }\n    else\n    {\n        _1737 = _1728;\n    }\n    if (_1737)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1744 = _1713 > 1;\n        bool _1751;\n        if (_1744)\n        {\n            _1751 = _1723 > _753.fa_shadow_split.x;\n        }\n        else\n        {\n            _1751 = _1744;\n        }\n        if (_1751)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1757 = _1713 > 2;\n        bool _1764;\n        if (_1757)\n        {\n            _1764 = _1723 > _753.fa_shadow_split.y;\n        }\n        else\n        {\n            _1764 = _1757;\n        }\n        if (_1764)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1770 = _1713 > 3;\n        bool _1777;\n        if (_1770)\n        {\n            _1777 = _1723 > _753.fa_shadow_split.z;\n        }\n        else\n        {\n            _1777 = _1770;\n        }\n        if (_1777)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _517 [[buffer(1)]], constant fa_material& _3004 [[buffer(5)]], constant fa_shadows& _753 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _3958 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3958 = -_3958;\n    }\n    float3 _3400 = fast::normalize(_517.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _517, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3958, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3400, short(gl_FrontFacing) };\n    Surface _3408 = fa_standard_surface(param_1, _517, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3989 = _3408.albedo;\n    float _3990 = _3408.alpha;\n    float3 _3991 = _3408.normal;\n    float _3992 = _3408.metallic;\n    float _3993 = _3408.roughness;\n    float _3994 = _3408.occlusion;\n    float3 _3995 = _3408.emission;\n    float _3996 = _3408.clearcoat;\n    float _3997 = _3408.clearcoat_roughness;\n    float3 _3998 = _3408.sheen_color;\n    float _3999 = _3408.sheen_roughness;\n    float _4000 = _3408.anisotropy;\n    float _4001 = _3408.anisotropy_rotation;\n    float _4002 = _3408.specular;\n    float _4003 = _3408.ior;\n    float3 _4004 = _3408.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3958, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3400, short(gl_FrontFacing) };\n    Surface param_3 = _3408;\n    surface(param_2, param_3, tint, _3004);\n    _3989 = param_3.albedo;\n    _3990 = param_3.alpha;\n    _3991 = param_3.normal;\n    _3992 = param_3.metallic;\n    _3993 = param_3.roughness;\n    _3994 = param_3.occlusion;\n    _3995 = param_3.emission;\n    _3996 = param_3.clearcoat;\n    _3997 = param_3.clearcoat_roughness;\n    _3998 = param_3.sheen_color;\n    _3999 = param_3.sheen_roughness;\n    _4000 = param_3.anisotropy;\n    _4001 = param_3.anisotropy_rotation;\n    _4002 = param_3.specular;\n    _4003 = param_3.ior;\n    _4004 = param_3.specular_color;\n    float3 result;\n    if (_517.fa_emissive.w > 0.5)\n    {\n        result = _3989;\n    }\n    else\n    {\n        float3 _3430 = fast::normalize(_3991);\n        float _3437 = fast::clamp(_3992, 0.0, 1.0);\n        float _3441 = fast::clamp(_3993, 0.0500000007450580596923828125, 1.0);\n        float _3445 = _3441 * _3441;\n        float _3449 = _3445 * _3445;\n        float _3454 = fast::max(dot(_3430, _3400), 9.9999997473787516355514526367188e-05);\n        float3 _3460 = _3989 * (1.0 - _3437);\n        float3 _3467 = mix(float3(0.039999999105930328369140625), _3989, float3(_3437));\n        float3 f0 = _3467;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _3958, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3400, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _3989, _3990, _3991, _3992, _3993, _3994, _3995, _3996, _3997, _3998, _3999, _4000, _4001, _4002, _4003, _4004 };\n        float3 param_6 = _3430;\n        float3 param_7 = _3400;\n        float param_8 = _3437;\n        float param_9 = _3441;\n        float3 param_10 = _3467;\n        FaLayers _3483 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _3430;\n        float3 lit = (fa_indirect_diffuse(param_11, _517, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap) * _3460) * _3994;\n        if (_3483.on)\n        {\n            lit *= _3483.base_scale;\n        }\n        int _3505 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3505; ln++)\n        {\n            int param_12 = ln;\n            int _3518 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _517, fa_cl_ndir, fa_cl_slot);\n            bool _3521 = in.fa_lm.z > 0.5;\n            bool _3527;\n            if (_3521)\n            {\n                int param_13 = _3518;\n                _3527 = fa_light_baked(param_13, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _3527 = _3521;\n            }\n            if (_3527)\n            {\n                continue;\n            }\n            int param_14 = _3518;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _3958;\n            LightSample _3539 = fa_light_shadowed(param_14, param_15, param_16, fa_light_tex, fa_shadow_smp, _517, gl_FragCoord, _753, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            float3 _4163 = _3539.direction;\n            float _3547 = fast::max(dot(_3430, _4163), 0.0);\n            float _3553 = _3539.attenuation * _3539.shadow;\n            float3 _3558 = fast::normalize(_4163 + _3400);\n            float _3563 = fast::max(dot(_3430, _3558), 0.0);\n            float _3568 = fast::max(dot(_3400, _3558), 0.0);\n            if (_3483.on)\n            {\n                FaLayers param_17 = _3483;\n                float3 param_18 = _3460;\n                float3 param_19 = f0;\n                float3 param_20 = _3430;\n                float3 param_21 = _3400;\n                float3 param_22 = _4163;\n                float3 param_23 = _3558;\n                float param_24 = _3547;\n                float param_25 = _3454;\n                float param_26 = _3563;\n                float param_27 = _3568;\n                float param_28 = _3445;\n                float param_29 = _3449;\n                int param_30 = _3518;\n                lit += (fa_layers_light(param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29) * (fa_light_rgb(param_30, fa_light_tex, fa_shadow_smp) * _3553));\n            }\n            else\n            {\n                float _3616 = ((_3563 * _3563) * (_3449 - 1.0)) + 1.0;\n                int param_31 = _3518;\n                lit += (((_3460 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _3568, 5.0))) * (((_3449 / ((3.1415927410125732421875 * _3616) * _3616)) * (0.5 / fast::max(mix((2.0 * _3547) * _3454, _3547 + _3454, _3445), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3547))) * fa_light_rgb(param_31, fa_light_tex, fa_shadow_smp)) * (_3547 * _3553));\n            }\n        }\n        if (_3483.on)\n        {\n            FaLayers param_32 = _3483;\n            float3 param_33 = _3430;\n            float3 param_34 = _3400;\n            float3 param_35 = f0;\n            float param_36 = _3441;\n            lit += (fa_layers_ibl(param_32, param_33, param_34, param_35, param_36, _517, fa_env_tex, fa_env_smp) * _3994);\n        }\n        else\n        {\n            float3 param_37 = _3430;\n            float3 param_38 = _3400;\n            float3 param_39 = f0;\n            float param_40 = _3441;\n            lit += (fa_sky_reflection(param_37, param_38, param_39, param_40, _517, fa_env_tex, fa_env_smp) * _3994);\n        }\n        result = lit;\n    }\n    float3 _3709 = result;\n    float3 _3710 = _3709 + _3995;\n    result = _3710;\n    float3 param_41 = _3710;\n    float3 param_42 = in.fa_world_pos;\n    result = fa_shadow_debug(param_41, param_42, _753);\n    bool _3719 = _517.fa_fog.w > 0.0;\n    bool _3726;\n    if (!_3719)\n    {\n        _3726 = _517.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3726 = _3719;\n    }\n    if (_3726)\n    {\n        float3 _3735 = in.fa_world_pos - _517.fa_camera_pos.xyz;\n        float _3741 = dot(_3735, _517.fa_fog_c.xyz);\n        bool _3745 = _517.fa_fog_c.w > 0.5;\n        float _3746;\n        if (_3745)\n        {\n            _3746 = _3741;\n        }\n        else\n        {\n            _3746 = length(_3735);\n        }\n        float _3758 = _3746 - _517.fa_fog_b.x;\n        if (_3758 > 0.0)\n        {\n            float _3767 = _517.fa_fog.w * _3758;\n            float tau = _3767 * _3767;\n            if (_517.fa_fog_b.y > 0.0)\n            {\n                float _3783;\n                if (_3745)\n                {\n                    _3783 = in.fa_world_pos.y - (_517.fa_fog_c.y * _3741);\n                }\n                else\n                {\n                    _3783 = _517.fa_camera_pos.y;\n                }\n                float _3804 = mix(_3783, in.fa_world_pos.y, fast::clamp(_517.fa_fog_b.x / _3746, 0.0, 1.0));\n                float _3808 = in.fa_world_pos.y - _3804;\n                float _3813 = _3804 - _517.fa_fog_b.z;\n                float _3818 = in.fa_world_pos.y - _517.fa_fog_b.z;\n                bool _3821 = _3813 <= 0.0;\n                bool _3822 = !_3821;\n                bool _3828;\n                if (_3822)\n                {\n                    _3828 = _517.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3828 = _3821;\n                }\n                float _3829;\n                if (_3828)\n                {\n                    _3829 = _517.fa_fog_b.y;\n                }\n                else\n                {\n                    _3829 = _517.fa_fog_b.y * exp(-fast::min(_517.fa_fog_b.w * _3813, 80.0));\n                }\n                bool _3856;\n                if (_3822)\n                {\n                    _3856 = _517.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3856 = _3821;\n                }\n                float _3857;\n                if (_3856)\n                {\n                    _3857 = _517.fa_fog_b.y * _3813;\n                }\n                else\n                {\n                    _3857 = (_517.fa_fog_b.y * (1.0 - exp(-fast::min(_517.fa_fog_b.w * _3813, 80.0)))) / _517.fa_fog_b.w;\n                }\n                bool _3882 = _3818 <= 0.0;\n                bool _3889;\n                if (!_3882)\n                {\n                    _3889 = _517.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3889 = _3882;\n                }\n                float _3890;\n                if (_3889)\n                {\n                    _3890 = _517.fa_fog_b.y * _3818;\n                }\n                else\n                {\n                    _3890 = (_517.fa_fog_b.y * (1.0 - exp(-fast::min(_517.fa_fog_b.w * _3818, 80.0)))) / _517.fa_fog_b.w;\n                }\n                float _3917;\n                if (abs(_3808) < 0.001000000047497451305389404296875)\n                {\n                    _3917 = _3829;\n                }\n                else\n                {\n                    _3917 = (_3890 - _3857) / _3808;\n                }\n                tau += (_3758 * fast::max(_3917, 0.0));\n            }\n            result = mix(result, _517.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3990);\n    return out;\n}\n\n",
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
            "type": "vec4",
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
            "inst_name": "_158",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_205",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_517",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_753",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3004",
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 9,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_inst_d0 [[attribute(9)]];\n    float4 fa_inst_d1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _153)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _153, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _153);\n    vertex0(param_6, raise);\n    float4 _197 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_153.fa_light_vp * _197).z;\n    fa_pre_r0 = float3(_153.fa_light_vp[0].x, _153.fa_light_vp[1].x, _153.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_153.fa_light_vp[0].y, _153.fa_light_vp[1].y, _153.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_153.fa_light_vp[0].z, _153.fa_light_vp[1].z, _153.fa_light_vp[2].z);\n    gl_Position = _153.fa_view_proj * _197;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _153 [[buffer(0)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, raise, _153, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _63;\n    if (bool(i.front_facing))\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = fast::normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = fast::normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (bool(i.front_facing))\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _253, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _253.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _770 = base_t;\n    _770.x = _264.x;\n    _770.y = _264.y;\n    _770.z = _264.z;\n    base_t = _770;\n    float4 _280 = (_770 * _253.fa_base_color) * i.vertex_color;\n    float3 _733 = i.world_normal;\n    if (_253.fa_maps.z > 0.5)\n    {\n        float param_4 = _253.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0) - float3(1.0);\n        float2 _322 = _317.xy * _253.fa_maps.x;\n        float3 _778 = _317;\n        _778.x = _322.x;\n        _778.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _778;\n        _733 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _253.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _781 = mrt;\n    _781.x = _351.x;\n    _781.y = _351.y;\n    _781.z = _351.z;\n    mrt = _781;\n    float4 _381 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _253.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _423 = fa_tex_fix(param_20, param_21);\n    float _738 = _253.fa_layers_a.x;\n    float _739 = _253.fa_layers_a.y;\n    float _742 = _253.fa_layers_a.z;\n    float _741 = _253.fa_layers_b.w;\n    float _744 = _253.fa_layers_c.x;\n    if (_253.fa_layers_c.z > 0.5)\n    {\n        if (mod(_253.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _738 *= _393.y;\n            _739 *= _393.z;\n            _741 *= _381.w;\n        }\n        if (_253.fa_layers_c.z > 1.5)\n        {\n            _742 *= mrt.x;\n            _744 *= mrt.w;\n        }\n    }\n    return Surface{ _280.xyz, _280.w, _733, fast::clamp(_253.fa_pbr.x * _351.z, 0.0, 1.0), fast::clamp(_253.fa_pbr.y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_253.fa_maps.y * (_393.x - 1.0)), _253.fa_emissive.xyz + (_253.fa_model_emissive.xyz * _423), _738, _739, _253.fa_layers_b.xyz, _741, _742, _253.fa_layers_a.w, _744, _253.fa_layers_c.y, _253.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _142)\n{\n    s.emission += ((tint.xyz * tint.w) * _142.boost);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _253 [[buffer(1)]], constant fa_material& _142 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _644 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _644 = -_644;\n    }\n    float3 _556 = fast::normalize(_253.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _644, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _556, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _644, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _556, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _253, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, tint, _142);\n    float3 _571 = fast::normalize(param_2.normal);\n    float3 _586 = fast::normalize(float3(dot(in.fa_pre_r0, _571), dot(in.fa_pre_r1, _571), dot(in.fa_pre_r2, _571)));\n    float _598 = _586.z;\n    float2 e = _586.xy / float2((abs(_586.x) + abs(_586.y)) + abs(_598));\n    if (_598 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "inst_name": "_153",
            "msl_buffer_n": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_142",
            "msl_buffer_n": 5
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n    float4 fa_inst_d0 [[attribute(11)]];\n    float4 fa_inst_d1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _205)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_205.fa_joint_rows[_196] * weights[i]);\n        r1 += (_205.fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205.fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _158)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, thread float& raise, constant fa_mesh_vs_params& _158, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _158);\n    vertex0(param_6, raise);\n    float4 _310 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_158.fa_light_vp * _310).z;\n    fa_pre_r0 = float3(_158.fa_light_vp[0].x, _158.fa_light_vp[1].x, _158.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_158.fa_light_vp[0].y, _158.fa_light_vp[1].y, _158.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_158.fa_light_vp[0].z, _158.fa_light_vp[1].z, _158.fa_light_vp[2].z);\n    gl_Position = _158.fa_view_proj * _310;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _158 [[buffer(0)]], constant fa_skin& _205 [[buffer(3)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _205);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, raise, _158, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _63;\n    if (bool(i.front_facing))\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = fast::normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = fast::normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (bool(i.front_facing))\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _253, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _253.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _770 = base_t;\n    _770.x = _264.x;\n    _770.y = _264.y;\n    _770.z = _264.z;\n    base_t = _770;\n    float4 _280 = (_770 * _253.fa_base_color) * i.vertex_color;\n    float3 _733 = i.world_normal;\n    if (_253.fa_maps.z > 0.5)\n    {\n        float param_4 = _253.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0) - float3(1.0);\n        float2 _322 = _317.xy * _253.fa_maps.x;\n        float3 _778 = _317;\n        _778.x = _322.x;\n        _778.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _778;\n        _733 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _253.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _781 = mrt;\n    _781.x = _351.x;\n    _781.y = _351.y;\n    _781.z = _351.z;\n    mrt = _781;\n    float4 _381 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _253.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _423 = fa_tex_fix(param_20, param_21);\n    float _738 = _253.fa_layers_a.x;\n    float _739 = _253.fa_layers_a.y;\n    float _742 = _253.fa_layers_a.z;\n    float _741 = _253.fa_layers_b.w;\n    float _744 = _253.fa_layers_c.x;\n    if (_253.fa_layers_c.z > 0.5)\n    {\n        if (mod(_253.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _738 *= _393.y;\n            _739 *= _393.z;\n            _741 *= _381.w;\n        }\n        if (_253.fa_layers_c.z > 1.5)\n        {\n            _742 *= mrt.x;\n            _744 *= mrt.w;\n        }\n    }\n    return Surface{ _280.xyz, _280.w, _733, fast::clamp(_253.fa_pbr.x * _351.z, 0.0, 1.0), fast::clamp(_253.fa_pbr.y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_253.fa_maps.y * (_393.x - 1.0)), _253.fa_emissive.xyz + (_253.fa_model_emissive.xyz * _423), _738, _739, _253.fa_layers_b.xyz, _741, _742, _253.fa_layers_a.w, _744, _253.fa_layers_c.y, _253.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, thread float4& tint, constant fa_material& _142)\n{\n    s.emission += ((tint.xyz * tint.w) * _142.boost);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _253 [[buffer(1)]], constant fa_material& _142 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _644 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _644 = -_644;\n    }\n    float3 _556 = fast::normalize(_253.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _644, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _556, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _644, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _556, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _253, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, tint, _142);\n    float3 _571 = fast::normalize(param_2.normal);\n    float3 _586 = fast::normalize(float3(dot(in.fa_pre_r0, _571), dot(in.fa_pre_r1, _571), dot(in.fa_pre_r2, _571)));\n    float _598 = _586.z;\n    float2 e = _586.xy / float2((abs(_586.x) + abs(_586.y)) + abs(_598));\n    if (_598 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "type": "vec4",
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
            "inst_name": "_158",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_205",
            "msl_buffer_n": 3
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_142",
            "msl_buffer_n": 5
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float3 fa_normal [[attribute(5)]];\n    float2 fa_texcoord0 [[attribute(6)]];\n    float4 fa_tangent [[attribute(7)]];\n    float4 fa_color [[attribute(8)]];\n    float4 fa_inst_d0 [[attribute(9)]];\n    float4 fa_inst_d1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _144)\n{\n    float3 _85 = cross(model[1].xyz, model[2].xyz);\n    float _91 = (dot(model[0].xyz, _85) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_85 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _91, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _91), texcoord0 * _144.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _144 [[buffer(0)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _144);\n    vertex0(param_6, raise);\n    out.gl_Position = _144.fa_light_vp * float4(param_6.world_pos, 1.0);\n    return out;\n}\n\n",
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
            "inst_name": "_144",
            "msl_buffer_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float4 fa_joints [[attribute(5)]];\n    float4 fa_weights [[attribute(6)]];\n    float3 fa_normal [[attribute(7)]];\n    float2 fa_texcoord0 [[attribute(8)]];\n    float4 fa_tangent [[attribute(9)]];\n    float4 fa_color [[attribute(10)]];\n    float4 fa_inst_d0 [[attribute(11)]];\n    float4 fa_inst_d1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _196)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _187 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_196.fa_joint_rows[_187] * weights[i]);\n        r1 += (_196.fa_joint_rows[_187 + 1] * weights[i]);\n        r2 += (_196.fa_joint_rows[_187 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _149)\n{\n    float3 _90 = cross(model[1].xyz, model[2].xyz);\n    float _96 = (dot(model[0].xyz, _90) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_90 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _96, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _96), texcoord0 * _149.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, thread float& raise)\n{\n    v.world_pos.y += raise;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _149 [[buffer(0)]], constant fa_skin& _196 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1);\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _196);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7, _149);\n    vertex0(param_8, raise);\n    out.gl_Position = _149.fa_light_vp * float4(param_8.world_pos, 1.0);\n    return out;\n}\n\n",
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
            "type": "vec4",
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
            "inst_name": "_196",
            "msl_buffer_n": 3
          }
        ]
      }
    }
  }
}
