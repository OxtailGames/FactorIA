{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "df130aaeb5c0790af276010723d2798f8fdace693dbde21948e5a037edff24ef",
  "slang": "metal_macos",
  "params": [
    "alphaCutoff"
  ],
  "textures": [
    "mask"
  ],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _276 = _160.world_pos;\n    fa_world_pos = _276;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_276, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nconstant spvUnsafeArray<float, 63> _2058 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _511)\n{\n    bool _516 = _511.fa_cl_info.x < 0.0;\n    bool _523;\n    if (!_516)\n    {\n        _523 = _511.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _523 = _516;\n    }\n    bool _531;\n    if (!_523)\n    {\n        _531 = _511.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _531 = _523;\n    }\n    bool _538;\n    if (!_531)\n    {\n        _538 = _511.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _538 = _531;\n    }\n    bool _545;\n    if (!_538)\n    {\n        _545 = _511.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _545 = _538;\n    }\n    if (_545)\n    {\n        return int2(0);\n    }\n    float4 _555 = float4(world_pos, 1.0);\n    float _562 = dot(_511.fa_cl_vpw, _555);\n    if (!(_562 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _584 = float2(dot(_511.fa_cl_vpx, _555), dot(_511.fa_cl_vpy, _555)) / float2(_562);\n    int _588 = int(_511.fa_cl_grid.x);\n    int _592 = int(_511.fa_cl_grid.y);\n    int param = (int(_511.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_511.fa_cl_fwd.xyz, world_pos) + _511.fa_cl_fwd.w, _511.fa_cl_grid.w) / _511.fa_cl_grid.w) * _511.fa_cl_grid.z)), 0, int(_511.fa_cl_info.y) - 1) * _592) + clamp(int(floor(((_584.y * 0.5) + 0.5) * _511.fa_cl_grid.y)), 0, _592 - 1)) * _588)) + clamp(int(floor(((_584.x * 0.5) + 0.5) * _511.fa_cl_grid.x)), 0, _588 - 1);\n    float4 _663 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_663.x), int(_663.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _511, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_511.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2875 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _511);\n    fa_cl_slot = _2875.x;\n    fa_cl_local = _2875.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3042 = fa_linear_to_srgb(param);\n        c = _3042;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3050 = fa_srgb_to_linear(param_1);\n            c = _3050;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _266;\n    if (bool(i.front_facing))\n    {\n        _266 = i.world_normal;\n    }\n    else\n    {\n        _266 = -i.world_normal;\n    }\n    float3 _290 = fast::normalize(i.world_tangent.xyz - (_266 * dot(_266, i.world_tangent.xyz)));\n    float3 _318 = fast::normalize(((_290 * m.x) + ((cross(_266, _290) * i.world_tangent.w) * m.y)) + (_266 * m.z));\n    float3 _321;\n    if (bool(i.front_facing))\n    {\n        _321 = _318;\n    }\n    else\n    {\n        _321 = -_318;\n    }\n    return _321;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _511, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _511.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3081 = fa_tex_fix(param_2, param_3);\n    float4 _4339 = base_t;\n    _4339.x = _3081.x;\n    _4339.y = _3081.y;\n    _4339.z = _3081.z;\n    base_t = _4339;\n    float4 _3095 = (_4339 * _511.fa_base_color) * i.vertex_color;\n    float3 _4241 = i.world_normal;\n    if (_511.fa_maps.z > 0.5)\n    {\n        float param_4 = _511.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3127 = fa_tex_fix(param_6, param_7);\n        float3 _3130 = (_3127 * 2.0) - float3(1.0);\n        float2 _3135 = _3130.xy * _511.fa_maps.x;\n        float3 _4347 = _3130;\n        _4347.x = _3135.x;\n        _4347.y = _3135.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4347;\n        _4241 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _511.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3164 = fa_tex_fix(param_12, param_13);\n    float4 _4350 = mrt;\n    _4350.x = _3164.x;\n    _4350.y = _3164.y;\n    _4350.z = _3164.z;\n    mrt = _4350;\n    float4 _3192 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _511.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3192.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3204 = fa_tex_fix(param_16, param_17);\n    float param_18 = _511.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3234 = fa_tex_fix(param_20, param_21);\n    float _4246 = _511.fa_layers_a.x;\n    float _4247 = _511.fa_layers_a.y;\n    float _4250 = _511.fa_layers_a.z;\n    float _4249 = _511.fa_layers_b.w;\n    float _4252 = _511.fa_layers_c.x;\n    if (_511.fa_layers_c.z > 0.5)\n    {\n        if (mod(_511.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4246 *= _3204.y;\n            _4247 *= _3204.z;\n            _4249 *= _3192.w;\n        }\n        if (_511.fa_layers_c.z > 1.5)\n        {\n            _4250 *= mrt.x;\n            _4252 *= mrt.w;\n        }\n    }\n    return Surface{ _3095.xyz, _3095.w, _4241, fast::clamp(_511.fa_pbr.x * _3164.z, 0.0, 1.0), fast::clamp(_511.fa_pbr.y * _3164.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_511.fa_maps.y * (_3204.x - 1.0)), _511.fa_emissive.xyz + (_511.fa_model_emissive.xyz * _3234), _4246, _4247, _511.fa_layers_b.xyz, _4249, _4250, _511.fa_layers_a.w, _4252, _511.fa_layers_c.y, _511.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1983 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1991 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1994 = int(_1983);\n    int _1997 = int(_1991);\n    float _2007 = _1991 - float(_1997);\n    int _2063 = (_1994 * 9) + _1997;\n    int _2083 = ((_1994 + 1) * 9) + _1997;\n    return mix(mix(_2058[_2063], _2058[_2063 + 1], _2007), mix(_2058[_2083], _2058[_2083 + 1], _2007), _1983 - float(_1994));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4164 = false;\n    float _4165 = 1.0;\n    float _4166 = 1.0;\n    float _4167 = 1.0;\n    float _4168 = 0.0;\n    float _4169 = 0.0;\n    float _4170 = 0.0;\n    float _4171 = 0.0;\n    float _4173 = 1.0;\n    bool _4174 = false;\n    float3 _4175 = float3(0.0);\n    float _4176 = 1.0;\n    float _4177 = 1.0;\n    float _4178 = 1.0;\n    float _4179 = 0.0;\n    float _4180 = 0.0;\n    float3 _4181 = float3(1.0, 0.0, 0.0);\n    float3 _4182 = float3(0.0, 0.0, 1.0);\n    float _4183 = 1.0;\n    float _4184 = 1.0;\n    float _2136 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2140 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2145 = (_2136 != 1.0) || (_2140 != 1.5);\n    bool _2155;\n    if (!_2145)\n    {\n        _2155 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2155 = _2145;\n    }\n    if (_2155)\n    {\n        float _2163 = (_2140 - 1.0) / (_2140 + 1.0);\n        f0 = mix(fast::min(float3(_2163 * _2163) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2136, s.albedo, float3(metallic));\n        _4165 = mix(_2136, 1.0, metallic);\n        _4164 = true;\n    }\n    float _2191 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2191 > 0.0)\n    {\n        float _2199 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4168 = _2191;\n        _4169 = _2199;\n        float _2206 = _2199 * _2199;\n        _4170 = _2206;\n        _4171 = _2206 * _2206;\n        float _2218 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4173 = _2218;\n        _4166 = 1.0 - (_2191 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2218, 0.0, 1.0), 5.0))));\n        _4164 = true;\n    }\n    float3 _2238 = fast::max(s.sheen_color, float3(0.0));\n    float _2247 = fast::max(_2238.x, fast::max(_2238.y, _2238.z));\n    if (_2247 > 0.0)\n    {\n        float _2255 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4174 = true;\n        _4175 = _2238;\n        _4176 = _2255;\n        _4177 = _2255 * _2255;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2255;\n        float _2272 = fa_sheen_albedo(param, param_1);\n        _4179 = _2272;\n        _4178 = 1.0 - fast::min(_2247 * _2272, 1.0);\n        _4164 = true;\n    }\n    _4167 = _4166 * _4178;\n    float _2291 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2291 != 0.0)\n    {\n        float3 _2306 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2306;\n        if (dot(_2306, _2306) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2324 = t;\n        float3 _2325 = fast::normalize(_2324);\n        t = _2325;\n        float3 _2350 = fast::normalize((_2325 * cos(s.anisotropy_rotation)) + ((cross(n, _2325) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4181 = _2350;\n        _4182 = cross(n, _2350);\n        float _2360 = roughness * roughness;\n        float _2366 = mix(_2360, 1.0, _2291 * _2291);\n        bool _2368 = _2291 > 0.0;\n        _4183 = _2368 ? _2366 : _2360;\n        _4184 = _2368 ? _2360 : _2366;\n        _4180 = _2291;\n        _4164 = true;\n    }\n    return FaLayers{ short(_4164), _4165, _4166, _4167, _4168, _4169, _4170, _4171, i.world_normal, _4173, short(_4174), _4175, _4176, _4177, _4178, _4179, _4180, _4181, _4182, _4183, _4184 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _511, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_511.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _511.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _511, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _511, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _511)\n{\n    int param = (int(_511.fa_cl_info.x) + int(_511.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _511, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _511);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _385 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _391 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _394 = _391.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _400 = _394 < 0.5;\n    float3 l;\n    if (_400)\n    {\n        l = fast::normalize(_385.xyz);\n    }\n    else\n    {\n        float3 _412 = _385.xyz - world_pos;\n        float _414 = length(_412);\n        dist = _414;\n        l = _412 / float3(fast::max(_414, 9.9999997473787516355514526367188e-05));\n        float _429 = _414 / fast::max(_385.w, 0.001000000047497451305389404296875);\n        float _435 = fast::clamp(1.0 - (_429 * _429), 0.0, 1.0);\n        atten = _435 * _435;\n        if (_394 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _449 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _459 = _449.w;\n            int param_3 = (li * 4) + 3;\n            float4 _465 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _466 = _465.x;\n            float cos_inner = _466;\n            if (_466 > 1.5)\n            {\n                cos_inner = mix(_459, 1.0, 0.25);\n            }\n            atten *= smoothstep(_459, cos_inner, dot(-l, fast::normalize(_449.xyz)));\n        }\n    }\n    int _497;\n    if (_400)\n    {\n        _497 = 0;\n    }\n    else\n    {\n        _497 = (_394 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _391.xyz * atten, atten, 1.0, dist, _497 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _747)\n{\n    float _737;\n    if (i == 0)\n    {\n        _737 = _747.fa_shadow_split.x;\n    }\n    else\n    {\n        float _753;\n        if (i == 1)\n        {\n            _753 = _747.fa_shadow_split.y;\n        }\n        else\n        {\n            float _761;\n            if (i == 2)\n            {\n                _761 = _747.fa_shadow_split.z;\n            }\n            else\n            {\n                _761 = _747.fa_shadow_split.w;\n            }\n            _753 = _761;\n        }\n        _737 = _753;\n    }\n    return _737;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _794 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _798;\n    if (conv.x < 0.5)\n    {\n        _798 = _794;\n    }\n    else\n    {\n        _798 = (conv.y * conv.z) / (conv.z - (_794 * (conv.z - conv.y)));\n    }\n    return _798;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _725 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_725), sin(_725)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _747, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _844 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _858 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _844;\n            float2 _877 = fa_shadow_vogel(param_3, param_4, param_5) * _858;\n            float2 param_6 = uv + (_877 * _747.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _889 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_889 < (zr - (length(_877) * plane)))\n            {\n                sum += _889;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _933 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _933; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _933;\n        float param_11 = _844;\n        float2 _952 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_952 * _747.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_952) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_933);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _747, texture2d<float> fa_shadow_tex)\n{\n    float _994 = fast::max(_747.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _999 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1005 = sqrt(1.0 - (_999 * _999));\n    float _1013 = fast::min(_1005 / fast::max(_999, 0.20000000298023223876953125), 4.0);\n    float _1018;\n    if (_747.fa_shadow_bias.y > 0.0)\n    {\n        _1018 = _747.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1018 = 1.5 * _747.fa_shadow_info[ci].x;\n    }\n    float4 _1043 = _747.fa_shadow_mat[ci] * float4(world + (n * (_1018 * _1005)), 1.0);\n    float _1050 = _1043.x;\n    bool _1053 = _1050 < _747.fa_shadow_rect[ci].x;\n    bool _1062;\n    if (!_1053)\n    {\n        _1062 = _1050 > _747.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1062 = _1053;\n    }\n    bool _1071;\n    if (!_1062)\n    {\n        _1071 = _1043.y < _747.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1071 = _1062;\n    }\n    bool _1080;\n    if (!_1071)\n    {\n        _1080 = _1043.y > _747.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1080 = _1071;\n    }\n    bool _1087;\n    if (!_1080)\n    {\n        _1087 = _1043.z > 1.0;\n    }\n    else\n    {\n        _1087 = _1080;\n    }\n    if (_1087)\n    {\n        return -1.0;\n    }\n    float _1096;\n    if (_747.fa_shadow_bias.x > 0.0)\n    {\n        _1096 = _747.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1096 = 1.5 * _747.fa_shadow_info[ci].x;\n    }\n    float2 param = _1043.xy;\n    float4 param_1 = _747.fa_shadow_rect[ci];\n    float param_2 = _1043.z - ((_1096 * (1.0 + (0.5 * _1013))) / _994);\n    float param_3 = _747.fa_shadow_info[ci].x;\n    float param_4 = _994;\n    float param_5 = _994 * 0.25;\n    float param_6 = ((_747.fa_shadow_info[ci].x * fast::min(_1013, 3.0)) * 0.5) / _994;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_747.fa_shadow_cfg.z + 0.5);\n    float param_9 = _747.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _747, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _511, thread float4& gl_FragCoord, constant fa_shadows& _747, texture2d<float> fa_shadow_tex)\n{\n    if (_511.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1524 = int(_747.fa_shadow_cfg.x + 0.5);\n    if (_1524 < 1)\n    {\n        return 1.0;\n    }\n    float _1540 = dot(world - _747.fa_shadow_eye.xyz, _747.fa_shadow_fwd.xyz);\n    int param = _1524 - 1;\n    if (_1540 > fa_shadow_split_at(param, _747))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1552 = _1524 > 1;\n    bool _1559;\n    if (_1552)\n    {\n        _1559 = _1540 > _747.fa_shadow_split.x;\n    }\n    else\n    {\n        _1559 = _1552;\n    }\n    if (_1559)\n    {\n        ci = 1;\n    }\n    bool _1563 = _1524 > 2;\n    bool _1570;\n    if (_1563)\n    {\n        _1570 = _1540 > _747.fa_shadow_split.y;\n    }\n    else\n    {\n        _1570 = _1563;\n    }\n    if (_1570)\n    {\n        ci = 2;\n    }\n    bool _1574 = _1524 > 3;\n    bool _1581;\n    if (_1574)\n    {\n        _1581 = _1540 > _747.fa_shadow_split.z;\n    }\n    else\n    {\n        _1581 = _1574;\n    }\n    if (_1581)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1524)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1607 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _747, fa_shadow_tex);\n        s = _1607;\n        if (_1607 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_747.fa_shadow_cfg.y > 0.0)\n    {\n        float _1632;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1632 = fa_shadow_split_at(param_5, _747);\n        }\n        else\n        {\n            _1632 = _747.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1651 = _747.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _747) - _1632, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1662 = fast::clamp((_1540 - (fa_shadow_split_at(param_7, _747) - _1651)) / _1651, 0.0, 1.0);\n        if (_1662 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1524)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1683 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _747, fa_shadow_tex);\n                s2 = _1683;\n                if (_1683 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1662);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _511, thread float4& gl_FragCoord, constant fa_shadows& _747, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _511, gl_FragCoord, _747, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _511, thread float4& gl_FragCoord, constant fa_shadows& _747, texture2d<float> fa_shadow_tex)\n{\n    bool _1155 = _511.fa_pbr.z < 0.5;\n    bool _1163;\n    if (!_1155)\n    {\n        _1163 = _747.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1163 = _1155;\n    }\n    if (_1163)\n    {\n        return 1.0;\n    }\n    int param = (int(_747.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1176 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1177 = _1176.x;\n    if (_1177 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1186 = int(_1177 + 0.5);\n    int param_1 = _1186;\n    float4 _1190 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1186 + 1;\n    float4 _1195 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1198 = _1190.y;\n    if (_1198 > 0.0)\n    {\n        float _1215 = 1.0 - smoothstep(0.75 * _1198, _1198, length(world - _747.fa_shadow_eye.xyz));\n        fade = _1215;\n        if (_1215 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1190.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1234 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1237 = abs(_1234);\n        float _1239 = _1237.x;\n        float _1241 = _1237.y;\n        bool _1242 = _1239 >= _1241;\n        bool _1250;\n        if (_1242)\n        {\n            _1250 = _1239 >= _1237.z;\n        }\n        else\n        {\n            _1250 = _1242;\n        }\n        int _1251;\n        if (_1250)\n        {\n            _1251 = (_1234.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1264;\n            if (_1241 >= _1237.z)\n            {\n                _1264 = (_1234.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1264 = (_1234.z > 0.0) ? 4 : 5;\n            }\n            _1251 = _1264;\n        }\n        face = _1251;\n    }\n    int _1283 = (_1186 + 2) + (face * 6);\n    int param_4 = _1283;\n    int param_5 = _1283 + 1;\n    int param_6 = _1283 + 3;\n    float4 _1297 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1283 + 4;\n    float4 _1302 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1283 + 5;\n    float4 _1307 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1319 = _1307.x * fast::max(dot(_1297, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1324 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1347 = fast::clamp(dot(n, _1297.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1370 = fast::min(sqrt(1.0 - (_1347 * _1347)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1297, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1373 = _1195.y;\n    float _1375;\n    if (_1373 > 0.0)\n    {\n        _1375 = _1373;\n    }\n    else\n    {\n        _1375 = 1.5 * _1319;\n    }\n    float4 _1395 = float4(world + (n * (_1375 * sqrt(1.0 - (_1324 * _1324)))), 1.0);\n    float _1399 = dot(_1297, _1395);\n    float _1402 = _1307.y;\n    if (_1399 < _1402)\n    {\n        return 1.0;\n    }\n    float2 _1417 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1395), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1395)) / float2(_1399);\n    float _1419 = _1417.x;\n    bool _1422 = _1419 < _1302.x;\n    bool _1431;\n    if (!_1422)\n    {\n        _1431 = _1419 > _1302.z;\n    }\n    else\n    {\n        _1431 = _1422;\n    }\n    bool _1440;\n    if (!_1431)\n    {\n        _1440 = _1417.y < _1302.y;\n    }\n    else\n    {\n        _1440 = _1431;\n    }\n    bool _1449;\n    if (!_1440)\n    {\n        _1449 = _1417.y > _1302.w;\n    }\n    else\n    {\n        _1449 = _1440;\n    }\n    if (_1449)\n    {\n        return 1.0;\n    }\n    float _1455 = _1195.x;\n    float _1457;\n    if (_1455 > 0.0)\n    {\n        _1457 = _1455;\n    }\n    else\n    {\n        _1457 = 1.5 * _1319;\n    }\n    float2 param_10 = _1417;\n    float4 param_11 = _1302;\n    float param_12 = _1399 - (_1457 * (1.0 + (0.5 * _1370)));\n    float param_13 = _1319;\n    float param_14 = 1.0;\n    float param_15 = _1307.z * 0.25;\n    float param_16 = (_1319 * fast::min(_1370, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1402, _1307.z);\n    int param_18 = int(_1190.z + 0.5);\n    float param_19 = _1190.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _747, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _511, thread float4& gl_FragCoord, constant fa_shadows& _747, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _2902 = fa_lm.z > 0.5;\n    bool _2908;\n    if (_2902)\n    {\n        int param = li;\n        _2908 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2908 = _2902;\n    }\n    if (_2908)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2930 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _4226 = _2930.direction;\n    float3 _4221 = _2930.color;\n    float _4228 = _2930.attenuation;\n    float _4223 = _2930.shadow;\n    int _4231 = _2930.type;\n    if ((_4231 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4226;\n        float _2944 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _511, gl_FragCoord, _747, fa_shadow_tex, fa_world_pos);\n        _4223 = _2944;\n        _4221 *= _2944;\n    }\n    else\n    {\n        bool _2955 = _4231 != 0;\n        bool _2961;\n        if (_2955)\n        {\n            _2961 = _4228 > 0.0;\n        }\n        else\n        {\n            _2961 = _2955;\n        }\n        if (_2961)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4226;\n            float _2973 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _511, gl_FragCoord, _747, fa_shadow_tex);\n            _4223 = _2973;\n            _4221 *= _2973;\n        }\n    }\n    return LightSample{ _4226, _4221, _4228, _4223, _2930._distance, _4231 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _2518 = tdh / at;\n    float _2522 = bdh / ab;\n    float _2534 = ((_2518 * _2518) + (_2522 * _2522)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2534) * _2534);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _2615 = 1.0 / alpha;\n    return ((2.0 + _2615) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2615)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _2648 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2727 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2727) * _2727);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2648);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2648));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2800 = fast::max(dot(L.nc, l), 0.0);\n        float _2806 = fast::max(dot(L.nc, h), 0.0);\n        float _2815 = ((_2806 * _2806) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2815) * _2815)) * (0.5 / fast::max(mix((2.0 * _2800) * L.coat_ndv, _2800 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2800)) * _2800);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1915 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1918 = _1915.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1918 * _1918, exp2((-9.27999973297119140625) * ndv)) * _1918) + _1915.y)) + _1915.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _511, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_511.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _511.fa_env_horizon.w)).xyz;\n    }\n    float _1820 = rough * rough;\n    float _1850 = 0.60000002384185791015625 * _1820;\n    return mix(mix(_511.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_511.fa_env_horizon.xyz, _511.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1820)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1850, 0.0500000007450580596923828125 + _1850, d.y))), ((_511.fa_env_sky.xyz + _511.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1820 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _511, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2401;\n        if (L.aniso >= 0.0)\n        {\n            _2401 = L.b;\n        }\n        else\n        {\n            _2401 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2401, v), _2401), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2434 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _511, fa_env_tex, fa_env_smp) * ((f0 * _2434.x) + (float3(L.f90) * _2434.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _511, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2489 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _511, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _2489.x) + _2489.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _511, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1957 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _511, fa_env_tex, fa_env_smp) * ((f0 * _1957.x) + float3(_1957.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _747)\n{\n    if (_747.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1707 = int(_747.fa_shadow_cfg.x + 0.5);\n    float _1717 = dot(world - _747.fa_shadow_eye.xyz, _747.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1722 = _1707 > 0;\n    bool _1731;\n    if (_1722)\n    {\n        int param = _1707 - 1;\n        _1731 = _1717 <= fa_shadow_split_at(param, _747);\n    }\n    else\n    {\n        _1731 = _1722;\n    }\n    if (_1731)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1738 = _1707 > 1;\n        bool _1745;\n        if (_1738)\n        {\n            _1745 = _1717 > _747.fa_shadow_split.x;\n        }\n        else\n        {\n            _1745 = _1738;\n        }\n        if (_1745)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1751 = _1707 > 2;\n        bool _1758;\n        if (_1751)\n        {\n            _1758 = _1717 > _747.fa_shadow_split.y;\n        }\n        else\n        {\n            _1758 = _1751;\n        }\n        if (_1758)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1764 = _1707 > 3;\n        bool _1771;\n        if (_1764)\n        {\n            _1771 = _1717 > _747.fa_shadow_split.z;\n        }\n        else\n        {\n            _1771 = _1764;\n        }\n        if (_1771)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _511 [[buffer(1)]], constant fa_material& _3393 [[buffer(5)]], constant fa_shadows& _747 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texture2d<float> mask [[texture(6)]], texturecube<float> fa_env_tex [[texture(7)]], texturecube<float> fa_irr_tex [[texture(8)]], texture2d<float> fa_light_tex [[texture(9)]], texture2d<float> fa_lightmap [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler mask_smp [[sampler(2)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3943 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3943 = -_3943;\n    }\n    float3 _3374 = fast::normalize(_511.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _511, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3943, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3374, short(gl_FrontFacing) };\n    Surface _3382 = fa_standard_surface(param_1, _511, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3974 = _3382.albedo;\n    float _3975 = _3382.alpha;\n    float3 _3976 = _3382.normal;\n    float _3977 = _3382.metallic;\n    float _3978 = _3382.roughness;\n    float _3979 = _3382.occlusion;\n    float3 _3980 = _3382.emission;\n    float _3981 = _3382.clearcoat;\n    float _3982 = _3382.clearcoat_roughness;\n    float3 _3983 = _3382.sheen_color;\n    float _3984 = _3382.sheen_roughness;\n    float _3985 = _3382.anisotropy;\n    float _3986 = _3382.anisotropy_rotation;\n    float _3987 = _3382.specular;\n    float _3988 = _3382.ior;\n    float3 _3989 = _3382.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3943, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3374, short(gl_FrontFacing) };\n    Surface param_3 = _3382;\n    surface(param_2, param_3, mask, mask_smp);\n    _3974 = param_3.albedo;\n    _3975 = param_3.alpha;\n    _3976 = param_3.normal;\n    _3977 = param_3.metallic;\n    _3978 = param_3.roughness;\n    _3979 = param_3.occlusion;\n    _3980 = param_3.emission;\n    _3981 = param_3.clearcoat;\n    _3982 = param_3.clearcoat_roughness;\n    _3983 = param_3.sheen_color;\n    _3984 = param_3.sheen_roughness;\n    _3985 = param_3.anisotropy;\n    _3986 = param_3.anisotropy_rotation;\n    _3987 = param_3.specular;\n    _3988 = param_3.ior;\n    _3989 = param_3.specular_color;\n    if (param_3.alpha < _3393.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    float3 result;\n    if (_511.fa_emissive.w > 0.5)\n    {\n        result = _3974;\n    }\n    else\n    {\n        float3 _3415 = fast::normalize(_3976);\n        float _3422 = fast::clamp(_3977, 0.0, 1.0);\n        float _3426 = fast::clamp(_3978, 0.0500000007450580596923828125, 1.0);\n        float _3430 = _3426 * _3426;\n        float _3434 = _3430 * _3430;\n        float _3439 = fast::max(dot(_3415, _3374), 9.9999997473787516355514526367188e-05);\n        float3 _3445 = _3974 * (1.0 - _3422);\n        float3 _3452 = mix(float3(0.039999999105930328369140625), _3974, float3(_3422));\n        float3 f0 = _3452;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _3943, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3374, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _3974, _3975, _3976, _3977, _3978, _3979, _3980, _3981, _3982, _3983, _3984, _3985, _3986, _3987, _3988, _3989 };\n        float3 param_6 = _3415;\n        float3 param_7 = _3374;\n        float param_8 = _3422;\n        float param_9 = _3426;\n        float3 param_10 = _3452;\n        FaLayers _3468 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _3415;\n        float3 lit = (fa_indirect_diffuse(param_11, _511, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap) * _3445) * _3979;\n        if (_3468.on)\n        {\n            lit *= _3468.base_scale;\n        }\n        int _3490 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3490; ln++)\n        {\n            int param_12 = ln;\n            int _3503 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _511, fa_cl_ndir, fa_cl_slot);\n            bool _3506 = in.fa_lm.z > 0.5;\n            bool _3512;\n            if (_3506)\n            {\n                int param_13 = _3503;\n                _3512 = fa_light_baked(param_13, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _3512 = _3506;\n            }\n            if (_3512)\n            {\n                continue;\n            }\n            int param_14 = _3503;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _3943;\n            LightSample _3524 = fa_light_shadowed(param_14, param_15, param_16, fa_light_tex, fa_shadow_smp, _511, gl_FragCoord, _747, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            float3 _4148 = _3524.direction;\n            float _3532 = fast::max(dot(_3415, _4148), 0.0);\n            float _3538 = _3524.attenuation * _3524.shadow;\n            float3 _3543 = fast::normalize(_4148 + _3374);\n            float _3548 = fast::max(dot(_3415, _3543), 0.0);\n            float _3553 = fast::max(dot(_3374, _3543), 0.0);\n            if (_3468.on)\n            {\n                FaLayers param_17 = _3468;\n                float3 param_18 = _3445;\n                float3 param_19 = f0;\n                float3 param_20 = _3415;\n                float3 param_21 = _3374;\n                float3 param_22 = _4148;\n                float3 param_23 = _3543;\n                float param_24 = _3532;\n                float param_25 = _3439;\n                float param_26 = _3548;\n                float param_27 = _3553;\n                float param_28 = _3430;\n                float param_29 = _3434;\n                int param_30 = _3503;\n                lit += (fa_layers_light(param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29) * (fa_light_rgb(param_30, fa_light_tex, fa_shadow_smp) * _3538));\n            }\n            else\n            {\n                float _3601 = ((_3548 * _3548) * (_3434 - 1.0)) + 1.0;\n                int param_31 = _3503;\n                lit += (((_3445 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _3553, 5.0))) * (((_3434 / ((3.1415927410125732421875 * _3601) * _3601)) * (0.5 / fast::max(mix((2.0 * _3532) * _3439, _3532 + _3439, _3430), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3532))) * fa_light_rgb(param_31, fa_light_tex, fa_shadow_smp)) * (_3532 * _3538));\n            }\n        }\n        if (_3468.on)\n        {\n            FaLayers param_32 = _3468;\n            float3 param_33 = _3415;\n            float3 param_34 = _3374;\n            float3 param_35 = f0;\n            float param_36 = _3426;\n            lit += (fa_layers_ibl(param_32, param_33, param_34, param_35, param_36, _511, fa_env_tex, fa_env_smp) * _3979);\n        }\n        else\n        {\n            float3 param_37 = _3415;\n            float3 param_38 = _3374;\n            float3 param_39 = f0;\n            float param_40 = _3426;\n            lit += (fa_sky_reflection(param_37, param_38, param_39, param_40, _511, fa_env_tex, fa_env_smp) * _3979);\n        }\n        result = lit;\n    }\n    float3 _3694 = result;\n    float3 _3695 = _3694 + _3980;\n    result = _3695;\n    float3 param_41 = _3695;\n    float3 param_42 = in.fa_world_pos;\n    result = fa_shadow_debug(param_41, param_42, _747);\n    bool _3704 = _511.fa_fog.w > 0.0;\n    bool _3711;\n    if (!_3704)\n    {\n        _3711 = _511.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3711 = _3704;\n    }\n    if (_3711)\n    {\n        float3 _3720 = in.fa_world_pos - _511.fa_camera_pos.xyz;\n        float _3726 = dot(_3720, _511.fa_fog_c.xyz);\n        bool _3730 = _511.fa_fog_c.w > 0.5;\n        float _3731;\n        if (_3730)\n        {\n            _3731 = _3726;\n        }\n        else\n        {\n            _3731 = length(_3720);\n        }\n        float _3743 = _3731 - _511.fa_fog_b.x;\n        if (_3743 > 0.0)\n        {\n            float _3752 = _511.fa_fog.w * _3743;\n            float tau = _3752 * _3752;\n            if (_511.fa_fog_b.y > 0.0)\n            {\n                float _3768;\n                if (_3730)\n                {\n                    _3768 = in.fa_world_pos.y - (_511.fa_fog_c.y * _3726);\n                }\n                else\n                {\n                    _3768 = _511.fa_camera_pos.y;\n                }\n                float _3789 = mix(_3768, in.fa_world_pos.y, fast::clamp(_511.fa_fog_b.x / _3731, 0.0, 1.0));\n                float _3793 = in.fa_world_pos.y - _3789;\n                float _3798 = _3789 - _511.fa_fog_b.z;\n                float _3803 = in.fa_world_pos.y - _511.fa_fog_b.z;\n                bool _3806 = _3798 <= 0.0;\n                bool _3807 = !_3806;\n                bool _3813;\n                if (_3807)\n                {\n                    _3813 = _511.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3813 = _3806;\n                }\n                float _3814;\n                if (_3813)\n                {\n                    _3814 = _511.fa_fog_b.y;\n                }\n                else\n                {\n                    _3814 = _511.fa_fog_b.y * exp(-fast::min(_511.fa_fog_b.w * _3798, 80.0));\n                }\n                bool _3841;\n                if (_3807)\n                {\n                    _3841 = _511.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3841 = _3806;\n                }\n                float _3842;\n                if (_3841)\n                {\n                    _3842 = _511.fa_fog_b.y * _3798;\n                }\n                else\n                {\n                    _3842 = (_511.fa_fog_b.y * (1.0 - exp(-fast::min(_511.fa_fog_b.w * _3798, 80.0)))) / _511.fa_fog_b.w;\n                }\n                bool _3867 = _3803 <= 0.0;\n                bool _3874;\n                if (!_3867)\n                {\n                    _3874 = _511.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3874 = _3867;\n                }\n                float _3875;\n                if (_3874)\n                {\n                    _3875 = _511.fa_fog_b.y * _3803;\n                }\n                else\n                {\n                    _3875 = (_511.fa_fog_b.y * (1.0 - exp(-fast::min(_511.fa_fog_b.w * _3803, 80.0)))) / _511.fa_fog_b.w;\n                }\n                float _3902;\n                if (abs(_3793) < 0.001000000047497451305389404296875)\n                {\n                    _3902 = _3814;\n                }\n                else\n                {\n                    _3902 = (_3875 - _3842) / _3793;\n                }\n                tau += (_3743 * fast::max(_3902, 0.0));\n            }\n            result = mix(result, _511.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3975);\n    return out;\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_511",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_747",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3393",
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
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 6
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
              "msl_texture_n": 7
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
              "msl_texture_n": 8
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
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 10,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _397 = _273.world_pos;\n    fa_world_pos = _397;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_397, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nconstant spvUnsafeArray<float, 63> _2058 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _511)\n{\n    bool _516 = _511.fa_cl_info.x < 0.0;\n    bool _523;\n    if (!_516)\n    {\n        _523 = _511.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _523 = _516;\n    }\n    bool _531;\n    if (!_523)\n    {\n        _531 = _511.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _531 = _523;\n    }\n    bool _538;\n    if (!_531)\n    {\n        _538 = _511.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _538 = _531;\n    }\n    bool _545;\n    if (!_538)\n    {\n        _545 = _511.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _545 = _538;\n    }\n    if (_545)\n    {\n        return int2(0);\n    }\n    float4 _555 = float4(world_pos, 1.0);\n    float _562 = dot(_511.fa_cl_vpw, _555);\n    if (!(_562 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _584 = float2(dot(_511.fa_cl_vpx, _555), dot(_511.fa_cl_vpy, _555)) / float2(_562);\n    int _588 = int(_511.fa_cl_grid.x);\n    int _592 = int(_511.fa_cl_grid.y);\n    int param = (int(_511.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_511.fa_cl_fwd.xyz, world_pos) + _511.fa_cl_fwd.w, _511.fa_cl_grid.w) / _511.fa_cl_grid.w) * _511.fa_cl_grid.z)), 0, int(_511.fa_cl_info.y) - 1) * _592) + clamp(int(floor(((_584.y * 0.5) + 0.5) * _511.fa_cl_grid.y)), 0, _592 - 1)) * _588)) + clamp(int(floor(((_584.x * 0.5) + 0.5) * _511.fa_cl_grid.x)), 0, _588 - 1);\n    float4 _663 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_663.x), int(_663.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _511, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_511.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2875 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _511);\n    fa_cl_slot = _2875.x;\n    fa_cl_local = _2875.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3042 = fa_linear_to_srgb(param);\n        c = _3042;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3050 = fa_srgb_to_linear(param_1);\n            c = _3050;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _266;\n    if (bool(i.front_facing))\n    {\n        _266 = i.world_normal;\n    }\n    else\n    {\n        _266 = -i.world_normal;\n    }\n    float3 _290 = fast::normalize(i.world_tangent.xyz - (_266 * dot(_266, i.world_tangent.xyz)));\n    float3 _318 = fast::normalize(((_290 * m.x) + ((cross(_266, _290) * i.world_tangent.w) * m.y)) + (_266 * m.z));\n    float3 _321;\n    if (bool(i.front_facing))\n    {\n        _321 = _318;\n    }\n    else\n    {\n        _321 = -_318;\n    }\n    return _321;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _511, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _511.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3081 = fa_tex_fix(param_2, param_3);\n    float4 _4339 = base_t;\n    _4339.x = _3081.x;\n    _4339.y = _3081.y;\n    _4339.z = _3081.z;\n    base_t = _4339;\n    float4 _3095 = (_4339 * _511.fa_base_color) * i.vertex_color;\n    float3 _4241 = i.world_normal;\n    if (_511.fa_maps.z > 0.5)\n    {\n        float param_4 = _511.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3127 = fa_tex_fix(param_6, param_7);\n        float3 _3130 = (_3127 * 2.0) - float3(1.0);\n        float2 _3135 = _3130.xy * _511.fa_maps.x;\n        float3 _4347 = _3130;\n        _4347.x = _3135.x;\n        _4347.y = _3135.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4347;\n        _4241 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _511.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3164 = fa_tex_fix(param_12, param_13);\n    float4 _4350 = mrt;\n    _4350.x = _3164.x;\n    _4350.y = _3164.y;\n    _4350.z = _3164.z;\n    mrt = _4350;\n    float4 _3192 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _511.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3192.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3204 = fa_tex_fix(param_16, param_17);\n    float param_18 = _511.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3234 = fa_tex_fix(param_20, param_21);\n    float _4246 = _511.fa_layers_a.x;\n    float _4247 = _511.fa_layers_a.y;\n    float _4250 = _511.fa_layers_a.z;\n    float _4249 = _511.fa_layers_b.w;\n    float _4252 = _511.fa_layers_c.x;\n    if (_511.fa_layers_c.z > 0.5)\n    {\n        if (mod(_511.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4246 *= _3204.y;\n            _4247 *= _3204.z;\n            _4249 *= _3192.w;\n        }\n        if (_511.fa_layers_c.z > 1.5)\n        {\n            _4250 *= mrt.x;\n            _4252 *= mrt.w;\n        }\n    }\n    return Surface{ _3095.xyz, _3095.w, _4241, fast::clamp(_511.fa_pbr.x * _3164.z, 0.0, 1.0), fast::clamp(_511.fa_pbr.y * _3164.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_511.fa_maps.y * (_3204.x - 1.0)), _511.fa_emissive.xyz + (_511.fa_model_emissive.xyz * _3234), _4246, _4247, _511.fa_layers_b.xyz, _4249, _4250, _511.fa_layers_a.w, _4252, _511.fa_layers_c.y, _511.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1983 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1991 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1994 = int(_1983);\n    int _1997 = int(_1991);\n    float _2007 = _1991 - float(_1997);\n    int _2063 = (_1994 * 9) + _1997;\n    int _2083 = ((_1994 + 1) * 9) + _1997;\n    return mix(mix(_2058[_2063], _2058[_2063 + 1], _2007), mix(_2058[_2083], _2058[_2083 + 1], _2007), _1983 - float(_1994));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4164 = false;\n    float _4165 = 1.0;\n    float _4166 = 1.0;\n    float _4167 = 1.0;\n    float _4168 = 0.0;\n    float _4169 = 0.0;\n    float _4170 = 0.0;\n    float _4171 = 0.0;\n    float _4173 = 1.0;\n    bool _4174 = false;\n    float3 _4175 = float3(0.0);\n    float _4176 = 1.0;\n    float _4177 = 1.0;\n    float _4178 = 1.0;\n    float _4179 = 0.0;\n    float _4180 = 0.0;\n    float3 _4181 = float3(1.0, 0.0, 0.0);\n    float3 _4182 = float3(0.0, 0.0, 1.0);\n    float _4183 = 1.0;\n    float _4184 = 1.0;\n    float _2136 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2140 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2145 = (_2136 != 1.0) || (_2140 != 1.5);\n    bool _2155;\n    if (!_2145)\n    {\n        _2155 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2155 = _2145;\n    }\n    if (_2155)\n    {\n        float _2163 = (_2140 - 1.0) / (_2140 + 1.0);\n        f0 = mix(fast::min(float3(_2163 * _2163) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2136, s.albedo, float3(metallic));\n        _4165 = mix(_2136, 1.0, metallic);\n        _4164 = true;\n    }\n    float _2191 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2191 > 0.0)\n    {\n        float _2199 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4168 = _2191;\n        _4169 = _2199;\n        float _2206 = _2199 * _2199;\n        _4170 = _2206;\n        _4171 = _2206 * _2206;\n        float _2218 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4173 = _2218;\n        _4166 = 1.0 - (_2191 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2218, 0.0, 1.0), 5.0))));\n        _4164 = true;\n    }\n    float3 _2238 = fast::max(s.sheen_color, float3(0.0));\n    float _2247 = fast::max(_2238.x, fast::max(_2238.y, _2238.z));\n    if (_2247 > 0.0)\n    {\n        float _2255 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4174 = true;\n        _4175 = _2238;\n        _4176 = _2255;\n        _4177 = _2255 * _2255;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2255;\n        float _2272 = fa_sheen_albedo(param, param_1);\n        _4179 = _2272;\n        _4178 = 1.0 - fast::min(_2247 * _2272, 1.0);\n        _4164 = true;\n    }\n    _4167 = _4166 * _4178;\n    float _2291 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2291 != 0.0)\n    {\n        float3 _2306 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2306;\n        if (dot(_2306, _2306) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2324 = t;\n        float3 _2325 = fast::normalize(_2324);\n        t = _2325;\n        float3 _2350 = fast::normalize((_2325 * cos(s.anisotropy_rotation)) + ((cross(n, _2325) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4181 = _2350;\n        _4182 = cross(n, _2350);\n        float _2360 = roughness * roughness;\n        float _2366 = mix(_2360, 1.0, _2291 * _2291);\n        bool _2368 = _2291 > 0.0;\n        _4183 = _2368 ? _2366 : _2360;\n        _4184 = _2368 ? _2360 : _2366;\n        _4180 = _2291;\n        _4164 = true;\n    }\n    return FaLayers{ short(_4164), _4165, _4166, _4167, _4168, _4169, _4170, _4171, i.world_normal, _4173, short(_4174), _4175, _4176, _4177, _4178, _4179, _4180, _4181, _4182, _4183, _4184 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _511, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_511.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _511.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _511, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _511, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _511)\n{\n    int param = (int(_511.fa_cl_info.x) + int(_511.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _511, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _511);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _385 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _391 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _394 = _391.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _400 = _394 < 0.5;\n    float3 l;\n    if (_400)\n    {\n        l = fast::normalize(_385.xyz);\n    }\n    else\n    {\n        float3 _412 = _385.xyz - world_pos;\n        float _414 = length(_412);\n        dist = _414;\n        l = _412 / float3(fast::max(_414, 9.9999997473787516355514526367188e-05));\n        float _429 = _414 / fast::max(_385.w, 0.001000000047497451305389404296875);\n        float _435 = fast::clamp(1.0 - (_429 * _429), 0.0, 1.0);\n        atten = _435 * _435;\n        if (_394 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _449 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _459 = _449.w;\n            int param_3 = (li * 4) + 3;\n            float4 _465 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _466 = _465.x;\n            float cos_inner = _466;\n            if (_466 > 1.5)\n            {\n                cos_inner = mix(_459, 1.0, 0.25);\n            }\n            atten *= smoothstep(_459, cos_inner, dot(-l, fast::normalize(_449.xyz)));\n        }\n    }\n    int _497;\n    if (_400)\n    {\n        _497 = 0;\n    }\n    else\n    {\n        _497 = (_394 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _391.xyz * atten, atten, 1.0, dist, _497 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _747)\n{\n    float _737;\n    if (i == 0)\n    {\n        _737 = _747.fa_shadow_split.x;\n    }\n    else\n    {\n        float _753;\n        if (i == 1)\n        {\n            _753 = _747.fa_shadow_split.y;\n        }\n        else\n        {\n            float _761;\n            if (i == 2)\n            {\n                _761 = _747.fa_shadow_split.z;\n            }\n            else\n            {\n                _761 = _747.fa_shadow_split.w;\n            }\n            _753 = _761;\n        }\n        _737 = _753;\n    }\n    return _737;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _794 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _798;\n    if (conv.x < 0.5)\n    {\n        _798 = _794;\n    }\n    else\n    {\n        _798 = (conv.y * conv.z) / (conv.z - (_794 * (conv.z - conv.y)));\n    }\n    return _798;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _725 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_725), sin(_725)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _747, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _844 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _858 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _844;\n            float2 _877 = fa_shadow_vogel(param_3, param_4, param_5) * _858;\n            float2 param_6 = uv + (_877 * _747.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _889 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_889 < (zr - (length(_877) * plane)))\n            {\n                sum += _889;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _933 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _933; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _933;\n        float param_11 = _844;\n        float2 _952 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_952 * _747.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_952) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_933);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _747, texture2d<float> fa_shadow_tex)\n{\n    float _994 = fast::max(_747.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _999 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1005 = sqrt(1.0 - (_999 * _999));\n    float _1013 = fast::min(_1005 / fast::max(_999, 0.20000000298023223876953125), 4.0);\n    float _1018;\n    if (_747.fa_shadow_bias.y > 0.0)\n    {\n        _1018 = _747.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1018 = 1.5 * _747.fa_shadow_info[ci].x;\n    }\n    float4 _1043 = _747.fa_shadow_mat[ci] * float4(world + (n * (_1018 * _1005)), 1.0);\n    float _1050 = _1043.x;\n    bool _1053 = _1050 < _747.fa_shadow_rect[ci].x;\n    bool _1062;\n    if (!_1053)\n    {\n        _1062 = _1050 > _747.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1062 = _1053;\n    }\n    bool _1071;\n    if (!_1062)\n    {\n        _1071 = _1043.y < _747.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1071 = _1062;\n    }\n    bool _1080;\n    if (!_1071)\n    {\n        _1080 = _1043.y > _747.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1080 = _1071;\n    }\n    bool _1087;\n    if (!_1080)\n    {\n        _1087 = _1043.z > 1.0;\n    }\n    else\n    {\n        _1087 = _1080;\n    }\n    if (_1087)\n    {\n        return -1.0;\n    }\n    float _1096;\n    if (_747.fa_shadow_bias.x > 0.0)\n    {\n        _1096 = _747.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1096 = 1.5 * _747.fa_shadow_info[ci].x;\n    }\n    float2 param = _1043.xy;\n    float4 param_1 = _747.fa_shadow_rect[ci];\n    float param_2 = _1043.z - ((_1096 * (1.0 + (0.5 * _1013))) / _994);\n    float param_3 = _747.fa_shadow_info[ci].x;\n    float param_4 = _994;\n    float param_5 = _994 * 0.25;\n    float param_6 = ((_747.fa_shadow_info[ci].x * fast::min(_1013, 3.0)) * 0.5) / _994;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_747.fa_shadow_cfg.z + 0.5);\n    float param_9 = _747.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _747, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _511, thread float4& gl_FragCoord, constant fa_shadows& _747, texture2d<float> fa_shadow_tex)\n{\n    if (_511.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1524 = int(_747.fa_shadow_cfg.x + 0.5);\n    if (_1524 < 1)\n    {\n        return 1.0;\n    }\n    float _1540 = dot(world - _747.fa_shadow_eye.xyz, _747.fa_shadow_fwd.xyz);\n    int param = _1524 - 1;\n    if (_1540 > fa_shadow_split_at(param, _747))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1552 = _1524 > 1;\n    bool _1559;\n    if (_1552)\n    {\n        _1559 = _1540 > _747.fa_shadow_split.x;\n    }\n    else\n    {\n        _1559 = _1552;\n    }\n    if (_1559)\n    {\n        ci = 1;\n    }\n    bool _1563 = _1524 > 2;\n    bool _1570;\n    if (_1563)\n    {\n        _1570 = _1540 > _747.fa_shadow_split.y;\n    }\n    else\n    {\n        _1570 = _1563;\n    }\n    if (_1570)\n    {\n        ci = 2;\n    }\n    bool _1574 = _1524 > 3;\n    bool _1581;\n    if (_1574)\n    {\n        _1581 = _1540 > _747.fa_shadow_split.z;\n    }\n    else\n    {\n        _1581 = _1574;\n    }\n    if (_1581)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1524)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1607 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _747, fa_shadow_tex);\n        s = _1607;\n        if (_1607 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_747.fa_shadow_cfg.y > 0.0)\n    {\n        float _1632;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1632 = fa_shadow_split_at(param_5, _747);\n        }\n        else\n        {\n            _1632 = _747.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1651 = _747.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _747) - _1632, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1662 = fast::clamp((_1540 - (fa_shadow_split_at(param_7, _747) - _1651)) / _1651, 0.0, 1.0);\n        if (_1662 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1524)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1683 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _747, fa_shadow_tex);\n                s2 = _1683;\n                if (_1683 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1662);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _511, thread float4& gl_FragCoord, constant fa_shadows& _747, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _511, gl_FragCoord, _747, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _511, thread float4& gl_FragCoord, constant fa_shadows& _747, texture2d<float> fa_shadow_tex)\n{\n    bool _1155 = _511.fa_pbr.z < 0.5;\n    bool _1163;\n    if (!_1155)\n    {\n        _1163 = _747.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1163 = _1155;\n    }\n    if (_1163)\n    {\n        return 1.0;\n    }\n    int param = (int(_747.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1176 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1177 = _1176.x;\n    if (_1177 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1186 = int(_1177 + 0.5);\n    int param_1 = _1186;\n    float4 _1190 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1186 + 1;\n    float4 _1195 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1198 = _1190.y;\n    if (_1198 > 0.0)\n    {\n        float _1215 = 1.0 - smoothstep(0.75 * _1198, _1198, length(world - _747.fa_shadow_eye.xyz));\n        fade = _1215;\n        if (_1215 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1190.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1234 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1237 = abs(_1234);\n        float _1239 = _1237.x;\n        float _1241 = _1237.y;\n        bool _1242 = _1239 >= _1241;\n        bool _1250;\n        if (_1242)\n        {\n            _1250 = _1239 >= _1237.z;\n        }\n        else\n        {\n            _1250 = _1242;\n        }\n        int _1251;\n        if (_1250)\n        {\n            _1251 = (_1234.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1264;\n            if (_1241 >= _1237.z)\n            {\n                _1264 = (_1234.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1264 = (_1234.z > 0.0) ? 4 : 5;\n            }\n            _1251 = _1264;\n        }\n        face = _1251;\n    }\n    int _1283 = (_1186 + 2) + (face * 6);\n    int param_4 = _1283;\n    int param_5 = _1283 + 1;\n    int param_6 = _1283 + 3;\n    float4 _1297 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1283 + 4;\n    float4 _1302 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1283 + 5;\n    float4 _1307 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1319 = _1307.x * fast::max(dot(_1297, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1324 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1347 = fast::clamp(dot(n, _1297.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1370 = fast::min(sqrt(1.0 - (_1347 * _1347)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1297, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1373 = _1195.y;\n    float _1375;\n    if (_1373 > 0.0)\n    {\n        _1375 = _1373;\n    }\n    else\n    {\n        _1375 = 1.5 * _1319;\n    }\n    float4 _1395 = float4(world + (n * (_1375 * sqrt(1.0 - (_1324 * _1324)))), 1.0);\n    float _1399 = dot(_1297, _1395);\n    float _1402 = _1307.y;\n    if (_1399 < _1402)\n    {\n        return 1.0;\n    }\n    float2 _1417 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1395), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1395)) / float2(_1399);\n    float _1419 = _1417.x;\n    bool _1422 = _1419 < _1302.x;\n    bool _1431;\n    if (!_1422)\n    {\n        _1431 = _1419 > _1302.z;\n    }\n    else\n    {\n        _1431 = _1422;\n    }\n    bool _1440;\n    if (!_1431)\n    {\n        _1440 = _1417.y < _1302.y;\n    }\n    else\n    {\n        _1440 = _1431;\n    }\n    bool _1449;\n    if (!_1440)\n    {\n        _1449 = _1417.y > _1302.w;\n    }\n    else\n    {\n        _1449 = _1440;\n    }\n    if (_1449)\n    {\n        return 1.0;\n    }\n    float _1455 = _1195.x;\n    float _1457;\n    if (_1455 > 0.0)\n    {\n        _1457 = _1455;\n    }\n    else\n    {\n        _1457 = 1.5 * _1319;\n    }\n    float2 param_10 = _1417;\n    float4 param_11 = _1302;\n    float param_12 = _1399 - (_1457 * (1.0 + (0.5 * _1370)));\n    float param_13 = _1319;\n    float param_14 = 1.0;\n    float param_15 = _1307.z * 0.25;\n    float param_16 = (_1319 * fast::min(_1370, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1402, _1307.z);\n    int param_18 = int(_1190.z + 0.5);\n    float param_19 = _1190.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _747, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _511, thread float4& gl_FragCoord, constant fa_shadows& _747, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _2902 = fa_lm.z > 0.5;\n    bool _2908;\n    if (_2902)\n    {\n        int param = li;\n        _2908 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _2908 = _2902;\n    }\n    if (_2908)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2930 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _4226 = _2930.direction;\n    float3 _4221 = _2930.color;\n    float _4228 = _2930.attenuation;\n    float _4223 = _2930.shadow;\n    int _4231 = _2930.type;\n    if ((_4231 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4226;\n        float _2944 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _511, gl_FragCoord, _747, fa_shadow_tex, fa_world_pos);\n        _4223 = _2944;\n        _4221 *= _2944;\n    }\n    else\n    {\n        bool _2955 = _4231 != 0;\n        bool _2961;\n        if (_2955)\n        {\n            _2961 = _4228 > 0.0;\n        }\n        else\n        {\n            _2961 = _2955;\n        }\n        if (_2961)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4226;\n            float _2973 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _511, gl_FragCoord, _747, fa_shadow_tex);\n            _4223 = _2973;\n            _4221 *= _2973;\n        }\n    }\n    return LightSample{ _4226, _4221, _4228, _4223, _2930._distance, _4231 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _2518 = tdh / at;\n    float _2522 = bdh / ab;\n    float _2534 = ((_2518 * _2518) + (_2522 * _2522)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2534) * _2534);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _2615 = 1.0 / alpha;\n    return ((2.0 + _2615) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2615)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _2648 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2727 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2727) * _2727);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2648);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2648));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2800 = fast::max(dot(L.nc, l), 0.0);\n        float _2806 = fast::max(dot(L.nc, h), 0.0);\n        float _2815 = ((_2806 * _2806) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2815) * _2815)) * (0.5 / fast::max(mix((2.0 * _2800) * L.coat_ndv, _2800 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2800)) * _2800);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1915 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1918 = _1915.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1918 * _1918, exp2((-9.27999973297119140625) * ndv)) * _1918) + _1915.y)) + _1915.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _511, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_511.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _511.fa_env_horizon.w)).xyz;\n    }\n    float _1820 = rough * rough;\n    float _1850 = 0.60000002384185791015625 * _1820;\n    return mix(mix(_511.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_511.fa_env_horizon.xyz, _511.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1820)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1850, 0.0500000007450580596923828125 + _1850, d.y))), ((_511.fa_env_sky.xyz + _511.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1820 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _511, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2401;\n        if (L.aniso >= 0.0)\n        {\n            _2401 = L.b;\n        }\n        else\n        {\n            _2401 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2401, v), _2401), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2434 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _511, fa_env_tex, fa_env_smp) * ((f0 * _2434.x) + (float3(L.f90) * _2434.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _511, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2489 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _511, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _2489.x) + _2489.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _511, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1957 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _511, fa_env_tex, fa_env_smp) * ((f0 * _1957.x) + float3(_1957.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _747)\n{\n    if (_747.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1707 = int(_747.fa_shadow_cfg.x + 0.5);\n    float _1717 = dot(world - _747.fa_shadow_eye.xyz, _747.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1722 = _1707 > 0;\n    bool _1731;\n    if (_1722)\n    {\n        int param = _1707 - 1;\n        _1731 = _1717 <= fa_shadow_split_at(param, _747);\n    }\n    else\n    {\n        _1731 = _1722;\n    }\n    if (_1731)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1738 = _1707 > 1;\n        bool _1745;\n        if (_1738)\n        {\n            _1745 = _1717 > _747.fa_shadow_split.x;\n        }\n        else\n        {\n            _1745 = _1738;\n        }\n        if (_1745)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1751 = _1707 > 2;\n        bool _1758;\n        if (_1751)\n        {\n            _1758 = _1717 > _747.fa_shadow_split.y;\n        }\n        else\n        {\n            _1758 = _1751;\n        }\n        if (_1758)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1764 = _1707 > 3;\n        bool _1771;\n        if (_1764)\n        {\n            _1771 = _1717 > _747.fa_shadow_split.z;\n        }\n        else\n        {\n            _1771 = _1764;\n        }\n        if (_1771)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _511 [[buffer(1)]], constant fa_material& _3393 [[buffer(5)]], constant fa_shadows& _747 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texture2d<float> mask [[texture(6)]], texturecube<float> fa_env_tex [[texture(7)]], texturecube<float> fa_irr_tex [[texture(8)]], texture2d<float> fa_light_tex [[texture(9)]], texture2d<float> fa_lightmap [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler mask_smp [[sampler(2)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3943 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3943 = -_3943;\n    }\n    float3 _3374 = fast::normalize(_511.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _511, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3943, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3374, short(gl_FrontFacing) };\n    Surface _3382 = fa_standard_surface(param_1, _511, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3974 = _3382.albedo;\n    float _3975 = _3382.alpha;\n    float3 _3976 = _3382.normal;\n    float _3977 = _3382.metallic;\n    float _3978 = _3382.roughness;\n    float _3979 = _3382.occlusion;\n    float3 _3980 = _3382.emission;\n    float _3981 = _3382.clearcoat;\n    float _3982 = _3382.clearcoat_roughness;\n    float3 _3983 = _3382.sheen_color;\n    float _3984 = _3382.sheen_roughness;\n    float _3985 = _3382.anisotropy;\n    float _3986 = _3382.anisotropy_rotation;\n    float _3987 = _3382.specular;\n    float _3988 = _3382.ior;\n    float3 _3989 = _3382.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3943, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3374, short(gl_FrontFacing) };\n    Surface param_3 = _3382;\n    surface(param_2, param_3, mask, mask_smp);\n    _3974 = param_3.albedo;\n    _3975 = param_3.alpha;\n    _3976 = param_3.normal;\n    _3977 = param_3.metallic;\n    _3978 = param_3.roughness;\n    _3979 = param_3.occlusion;\n    _3980 = param_3.emission;\n    _3981 = param_3.clearcoat;\n    _3982 = param_3.clearcoat_roughness;\n    _3983 = param_3.sheen_color;\n    _3984 = param_3.sheen_roughness;\n    _3985 = param_3.anisotropy;\n    _3986 = param_3.anisotropy_rotation;\n    _3987 = param_3.specular;\n    _3988 = param_3.ior;\n    _3989 = param_3.specular_color;\n    if (param_3.alpha < _3393.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    float3 result;\n    if (_511.fa_emissive.w > 0.5)\n    {\n        result = _3974;\n    }\n    else\n    {\n        float3 _3415 = fast::normalize(_3976);\n        float _3422 = fast::clamp(_3977, 0.0, 1.0);\n        float _3426 = fast::clamp(_3978, 0.0500000007450580596923828125, 1.0);\n        float _3430 = _3426 * _3426;\n        float _3434 = _3430 * _3430;\n        float _3439 = fast::max(dot(_3415, _3374), 9.9999997473787516355514526367188e-05);\n        float3 _3445 = _3974 * (1.0 - _3422);\n        float3 _3452 = mix(float3(0.039999999105930328369140625), _3974, float3(_3422));\n        float3 f0 = _3452;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _3943, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3374, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _3974, _3975, _3976, _3977, _3978, _3979, _3980, _3981, _3982, _3983, _3984, _3985, _3986, _3987, _3988, _3989 };\n        float3 param_6 = _3415;\n        float3 param_7 = _3374;\n        float param_8 = _3422;\n        float param_9 = _3426;\n        float3 param_10 = _3452;\n        FaLayers _3468 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _3415;\n        float3 lit = (fa_indirect_diffuse(param_11, _511, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap) * _3445) * _3979;\n        if (_3468.on)\n        {\n            lit *= _3468.base_scale;\n        }\n        int _3490 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3490; ln++)\n        {\n            int param_12 = ln;\n            int _3503 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _511, fa_cl_ndir, fa_cl_slot);\n            bool _3506 = in.fa_lm.z > 0.5;\n            bool _3512;\n            if (_3506)\n            {\n                int param_13 = _3503;\n                _3512 = fa_light_baked(param_13, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _3512 = _3506;\n            }\n            if (_3512)\n            {\n                continue;\n            }\n            int param_14 = _3503;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _3943;\n            LightSample _3524 = fa_light_shadowed(param_14, param_15, param_16, fa_light_tex, fa_shadow_smp, _511, gl_FragCoord, _747, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            float3 _4148 = _3524.direction;\n            float _3532 = fast::max(dot(_3415, _4148), 0.0);\n            float _3538 = _3524.attenuation * _3524.shadow;\n            float3 _3543 = fast::normalize(_4148 + _3374);\n            float _3548 = fast::max(dot(_3415, _3543), 0.0);\n            float _3553 = fast::max(dot(_3374, _3543), 0.0);\n            if (_3468.on)\n            {\n                FaLayers param_17 = _3468;\n                float3 param_18 = _3445;\n                float3 param_19 = f0;\n                float3 param_20 = _3415;\n                float3 param_21 = _3374;\n                float3 param_22 = _4148;\n                float3 param_23 = _3543;\n                float param_24 = _3532;\n                float param_25 = _3439;\n                float param_26 = _3548;\n                float param_27 = _3553;\n                float param_28 = _3430;\n                float param_29 = _3434;\n                int param_30 = _3503;\n                lit += (fa_layers_light(param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29) * (fa_light_rgb(param_30, fa_light_tex, fa_shadow_smp) * _3538));\n            }\n            else\n            {\n                float _3601 = ((_3548 * _3548) * (_3434 - 1.0)) + 1.0;\n                int param_31 = _3503;\n                lit += (((_3445 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _3553, 5.0))) * (((_3434 / ((3.1415927410125732421875 * _3601) * _3601)) * (0.5 / fast::max(mix((2.0 * _3532) * _3439, _3532 + _3439, _3430), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3532))) * fa_light_rgb(param_31, fa_light_tex, fa_shadow_smp)) * (_3532 * _3538));\n            }\n        }\n        if (_3468.on)\n        {\n            FaLayers param_32 = _3468;\n            float3 param_33 = _3415;\n            float3 param_34 = _3374;\n            float3 param_35 = f0;\n            float param_36 = _3426;\n            lit += (fa_layers_ibl(param_32, param_33, param_34, param_35, param_36, _511, fa_env_tex, fa_env_smp) * _3979);\n        }\n        else\n        {\n            float3 param_37 = _3415;\n            float3 param_38 = _3374;\n            float3 param_39 = f0;\n            float param_40 = _3426;\n            lit += (fa_sky_reflection(param_37, param_38, param_39, param_40, _511, fa_env_tex, fa_env_smp) * _3979);\n        }\n        result = lit;\n    }\n    float3 _3694 = result;\n    float3 _3695 = _3694 + _3980;\n    result = _3695;\n    float3 param_41 = _3695;\n    float3 param_42 = in.fa_world_pos;\n    result = fa_shadow_debug(param_41, param_42, _747);\n    bool _3704 = _511.fa_fog.w > 0.0;\n    bool _3711;\n    if (!_3704)\n    {\n        _3711 = _511.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3711 = _3704;\n    }\n    if (_3711)\n    {\n        float3 _3720 = in.fa_world_pos - _511.fa_camera_pos.xyz;\n        float _3726 = dot(_3720, _511.fa_fog_c.xyz);\n        bool _3730 = _511.fa_fog_c.w > 0.5;\n        float _3731;\n        if (_3730)\n        {\n            _3731 = _3726;\n        }\n        else\n        {\n            _3731 = length(_3720);\n        }\n        float _3743 = _3731 - _511.fa_fog_b.x;\n        if (_3743 > 0.0)\n        {\n            float _3752 = _511.fa_fog.w * _3743;\n            float tau = _3752 * _3752;\n            if (_511.fa_fog_b.y > 0.0)\n            {\n                float _3768;\n                if (_3730)\n                {\n                    _3768 = in.fa_world_pos.y - (_511.fa_fog_c.y * _3726);\n                }\n                else\n                {\n                    _3768 = _511.fa_camera_pos.y;\n                }\n                float _3789 = mix(_3768, in.fa_world_pos.y, fast::clamp(_511.fa_fog_b.x / _3731, 0.0, 1.0));\n                float _3793 = in.fa_world_pos.y - _3789;\n                float _3798 = _3789 - _511.fa_fog_b.z;\n                float _3803 = in.fa_world_pos.y - _511.fa_fog_b.z;\n                bool _3806 = _3798 <= 0.0;\n                bool _3807 = !_3806;\n                bool _3813;\n                if (_3807)\n                {\n                    _3813 = _511.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3813 = _3806;\n                }\n                float _3814;\n                if (_3813)\n                {\n                    _3814 = _511.fa_fog_b.y;\n                }\n                else\n                {\n                    _3814 = _511.fa_fog_b.y * exp(-fast::min(_511.fa_fog_b.w * _3798, 80.0));\n                }\n                bool _3841;\n                if (_3807)\n                {\n                    _3841 = _511.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3841 = _3806;\n                }\n                float _3842;\n                if (_3841)\n                {\n                    _3842 = _511.fa_fog_b.y * _3798;\n                }\n                else\n                {\n                    _3842 = (_511.fa_fog_b.y * (1.0 - exp(-fast::min(_511.fa_fog_b.w * _3798, 80.0)))) / _511.fa_fog_b.w;\n                }\n                bool _3867 = _3803 <= 0.0;\n                bool _3874;\n                if (!_3867)\n                {\n                    _3874 = _511.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3874 = _3867;\n                }\n                float _3875;\n                if (_3874)\n                {\n                    _3875 = _511.fa_fog_b.y * _3803;\n                }\n                else\n                {\n                    _3875 = (_511.fa_fog_b.y * (1.0 - exp(-fast::min(_511.fa_fog_b.w * _3803, 80.0)))) / _511.fa_fog_b.w;\n                }\n                float _3902;\n                if (abs(_3793) < 0.001000000047497451305389404296875)\n                {\n                    _3902 = _3814;\n                }\n                else\n                {\n                    _3902 = (_3875 - _3842) / _3793;\n                }\n                tau += (_3743 * fast::max(_3902, 0.0));\n            }\n            result = mix(result, _511.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3975);\n    return out;\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_511",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_747",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3393",
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
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 6
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
              "msl_texture_n": 7
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
              "msl_texture_n": 8
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
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 10,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _308 = _160.world_pos;\n    float4 _171 = float4(_308, 1.0);\n    fa_world_pos = _308;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _225, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _225.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _755 = base_t;\n    _755.x = _237.x;\n    _755.y = _237.y;\n    _755.z = _237.z;\n    base_t = _755;\n    float4 _253 = (_755 * _225.fa_base_color) * i.vertex_color;\n    float3 _718 = i.world_normal;\n    if (_225.fa_maps.z > 0.5)\n    {\n        float param_4 = _225.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0) - float3(1.0);\n        float2 _295 = _290.xy * _225.fa_maps.x;\n        float3 _763 = _290;\n        _763.x = _295.x;\n        _763.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _763;\n        _718 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _225.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _766 = mrt;\n    _766.x = _324.x;\n    _766.y = _324.y;\n    _766.z = _324.z;\n    mrt = _766;\n    float4 _354 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _225.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _723 = _225.fa_layers_a.x;\n    float _724 = _225.fa_layers_a.y;\n    float _727 = _225.fa_layers_a.z;\n    float _726 = _225.fa_layers_b.w;\n    float _729 = _225.fa_layers_c.x;\n    if (_225.fa_layers_c.z > 0.5)\n    {\n        if (mod(_225.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _723 *= _366.y;\n            _724 *= _366.z;\n            _726 *= _354.w;\n        }\n        if (_225.fa_layers_c.z > 1.5)\n        {\n            _727 *= mrt.x;\n            _729 *= mrt.w;\n        }\n    }\n    return Surface{ _253.xyz, _253.w, _718, fast::clamp(_225.fa_pbr.x * _324.z, 0.0, 1.0), fast::clamp(_225.fa_pbr.y * _324.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_225.fa_maps.y * (_366.x - 1.0)), _225.fa_emissive.xyz + (_225.fa_model_emissive.xyz * _396), _723, _724, _225.fa_layers_b.xyz, _726, _727, _225.fa_layers_a.w, _729, _225.fa_layers_c.y, _225.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _225 [[buffer(1)]], constant fa_material& _546 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], texture2d<float> mask [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler mask_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _629 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _629 = -_629;\n    }\n    float3 _530 = fast::normalize(_225.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _629, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    Surface _535 = fa_standard_surface(param, fa_tex, fa_smp, _225, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _653 = _535.normal;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _629, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    Surface param_2 = _535;\n    surface(param_1, param_2, mask, mask_smp);\n    _653 = param_2.normal;\n    if (param_2.alpha < _546.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    float3 _556 = fast::normalize(_653);\n    float3 _571 = fast::normalize(float3(dot(in.fa_pre_r0, _556), dot(in.fa_pre_r1, _556), dot(in.fa_pre_r2, _556)));\n    float _583 = _571.z;\n    float2 e = _571.xy / float2((abs(_571.x) + abs(_571.y)) + abs(_583));\n    if (_583 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_225",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_546",
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
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _429 = _273.world_pos;\n    float4 _284 = float4(_429, 1.0);\n    fa_world_pos = _429;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _225, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _225.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _755 = base_t;\n    _755.x = _237.x;\n    _755.y = _237.y;\n    _755.z = _237.z;\n    base_t = _755;\n    float4 _253 = (_755 * _225.fa_base_color) * i.vertex_color;\n    float3 _718 = i.world_normal;\n    if (_225.fa_maps.z > 0.5)\n    {\n        float param_4 = _225.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0) - float3(1.0);\n        float2 _295 = _290.xy * _225.fa_maps.x;\n        float3 _763 = _290;\n        _763.x = _295.x;\n        _763.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _763;\n        _718 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _225.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _766 = mrt;\n    _766.x = _324.x;\n    _766.y = _324.y;\n    _766.z = _324.z;\n    mrt = _766;\n    float4 _354 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _225.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _723 = _225.fa_layers_a.x;\n    float _724 = _225.fa_layers_a.y;\n    float _727 = _225.fa_layers_a.z;\n    float _726 = _225.fa_layers_b.w;\n    float _729 = _225.fa_layers_c.x;\n    if (_225.fa_layers_c.z > 0.5)\n    {\n        if (mod(_225.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _723 *= _366.y;\n            _724 *= _366.z;\n            _726 *= _354.w;\n        }\n        if (_225.fa_layers_c.z > 1.5)\n        {\n            _727 *= mrt.x;\n            _729 *= mrt.w;\n        }\n    }\n    return Surface{ _253.xyz, _253.w, _718, fast::clamp(_225.fa_pbr.x * _324.z, 0.0, 1.0), fast::clamp(_225.fa_pbr.y * _324.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_225.fa_maps.y * (_366.x - 1.0)), _225.fa_emissive.xyz + (_225.fa_model_emissive.xyz * _396), _723, _724, _225.fa_layers_b.xyz, _726, _727, _225.fa_layers_a.w, _729, _225.fa_layers_c.y, _225.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _225 [[buffer(1)]], constant fa_material& _546 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], texture2d<float> mask [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler mask_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _629 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _629 = -_629;\n    }\n    float3 _530 = fast::normalize(_225.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _629, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    Surface _535 = fa_standard_surface(param, fa_tex, fa_smp, _225, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _653 = _535.normal;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _629, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    Surface param_2 = _535;\n    surface(param_1, param_2, mask, mask_smp);\n    _653 = param_2.normal;\n    if (param_2.alpha < _546.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    float3 _556 = fast::normalize(_653);\n    float3 _571 = fast::normalize(float3(dot(in.fa_pre_r0, _556), dot(in.fa_pre_r1, _556), dot(in.fa_pre_r2, _556)));\n    float _583 = _571.z;\n    float2 e = _571.xy / float2((abs(_571.x) + abs(_571.y)) + abs(_583));\n    if (_583 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_225",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_546",
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
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float3 fa_normal [[attribute(5)]];\n    float2 fa_texcoord0 [[attribute(6)]];\n    float4 fa_tangent [[attribute(7)]];\n    float4 fa_color [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _122)\n{\n    float3 _60 = cross(model[1].xyz, model[2].xyz);\n    float _66 = (dot(model[0].xyz, _60) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_60 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _66, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _66), texcoord0 * _122.fa_uv_scale.xy, color, position };\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _122 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    VertexData _190 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _122);\n    float3 _239 = _190.world_pos;\n    out.fa_world_pos = _239;\n    out.fa_world_normal = _190.world_normal;\n    out.fa_world_tangent = _190.world_tangent;\n    out.fa_uv = _190.uv;\n    out.fa_vertex_color = _190.color;\n    out.gl_Position = _122.fa_light_vp * float4(_239, 1.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _225, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _225.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _689 = base_t;\n    _689.x = _237.x;\n    _689.y = _237.y;\n    _689.z = _237.z;\n    base_t = _689;\n    float4 _253 = (_689 * _225.fa_base_color) * i.vertex_color;\n    float3 _658 = i.world_normal;\n    if (_225.fa_maps.z > 0.5)\n    {\n        float param_4 = _225.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0) - float3(1.0);\n        float2 _295 = _290.xy * _225.fa_maps.x;\n        float3 _697 = _290;\n        _697.x = _295.x;\n        _697.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _697;\n        _658 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _225.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _700 = mrt;\n    _700.x = _324.x;\n    _700.y = _324.y;\n    _700.z = _324.z;\n    mrt = _700;\n    float4 _354 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _225.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _663 = _225.fa_layers_a.x;\n    float _664 = _225.fa_layers_a.y;\n    float _667 = _225.fa_layers_a.z;\n    float _666 = _225.fa_layers_b.w;\n    float _669 = _225.fa_layers_c.x;\n    if (_225.fa_layers_c.z > 0.5)\n    {\n        if (mod(_225.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _663 *= _366.y;\n            _664 *= _366.z;\n            _666 *= _354.w;\n        }\n        if (_225.fa_layers_c.z > 1.5)\n        {\n            _667 *= mrt.x;\n            _669 *= mrt.w;\n        }\n    }\n    return Surface{ _253.xyz, _253.w, _658, fast::clamp(_225.fa_pbr.x * _324.z, 0.0, 1.0), fast::clamp(_225.fa_pbr.y * _324.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_225.fa_maps.y * (_366.x - 1.0)), _225.fa_emissive.xyz + (_225.fa_model_emissive.xyz * _396), _663, _664, _225.fa_layers_b.xyz, _666, _667, _225.fa_layers_a.w, _669, _225.fa_layers_c.y, _225.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _225 [[buffer(1)]], constant fa_material& _546 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], texture2d<float> mask [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler mask_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _569 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _569 = -_569;\n    }\n    float3 _530 = fast::normalize(_225.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _569, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _569, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _225, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, mask, mask_smp);\n    if (param_2.alpha < _546.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    out.fa_frag_color = float4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n    return out;\n}\n\n",
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
            "inst_name": "_122",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_225",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_546",
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
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float4 fa_joints [[attribute(5)]];\n    float4 fa_weights [[attribute(6)]];\n    float3 fa_normal [[attribute(7)]];\n    float2 fa_texcoord0 [[attribute(8)]];\n    float4 fa_tangent [[attribute(9)]];\n    float4 fa_color [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _174)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _165 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_174.fa_joint_rows[_165] * weights[i]);\n        r1 += (_174.fa_joint_rows[_165 + 1] * weights[i]);\n        r2 += (_174.fa_joint_rows[_165 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _127)\n{\n    float3 _65 = cross(model[1].xyz, model[2].xyz);\n    float _71 = (dot(model[0].xyz, _65) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_65 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _71, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _71), texcoord0 * _127.fa_uv_scale.xy, color, position };\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _127 [[buffer(0)]], constant fa_skin& _174 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _174);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    VertexData _311 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7, _127);\n    float3 _360 = _311.world_pos;\n    out.fa_world_pos = _360;\n    out.fa_world_normal = _311.world_normal;\n    out.fa_world_tangent = _311.world_tangent;\n    out.fa_uv = _311.uv;\n    out.fa_vertex_color = _311.color;\n    out.gl_Position = _127.fa_light_vp * float4(_360, 1.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _225, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _225.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _689 = base_t;\n    _689.x = _237.x;\n    _689.y = _237.y;\n    _689.z = _237.z;\n    base_t = _689;\n    float4 _253 = (_689 * _225.fa_base_color) * i.vertex_color;\n    float3 _658 = i.world_normal;\n    if (_225.fa_maps.z > 0.5)\n    {\n        float param_4 = _225.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0) - float3(1.0);\n        float2 _295 = _290.xy * _225.fa_maps.x;\n        float3 _697 = _290;\n        _697.x = _295.x;\n        _697.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _697;\n        _658 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _225.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _700 = mrt;\n    _700.x = _324.x;\n    _700.y = _324.y;\n    _700.z = _324.z;\n    mrt = _700;\n    float4 _354 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _225.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _663 = _225.fa_layers_a.x;\n    float _664 = _225.fa_layers_a.y;\n    float _667 = _225.fa_layers_a.z;\n    float _666 = _225.fa_layers_b.w;\n    float _669 = _225.fa_layers_c.x;\n    if (_225.fa_layers_c.z > 0.5)\n    {\n        if (mod(_225.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _663 *= _366.y;\n            _664 *= _366.z;\n            _666 *= _354.w;\n        }\n        if (_225.fa_layers_c.z > 1.5)\n        {\n            _667 *= mrt.x;\n            _669 *= mrt.w;\n        }\n    }\n    return Surface{ _253.xyz, _253.w, _658, fast::clamp(_225.fa_pbr.x * _324.z, 0.0, 1.0), fast::clamp(_225.fa_pbr.y * _324.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_225.fa_maps.y * (_366.x - 1.0)), _225.fa_emissive.xyz + (_225.fa_model_emissive.xyz * _396), _663, _664, _225.fa_layers_b.xyz, _666, _667, _225.fa_layers_a.w, _669, _225.fa_layers_c.y, _225.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _225 [[buffer(1)]], constant fa_material& _546 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], texture2d<float> mask [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler mask_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _569 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _569 = -_569;\n    }\n    float3 _530 = fast::normalize(_225.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _569, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _569, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _225, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, mask, mask_smp);\n    if (param_2.alpha < _546.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    out.fa_frag_color = float4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n    return out;\n}\n\n",
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
            "inst_name": "_127",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_174",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_225",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_546",
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
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    }
  }
}
