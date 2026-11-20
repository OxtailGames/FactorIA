{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "df130aaeb5c0790af276010723d2798f8fdace693dbde21948e5a037edff24ef",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "vertexAttributes": [
    "color1",
    "uv1"
  ],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _144_fa_view_proj : packoffset(c0);\n    row_major float4x4 _144_fa_light_vp : packoffset(c4);\n    float4 _144_fa_uv_scale : packoffset(c8);\n    float4 _144_fa_time : packoffset(c9);\n    float4 _144_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float2 fa_attr_uv1 : TEXCOORD9;\n    float4 fa_attr_color1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _296 = { mul(float4(position, 1.0f), model).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _144_fa_uv_scale.xy, color, position };\n    return _296;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _144_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = float3((fa_attr_uv1 * _144_fa_lm_so.xy) + _144_fa_lm_so.zw, float(_144_fa_lm_so.x > 0.0f));\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _2058[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _511_fa_camera_pos : packoffset(c0);\n    float4 _511_fa_ambient : packoffset(c1);\n    float4 _511_fa_base_color : packoffset(c2);\n    float4 _511_fa_emissive : packoffset(c3);\n    float4 _511_fa_model_emissive : packoffset(c4);\n    float4 _511_fa_pbr : packoffset(c5);\n    float4 _511_fa_maps : packoffset(c6);\n    float4 _511_fa_fog : packoffset(c7);\n    float4 _511_fa_fog_b : packoffset(c8);\n    float4 _511_fa_fog_c : packoffset(c9);\n    float4 _511_fa_counts : packoffset(c10);\n    float4 _511_fa_env_sky : packoffset(c11);\n    float4 _511_fa_env_horizon : packoffset(c12);\n    float4 _511_fa_time : packoffset(c13);\n    float4 _511_fa_cl_vpx : packoffset(c14);\n    float4 _511_fa_cl_vpy : packoffset(c15);\n    float4 _511_fa_cl_vpw : packoffset(c16);\n    float4 _511_fa_cl_fwd : packoffset(c17);\n    float4 _511_fa_cl_grid : packoffset(c18);\n    float4 _511_fa_cl_info : packoffset(c19);\n    float4 _511_fa_layers_a : packoffset(c20);\n    float4 _511_fa_layers_b : packoffset(c21);\n    float4 _511_fa_layers_c : packoffset(c22);\n    float4 _511_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _747_fa_shadow_mat[4] : packoffset(c0);\n    float4 _747_fa_shadow_rect[4] : packoffset(c16);\n    float4 _747_fa_shadow_info[4] : packoffset(c20);\n    float4 _747_fa_shadow_split : packoffset(c24);\n    float4 _747_fa_shadow_cfg : packoffset(c25);\n    float4 _747_fa_shadow_bias : packoffset(c26);\n    float4 _747_fa_shadow_eye : packoffset(c27);\n    float4 _747_fa_shadow_fwd : packoffset(c28);\n    float4 _747_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _516 = _511_fa_cl_info.x < 0.0f;\n    bool _523;\n    if (!_516)\n    {\n        _523 = _511_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _523 = _516;\n    }\n    bool _531;\n    if (!_523)\n    {\n        _531 = _511_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _531 = _523;\n    }\n    bool _538;\n    if (!_531)\n    {\n        _538 = _511_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _538 = _531;\n    }\n    bool _545;\n    if (!_538)\n    {\n        _545 = _511_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _545 = _538;\n    }\n    if (_545)\n    {\n        return int2(0, 0);\n    }\n    float4 _555 = float4(world_pos, 1.0f);\n    float _562 = dot(_511_fa_cl_vpw, _555);\n    if (!(_562 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _584 = float2(dot(_511_fa_cl_vpx, _555), dot(_511_fa_cl_vpy, _555)) / _562.xx;\n    int _588 = int(_511_fa_cl_grid.x);\n    int _592 = int(_511_fa_cl_grid.y);\n    int param = (int(_511_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_511_fa_cl_fwd.xyz, world_pos) + _511_fa_cl_fwd.w, _511_fa_cl_grid.w) / _511_fa_cl_grid.w) * _511_fa_cl_grid.z)), 0, int(_511_fa_cl_info.y) - 1) * _592) + clamp(int(floor(((_584.y * 0.5f) + 0.5f) * _511_fa_cl_grid.y)), 0, _592 - 1)) * _588)) + clamp(int(floor(((_584.x * 0.5f) + 0.5f) * _511_fa_cl_grid.x)), 0, _588 - 1);\n    float4 _663 = fa_light_texel(param);\n    return int2(int(_663.x), int(_663.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_511_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2875 = fa_cluster_lookup(param);\n    fa_cl_slot = _2875.x;\n    fa_cl_local = _2875.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3042 = fa_linear_to_srgb(param);\n        c = _3042;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3050 = fa_srgb_to_linear(param_1);\n            c = _3050;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _266;\n    if (i.front_facing)\n    {\n        _266 = i.world_normal;\n    }\n    else\n    {\n        _266 = -i.world_normal;\n    }\n    float3 _290 = normalize(i.world_tangent.xyz - (_266 * dot(_266, i.world_tangent.xyz)));\n    float3 _318 = normalize(((_290 * m.x) + ((cross(_266, _290) * i.world_tangent.w) * m.y)) + (_266 * m.z));\n    float3 _321;\n    if (i.front_facing)\n    {\n        _321 = _318;\n    }\n    else\n    {\n        _321 = -_318;\n    }\n    return _321;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _511_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3081 = fa_tex_fix(param_2, param_3);\n    float4 _4328 = base_t;\n    _4328.x = _3081.x;\n    _4328.y = _3081.y;\n    _4328.z = _3081.z;\n    base_t = _4328;\n    float4 _3095 = (_4328 * _511_fa_base_color) * i.vertex_color;\n    float3 _4230 = i.world_normal;\n    if (_511_fa_maps.z > 0.5f)\n    {\n        float param_4 = _511_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3127 = fa_tex_fix(param_6, param_7);\n        float3 _3130 = (_3127 * 2.0f) - 1.0f.xxx;\n        float2 _3135 = _3130.xy * _511_fa_maps.x;\n        float3 _4336 = _3130;\n        _4336.x = _3135.x;\n        _4336.y = _3135.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4336;\n        _4230 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _511_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3164 = fa_tex_fix(param_12, param_13);\n    float4 _4339 = mrt;\n    _4339.x = _3164.x;\n    _4339.y = _3164.y;\n    _4339.z = _3164.z;\n    mrt = _4339;\n    float4 _3192 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _511_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3192.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3204 = fa_tex_fix(param_16, param_17);\n    float param_18 = _511_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3234 = fa_tex_fix(param_20, param_21);\n    float _4235 = _511_fa_layers_a.x;\n    float _4236 = _511_fa_layers_a.y;\n    float _4239 = _511_fa_layers_a.z;\n    float _4238 = _511_fa_layers_b.w;\n    float _4241 = _511_fa_layers_c.x;\n    if (_511_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_511_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4235 *= _3204.y;\n            _4236 *= _3204.z;\n            _4238 *= _3192.w;\n        }\n        if (_511_fa_layers_c.z > 1.5f)\n        {\n            _4239 *= mrt.x;\n            _4241 *= mrt.w;\n        }\n    }\n    Surface _4260 = { _3095.xyz, _3095.w, _4230, clamp(_511_fa_pbr.x * _3164.z, 0.0f, 1.0f), clamp(_511_fa_pbr.y * _3164.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_511_fa_maps.y * (_3204.x - 1.0f)), _511_fa_emissive.xyz + (_511_fa_model_emissive.xyz * _3234), _4235, _4236, _511_fa_layers_b.xyz, _4238, _4239, _511_fa_layers_a.w, _4241, _511_fa_layers_c.y, _511_fa_layers_d.xyz };\n    return _4260;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0f));\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1983 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1991 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1994 = int(_1983);\n    int _1997 = int(_1991);\n    float _2007 = _1991 - float(_1997);\n    int _2063 = (_1994 * 9) + _1997;\n    int _2083 = ((_1994 + 1) * 9) + _1997;\n    return lerp(lerp(_2058[_2063], _2058[_2063 + 1], _2007), lerp(_2058[_2083], _2058[_2083 + 1], _2007), _1983 - float(_1994));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4153 = false;\n    float _4154 = 1.0f;\n    float _4155 = 1.0f;\n    float _4156 = 1.0f;\n    float _4157 = 0.0f;\n    float _4158 = 0.0f;\n    float _4159 = 0.0f;\n    float _4160 = 0.0f;\n    float _4162 = 1.0f;\n    bool _4163 = false;\n    float3 _4164 = 0.0f.xxx;\n    float _4165 = 1.0f;\n    float _4166 = 1.0f;\n    float _4167 = 1.0f;\n    float _4168 = 0.0f;\n    float _4169 = 0.0f;\n    float3 _4170 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4171 = float3(0.0f, 0.0f, 1.0f);\n    float _4172 = 1.0f;\n    float _4173 = 1.0f;\n    float _2136 = clamp(s.specular, 0.0f, 1.0f);\n    float _2140 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2145 = (_2136 != 1.0f) || (_2140 != 1.5f);\n    bool _2155;\n    if (!_2145)\n    {\n        _2155 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2155 = _2145;\n    }\n    if (_2155)\n    {\n        float _2163 = (_2140 - 1.0f) / (_2140 + 1.0f);\n        f0 = lerp(min((_2163 * _2163).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2136, s.albedo, metallic.xxx);\n        _4154 = lerp(_2136, 1.0f, metallic);\n        _4153 = true;\n    }\n    float _2191 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2191 > 0.0f)\n    {\n        float _2199 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4157 = _2191;\n        _4158 = _2199;\n        float _2206 = _2199 * _2199;\n        _4159 = _2206;\n        _4160 = _2206 * _2206;\n        float _2218 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4162 = _2218;\n        _4155 = 1.0f - (_2191 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2218, 0.0f, 1.0f), 5.0f))));\n        _4153 = true;\n    }\n    float3 _2238 = max(s.sheen_color, 0.0f.xxx);\n    float _2247 = max(_2238.x, max(_2238.y, _2238.z));\n    if (_2247 > 0.0f)\n    {\n        float _2255 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4163 = true;\n        _4164 = _2238;\n        _4165 = _2255;\n        _4166 = _2255 * _2255;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2255;\n        float _2272 = fa_sheen_albedo(param, param_1);\n        _4168 = _2272;\n        _4167 = 1.0f - min(_2247 * _2272, 1.0f);\n        _4153 = true;\n    }\n    _4156 = _4155 * _4167;\n    float _2291 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2291 != 0.0f)\n    {\n        float3 _2306 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2306;\n        if (dot(_2306, _2306) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2320 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2320.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2320.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2320.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2324 = t;\n        float3 _2325 = normalize(_2324);\n        t = _2325;\n        float3 _2350 = normalize((_2325 * cos(s.anisotropy_rotation)) + ((cross(n, _2325) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4170 = _2350;\n        _4171 = cross(n, _2350);\n        float _2360 = roughness * roughness;\n        float _2366 = lerp(_2360, 1.0f, _2291 * _2291);\n        bool _2368 = _2291 > 0.0f;\n        _4172 = _2368 ? _2366 : _2360;\n        _4173 = _2368 ? _2360 : _2366;\n        _4169 = _2291;\n        _4153 = true;\n    }\n    FaLayers _4195 = { _4153, _4154, _4155, _4156, _4157, _4158, _4159, _4160, i.world_normal, _4162, _4163, _4164, _4165, _4166, _4167, _4168, _4169, _4170, _4171, _4172, _4173 };\n    return _4195;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_511_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _511_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_511_fa_cl_info.x) + int(_511_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _385 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _391 = fa_light_texel(param_1);\n    float _394 = _391.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _400 = _394 < 0.5f;\n    float3 l;\n    if (_400)\n    {\n        l = normalize(_385.xyz);\n    }\n    else\n    {\n        float3 _412 = _385.xyz - world_pos;\n        float _414 = length(_412);\n        dist = _414;\n        l = _412 / max(_414, 9.9999997473787516355514526367188e-05f).xxx;\n        float _429 = _414 / max(_385.w, 0.001000000047497451305389404296875f);\n        float _435 = clamp(1.0f - (_429 * _429), 0.0f, 1.0f);\n        atten = _435 * _435;\n        if (_394 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _449 = fa_light_texel(param_2);\n            float _459 = _449.w;\n            int param_3 = (li * 4) + 3;\n            float4 _465 = fa_light_texel(param_3);\n            float _466 = _465.x;\n            float cos_inner = _466;\n            if (_466 > 1.5f)\n            {\n                cos_inner = lerp(_459, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_459, cos_inner, dot(-l, normalize(_449.xyz)));\n        }\n    }\n    int _497;\n    if (_400)\n    {\n        _497 = 0;\n    }\n    else\n    {\n        _497 = (_394 > 1.5f) ? 2 : 1;\n    }\n    LightSample _4152 = { l, _391.xyz * atten, atten, 1.0f, dist, _497 };\n    return _4152;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _737;\n    if (i == 0)\n    {\n        _737 = _747_fa_shadow_split.x;\n    }\n    else\n    {\n        float _753;\n        if (i == 1)\n        {\n            _753 = _747_fa_shadow_split.y;\n        }\n        else\n        {\n            float _761;\n            if (i == 2)\n            {\n                _761 = _747_fa_shadow_split.z;\n            }\n            else\n            {\n                _761 = _747_fa_shadow_split.w;\n            }\n            _753 = _761;\n        }\n        _737 = _753;\n    }\n    return _737;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _794 = fa_shadow_depth(param, param_1);\n    float _798;\n    if (conv.x < 0.5f)\n    {\n        _798 = _794;\n    }\n    else\n    {\n        _798 = (conv.y * conv.z) / (conv.z - (_794 * (conv.z - conv.y)));\n    }\n    return _798;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _725 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_725), sin(_725)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _844 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _858 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _844;\n            float2 _877 = fa_shadow_vogel(param_3, param_4, param_5) * _858;\n            float2 param_6 = uv + (_877 * _747_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _889 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_889 < (zr - (length(_877) * plane)))\n            {\n                sum += _889;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _933 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _933; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _933;\n        float param_11 = _844;\n        float2 _952 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_952 * _747_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_952) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_933);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _994 = max(_747_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _999 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1005 = sqrt(1.0f - (_999 * _999));\n    float _1013 = min(_1005 / max(_999, 0.20000000298023223876953125f), 4.0f);\n    float _1018;\n    if (_747_fa_shadow_bias.y > 0.0f)\n    {\n        _1018 = _747_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1018 = 1.5f * _747_fa_shadow_info[ci].x;\n    }\n    float4 _1043 = mul(float4(world + (n * (_1018 * _1005)), 1.0f), _747_fa_shadow_mat[ci]);\n    float _1050 = _1043.x;\n    bool _1053 = _1050 < _747_fa_shadow_rect[ci].x;\n    bool _1062;\n    if (!_1053)\n    {\n        _1062 = _1050 > _747_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1062 = _1053;\n    }\n    bool _1071;\n    if (!_1062)\n    {\n        _1071 = _1043.y < _747_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1071 = _1062;\n    }\n    bool _1080;\n    if (!_1071)\n    {\n        _1080 = _1043.y > _747_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1080 = _1071;\n    }\n    bool _1087;\n    if (!_1080)\n    {\n        _1087 = _1043.z > 1.0f;\n    }\n    else\n    {\n        _1087 = _1080;\n    }\n    if (_1087)\n    {\n        return -1.0f;\n    }\n    float _1096;\n    if (_747_fa_shadow_bias.x > 0.0f)\n    {\n        _1096 = _747_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1096 = 1.5f * _747_fa_shadow_info[ci].x;\n    }\n    float2 param = _1043.xy;\n    float4 param_1 = _747_fa_shadow_rect[ci];\n    float param_2 = _1043.z - ((_1096 * (1.0f + (0.5f * _1013))) / _994);\n    float param_3 = _747_fa_shadow_info[ci].x;\n    float param_4 = _994;\n    float param_5 = _994 * 0.25f;\n    float param_6 = ((_747_fa_shadow_info[ci].x * min(_1013, 3.0f)) * 0.5f) / _994;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_747_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _747_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_511_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1524 = int(_747_fa_shadow_cfg.x + 0.5f);\n    if (_1524 < 1)\n    {\n        return 1.0f;\n    }\n    float _1540 = dot(world - _747_fa_shadow_eye.xyz, _747_fa_shadow_fwd.xyz);\n    int param = _1524 - 1;\n    if (_1540 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1552 = _1524 > 1;\n    bool _1559;\n    if (_1552)\n    {\n        _1559 = _1540 > _747_fa_shadow_split.x;\n    }\n    else\n    {\n        _1559 = _1552;\n    }\n    if (_1559)\n    {\n        ci = 1;\n    }\n    bool _1563 = _1524 > 2;\n    bool _1570;\n    if (_1563)\n    {\n        _1570 = _1540 > _747_fa_shadow_split.y;\n    }\n    else\n    {\n        _1570 = _1563;\n    }\n    if (_1570)\n    {\n        ci = 2;\n    }\n    bool _1574 = _1524 > 3;\n    bool _1581;\n    if (_1574)\n    {\n        _1581 = _1540 > _747_fa_shadow_split.z;\n    }\n    else\n    {\n        _1581 = _1574;\n    }\n    if (_1581)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1524)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1607 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1607;\n        if (_1607 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_747_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1632;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1632 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1632 = _747_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1651 = _747_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1632, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1662 = clamp((_1540 - (fa_shadow_split_at(param_7) - _1651)) / _1651, 0.0f, 1.0f);\n        if (_1662 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1524)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1683 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1683;\n                if (_1683 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1662);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1155 = _511_fa_pbr.z < 0.5f;\n    bool _1163;\n    if (!_1155)\n    {\n        _1163 = _747_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1163 = _1155;\n    }\n    if (_1163)\n    {\n        return 1.0f;\n    }\n    int param = (int(_747_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1176 = fa_light_texel(param);\n    float _1177 = _1176.x;\n    if (_1177 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1186 = int(_1177 + 0.5f);\n    int param_1 = _1186;\n    float4 _1190 = fa_light_texel(param_1);\n    int param_2 = _1186 + 1;\n    float4 _1195 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1198 = _1190.y;\n    if (_1198 > 0.0f)\n    {\n        float _1215 = 1.0f - smoothstep(0.75f * _1198, _1198, length(world - _747_fa_shadow_eye.xyz));\n        fade = _1215;\n        if (_1215 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1190.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1234 = world - fa_light_texel(param_3).xyz;\n        float3 _1237 = abs(_1234);\n        float _1239 = _1237.x;\n        float _1241 = _1237.y;\n        bool _1242 = _1239 >= _1241;\n        bool _1250;\n        if (_1242)\n        {\n            _1250 = _1239 >= _1237.z;\n        }\n        else\n        {\n            _1250 = _1242;\n        }\n        int _1251;\n        if (_1250)\n        {\n            _1251 = (_1234.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1264;\n            if (_1241 >= _1237.z)\n            {\n                _1264 = (_1234.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1264 = (_1234.z > 0.0f) ? 4 : 5;\n            }\n            _1251 = _1264;\n        }\n        face = _1251;\n    }\n    int _1283 = (_1186 + 2) + (face * 6);\n    int param_4 = _1283;\n    int param_5 = _1283 + 1;\n    int param_6 = _1283 + 3;\n    float4 _1297 = fa_light_texel(param_6);\n    int param_7 = _1283 + 4;\n    float4 _1302 = fa_light_texel(param_7);\n    int param_8 = _1283 + 5;\n    float4 _1307 = fa_light_texel(param_8);\n    float _1319 = _1307.x * max(dot(_1297, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1324 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1347 = clamp(dot(n, _1297.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1370 = min(sqrt(1.0f - (_1347 * _1347)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1297, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1373 = _1195.y;\n    float _1375;\n    if (_1373 > 0.0f)\n    {\n        _1375 = _1373;\n    }\n    else\n    {\n        _1375 = 1.5f * _1319;\n    }\n    float4 _1395 = float4(world + (n * (_1375 * sqrt(1.0f - (_1324 * _1324)))), 1.0f);\n    float _1399 = dot(_1297, _1395);\n    float _1402 = _1307.y;\n    if (_1399 < _1402)\n    {\n        return 1.0f;\n    }\n    float2 _1417 = float2(dot(fa_light_texel(param_4), _1395), dot(fa_light_texel(param_5), _1395)) / _1399.xx;\n    float _1419 = _1417.x;\n    bool _1422 = _1419 < _1302.x;\n    bool _1431;\n    if (!_1422)\n    {\n        _1431 = _1419 > _1302.z;\n    }\n    else\n    {\n        _1431 = _1422;\n    }\n    bool _1440;\n    if (!_1431)\n    {\n        _1440 = _1417.y < _1302.y;\n    }\n    else\n    {\n        _1440 = _1431;\n    }\n    bool _1449;\n    if (!_1440)\n    {\n        _1449 = _1417.y > _1302.w;\n    }\n    else\n    {\n        _1449 = _1440;\n    }\n    if (_1449)\n    {\n        return 1.0f;\n    }\n    float _1455 = _1195.x;\n    float _1457;\n    if (_1455 > 0.0f)\n    {\n        _1457 = _1455;\n    }\n    else\n    {\n        _1457 = 1.5f * _1319;\n    }\n    float2 param_10 = _1417;\n    float4 param_11 = _1302;\n    float param_12 = _1399 - (_1457 * (1.0f + (0.5f * _1370)));\n    float param_13 = _1319;\n    float param_14 = 1.0f;\n    float param_15 = _1307.z * 0.25f;\n    float param_16 = (_1319 * min(_1370, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1402, _1307.z);\n    int param_18 = int(_1190.z + 0.5f);\n    float param_19 = _1190.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _2902 = fa_lm.z > 0.5f;\n    bool _2908;\n    if (_2902)\n    {\n        int param = li;\n        _2908 = fa_light_baked(param);\n    }\n    else\n    {\n        _2908 = _2902;\n    }\n    if (_2908)\n    {\n        int param_1 = li;\n        LightSample _4208 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4208;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2930 = fa_light_sample(param_2, param_3);\n    float3 _4215 = _2930.direction;\n    float3 _4210 = _2930.color;\n    float _4217 = _2930.attenuation;\n    float _4212 = _2930.shadow;\n    int _4220 = _2930.type;\n    if ((_4220 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4215;\n        float _2944 = fa_shadow_factor(param_4, param_5);\n        _4212 = _2944;\n        _4210 *= _2944;\n    }\n    else\n    {\n        bool _2955 = _4220 != 0;\n        bool _2961;\n        if (_2955)\n        {\n            _2961 = _4217 > 0.0f;\n        }\n        else\n        {\n            _2961 = _2955;\n        }\n        if (_2961)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4215;\n            float _2973 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4212 = _2973;\n            _4210 *= _2973;\n        }\n    }\n    LightSample _4227 = { _4215, _4210, _4217, _4212, _2930._distance, _4220 };\n    return _4227;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2518 = tdh / at;\n    float _2522 = bdh / ab;\n    float _2534 = ((_2518 * _2518) + (_2522 * _2522)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _2534) * _2534);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2615 = 1.0f / alpha;\n    return ((2.0f + _2615) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _2615)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2648 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2727 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _2727) * _2727);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _2648);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _2648));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _2800 = max(dot(L.nc, l), 0.0f);\n        float _2806 = max(dot(L.nc, h), 0.0f);\n        float _2815 = ((_2806 * _2806) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _2815) * _2815)) * (0.5f / max(lerp((2.0f * _2800) * L.coat_ndv, _2800 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2800)) * _2800).xxx;\n    }\n    return result;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1915 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1918 = _1915.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1918 * _1918, exp2((-9.27999973297119140625f) * ndv)) * _1918) + _1915.y)) + _1915.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_511_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _511_fa_env_horizon.w).xyz;\n    }\n    float _1820 = rough * rough;\n    float _1850 = 0.60000002384185791015625f * _1820;\n    return lerp(lerp(_511_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_511_fa_env_horizon.xyz, _511_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1820)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1850, 0.0500000007450580596923828125f + _1850, d.y).xxx), ((_511_fa_env_sky.xyz + _511_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1820 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2401;\n        if (L.aniso >= 0.0f)\n        {\n            _2401 = L.b;\n        }\n        else\n        {\n            _2401 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2401, v), _2401), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2434 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2434.x) + (L.f90.xxx * _2434.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2489 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2489.x) + _2489.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1957 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1957.x) + _1957.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_747_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1707 = int(_747_fa_shadow_cfg.x + 0.5f);\n    float _1717 = dot(world - _747_fa_shadow_eye.xyz, _747_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1722 = _1707 > 0;\n    bool _1731;\n    if (_1722)\n    {\n        int param = _1707 - 1;\n        _1731 = _1717 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1731 = _1722;\n    }\n    if (_1731)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1738 = _1707 > 1;\n        bool _1745;\n        if (_1738)\n        {\n            _1745 = _1717 > _747_fa_shadow_split.x;\n        }\n        else\n        {\n            _1745 = _1738;\n        }\n        if (_1745)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1751 = _1707 > 2;\n        bool _1758;\n        if (_1751)\n        {\n            _1758 = _1717 > _747_fa_shadow_split.y;\n        }\n        else\n        {\n            _1758 = _1751;\n        }\n        if (_1758)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1764 = _1707 > 3;\n        bool _1771;\n        if (_1764)\n        {\n            _1771 = _1717 > _747_fa_shadow_split.z;\n        }\n        else\n        {\n            _1771 = _1764;\n        }\n        if (_1771)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3932 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3932 = -_3932;\n    }\n    float3 _3374 = normalize(_511_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3945 = { fa_world_pos, _3932, fa_world_tangent, fa_uv, fa_vertex_color, _3374, gl_FrontFacing };\n    SurfaceInput param_1 = _3945;\n    Surface _3382 = fa_standard_surface(param_1);\n    float3 _3963 = _3382.albedo;\n    float _3964 = _3382.alpha;\n    float3 _3965 = _3382.normal;\n    float _3966 = _3382.metallic;\n    float _3967 = _3382.roughness;\n    float _3968 = _3382.occlusion;\n    float3 _3969 = _3382.emission;\n    float _3970 = _3382.clearcoat;\n    float _3971 = _3382.clearcoat_roughness;\n    float3 _3972 = _3382.sheen_color;\n    float _3973 = _3382.sheen_roughness;\n    float _3974 = _3382.anisotropy;\n    float _3975 = _3382.anisotropy_rotation;\n    float _3976 = _3382.specular;\n    float _3977 = _3382.ior;\n    float3 _3978 = _3382.specular_color;\n    SurfaceInput _3953 = { fa_world_pos, _3932, fa_world_tangent, fa_uv, fa_vertex_color, _3374, gl_FrontFacing };\n    SurfaceInput param_2 = _3953;\n    Surface param_3 = _3382;\n    surface(param_2, param_3);\n    _3963 = param_3.albedo;\n    _3964 = param_3.alpha;\n    _3965 = param_3.normal;\n    _3966 = param_3.metallic;\n    _3967 = param_3.roughness;\n    _3968 = param_3.occlusion;\n    _3969 = param_3.emission;\n    _3970 = param_3.clearcoat;\n    _3971 = param_3.clearcoat_roughness;\n    _3972 = param_3.sheen_color;\n    _3973 = param_3.sheen_roughness;\n    _3974 = param_3.anisotropy;\n    _3975 = param_3.anisotropy_rotation;\n    _3976 = param_3.specular;\n    _3977 = param_3.ior;\n    _3978 = param_3.specular_color;\n    float3 result;\n    if (_511_fa_emissive.w > 0.5f)\n    {\n        result = _3963;\n    }\n    else\n    {\n        float3 _3404 = normalize(_3965);\n        float _3411 = clamp(_3966, 0.0f, 1.0f);\n        float _3415 = clamp(_3967, 0.0500000007450580596923828125f, 1.0f);\n        float _3419 = _3415 * _3415;\n        float _3423 = _3419 * _3419;\n        float _3428 = max(dot(_3404, _3374), 9.9999997473787516355514526367188e-05f);\n        float3 _3434 = _3963 * (1.0f - _3411);\n        float3 _3441 = lerp(0.039999999105930328369140625f.xxx, _3963, _3411.xxx);\n        float3 f0 = _3441;\n        SurfaceInput _3961 = { fa_world_pos, _3932, fa_world_tangent, fa_uv, fa_vertex_color, _3374, gl_FrontFacing };\n        SurfaceInput param_4 = _3961;\n        Surface _4044 = { _3963, _3964, _3965, _3966, _3967, _3968, _3969, _3970, _3971, _3972, _3973, _3974, _3975, _3976, _3977, _3978 };\n        Surface param_5 = _4044;\n        float3 param_6 = _3404;\n        float3 param_7 = _3374;\n        float param_8 = _3411;\n        float param_9 = _3415;\n        float3 param_10 = _3441;\n        FaLayers _3457 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _3404;\n        float3 lit = (fa_indirect_diffuse(param_11) * _3434) * _3968;\n        if (_3457.on)\n        {\n            lit *= _3457.base_scale;\n        }\n        int _3479 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3479; ln++)\n        {\n            int param_12 = ln;\n            int _3492 = fa_cl_light(param_12);\n            bool _3495 = fa_lm.z > 0.5f;\n            bool _3501;\n            if (_3495)\n            {\n                int param_13 = _3492;\n                _3501 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3501 = _3495;\n            }\n            if (_3501)\n            {\n                continue;\n            }\n            int param_14 = _3492;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _3932;\n            LightSample _3513 = fa_light_shadowed(param_14, param_15, param_16);\n            float3 _4137 = _3513.direction;\n            float _3521 = max(dot(_3404, _4137), 0.0f);\n            float _3527 = _3513.attenuation * _3513.shadow;\n            float3 _3532 = normalize(_4137 + _3374);\n            float _3537 = max(dot(_3404, _3532), 0.0f);\n            float _3542 = max(dot(_3374, _3532), 0.0f);\n            if (_3457.on)\n            {\n                FaLayers param_17 = _3457;\n                float3 param_18 = _3434;\n                float3 param_19 = f0;\n                float3 param_20 = _3404;\n                float3 param_21 = _3374;\n                float3 param_22 = _4137;\n                float3 param_23 = _3532;\n                float param_24 = _3521;\n                float param_25 = _3428;\n                float param_26 = _3537;\n                float param_27 = _3542;\n                float param_28 = _3419;\n                float param_29 = _3423;\n                int param_30 = _3492;\n                lit += (fa_layers_light(param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29) * (fa_light_rgb(param_30) * _3527));\n            }\n            else\n            {\n                float _3590 = ((_3537 * _3537) * (_3423 - 1.0f)) + 1.0f;\n                int param_31 = _3492;\n                lit += (((_3434 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _3542, 5.0f))) * (((_3423 / ((3.1415927410125732421875f * _3590) * _3590)) * (0.5f / max(lerp((2.0f * _3521) * _3428, _3521 + _3428, _3419), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _3521))) * fa_light_rgb(param_31)) * (_3521 * _3527));\n            }\n        }\n        if (_3457.on)\n        {\n            FaLayers param_32 = _3457;\n            float3 param_33 = _3404;\n            float3 param_34 = _3374;\n            float3 param_35 = f0;\n            float param_36 = _3415;\n            lit += (fa_layers_ibl(param_32, param_33, param_34, param_35, param_36) * _3968);\n        }\n        else\n        {\n            float3 param_37 = _3404;\n            float3 param_38 = _3374;\n            float3 param_39 = f0;\n            float param_40 = _3415;\n            lit += (fa_sky_reflection(param_37, param_38, param_39, param_40) * _3968);\n        }\n        result = lit;\n    }\n    float3 _3683 = result;\n    float3 _3684 = _3683 + _3969;\n    result = _3684;\n    float3 param_41 = _3684;\n    float3 param_42 = fa_world_pos;\n    result = fa_shadow_debug(param_41, param_42);\n    bool _3693 = _511_fa_fog.w > 0.0f;\n    bool _3700;\n    if (!_3693)\n    {\n        _3700 = _511_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3700 = _3693;\n    }\n    if (_3700)\n    {\n        float3 _3709 = fa_world_pos - _511_fa_camera_pos.xyz;\n        float _3715 = dot(_3709, _511_fa_fog_c.xyz);\n        bool _3719 = _511_fa_fog_c.w > 0.5f;\n        float _3720;\n        if (_3719)\n        {\n            _3720 = _3715;\n        }\n        else\n        {\n            _3720 = length(_3709);\n        }\n        float _3732 = _3720 - _511_fa_fog_b.x;\n        if (_3732 > 0.0f)\n        {\n            float _3741 = _511_fa_fog.w * _3732;\n            float tau = _3741 * _3741;\n            if (_511_fa_fog_b.y > 0.0f)\n            {\n                float _3757;\n                if (_3719)\n                {\n                    _3757 = fa_world_pos.y - (_511_fa_fog_c.y * _3715);\n                }\n                else\n                {\n                    _3757 = _511_fa_camera_pos.y;\n                }\n                float _3778 = lerp(_3757, fa_world_pos.y, clamp(_511_fa_fog_b.x / _3720, 0.0f, 1.0f));\n                float _3782 = fa_world_pos.y - _3778;\n                float _3787 = _3778 - _511_fa_fog_b.z;\n                float _3792 = fa_world_pos.y - _511_fa_fog_b.z;\n                bool _3795 = _3787 <= 0.0f;\n                bool _3796 = !_3795;\n                bool _3802;\n                if (_3796)\n                {\n                    _3802 = _511_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3802 = _3795;\n                }\n                float _3803;\n                if (_3802)\n                {\n                    _3803 = _511_fa_fog_b.y;\n                }\n                else\n                {\n                    _3803 = _511_fa_fog_b.y * exp(-min(_511_fa_fog_b.w * _3787, 80.0f));\n                }\n                bool _3830;\n                if (_3796)\n                {\n                    _3830 = _511_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3830 = _3795;\n                }\n                float _3831;\n                if (_3830)\n                {\n                    _3831 = _511_fa_fog_b.y * _3787;\n                }\n                else\n                {\n                    _3831 = (_511_fa_fog_b.y * (1.0f - exp(-min(_511_fa_fog_b.w * _3787, 80.0f)))) / _511_fa_fog_b.w;\n                }\n                bool _3856 = _3792 <= 0.0f;\n                bool _3863;\n                if (!_3856)\n                {\n                    _3863 = _511_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3863 = _3856;\n                }\n                float _3864;\n                if (_3863)\n                {\n                    _3864 = _511_fa_fog_b.y * _3792;\n                }\n                else\n                {\n                    _3864 = (_511_fa_fog_b.y * (1.0f - exp(-min(_511_fa_fog_b.w * _3792, 80.0f)))) / _511_fa_fog_b.w;\n                }\n                float _3891;\n                if (abs(_3782) < 0.001000000047497451305389404296875f)\n                {\n                    _3891 = _3803;\n                }\n                else\n                {\n                    _3891 = (_3864 - _3831) / _3782;\n                }\n                tau += (_3732 * max(_3891, 0.0f));\n            }\n            result = lerp(result, _511_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3964);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main",
          "d3d11_target": "vs_5_0"
        },
        "fragment_func": {
          "entry_point": "main",
          "d3d11_target": "ps_5_0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 0
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 3
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 4
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 6
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 8
          },
          {
            "slot": 9,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 9
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 10
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_144",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_511",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_747",
            "hlsl_register_b_n": 7
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
              "hlsl_register_t_n": 0
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
              "hlsl_register_t_n": 1
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
              "hlsl_register_t_n": 2
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
              "hlsl_register_t_n": 3
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
              "hlsl_register_t_n": 4
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
              "hlsl_register_t_n": 5
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
              "hlsl_register_t_n": 6
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
              "hlsl_register_t_n": 7
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
              "hlsl_register_t_n": 8
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
              "hlsl_register_t_n": 9
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 10
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _149_fa_view_proj : packoffset(c0);\n    row_major float4x4 _149_fa_light_vp : packoffset(c4);\n    float4 _149_fa_uv_scale : packoffset(c8);\n    float4 _149_fa_time : packoffset(c9);\n    float4 _149_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _195_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float2 fa_attr_uv1 : TEXCOORD11;\n    float4 fa_attr_color1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _186 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_195_fa_joint_rows[_186] * weights[i]);\n        r1 += (_195_fa_joint_rows[_186 + 1] * weights[i]);\n        r2 += (_195_fa_joint_rows[_186 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _401 = { mul(float4(position, 1.0f), model).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _149_fa_uv_scale.xy, color, position };\n    return _401;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _149_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _2058[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _511_fa_camera_pos : packoffset(c0);\n    float4 _511_fa_ambient : packoffset(c1);\n    float4 _511_fa_base_color : packoffset(c2);\n    float4 _511_fa_emissive : packoffset(c3);\n    float4 _511_fa_model_emissive : packoffset(c4);\n    float4 _511_fa_pbr : packoffset(c5);\n    float4 _511_fa_maps : packoffset(c6);\n    float4 _511_fa_fog : packoffset(c7);\n    float4 _511_fa_fog_b : packoffset(c8);\n    float4 _511_fa_fog_c : packoffset(c9);\n    float4 _511_fa_counts : packoffset(c10);\n    float4 _511_fa_env_sky : packoffset(c11);\n    float4 _511_fa_env_horizon : packoffset(c12);\n    float4 _511_fa_time : packoffset(c13);\n    float4 _511_fa_cl_vpx : packoffset(c14);\n    float4 _511_fa_cl_vpy : packoffset(c15);\n    float4 _511_fa_cl_vpw : packoffset(c16);\n    float4 _511_fa_cl_fwd : packoffset(c17);\n    float4 _511_fa_cl_grid : packoffset(c18);\n    float4 _511_fa_cl_info : packoffset(c19);\n    float4 _511_fa_layers_a : packoffset(c20);\n    float4 _511_fa_layers_b : packoffset(c21);\n    float4 _511_fa_layers_c : packoffset(c22);\n    float4 _511_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _747_fa_shadow_mat[4] : packoffset(c0);\n    float4 _747_fa_shadow_rect[4] : packoffset(c16);\n    float4 _747_fa_shadow_info[4] : packoffset(c20);\n    float4 _747_fa_shadow_split : packoffset(c24);\n    float4 _747_fa_shadow_cfg : packoffset(c25);\n    float4 _747_fa_shadow_bias : packoffset(c26);\n    float4 _747_fa_shadow_eye : packoffset(c27);\n    float4 _747_fa_shadow_fwd : packoffset(c28);\n    float4 _747_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _516 = _511_fa_cl_info.x < 0.0f;\n    bool _523;\n    if (!_516)\n    {\n        _523 = _511_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _523 = _516;\n    }\n    bool _531;\n    if (!_523)\n    {\n        _531 = _511_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _531 = _523;\n    }\n    bool _538;\n    if (!_531)\n    {\n        _538 = _511_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _538 = _531;\n    }\n    bool _545;\n    if (!_538)\n    {\n        _545 = _511_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _545 = _538;\n    }\n    if (_545)\n    {\n        return int2(0, 0);\n    }\n    float4 _555 = float4(world_pos, 1.0f);\n    float _562 = dot(_511_fa_cl_vpw, _555);\n    if (!(_562 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _584 = float2(dot(_511_fa_cl_vpx, _555), dot(_511_fa_cl_vpy, _555)) / _562.xx;\n    int _588 = int(_511_fa_cl_grid.x);\n    int _592 = int(_511_fa_cl_grid.y);\n    int param = (int(_511_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_511_fa_cl_fwd.xyz, world_pos) + _511_fa_cl_fwd.w, _511_fa_cl_grid.w) / _511_fa_cl_grid.w) * _511_fa_cl_grid.z)), 0, int(_511_fa_cl_info.y) - 1) * _592) + clamp(int(floor(((_584.y * 0.5f) + 0.5f) * _511_fa_cl_grid.y)), 0, _592 - 1)) * _588)) + clamp(int(floor(((_584.x * 0.5f) + 0.5f) * _511_fa_cl_grid.x)), 0, _588 - 1);\n    float4 _663 = fa_light_texel(param);\n    return int2(int(_663.x), int(_663.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_511_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2875 = fa_cluster_lookup(param);\n    fa_cl_slot = _2875.x;\n    fa_cl_local = _2875.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3042 = fa_linear_to_srgb(param);\n        c = _3042;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3050 = fa_srgb_to_linear(param_1);\n            c = _3050;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _266;\n    if (i.front_facing)\n    {\n        _266 = i.world_normal;\n    }\n    else\n    {\n        _266 = -i.world_normal;\n    }\n    float3 _290 = normalize(i.world_tangent.xyz - (_266 * dot(_266, i.world_tangent.xyz)));\n    float3 _318 = normalize(((_290 * m.x) + ((cross(_266, _290) * i.world_tangent.w) * m.y)) + (_266 * m.z));\n    float3 _321;\n    if (i.front_facing)\n    {\n        _321 = _318;\n    }\n    else\n    {\n        _321 = -_318;\n    }\n    return _321;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _511_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3081 = fa_tex_fix(param_2, param_3);\n    float4 _4328 = base_t;\n    _4328.x = _3081.x;\n    _4328.y = _3081.y;\n    _4328.z = _3081.z;\n    base_t = _4328;\n    float4 _3095 = (_4328 * _511_fa_base_color) * i.vertex_color;\n    float3 _4230 = i.world_normal;\n    if (_511_fa_maps.z > 0.5f)\n    {\n        float param_4 = _511_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3127 = fa_tex_fix(param_6, param_7);\n        float3 _3130 = (_3127 * 2.0f) - 1.0f.xxx;\n        float2 _3135 = _3130.xy * _511_fa_maps.x;\n        float3 _4336 = _3130;\n        _4336.x = _3135.x;\n        _4336.y = _3135.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4336;\n        _4230 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _511_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3164 = fa_tex_fix(param_12, param_13);\n    float4 _4339 = mrt;\n    _4339.x = _3164.x;\n    _4339.y = _3164.y;\n    _4339.z = _3164.z;\n    mrt = _4339;\n    float4 _3192 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _511_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3192.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3204 = fa_tex_fix(param_16, param_17);\n    float param_18 = _511_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3234 = fa_tex_fix(param_20, param_21);\n    float _4235 = _511_fa_layers_a.x;\n    float _4236 = _511_fa_layers_a.y;\n    float _4239 = _511_fa_layers_a.z;\n    float _4238 = _511_fa_layers_b.w;\n    float _4241 = _511_fa_layers_c.x;\n    if (_511_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_511_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4235 *= _3204.y;\n            _4236 *= _3204.z;\n            _4238 *= _3192.w;\n        }\n        if (_511_fa_layers_c.z > 1.5f)\n        {\n            _4239 *= mrt.x;\n            _4241 *= mrt.w;\n        }\n    }\n    Surface _4260 = { _3095.xyz, _3095.w, _4230, clamp(_511_fa_pbr.x * _3164.z, 0.0f, 1.0f), clamp(_511_fa_pbr.y * _3164.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_511_fa_maps.y * (_3204.x - 1.0f)), _511_fa_emissive.xyz + (_511_fa_model_emissive.xyz * _3234), _4235, _4236, _511_fa_layers_b.xyz, _4238, _4239, _511_fa_layers_a.w, _4241, _511_fa_layers_c.y, _511_fa_layers_d.xyz };\n    return _4260;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0f));\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1983 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1991 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1994 = int(_1983);\n    int _1997 = int(_1991);\n    float _2007 = _1991 - float(_1997);\n    int _2063 = (_1994 * 9) + _1997;\n    int _2083 = ((_1994 + 1) * 9) + _1997;\n    return lerp(lerp(_2058[_2063], _2058[_2063 + 1], _2007), lerp(_2058[_2083], _2058[_2083 + 1], _2007), _1983 - float(_1994));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4153 = false;\n    float _4154 = 1.0f;\n    float _4155 = 1.0f;\n    float _4156 = 1.0f;\n    float _4157 = 0.0f;\n    float _4158 = 0.0f;\n    float _4159 = 0.0f;\n    float _4160 = 0.0f;\n    float _4162 = 1.0f;\n    bool _4163 = false;\n    float3 _4164 = 0.0f.xxx;\n    float _4165 = 1.0f;\n    float _4166 = 1.0f;\n    float _4167 = 1.0f;\n    float _4168 = 0.0f;\n    float _4169 = 0.0f;\n    float3 _4170 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4171 = float3(0.0f, 0.0f, 1.0f);\n    float _4172 = 1.0f;\n    float _4173 = 1.0f;\n    float _2136 = clamp(s.specular, 0.0f, 1.0f);\n    float _2140 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2145 = (_2136 != 1.0f) || (_2140 != 1.5f);\n    bool _2155;\n    if (!_2145)\n    {\n        _2155 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2155 = _2145;\n    }\n    if (_2155)\n    {\n        float _2163 = (_2140 - 1.0f) / (_2140 + 1.0f);\n        f0 = lerp(min((_2163 * _2163).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2136, s.albedo, metallic.xxx);\n        _4154 = lerp(_2136, 1.0f, metallic);\n        _4153 = true;\n    }\n    float _2191 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2191 > 0.0f)\n    {\n        float _2199 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4157 = _2191;\n        _4158 = _2199;\n        float _2206 = _2199 * _2199;\n        _4159 = _2206;\n        _4160 = _2206 * _2206;\n        float _2218 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4162 = _2218;\n        _4155 = 1.0f - (_2191 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2218, 0.0f, 1.0f), 5.0f))));\n        _4153 = true;\n    }\n    float3 _2238 = max(s.sheen_color, 0.0f.xxx);\n    float _2247 = max(_2238.x, max(_2238.y, _2238.z));\n    if (_2247 > 0.0f)\n    {\n        float _2255 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4163 = true;\n        _4164 = _2238;\n        _4165 = _2255;\n        _4166 = _2255 * _2255;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2255;\n        float _2272 = fa_sheen_albedo(param, param_1);\n        _4168 = _2272;\n        _4167 = 1.0f - min(_2247 * _2272, 1.0f);\n        _4153 = true;\n    }\n    _4156 = _4155 * _4167;\n    float _2291 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2291 != 0.0f)\n    {\n        float3 _2306 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2306;\n        if (dot(_2306, _2306) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2320 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2320.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2320.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2320.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2324 = t;\n        float3 _2325 = normalize(_2324);\n        t = _2325;\n        float3 _2350 = normalize((_2325 * cos(s.anisotropy_rotation)) + ((cross(n, _2325) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4170 = _2350;\n        _4171 = cross(n, _2350);\n        float _2360 = roughness * roughness;\n        float _2366 = lerp(_2360, 1.0f, _2291 * _2291);\n        bool _2368 = _2291 > 0.0f;\n        _4172 = _2368 ? _2366 : _2360;\n        _4173 = _2368 ? _2360 : _2366;\n        _4169 = _2291;\n        _4153 = true;\n    }\n    FaLayers _4195 = { _4153, _4154, _4155, _4156, _4157, _4158, _4159, _4160, i.world_normal, _4162, _4163, _4164, _4165, _4166, _4167, _4168, _4169, _4170, _4171, _4172, _4173 };\n    return _4195;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_511_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _511_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_511_fa_cl_info.x) + int(_511_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _385 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _391 = fa_light_texel(param_1);\n    float _394 = _391.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _400 = _394 < 0.5f;\n    float3 l;\n    if (_400)\n    {\n        l = normalize(_385.xyz);\n    }\n    else\n    {\n        float3 _412 = _385.xyz - world_pos;\n        float _414 = length(_412);\n        dist = _414;\n        l = _412 / max(_414, 9.9999997473787516355514526367188e-05f).xxx;\n        float _429 = _414 / max(_385.w, 0.001000000047497451305389404296875f);\n        float _435 = clamp(1.0f - (_429 * _429), 0.0f, 1.0f);\n        atten = _435 * _435;\n        if (_394 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _449 = fa_light_texel(param_2);\n            float _459 = _449.w;\n            int param_3 = (li * 4) + 3;\n            float4 _465 = fa_light_texel(param_3);\n            float _466 = _465.x;\n            float cos_inner = _466;\n            if (_466 > 1.5f)\n            {\n                cos_inner = lerp(_459, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_459, cos_inner, dot(-l, normalize(_449.xyz)));\n        }\n    }\n    int _497;\n    if (_400)\n    {\n        _497 = 0;\n    }\n    else\n    {\n        _497 = (_394 > 1.5f) ? 2 : 1;\n    }\n    LightSample _4152 = { l, _391.xyz * atten, atten, 1.0f, dist, _497 };\n    return _4152;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _737;\n    if (i == 0)\n    {\n        _737 = _747_fa_shadow_split.x;\n    }\n    else\n    {\n        float _753;\n        if (i == 1)\n        {\n            _753 = _747_fa_shadow_split.y;\n        }\n        else\n        {\n            float _761;\n            if (i == 2)\n            {\n                _761 = _747_fa_shadow_split.z;\n            }\n            else\n            {\n                _761 = _747_fa_shadow_split.w;\n            }\n            _753 = _761;\n        }\n        _737 = _753;\n    }\n    return _737;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _794 = fa_shadow_depth(param, param_1);\n    float _798;\n    if (conv.x < 0.5f)\n    {\n        _798 = _794;\n    }\n    else\n    {\n        _798 = (conv.y * conv.z) / (conv.z - (_794 * (conv.z - conv.y)));\n    }\n    return _798;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _725 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_725), sin(_725)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _844 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _858 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _844;\n            float2 _877 = fa_shadow_vogel(param_3, param_4, param_5) * _858;\n            float2 param_6 = uv + (_877 * _747_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _889 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_889 < (zr - (length(_877) * plane)))\n            {\n                sum += _889;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _933 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _933; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _933;\n        float param_11 = _844;\n        float2 _952 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_952 * _747_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_952) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_933);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _994 = max(_747_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _999 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1005 = sqrt(1.0f - (_999 * _999));\n    float _1013 = min(_1005 / max(_999, 0.20000000298023223876953125f), 4.0f);\n    float _1018;\n    if (_747_fa_shadow_bias.y > 0.0f)\n    {\n        _1018 = _747_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1018 = 1.5f * _747_fa_shadow_info[ci].x;\n    }\n    float4 _1043 = mul(float4(world + (n * (_1018 * _1005)), 1.0f), _747_fa_shadow_mat[ci]);\n    float _1050 = _1043.x;\n    bool _1053 = _1050 < _747_fa_shadow_rect[ci].x;\n    bool _1062;\n    if (!_1053)\n    {\n        _1062 = _1050 > _747_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1062 = _1053;\n    }\n    bool _1071;\n    if (!_1062)\n    {\n        _1071 = _1043.y < _747_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1071 = _1062;\n    }\n    bool _1080;\n    if (!_1071)\n    {\n        _1080 = _1043.y > _747_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1080 = _1071;\n    }\n    bool _1087;\n    if (!_1080)\n    {\n        _1087 = _1043.z > 1.0f;\n    }\n    else\n    {\n        _1087 = _1080;\n    }\n    if (_1087)\n    {\n        return -1.0f;\n    }\n    float _1096;\n    if (_747_fa_shadow_bias.x > 0.0f)\n    {\n        _1096 = _747_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1096 = 1.5f * _747_fa_shadow_info[ci].x;\n    }\n    float2 param = _1043.xy;\n    float4 param_1 = _747_fa_shadow_rect[ci];\n    float param_2 = _1043.z - ((_1096 * (1.0f + (0.5f * _1013))) / _994);\n    float param_3 = _747_fa_shadow_info[ci].x;\n    float param_4 = _994;\n    float param_5 = _994 * 0.25f;\n    float param_6 = ((_747_fa_shadow_info[ci].x * min(_1013, 3.0f)) * 0.5f) / _994;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_747_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _747_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_511_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1524 = int(_747_fa_shadow_cfg.x + 0.5f);\n    if (_1524 < 1)\n    {\n        return 1.0f;\n    }\n    float _1540 = dot(world - _747_fa_shadow_eye.xyz, _747_fa_shadow_fwd.xyz);\n    int param = _1524 - 1;\n    if (_1540 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1552 = _1524 > 1;\n    bool _1559;\n    if (_1552)\n    {\n        _1559 = _1540 > _747_fa_shadow_split.x;\n    }\n    else\n    {\n        _1559 = _1552;\n    }\n    if (_1559)\n    {\n        ci = 1;\n    }\n    bool _1563 = _1524 > 2;\n    bool _1570;\n    if (_1563)\n    {\n        _1570 = _1540 > _747_fa_shadow_split.y;\n    }\n    else\n    {\n        _1570 = _1563;\n    }\n    if (_1570)\n    {\n        ci = 2;\n    }\n    bool _1574 = _1524 > 3;\n    bool _1581;\n    if (_1574)\n    {\n        _1581 = _1540 > _747_fa_shadow_split.z;\n    }\n    else\n    {\n        _1581 = _1574;\n    }\n    if (_1581)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1524)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1607 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1607;\n        if (_1607 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_747_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1632;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1632 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1632 = _747_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1651 = _747_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1632, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1662 = clamp((_1540 - (fa_shadow_split_at(param_7) - _1651)) / _1651, 0.0f, 1.0f);\n        if (_1662 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1524)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1683 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1683;\n                if (_1683 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1662);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1155 = _511_fa_pbr.z < 0.5f;\n    bool _1163;\n    if (!_1155)\n    {\n        _1163 = _747_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1163 = _1155;\n    }\n    if (_1163)\n    {\n        return 1.0f;\n    }\n    int param = (int(_747_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1176 = fa_light_texel(param);\n    float _1177 = _1176.x;\n    if (_1177 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1186 = int(_1177 + 0.5f);\n    int param_1 = _1186;\n    float4 _1190 = fa_light_texel(param_1);\n    int param_2 = _1186 + 1;\n    float4 _1195 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1198 = _1190.y;\n    if (_1198 > 0.0f)\n    {\n        float _1215 = 1.0f - smoothstep(0.75f * _1198, _1198, length(world - _747_fa_shadow_eye.xyz));\n        fade = _1215;\n        if (_1215 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1190.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1234 = world - fa_light_texel(param_3).xyz;\n        float3 _1237 = abs(_1234);\n        float _1239 = _1237.x;\n        float _1241 = _1237.y;\n        bool _1242 = _1239 >= _1241;\n        bool _1250;\n        if (_1242)\n        {\n            _1250 = _1239 >= _1237.z;\n        }\n        else\n        {\n            _1250 = _1242;\n        }\n        int _1251;\n        if (_1250)\n        {\n            _1251 = (_1234.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1264;\n            if (_1241 >= _1237.z)\n            {\n                _1264 = (_1234.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1264 = (_1234.z > 0.0f) ? 4 : 5;\n            }\n            _1251 = _1264;\n        }\n        face = _1251;\n    }\n    int _1283 = (_1186 + 2) + (face * 6);\n    int param_4 = _1283;\n    int param_5 = _1283 + 1;\n    int param_6 = _1283 + 3;\n    float4 _1297 = fa_light_texel(param_6);\n    int param_7 = _1283 + 4;\n    float4 _1302 = fa_light_texel(param_7);\n    int param_8 = _1283 + 5;\n    float4 _1307 = fa_light_texel(param_8);\n    float _1319 = _1307.x * max(dot(_1297, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1324 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1347 = clamp(dot(n, _1297.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1370 = min(sqrt(1.0f - (_1347 * _1347)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1297, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1373 = _1195.y;\n    float _1375;\n    if (_1373 > 0.0f)\n    {\n        _1375 = _1373;\n    }\n    else\n    {\n        _1375 = 1.5f * _1319;\n    }\n    float4 _1395 = float4(world + (n * (_1375 * sqrt(1.0f - (_1324 * _1324)))), 1.0f);\n    float _1399 = dot(_1297, _1395);\n    float _1402 = _1307.y;\n    if (_1399 < _1402)\n    {\n        return 1.0f;\n    }\n    float2 _1417 = float2(dot(fa_light_texel(param_4), _1395), dot(fa_light_texel(param_5), _1395)) / _1399.xx;\n    float _1419 = _1417.x;\n    bool _1422 = _1419 < _1302.x;\n    bool _1431;\n    if (!_1422)\n    {\n        _1431 = _1419 > _1302.z;\n    }\n    else\n    {\n        _1431 = _1422;\n    }\n    bool _1440;\n    if (!_1431)\n    {\n        _1440 = _1417.y < _1302.y;\n    }\n    else\n    {\n        _1440 = _1431;\n    }\n    bool _1449;\n    if (!_1440)\n    {\n        _1449 = _1417.y > _1302.w;\n    }\n    else\n    {\n        _1449 = _1440;\n    }\n    if (_1449)\n    {\n        return 1.0f;\n    }\n    float _1455 = _1195.x;\n    float _1457;\n    if (_1455 > 0.0f)\n    {\n        _1457 = _1455;\n    }\n    else\n    {\n        _1457 = 1.5f * _1319;\n    }\n    float2 param_10 = _1417;\n    float4 param_11 = _1302;\n    float param_12 = _1399 - (_1457 * (1.0f + (0.5f * _1370)));\n    float param_13 = _1319;\n    float param_14 = 1.0f;\n    float param_15 = _1307.z * 0.25f;\n    float param_16 = (_1319 * min(_1370, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1402, _1307.z);\n    int param_18 = int(_1190.z + 0.5f);\n    float param_19 = _1190.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _2902 = fa_lm.z > 0.5f;\n    bool _2908;\n    if (_2902)\n    {\n        int param = li;\n        _2908 = fa_light_baked(param);\n    }\n    else\n    {\n        _2908 = _2902;\n    }\n    if (_2908)\n    {\n        int param_1 = li;\n        LightSample _4208 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4208;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2930 = fa_light_sample(param_2, param_3);\n    float3 _4215 = _2930.direction;\n    float3 _4210 = _2930.color;\n    float _4217 = _2930.attenuation;\n    float _4212 = _2930.shadow;\n    int _4220 = _2930.type;\n    if ((_4220 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4215;\n        float _2944 = fa_shadow_factor(param_4, param_5);\n        _4212 = _2944;\n        _4210 *= _2944;\n    }\n    else\n    {\n        bool _2955 = _4220 != 0;\n        bool _2961;\n        if (_2955)\n        {\n            _2961 = _4217 > 0.0f;\n        }\n        else\n        {\n            _2961 = _2955;\n        }\n        if (_2961)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4215;\n            float _2973 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4212 = _2973;\n            _4210 *= _2973;\n        }\n    }\n    LightSample _4227 = { _4215, _4210, _4217, _4212, _2930._distance, _4220 };\n    return _4227;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2518 = tdh / at;\n    float _2522 = bdh / ab;\n    float _2534 = ((_2518 * _2518) + (_2522 * _2522)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _2534) * _2534);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2615 = 1.0f / alpha;\n    return ((2.0f + _2615) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _2615)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2648 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2727 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _2727) * _2727);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _2648);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _2648));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _2800 = max(dot(L.nc, l), 0.0f);\n        float _2806 = max(dot(L.nc, h), 0.0f);\n        float _2815 = ((_2806 * _2806) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _2815) * _2815)) * (0.5f / max(lerp((2.0f * _2800) * L.coat_ndv, _2800 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2800)) * _2800).xxx;\n    }\n    return result;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1915 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1918 = _1915.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1918 * _1918, exp2((-9.27999973297119140625f) * ndv)) * _1918) + _1915.y)) + _1915.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_511_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _511_fa_env_horizon.w).xyz;\n    }\n    float _1820 = rough * rough;\n    float _1850 = 0.60000002384185791015625f * _1820;\n    return lerp(lerp(_511_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_511_fa_env_horizon.xyz, _511_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1820)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1850, 0.0500000007450580596923828125f + _1850, d.y).xxx), ((_511_fa_env_sky.xyz + _511_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1820 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2401;\n        if (L.aniso >= 0.0f)\n        {\n            _2401 = L.b;\n        }\n        else\n        {\n            _2401 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2401, v), _2401), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2434 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2434.x) + (L.f90.xxx * _2434.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2489 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2489.x) + _2489.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1957 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1957.x) + _1957.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_747_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1707 = int(_747_fa_shadow_cfg.x + 0.5f);\n    float _1717 = dot(world - _747_fa_shadow_eye.xyz, _747_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1722 = _1707 > 0;\n    bool _1731;\n    if (_1722)\n    {\n        int param = _1707 - 1;\n        _1731 = _1717 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1731 = _1722;\n    }\n    if (_1731)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1738 = _1707 > 1;\n        bool _1745;\n        if (_1738)\n        {\n            _1745 = _1717 > _747_fa_shadow_split.x;\n        }\n        else\n        {\n            _1745 = _1738;\n        }\n        if (_1745)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1751 = _1707 > 2;\n        bool _1758;\n        if (_1751)\n        {\n            _1758 = _1717 > _747_fa_shadow_split.y;\n        }\n        else\n        {\n            _1758 = _1751;\n        }\n        if (_1758)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1764 = _1707 > 3;\n        bool _1771;\n        if (_1764)\n        {\n            _1771 = _1717 > _747_fa_shadow_split.z;\n        }\n        else\n        {\n            _1771 = _1764;\n        }\n        if (_1771)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3932 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3932 = -_3932;\n    }\n    float3 _3374 = normalize(_511_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3945 = { fa_world_pos, _3932, fa_world_tangent, fa_uv, fa_vertex_color, _3374, gl_FrontFacing };\n    SurfaceInput param_1 = _3945;\n    Surface _3382 = fa_standard_surface(param_1);\n    float3 _3963 = _3382.albedo;\n    float _3964 = _3382.alpha;\n    float3 _3965 = _3382.normal;\n    float _3966 = _3382.metallic;\n    float _3967 = _3382.roughness;\n    float _3968 = _3382.occlusion;\n    float3 _3969 = _3382.emission;\n    float _3970 = _3382.clearcoat;\n    float _3971 = _3382.clearcoat_roughness;\n    float3 _3972 = _3382.sheen_color;\n    float _3973 = _3382.sheen_roughness;\n    float _3974 = _3382.anisotropy;\n    float _3975 = _3382.anisotropy_rotation;\n    float _3976 = _3382.specular;\n    float _3977 = _3382.ior;\n    float3 _3978 = _3382.specular_color;\n    SurfaceInput _3953 = { fa_world_pos, _3932, fa_world_tangent, fa_uv, fa_vertex_color, _3374, gl_FrontFacing };\n    SurfaceInput param_2 = _3953;\n    Surface param_3 = _3382;\n    surface(param_2, param_3);\n    _3963 = param_3.albedo;\n    _3964 = param_3.alpha;\n    _3965 = param_3.normal;\n    _3966 = param_3.metallic;\n    _3967 = param_3.roughness;\n    _3968 = param_3.occlusion;\n    _3969 = param_3.emission;\n    _3970 = param_3.clearcoat;\n    _3971 = param_3.clearcoat_roughness;\n    _3972 = param_3.sheen_color;\n    _3973 = param_3.sheen_roughness;\n    _3974 = param_3.anisotropy;\n    _3975 = param_3.anisotropy_rotation;\n    _3976 = param_3.specular;\n    _3977 = param_3.ior;\n    _3978 = param_3.specular_color;\n    float3 result;\n    if (_511_fa_emissive.w > 0.5f)\n    {\n        result = _3963;\n    }\n    else\n    {\n        float3 _3404 = normalize(_3965);\n        float _3411 = clamp(_3966, 0.0f, 1.0f);\n        float _3415 = clamp(_3967, 0.0500000007450580596923828125f, 1.0f);\n        float _3419 = _3415 * _3415;\n        float _3423 = _3419 * _3419;\n        float _3428 = max(dot(_3404, _3374), 9.9999997473787516355514526367188e-05f);\n        float3 _3434 = _3963 * (1.0f - _3411);\n        float3 _3441 = lerp(0.039999999105930328369140625f.xxx, _3963, _3411.xxx);\n        float3 f0 = _3441;\n        SurfaceInput _3961 = { fa_world_pos, _3932, fa_world_tangent, fa_uv, fa_vertex_color, _3374, gl_FrontFacing };\n        SurfaceInput param_4 = _3961;\n        Surface _4044 = { _3963, _3964, _3965, _3966, _3967, _3968, _3969, _3970, _3971, _3972, _3973, _3974, _3975, _3976, _3977, _3978 };\n        Surface param_5 = _4044;\n        float3 param_6 = _3404;\n        float3 param_7 = _3374;\n        float param_8 = _3411;\n        float param_9 = _3415;\n        float3 param_10 = _3441;\n        FaLayers _3457 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _3404;\n        float3 lit = (fa_indirect_diffuse(param_11) * _3434) * _3968;\n        if (_3457.on)\n        {\n            lit *= _3457.base_scale;\n        }\n        int _3479 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3479; ln++)\n        {\n            int param_12 = ln;\n            int _3492 = fa_cl_light(param_12);\n            bool _3495 = fa_lm.z > 0.5f;\n            bool _3501;\n            if (_3495)\n            {\n                int param_13 = _3492;\n                _3501 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3501 = _3495;\n            }\n            if (_3501)\n            {\n                continue;\n            }\n            int param_14 = _3492;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _3932;\n            LightSample _3513 = fa_light_shadowed(param_14, param_15, param_16);\n            float3 _4137 = _3513.direction;\n            float _3521 = max(dot(_3404, _4137), 0.0f);\n            float _3527 = _3513.attenuation * _3513.shadow;\n            float3 _3532 = normalize(_4137 + _3374);\n            float _3537 = max(dot(_3404, _3532), 0.0f);\n            float _3542 = max(dot(_3374, _3532), 0.0f);\n            if (_3457.on)\n            {\n                FaLayers param_17 = _3457;\n                float3 param_18 = _3434;\n                float3 param_19 = f0;\n                float3 param_20 = _3404;\n                float3 param_21 = _3374;\n                float3 param_22 = _4137;\n                float3 param_23 = _3532;\n                float param_24 = _3521;\n                float param_25 = _3428;\n                float param_26 = _3537;\n                float param_27 = _3542;\n                float param_28 = _3419;\n                float param_29 = _3423;\n                int param_30 = _3492;\n                lit += (fa_layers_light(param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29) * (fa_light_rgb(param_30) * _3527));\n            }\n            else\n            {\n                float _3590 = ((_3537 * _3537) * (_3423 - 1.0f)) + 1.0f;\n                int param_31 = _3492;\n                lit += (((_3434 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _3542, 5.0f))) * (((_3423 / ((3.1415927410125732421875f * _3590) * _3590)) * (0.5f / max(lerp((2.0f * _3521) * _3428, _3521 + _3428, _3419), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _3521))) * fa_light_rgb(param_31)) * (_3521 * _3527));\n            }\n        }\n        if (_3457.on)\n        {\n            FaLayers param_32 = _3457;\n            float3 param_33 = _3404;\n            float3 param_34 = _3374;\n            float3 param_35 = f0;\n            float param_36 = _3415;\n            lit += (fa_layers_ibl(param_32, param_33, param_34, param_35, param_36) * _3968);\n        }\n        else\n        {\n            float3 param_37 = _3404;\n            float3 param_38 = _3374;\n            float3 param_39 = f0;\n            float param_40 = _3415;\n            lit += (fa_sky_reflection(param_37, param_38, param_39, param_40) * _3968);\n        }\n        result = lit;\n    }\n    float3 _3683 = result;\n    float3 _3684 = _3683 + _3969;\n    result = _3684;\n    float3 param_41 = _3684;\n    float3 param_42 = fa_world_pos;\n    result = fa_shadow_debug(param_41, param_42);\n    bool _3693 = _511_fa_fog.w > 0.0f;\n    bool _3700;\n    if (!_3693)\n    {\n        _3700 = _511_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3700 = _3693;\n    }\n    if (_3700)\n    {\n        float3 _3709 = fa_world_pos - _511_fa_camera_pos.xyz;\n        float _3715 = dot(_3709, _511_fa_fog_c.xyz);\n        bool _3719 = _511_fa_fog_c.w > 0.5f;\n        float _3720;\n        if (_3719)\n        {\n            _3720 = _3715;\n        }\n        else\n        {\n            _3720 = length(_3709);\n        }\n        float _3732 = _3720 - _511_fa_fog_b.x;\n        if (_3732 > 0.0f)\n        {\n            float _3741 = _511_fa_fog.w * _3732;\n            float tau = _3741 * _3741;\n            if (_511_fa_fog_b.y > 0.0f)\n            {\n                float _3757;\n                if (_3719)\n                {\n                    _3757 = fa_world_pos.y - (_511_fa_fog_c.y * _3715);\n                }\n                else\n                {\n                    _3757 = _511_fa_camera_pos.y;\n                }\n                float _3778 = lerp(_3757, fa_world_pos.y, clamp(_511_fa_fog_b.x / _3720, 0.0f, 1.0f));\n                float _3782 = fa_world_pos.y - _3778;\n                float _3787 = _3778 - _511_fa_fog_b.z;\n                float _3792 = fa_world_pos.y - _511_fa_fog_b.z;\n                bool _3795 = _3787 <= 0.0f;\n                bool _3796 = !_3795;\n                bool _3802;\n                if (_3796)\n                {\n                    _3802 = _511_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3802 = _3795;\n                }\n                float _3803;\n                if (_3802)\n                {\n                    _3803 = _511_fa_fog_b.y;\n                }\n                else\n                {\n                    _3803 = _511_fa_fog_b.y * exp(-min(_511_fa_fog_b.w * _3787, 80.0f));\n                }\n                bool _3830;\n                if (_3796)\n                {\n                    _3830 = _511_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3830 = _3795;\n                }\n                float _3831;\n                if (_3830)\n                {\n                    _3831 = _511_fa_fog_b.y * _3787;\n                }\n                else\n                {\n                    _3831 = (_511_fa_fog_b.y * (1.0f - exp(-min(_511_fa_fog_b.w * _3787, 80.0f)))) / _511_fa_fog_b.w;\n                }\n                bool _3856 = _3792 <= 0.0f;\n                bool _3863;\n                if (!_3856)\n                {\n                    _3863 = _511_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3863 = _3856;\n                }\n                float _3864;\n                if (_3863)\n                {\n                    _3864 = _511_fa_fog_b.y * _3792;\n                }\n                else\n                {\n                    _3864 = (_511_fa_fog_b.y * (1.0f - exp(-min(_511_fa_fog_b.w * _3792, 80.0f)))) / _511_fa_fog_b.w;\n                }\n                float _3891;\n                if (abs(_3782) < 0.001000000047497451305389404296875f)\n                {\n                    _3891 = _3803;\n                }\n                else\n                {\n                    _3891 = (_3864 - _3831) / _3782;\n                }\n                tau += (_3732 * max(_3891, 0.0f));\n            }\n            result = lerp(result, _511_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3964);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main",
          "d3d11_target": "vs_5_0"
        },
        "fragment_func": {
          "entry_point": "main",
          "d3d11_target": "ps_5_0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 0
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 3
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 4
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 6
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 8
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 9
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 10
          },
          {
            "slot": 11,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 11
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 12
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_149",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_195",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_511",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_747",
            "hlsl_register_b_n": 7
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
              "hlsl_register_t_n": 0
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
              "hlsl_register_t_n": 1
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
              "hlsl_register_t_n": 2
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
              "hlsl_register_t_n": 3
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
              "hlsl_register_t_n": 4
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
              "hlsl_register_t_n": 5
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
              "hlsl_register_t_n": 6
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
              "hlsl_register_t_n": 7
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
              "hlsl_register_t_n": 8
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
              "hlsl_register_t_n": 9
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 10
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _144_fa_view_proj : packoffset(c0);\n    row_major float4x4 _144_fa_light_vp : packoffset(c4);\n    float4 _144_fa_uv_scale : packoffset(c8);\n    float4 _144_fa_time : packoffset(c9);\n    float4 _144_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float2 fa_attr_uv1 : TEXCOORD9;\n    float4 fa_attr_color1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _312 = { mul(float4(position, 1.0f), model).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _144_fa_uv_scale.xy, color, position };\n    return _312;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _187 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_187, _144_fa_light_vp).z;\n    fa_pre_r0 = float3(_144_fa_light_vp[0].x, _144_fa_light_vp[1].x, _144_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_144_fa_light_vp[0].y, _144_fa_light_vp[1].y, _144_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_144_fa_light_vp[0].z, _144_fa_light_vp[1].z, _144_fa_light_vp[2].z);\n    gl_Position = mul(_187, _144_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _226_fa_camera_pos : packoffset(c0);\n    float4 _226_fa_ambient : packoffset(c1);\n    float4 _226_fa_base_color : packoffset(c2);\n    float4 _226_fa_emissive : packoffset(c3);\n    float4 _226_fa_model_emissive : packoffset(c4);\n    float4 _226_fa_pbr : packoffset(c5);\n    float4 _226_fa_maps : packoffset(c6);\n    float4 _226_fa_fog : packoffset(c7);\n    float4 _226_fa_fog_b : packoffset(c8);\n    float4 _226_fa_fog_c : packoffset(c9);\n    float4 _226_fa_counts : packoffset(c10);\n    float4 _226_fa_env_sky : packoffset(c11);\n    float4 _226_fa_env_horizon : packoffset(c12);\n    float4 _226_fa_time : packoffset(c13);\n    float4 _226_fa_cl_vpx : packoffset(c14);\n    float4 _226_fa_cl_vpy : packoffset(c15);\n    float4 _226_fa_cl_vpw : packoffset(c16);\n    float4 _226_fa_cl_fwd : packoffset(c17);\n    float4 _226_fa_cl_grid : packoffset(c18);\n    float4 _226_fa_cl_info : packoffset(c19);\n    float4 _226_fa_layers_a : packoffset(c20);\n    float4 _226_fa_layers_b : packoffset(c21);\n    float4 _226_fa_layers_c : packoffset(c22);\n    float4 _226_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _186 = fa_linear_to_srgb(param);\n        c = _186;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _195 = fa_srgb_to_linear(param_1);\n            c = _195;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _226_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _238 = fa_tex_fix(param_2, param_3);\n    float4 _744 = base_t;\n    _744.x = _238.x;\n    _744.y = _238.y;\n    _744.z = _238.z;\n    base_t = _744;\n    float4 _253 = (_744 * _226_fa_base_color) * i.vertex_color;\n    float3 _707 = i.world_normal;\n    if (_226_fa_maps.z > 0.5f)\n    {\n        float param_4 = _226_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _226_fa_maps.x;\n        float3 _752 = _290;\n        _752.x = _295.x;\n        _752.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _752;\n        _707 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _226_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _755 = mrt;\n    _755.x = _324.x;\n    _755.y = _324.y;\n    _755.z = _324.z;\n    mrt = _755;\n    float4 _354 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _226_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _226_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _712 = _226_fa_layers_a.x;\n    float _713 = _226_fa_layers_a.y;\n    float _716 = _226_fa_layers_a.z;\n    float _715 = _226_fa_layers_b.w;\n    float _718 = _226_fa_layers_c.x;\n    if (_226_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_226_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _712 *= _366.y;\n            _713 *= _366.z;\n            _715 *= _354.w;\n        }\n        if (_226_fa_layers_c.z > 1.5f)\n        {\n            _716 *= mrt.x;\n            _718 *= mrt.w;\n        }\n    }\n    Surface _737 = { _253.xyz, _253.w, _707, clamp(_226_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_226_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_226_fa_maps.y * (_366.x - 1.0f)), _226_fa_emissive.xyz + (_226_fa_model_emissive.xyz * _396), _712, _713, _226_fa_layers_b.xyz, _715, _716, _226_fa_layers_a.w, _718, _226_fa_layers_c.y, _226_fa_layers_d.xyz };\n    return _737;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0f));\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _618 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _618 = -_618;\n    }\n    float3 _530 = normalize(_226_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _631 = { fa_world_pos, _618, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param = _631;\n    SurfaceInput _639 = { fa_world_pos, _618, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param_1 = _639;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _545 = normalize(param_2.normal);\n    float3 _560 = normalize(float3(dot(fa_pre_r0, _545), dot(fa_pre_r1, _545), dot(fa_pre_r2, _545)));\n    float _572 = _560.z;\n    float2 e = _560.xy / ((abs(_560.x) + abs(_560.y)) + abs(_572)).xx;\n    if (_572 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main",
          "d3d11_target": "vs_5_0"
        },
        "fragment_func": {
          "entry_point": "main",
          "d3d11_target": "ps_5_0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 0
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 3
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 4
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 6
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 8
          },
          {
            "slot": 9,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 9
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 10
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_144",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_226",
            "hlsl_register_b_n": 1
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
              "hlsl_register_t_n": 0
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
              "hlsl_register_t_n": 1
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
              "hlsl_register_t_n": 2
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
              "hlsl_register_t_n": 3
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
              "hlsl_register_t_n": 4
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _149_fa_view_proj : packoffset(c0);\n    row_major float4x4 _149_fa_light_vp : packoffset(c4);\n    float4 _149_fa_uv_scale : packoffset(c8);\n    float4 _149_fa_time : packoffset(c9);\n    float4 _149_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _195_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float2 fa_attr_uv1 : TEXCOORD11;\n    float4 fa_attr_color1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _186 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_195_fa_joint_rows[_186] * weights[i]);\n        r1 += (_195_fa_joint_rows[_186 + 1] * weights[i]);\n        r2 += (_195_fa_joint_rows[_186 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _433 = { mul(float4(position, 1.0f), model).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _149_fa_uv_scale.xy, color, position };\n    return _433;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _300 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_300, _149_fa_light_vp).z;\n    fa_pre_r0 = float3(_149_fa_light_vp[0].x, _149_fa_light_vp[1].x, _149_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_149_fa_light_vp[0].y, _149_fa_light_vp[1].y, _149_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_149_fa_light_vp[0].z, _149_fa_light_vp[1].z, _149_fa_light_vp[2].z);\n    gl_Position = mul(_300, _149_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _226_fa_camera_pos : packoffset(c0);\n    float4 _226_fa_ambient : packoffset(c1);\n    float4 _226_fa_base_color : packoffset(c2);\n    float4 _226_fa_emissive : packoffset(c3);\n    float4 _226_fa_model_emissive : packoffset(c4);\n    float4 _226_fa_pbr : packoffset(c5);\n    float4 _226_fa_maps : packoffset(c6);\n    float4 _226_fa_fog : packoffset(c7);\n    float4 _226_fa_fog_b : packoffset(c8);\n    float4 _226_fa_fog_c : packoffset(c9);\n    float4 _226_fa_counts : packoffset(c10);\n    float4 _226_fa_env_sky : packoffset(c11);\n    float4 _226_fa_env_horizon : packoffset(c12);\n    float4 _226_fa_time : packoffset(c13);\n    float4 _226_fa_cl_vpx : packoffset(c14);\n    float4 _226_fa_cl_vpy : packoffset(c15);\n    float4 _226_fa_cl_vpw : packoffset(c16);\n    float4 _226_fa_cl_fwd : packoffset(c17);\n    float4 _226_fa_cl_grid : packoffset(c18);\n    float4 _226_fa_cl_info : packoffset(c19);\n    float4 _226_fa_layers_a : packoffset(c20);\n    float4 _226_fa_layers_b : packoffset(c21);\n    float4 _226_fa_layers_c : packoffset(c22);\n    float4 _226_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _186 = fa_linear_to_srgb(param);\n        c = _186;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _195 = fa_srgb_to_linear(param_1);\n            c = _195;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _226_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _238 = fa_tex_fix(param_2, param_3);\n    float4 _744 = base_t;\n    _744.x = _238.x;\n    _744.y = _238.y;\n    _744.z = _238.z;\n    base_t = _744;\n    float4 _253 = (_744 * _226_fa_base_color) * i.vertex_color;\n    float3 _707 = i.world_normal;\n    if (_226_fa_maps.z > 0.5f)\n    {\n        float param_4 = _226_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _226_fa_maps.x;\n        float3 _752 = _290;\n        _752.x = _295.x;\n        _752.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _752;\n        _707 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _226_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _755 = mrt;\n    _755.x = _324.x;\n    _755.y = _324.y;\n    _755.z = _324.z;\n    mrt = _755;\n    float4 _354 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _226_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _226_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _712 = _226_fa_layers_a.x;\n    float _713 = _226_fa_layers_a.y;\n    float _716 = _226_fa_layers_a.z;\n    float _715 = _226_fa_layers_b.w;\n    float _718 = _226_fa_layers_c.x;\n    if (_226_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_226_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _712 *= _366.y;\n            _713 *= _366.z;\n            _715 *= _354.w;\n        }\n        if (_226_fa_layers_c.z > 1.5f)\n        {\n            _716 *= mrt.x;\n            _718 *= mrt.w;\n        }\n    }\n    Surface _737 = { _253.xyz, _253.w, _707, clamp(_226_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_226_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_226_fa_maps.y * (_366.x - 1.0f)), _226_fa_emissive.xyz + (_226_fa_model_emissive.xyz * _396), _712, _713, _226_fa_layers_b.xyz, _715, _716, _226_fa_layers_a.w, _718, _226_fa_layers_c.y, _226_fa_layers_d.xyz };\n    return _737;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0f));\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _618 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _618 = -_618;\n    }\n    float3 _530 = normalize(_226_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _631 = { fa_world_pos, _618, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param = _631;\n    SurfaceInput _639 = { fa_world_pos, _618, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param_1 = _639;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _545 = normalize(param_2.normal);\n    float3 _560 = normalize(float3(dot(fa_pre_r0, _545), dot(fa_pre_r1, _545), dot(fa_pre_r2, _545)));\n    float _572 = _560.z;\n    float2 e = _560.xy / ((abs(_560.x) + abs(_560.y)) + abs(_572)).xx;\n    if (_572 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main",
          "d3d11_target": "vs_5_0"
        },
        "fragment_func": {
          "entry_point": "main",
          "d3d11_target": "ps_5_0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 0
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 3
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 4
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 6
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 8
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 9
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 10
          },
          {
            "slot": 11,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 11
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 12
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_149",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_195",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_226",
            "hlsl_register_b_n": 1
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
              "hlsl_register_t_n": 0
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
              "hlsl_register_t_n": 1
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
              "hlsl_register_t_n": 2
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
              "hlsl_register_t_n": 3
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
              "hlsl_register_t_n": 4
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _135_fa_view_proj : packoffset(c0);\n    row_major float4x4 _135_fa_light_vp : packoffset(c4);\n    float4 _135_fa_uv_scale : packoffset(c8);\n    float4 _135_fa_time : packoffset(c9);\n    float4 _135_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n    float2 fa_attr_uv1 : TEXCOORD9;\n    float4 fa_attr_color1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _264 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _135_fa_uv_scale.xy, color, position };\n    return _264;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _135_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
      "fs": "static float4 gl_FragCoord;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid frag_main()\n{\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main",
          "d3d11_target": "vs_5_0"
        },
        "fragment_func": {
          "entry_point": "main",
          "d3d11_target": "ps_5_0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 0
          },
          {
            "slot": 1,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 3
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 4
          },
          {
            "slot": 5,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 6
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 8
          },
          {
            "slot": 9,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 9
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 10
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_135",
            "hlsl_register_b_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _140_fa_view_proj : packoffset(c0);\n    row_major float4x4 _140_fa_light_vp : packoffset(c4);\n    float4 _140_fa_uv_scale : packoffset(c8);\n    float4 _140_fa_time : packoffset(c9);\n    float4 _140_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _186_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n    float2 fa_attr_uv1 : TEXCOORD11;\n    float4 fa_attr_color1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _177 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_186_fa_joint_rows[_177] * weights[i]);\n        r1 += (_186_fa_joint_rows[_177 + 1] * weights[i]);\n        r2 += (_186_fa_joint_rows[_177 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _79 = cross(model[1].xyz, model[2].xyz);\n    float _85 = (dot(model[0].xyz, _79) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _385 = { mul(float4(position, 1.0f), model).xyz, (((_79 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _85, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _85), texcoord0 * _140_fa_uv_scale.xy, color, position };\n    return _385;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mul(float4(param_8.world_pos, 1.0f), _140_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
      "fs": "static float4 gl_FragCoord;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid frag_main()\n{\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main",
          "d3d11_target": "vs_5_0"
        },
        "fragment_func": {
          "entry_point": "main",
          "d3d11_target": "ps_5_0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 0
          },
          {
            "slot": 1,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 3
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 4
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 6
          },
          {
            "slot": 7,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 8
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 9
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 10
          },
          {
            "slot": 11,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 11
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 12
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_140",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_186",
            "hlsl_register_b_n": 3
          }
        ]
      }
    }
  }
}
