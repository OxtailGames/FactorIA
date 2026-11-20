{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "63c8ed9ef72f0fba56beb38b3018a9ae9876604a67ae71ca005757f89f9b9e64",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3356[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _365_fa_camera_pos : packoffset(c0);\n    float4 _365_fa_ambient : packoffset(c1);\n    float4 _365_fa_base_color : packoffset(c2);\n    float4 _365_fa_emissive : packoffset(c3);\n    float4 _365_fa_model_emissive : packoffset(c4);\n    float4 _365_fa_pbr : packoffset(c5);\n    float4 _365_fa_maps : packoffset(c6);\n    float4 _365_fa_fog : packoffset(c7);\n    float4 _365_fa_fog_b : packoffset(c8);\n    float4 _365_fa_fog_c : packoffset(c9);\n    float4 _365_fa_counts : packoffset(c10);\n    float4 _365_fa_env_sky : packoffset(c11);\n    float4 _365_fa_env_horizon : packoffset(c12);\n    float4 _365_fa_time : packoffset(c13);\n    float4 _365_fa_cl_vpx : packoffset(c14);\n    float4 _365_fa_cl_vpy : packoffset(c15);\n    float4 _365_fa_cl_vpw : packoffset(c16);\n    float4 _365_fa_cl_fwd : packoffset(c17);\n    float4 _365_fa_cl_grid : packoffset(c18);\n    float4 _365_fa_cl_info : packoffset(c19);\n    float4 _365_fa_layers_a : packoffset(c20);\n    float4 _365_fa_layers_b : packoffset(c21);\n    float4 _365_fa_layers_c : packoffset(c22);\n    float4 _365_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2062_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2062_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2062_fa_shadow_info[4] : packoffset(c20);\n    float4 _2062_fa_shadow_split : packoffset(c24);\n    float4 _2062_fa_shadow_cfg : packoffset(c25);\n    float4 _2062_fa_shadow_bias : packoffset(c26);\n    float4 _2062_fa_shadow_eye : packoffset(c27);\n    float4 _2062_fa_shadow_fwd : packoffset(c28);\n    float4 _2062_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1333 = _365_fa_cl_info.x < 0.0f;\n    bool _1340;\n    if (!_1333)\n    {\n        _1340 = _365_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1340 = _1333;\n    }\n    bool _1348;\n    if (!_1340)\n    {\n        _1348 = _365_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1348 = _1340;\n    }\n    bool _1355;\n    if (!_1348)\n    {\n        _1355 = _365_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1355 = _1348;\n    }\n    bool _1362;\n    if (!_1355)\n    {\n        _1362 = _365_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1362 = _1355;\n    }\n    if (_1362)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1372 = float4(world_pos, 1.0f);\n    float _1378 = dot(_365_fa_cl_vpw, _1372);\n    if (!(_1378 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1400 = float2(dot(_365_fa_cl_vpx, _1372), dot(_365_fa_cl_vpy, _1372)) / _1378.xx;\n    int _1404 = int(_365_fa_cl_grid.x);\n    int _1408 = int(_365_fa_cl_grid.y);\n    int param = (int(_365_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_365_fa_cl_fwd.xyz, world_pos) + _365_fa_cl_fwd.w, _365_fa_cl_grid.w) / _365_fa_cl_grid.w) * _365_fa_cl_grid.z)), 0, int(_365_fa_cl_info.y) - 1) * _1408) + clamp(int(floor(((_1400.y * 0.5f) + 0.5f) * _365_fa_cl_grid.y)), 0, _1408 - 1)) * _1404)) + clamp(int(floor(((_1400.x * 0.5f) + 0.5f) * _365_fa_cl_grid.x)), 0, _1404 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1484 = fa_cluster_texel(param);\n    return int2(int(_1484.x), int(_1484.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_365_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3888 = fa_cluster_lookup(param);\n    fa_cl_slot = _3888.x;\n    fa_cl_local = _3888.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4044 = fa_linear_to_srgb(param);\n        c = _4044;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4052 = fa_srgb_to_linear(param_1);\n            c = _4052;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _297;\n    if (i.front_facing)\n    {\n        _297 = i.world_normal;\n    }\n    else\n    {\n        _297 = -i.world_normal;\n    }\n    float3 _321 = normalize(i.world_tangent.xyz - (_297 * dot(_297, i.world_tangent.xyz)));\n    float3 _349 = normalize(((_321 * m.x) + ((cross(_297, _321) * i.world_tangent.w) * m.y)) + (_297 * m.z));\n    float3 _352;\n    if (i.front_facing)\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _365_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4083 = fa_tex_fix(param_2, param_3);\n    float4 _5198 = base_t;\n    _5198.x = _4083.x;\n    _5198.y = _4083.y;\n    _5198.z = _4083.z;\n    base_t = _5198;\n    float4 _4097 = (_5198 * _365_fa_base_color) * i.vertex_color;\n    float3 _5050 = i.world_normal;\n    if (_365_fa_maps.z > 0.5f)\n    {\n        float param_4 = _365_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4129 = fa_tex_fix(param_6, param_7);\n        float3 _4132 = (_4129 * 2.0f) - 1.0f.xxx;\n        float2 _4137 = _4132.xy * _365_fa_maps.x;\n        float3 _5206 = _4132;\n        _5206.x = _4137.x;\n        _5206.y = _4137.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5206;\n        _5050 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _365_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4165 = fa_tex_fix(param_12, param_13);\n    float4 _5209 = mrt;\n    _5209.x = _4165.x;\n    _5209.y = _4165.y;\n    _5209.z = _4165.z;\n    mrt = _5209;\n    float4 _4193 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _365_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4193.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4204 = fa_tex_fix(param_16, param_17);\n    float param_18 = _365_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4234 = fa_tex_fix(param_20, param_21);\n    float _5055 = _365_fa_layers_a.x;\n    float _5056 = _365_fa_layers_a.y;\n    float _5059 = _365_fa_layers_a.z;\n    float _5058 = _365_fa_layers_b.w;\n    float _5061 = _365_fa_layers_c.x;\n    if (_365_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_365_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5055 *= _4204.y;\n            _5056 *= _4204.z;\n            _5058 *= _4193.w;\n        }\n        if (_365_fa_layers_c.z > 1.5f)\n        {\n            _5059 *= mrt.x;\n            _5061 *= mrt.w;\n        }\n    }\n    Surface _5080 = { _4097.xyz, _4097.w, _5050, clamp(_365_fa_pbr.x * _4165.z, 0.0f, 1.0f), clamp(_365_fa_pbr.y * _4165.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_365_fa_maps.y * (_4204.x - 1.0f)), _365_fa_emissive.xyz + (_365_fa_model_emissive.xyz * _4234), _5055, _5056, _365_fa_layers_b.xyz, _5058, _5059, _365_fa_layers_a.w, _5061, _365_fa_layers_c.y, _365_fa_layers_d.xyz };\n    return _5080;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1564 = rect.zw - rect.xy;\n    float2 _1568 = _1564 * atlas;\n    float2 _1572 = ddx * _1568;\n    float2 _1576 = ddy * _1568;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1564), clamp(0.5f * log2(max(max(dot(_1572, _1572), dot(_1576, _1576)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1609 = _365_fa_counts.y < 0.5f;\n    bool _1616;\n    if (!_1609)\n    {\n        _1616 = _365_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1616 = _1609;\n    }\n    if (_1616)\n    {\n        return;\n    }\n    float3 _1622 = ddx(world_pos);\n    float3 _1625 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1629 = fa_cluster_texel(param);\n    int _1633 = int(_1629.w);\n    if (_1633 < 1)\n    {\n        return;\n    }\n    int _1643 = int(_365_fa_counts.y + 0.5f);\n    int param_1 = _1643;\n    float4 _1647 = fa_light_texel(param_1);\n    float2 _1650 = _1647.yz;\n    int _1654 = int(_1647.w);\n    int param_2 = _1643 + 1;\n    float4 _1659 = fa_light_texel(param_2);\n    float _1660 = _1659.x;\n    int _1666 = int(_365_fa_counts.w + 0.5f) - 1;\n    int _1670 = int(_1629.z);\n    float3 _1935;\n    for (int k = 0; k < _1633; k++)\n    {\n        int _1683 = _1670 + k;\n        int param_3 = _1654 + (_1683 >> 2);\n        int _1700 = (_1643 + 2) + (int(fa_light_texel(param_3)[_1683 & 3]) * 7);\n        int param_4 = _1700 + 6;\n        float4 _1705 = fa_light_texel(param_4);\n        if (((int(_1705.w + 0.5f) >> _1666) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1700;\n        float4 _1720 = fa_light_texel(param_5);\n        int param_6 = _1700 + 1;\n        float4 _1725 = fa_light_texel(param_6);\n        int param_7 = _1700 + 2;\n        float4 _1730 = fa_light_texel(param_7);\n        float3 _1733 = _1720.xyz;\n        float _1738 = dot(_1733, world_pos) + _1720.w;\n        float3 _1740 = _1725.xyz;\n        float _1745 = dot(_1740, world_pos) + _1725.w;\n        float3 _1747 = _1730.xyz;\n        float _1752 = dot(_1747, world_pos) + _1730.w;\n        bool _1757 = abs(_1738) > 0.5f;\n        bool _1765;\n        if (!_1757)\n        {\n            _1765 = abs(_1745) > 0.5f;\n        }\n        else\n        {\n            _1765 = _1757;\n        }\n        bool _1773;\n        if (!_1765)\n        {\n            _1773 = abs(_1752) > 0.5f;\n        }\n        else\n        {\n            _1773 = _1765;\n        }\n        if (_1773)\n        {\n            continue;\n        }\n        float _1788 = clamp(dot(geo_normal, normalize(_1747)) * _1705.z, 0.0f, 1.0f);\n        if (_1788 <= 0.0f)\n        {\n            continue;\n        }\n        float _1808 = (clamp((0.5f - abs(_1752)) * 10.0f, 0.0f, 1.0f) * _1788) * _1705.x;\n        float2 _1816 = float2(_1738 + 0.5f, 0.5f - _1745);\n        float2 _1826 = float2(dot(_1733, _1622), dot(_1740, _1622));\n        float2 _1836 = float2(dot(_1733, _1625), dot(_1740, _1625));\n        int param_8 = _1700 + 5;\n        float4 _1841 = fa_light_texel(param_8);\n        int param_9 = _1700 + 3;\n        float4 _1846 = fa_light_texel(param_9);\n        int param_10 = _1700 + 4;\n        float4 _1851 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1841.xyz;\n        bool _1861 = _1846.z > _1846.x;\n        if (_1861)\n        {\n            float4 param_11 = _1846;\n            float2 param_12 = _1816;\n            float2 param_13 = _1650;\n            float2 param_14 = _1826;\n            float2 param_15 = _1836;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1660 > 0.5f) && (_1660 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1887 = fa_dc_to_linear(param_16);\n                float4 _5130 = tx;\n                _5130.x = _1887.x;\n                _5130.y = _1887.y;\n                _5130.z = _1887.z;\n                tx = _5130;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1808 * tex_a) * _1841.w, 0.0f, 1.0f).xxx);\n        if (_1851.z > _1851.x)\n        {\n            float4 param_17 = _1851;\n            float2 param_18 = _1816;\n            float2 param_19 = _1650;\n            float2 param_20 = _1826;\n            float2 param_21 = _1836;\n            float4 _1931 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1660 > 1.5f)\n            {\n                float3 param_22 = _1931.xyz;\n                float3 _1941 = fa_dc_to_srgb(param_22);\n                _1935 = _1941;\n            }\n            else\n            {\n                _1935 = _1931.xyz;\n            }\n            float3 _1950 = (_1935 * 2.0f) - 1.0f.xxx;\n            float2 _1955 = _1950.xy * _1705.y;\n            float3 _1977 = (normalize(_1733) * _1955.x) + (normalize(_1740) * _1955.y);\n            float3 _1980 = normalize(normal);\n            normal = normalize(lerp(_1980, normalize((_1980 * max(_1950.z, 0.0500000007450580596923828125f)) + (_1977 - (_1980 * dot(_1980, _1977)))), clamp(_1808 * (_1861 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_365_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _365_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3281 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3289 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3292 = int(_3281);\n    int _3295 = int(_3289);\n    float _3305 = _3289 - float(_3295);\n    int _3361 = (_3292 * 9) + _3295;\n    int _3381 = ((_3292 + 1) * 9) + _3295;\n    return lerp(lerp(_3356[_3361], _3356[_3361 + 1], _3305), lerp(_3356[_3381], _3356[_3381 + 1], _3305), _3281 - float(_3292));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4909 = false;\n    float _4910 = 1.0f;\n    float _4911 = 1.0f;\n    float _4912 = 1.0f;\n    float _4913 = 0.0f;\n    float _4914 = 0.0f;\n    float _4915 = 0.0f;\n    float _4916 = 0.0f;\n    float _4918 = 1.0f;\n    bool _4919 = false;\n    float3 _4920 = 0.0f.xxx;\n    float _4921 = 1.0f;\n    float _4922 = 1.0f;\n    float _4923 = 1.0f;\n    float _4924 = 0.0f;\n    float _4925 = 0.0f;\n    float3 _4926 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4927 = float3(0.0f, 0.0f, 1.0f);\n    float _4928 = 1.0f;\n    float _4929 = 1.0f;\n    float _3432 = clamp(s.specular, 0.0f, 1.0f);\n    float _3436 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3441 = (_3432 != 1.0f) || (_3436 != 1.5f);\n    bool _3450;\n    if (!_3441)\n    {\n        _3450 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3450 = _3441;\n    }\n    if (_3450)\n    {\n        float _3458 = (_3436 - 1.0f) / (_3436 + 1.0f);\n        f0 = lerp(min((_3458 * _3458).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3432, s.albedo, metallic.xxx);\n        _4910 = lerp(_3432, 1.0f, metallic);\n        _4909 = true;\n    }\n    float _3485 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3485 > 0.0f)\n    {\n        float _3493 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4913 = _3485;\n        _4914 = _3493;\n        float _3500 = _3493 * _3493;\n        _4915 = _3500;\n        _4916 = _3500 * _3500;\n        float _3512 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4918 = _3512;\n        _4911 = 1.0f - (_3485 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3512, 0.0f, 1.0f), 5.0f))));\n        _4909 = true;\n    }\n    float3 _3532 = max(s.sheen_color, 0.0f.xxx);\n    float _3541 = max(_3532.x, max(_3532.y, _3532.z));\n    if (_3541 > 0.0f)\n    {\n        float _3549 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4919 = true;\n        _4920 = _3532;\n        _4921 = _3549;\n        _4922 = _3549 * _3549;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3549;\n        float _3566 = fa_sheen_albedo(param, param_1);\n        _4924 = _3566;\n        _4923 = 1.0f - min(_3541 * _3566, 1.0f);\n        _4909 = true;\n    }\n    _4912 = _4911 * _4923;\n    float _3585 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3585 != 0.0f)\n    {\n        float3 _3600 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3600;\n        if (dot(_3600, _3600) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3612 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3612.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3612.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3612.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3616 = t;\n        float3 _3617 = normalize(_3616);\n        t = _3617;\n        float3 _3642 = normalize((_3617 * cos(s.anisotropy_rotation)) + ((cross(n, _3617) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4926 = _3642;\n        _4927 = cross(n, _3642);\n        float _3652 = roughness * roughness;\n        float _3658 = lerp(_3652, 1.0f, _3585 * _3585);\n        bool _3660 = _3585 > 0.0f;\n        _4928 = _3660 ? _3658 : _3652;\n        _4929 = _3660 ? _3652 : _3658;\n        _4925 = _3585;\n        _4909 = true;\n    }\n    FaLayers _4951 = { _4909, _4910, _4911, _4912, _4913, _4914, _4915, _4916, i.world_normal, _4918, _4919, _4920, _4921, _4922, _4923, _4924, _4925, _4926, _4927, _4928, _4929 };\n    return _4951;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3213 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3216 = _3213.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3216 * _3216, exp2((-9.27999973297119140625f) * ndv)) * _3216) + _3213.y)) + _3213.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_365_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _365_fa_env_horizon.w).xyz;\n    }\n    float _3119 = rough * rough;\n    float _3149 = 0.60000002384185791015625f * _3119;\n    return lerp(lerp(_365_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_365_fa_env_horizon.xyz, _365_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3119)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3149, 0.0500000007450580596923828125f + _3149, d.y).xxx), ((_365_fa_env_sky.xyz + _365_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3119 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3693;\n        if (L.aniso >= 0.0f)\n        {\n            _3693 = L.b;\n        }\n        else\n        {\n            _3693 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3693, v), _3693), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3726 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3726.x) + (L.f90.xxx * _3726.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3781 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3781.x) + _3781.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3255 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3255.x) + _3255.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3810 = clamp(s.metallic, 0.0f, 1.0f);\n    float _3814 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3821 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _3810.xxx);\n    float3 f0 = _3821;\n    float3 _3825 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3825;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3810;\n    float param_5 = _3814;\n    float3 param_6 = _3821;\n    FaLayers _3842 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3842.on)\n    {\n        FaLayers param_7 = _3842;\n        float3 param_8 = _3825;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3814;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3825;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3814;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_365_fa_cl_info.x) + int(_365_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_365_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _427_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _427_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _593 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _606 = (c - (ru * hx)) - p;\n        float3 _612 = ru * (2.0f * hx);\n        float _618 = max(dot(_612, _612), 9.9999999392252902907785028219223e-09f);\n        float _622 = dot(_606, _612);\n        float t = clamp((-_622) / _618, 0.0f, 1.0f);\n        if (_593)\n        {\n            float _637 = dot(r, _612);\n            float _643 = _618 - (_637 * _637);\n            if (abs(_643) > (9.9999997473787516355514526367188e-06f * _618))\n            {\n                t = clamp(((dot(r, _606) * _637) - _622) / _643, 0.0f, 1.0f);\n            }\n        }\n        return (p + _606) + (_612 * t);\n    }\n    float3 q = p;\n    float _675 = dot(r, axis);\n    bool _683;\n    if (_593)\n    {\n        _683 = abs(_675) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _683 = _593;\n    }\n    if (_683)\n    {\n        float _693 = dot(c - p, axis) / _675;\n        if (_693 > 0.0f)\n        {\n            q = p + (r * _693);\n        }\n    }\n    float3 _706 = q - c;\n    float2 xy = float2(dot(_706, ru), dot(_706, uu));\n    if (shape > 0.5f)\n    {\n        float _721 = length(xy);\n        if (_721 > hx)\n        {\n            xy *= (hx / _721);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _514 = abs(d);\n    float _516 = _514.x;\n    float _518 = _514.y;\n    bool _519 = _516 >= _518;\n    bool _527;\n    if (_519)\n    {\n        _527 = _516 >= _514.z;\n    }\n    else\n    {\n        _527 = _519;\n    }\n    int _528;\n    if (_527)\n    {\n        _528 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _541;\n        if (_518 >= _514.z)\n        {\n            _541 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _541 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _528 = _541;\n    }\n    return _528;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _467 = dot(d, right);\n    float _471 = dot(d, up);\n    float _482;\n    if (((_467 * _467) + (_471 * _471)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _482 = atan2(_471, _467) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _482 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_482 - floor(_482)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _759 = fa_light_base(param);\n    bool _763 = _365_fa_ambient.w > 4.5f;\n    int param_1 = _759;\n    float4 _767 = fa_light_texel(param_1);\n    int param_2 = _759 + 1;\n    float4 _772 = fa_light_texel(param_2);\n    float _775 = _772.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _787 = _763 && (_775 > 2.5f);\n    fa_light_is_area = _787;\n    bool _789 = _775 < 0.5f;\n    float3 l;\n    if (_789)\n    {\n        l = normalize(_767.xyz);\n        if (_763)\n        {\n            int param_3 = _759 + 6;\n            float4 _803 = fa_light_texel(param_3);\n            if (_803.z > 0.5f)\n            {\n                int param_4 = _759 + 4;\n                float4 _813 = fa_light_texel(param_4);\n                int param_5 = _759 + 5;\n                float4 _818 = fa_light_texel(param_5);\n                float2 param_6 = _803.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _813.xyz) * _813.w, (-dot(world_pos, _818.xyz)) * _818.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _848 = _767.xyz;\n        float3 _850 = _848 - world_pos;\n        float3 to_light = _850;\n        float _853 = length(_850);\n        float reach = _853;\n        bool front = true;\n        if (_787)\n        {\n            int param_8 = _759 + 7;\n            reach = max(_853 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _759 + 4;\n            float4 _877 = fa_light_texel(param_9);\n            int param_10 = _759 + 5;\n            float4 _882 = fa_light_texel(param_10);\n            int param_11 = _759 + 6;\n            float4 _887 = fa_light_texel(param_11);\n            float _888 = _887.w;\n            int param_12 = _759 + 2;\n            float3 _895 = normalize(fa_light_texel(param_12).xyz);\n            bool _897 = _888 > 1.5f;\n            bool _905;\n            if (!_897)\n            {\n                _905 = dot(_895, to_light) < 0.0f;\n            }\n            else\n            {\n                _905 = _897;\n            }\n            front = _905;\n            float3 r = 0.0f.xxx;\n            if (dot(n, n) > 0.5f)\n            {\n                r = reflect(-normalize(_365_fa_camera_pos.xyz - world_pos), normalize(n));\n            }\n            float3 param_13 = _848;\n            float3 param_14 = _895;\n            float3 param_15 = _877.xyz;\n            float3 param_16 = _882.xyz;\n            float param_17 = _877.w;\n            float param_18 = _882.w;\n            float param_19 = _888;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _952 = length(to_light);\n        dist = _952;\n        l = to_light / max(_952, 9.9999997473787516355514526367188e-05f).xxx;\n        float _966 = reach / max(_767.w, 0.001000000047497451305389404296875f);\n        float _972 = clamp(1.0f - (_966 * _966), 0.0f, 1.0f);\n        float _974;\n        if (front)\n        {\n            _974 = _972 * _972;\n        }\n        else\n        {\n            _974 = 0.0f;\n        }\n        atten = _974;\n        bool _985 = _775 < 2.5f;\n        if ((_775 > 1.5f) && _985)\n        {\n            int param_22 = _759 + 2;\n            float4 _993 = fa_light_texel(param_22);\n            float _1003 = _993.w;\n            int param_23 = _759 + 3;\n            float4 _1008 = fa_light_texel(param_23);\n            float _1009 = _1008.x;\n            float cos_inner = _1009;\n            if (_1009 > 1.5f)\n            {\n                cos_inner = lerp(_1003, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1003, cos_inner, dot(-l, normalize(_993.xyz)));\n        }\n        if (_763 && (_775 < 1.5f))\n        {\n            int param_24 = _759 + 6;\n            float4 _1033 = fa_light_texel(param_24);\n            if (_1033.z > 0.5f)\n            {\n                float3 _1041 = -to_light;\n                int param_25 = _759 + 4;\n                int param_26 = _759 + 5;\n                float3 _1055 = fa_light_texel(param_25).xyz;\n                float3 _1059 = fa_light_texel(param_26).xyz;\n                float3 _1068 = float3(dot(_1041, _1055), dot(_1041, _1059), dot(_1041, cross(_1055, _1059)));\n                float3 param_27 = _1068;\n                int _1072 = fa_cube_face(param_27);\n                int param_28 = _1072;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1099 = float2(dot(_1068, cross(param_29, param_30)), dot(_1068, param_30)) / max(dot(_1068, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1103 = _1072 / 3;\n                float2 param_31 = _1033.xy + (float2(float(_1072 - (_1103 * 3)), float(_1103)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1099.x), 0.5f - (0.5f * _1099.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _759 + 7;\n            float4 _1133 = fa_light_texel(param_33);\n            if (_1133.z > 0.5f)\n            {\n                int param_34 = _759 + 2;\n                int param_35 = _759 + 4;\n                int param_36 = _759 + 5;\n                float2 param_37 = _1133.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_763 && _985)\n            {\n                int param_42 = _759 + 6;\n                float4 _1180 = fa_light_texel(param_42);\n                int param_43 = _759 + 7;\n                float4 _1185 = fa_light_texel(param_43);\n                bool _1188 = _1180.z > 0.5f;\n                bool _1195;\n                if (!_1188)\n                {\n                    _1195 = _1185.z > 0.5f;\n                }\n                else\n                {\n                    _1195 = _1188;\n                }\n                if (_1195)\n                {\n                    int param_44 = _759 + 2;\n                    float4 _1202 = fa_light_texel(param_44);\n                    float3 _1206 = normalize(_1202.xyz);\n                    int param_45 = _759 + 4;\n                    float4 _1211 = fa_light_texel(param_45);\n                    int param_46 = _759 + 5;\n                    float4 _1216 = fa_light_texel(param_46);\n                    if (_1188)\n                    {\n                        float3 _1224 = -to_light;\n                        float _1231 = _1202.w;\n                        float _1247 = 0.5f / max(dot(_1224, _1206) * (sqrt(max(1.0f - (_1231 * _1231), 0.0f)) / max(_1231, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1180.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1224, _1211.xyz) * _1247), 0.5f - (dot(_1224, _1216.xyz) * _1247));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1185.z > 0.5f)\n                    {\n                        float2 param_49 = _1185.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1206;\n                        float3 param_52 = _1211.xyz;\n                        float3 param_53 = _1216.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4897 = _772.xyz * atten;\n    if (_763)\n    {\n        _4897 *= fa_light_tint;\n    }\n    int _1315;\n    if (_789)\n    {\n        _1315 = 0;\n    }\n    else\n    {\n        _1315 = ((_775 > 1.5f) && (_775 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4908 = { l, _4897, atten, 1.0f, dist, _1315 };\n    return _4908;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2052;\n    if (i == 0)\n    {\n        _2052 = _2062_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2068;\n        if (i == 1)\n        {\n            _2068 = _2062_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2076;\n            if (i == 2)\n            {\n                _2076 = _2062_fa_shadow_split.z;\n            }\n            else\n            {\n                _2076 = _2062_fa_shadow_split.w;\n            }\n            _2068 = _2076;\n        }\n        _2052 = _2068;\n    }\n    return _2052;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2109 = fa_shadow_depth(param, param_1);\n    float _2113;\n    if (conv.x < 0.5f)\n    {\n        _2113 = _2109;\n    }\n    else\n    {\n        _2113 = (conv.y * conv.z) / (conv.z - (_2109 * (conv.z - conv.y)));\n    }\n    return _2113;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2040 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2040), sin(_2040)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2159 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2168;\n        if (k < 0.0f)\n        {\n            _2168 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2168 = k;\n        }\n        float _2188 = clamp((_2168 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2159;\n            float2 _2207 = fa_shadow_vogel(param_3, param_4, param_5) * _2188;\n            float2 param_6 = uv + (_2207 * _2062_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2219 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2219 < (zr - (length(_2207) * plane)))\n            {\n                sum += _2219;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2245 = sum / cnt;\n        float _2255;\n        if (k < 0.0f)\n        {\n            _2255 = (-k) / max(_2245, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2255 = k;\n        }\n        radius = clamp(((max(zr - _2245, 0.0f) * unit) * _2255) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2277 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2277; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2277;\n        float param_11 = _2159;\n        float2 _2296 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2296 * _2062_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2296) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2277);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2338 = max(_2062_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2343 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2349 = sqrt(1.0f - (_2343 * _2343));\n    float _2356 = min(_2349 / max(_2343, 0.20000000298023223876953125f), 4.0f);\n    float _2361;\n    if (_2062_fa_shadow_bias.y > 0.0f)\n    {\n        _2361 = _2062_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2361 = 1.5f * _2062_fa_shadow_info[ci].x;\n    }\n    float4 _2386 = mul(float4(world + (n * (_2361 * _2349)), 1.0f), _2062_fa_shadow_mat[ci]);\n    float _2393 = _2386.x;\n    bool _2396 = _2393 < _2062_fa_shadow_rect[ci].x;\n    bool _2405;\n    if (!_2396)\n    {\n        _2405 = _2393 > _2062_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2405 = _2396;\n    }\n    bool _2414;\n    if (!_2405)\n    {\n        _2414 = _2386.y < _2062_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2414 = _2405;\n    }\n    bool _2423;\n    if (!_2414)\n    {\n        _2423 = _2386.y > _2062_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2423 = _2414;\n    }\n    bool _2430;\n    if (!_2423)\n    {\n        _2430 = _2386.z > 1.0f;\n    }\n    else\n    {\n        _2430 = _2423;\n    }\n    if (_2430)\n    {\n        return -1.0f;\n    }\n    float _2438;\n    if (_2062_fa_shadow_bias.x > 0.0f)\n    {\n        _2438 = _2062_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2438 = 1.5f * _2062_fa_shadow_info[ci].x;\n    }\n    float2 param = _2386.xy;\n    float4 param_1 = _2062_fa_shadow_rect[ci];\n    float param_2 = _2386.z - ((_2438 * (1.0f + (0.5f * _2356))) / _2338);\n    float param_3 = _2062_fa_shadow_info[ci].x;\n    float param_4 = _2338;\n    float param_5 = _2338 * 0.25f;\n    float param_6 = ((_2062_fa_shadow_info[ci].x * min(_2356, 3.0f)) * 0.5f) / _2338;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2062_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2062_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_365_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2826 = int(_2062_fa_shadow_cfg.x + 0.5f);\n    if (_2826 < 1)\n    {\n        return 1.0f;\n    }\n    float _2841 = dot(world - _2062_fa_shadow_eye.xyz, _2062_fa_shadow_fwd.xyz);\n    int param = _2826 - 1;\n    if (_2841 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2853 = _2826 > 1;\n    bool _2860;\n    if (_2853)\n    {\n        _2860 = _2841 > _2062_fa_shadow_split.x;\n    }\n    else\n    {\n        _2860 = _2853;\n    }\n    if (_2860)\n    {\n        ci = 1;\n    }\n    bool _2864 = _2826 > 2;\n    bool _2871;\n    if (_2864)\n    {\n        _2871 = _2841 > _2062_fa_shadow_split.y;\n    }\n    else\n    {\n        _2871 = _2864;\n    }\n    if (_2871)\n    {\n        ci = 2;\n    }\n    bool _2875 = _2826 > 3;\n    bool _2882;\n    if (_2875)\n    {\n        _2882 = _2841 > _2062_fa_shadow_split.z;\n    }\n    else\n    {\n        _2882 = _2875;\n    }\n    if (_2882)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2826)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2908 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2908;\n        if (_2908 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2062_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2933;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2933 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2933 = _2062_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2952 = _2062_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2933, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2963 = clamp((_2841 - (fa_shadow_split_at(param_7) - _2952)) / _2952, 0.0f, 1.0f);\n        if (_2963 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2826)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2984 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2984;\n                if (_2984 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2963);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2496 = _365_fa_pbr.z < 0.5f;\n    bool _2503;\n    if (!_2496)\n    {\n        _2503 = _2062_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2503 = _2496;\n    }\n    if (_2503)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2062_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2516 = fa_light_texel(param);\n    float _2517 = _2516.x;\n    if (_2517 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2526 = int(_2517 + 0.5f);\n    int param_1 = _2526;\n    float4 _2530 = fa_light_texel(param_1);\n    int param_2 = _2526 + 1;\n    float4 _2535 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2538 = _2530.y;\n    if (_2538 > 0.0f)\n    {\n        float _2555 = 1.0f - smoothstep(0.75f * _2538, _2538, length(world - _2062_fa_shadow_eye.xyz));\n        fade = _2555;\n        if (_2555 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2530.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2584 = (_2526 + 2) + (face * 6);\n    int param_6 = _2584;\n    int param_7 = _2584 + 1;\n    int param_8 = _2584 + 3;\n    float4 _2598 = fa_light_texel(param_8);\n    int param_9 = _2584 + 4;\n    float4 _2603 = fa_light_texel(param_9);\n    int param_10 = _2584 + 5;\n    float4 _2608 = fa_light_texel(param_10);\n    float _2620 = _2608.x * max(dot(_2598, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2625 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2648 = clamp(dot(n, _2598.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2672 = min(sqrt(1.0f - (_2648 * _2648)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2598, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2675 = _2535.y;\n    float _2677;\n    if (_2675 > 0.0f)\n    {\n        _2677 = _2675;\n    }\n    else\n    {\n        _2677 = 1.5f * _2620;\n    }\n    float4 _2697 = float4(world + (n * (_2677 * sqrt(1.0f - (_2625 * _2625)))), 1.0f);\n    float _2701 = dot(_2598, _2697);\n    float _2704 = _2608.y;\n    if (_2701 < _2704)\n    {\n        return 1.0f;\n    }\n    float2 _2719 = float2(dot(fa_light_texel(param_6), _2697), dot(fa_light_texel(param_7), _2697)) / _2701.xx;\n    float _2721 = _2719.x;\n    bool _2724 = _2721 < _2603.x;\n    bool _2733;\n    if (!_2724)\n    {\n        _2733 = _2721 > _2603.z;\n    }\n    else\n    {\n        _2733 = _2724;\n    }\n    bool _2742;\n    if (!_2733)\n    {\n        _2742 = _2719.y < _2603.y;\n    }\n    else\n    {\n        _2742 = _2733;\n    }\n    bool _2751;\n    if (!_2742)\n    {\n        _2751 = _2719.y > _2603.w;\n    }\n    else\n    {\n        _2751 = _2742;\n    }\n    if (_2751)\n    {\n        return 1.0f;\n    }\n    float _2757 = _2535.x;\n    float _2759;\n    if (_2757 > 0.0f)\n    {\n        _2759 = _2757;\n    }\n    else\n    {\n        _2759 = 1.5f * _2620;\n    }\n    float2 param_13 = _2719;\n    float4 param_14 = _2603;\n    float param_15 = _2701 - (_2759 * (1.0f + (0.5f * _2672)));\n    float param_16 = _2620;\n    float param_17 = 1.0f;\n    float param_18 = _2608.z * 0.25f;\n    float param_19 = (_2620 * min(_2672, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2704, _2608.z);\n    int param_21 = int(_2530.z + 0.5f);\n    float param_22 = _2530.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3915 = fa_lm.z > 0.5f;\n    bool _3921;\n    if (_3915)\n    {\n        int param = li;\n        _3921 = fa_light_baked(param);\n    }\n    else\n    {\n        _3921 = _3915;\n    }\n    if (_3921)\n    {\n        int param_1 = li;\n        LightSample _5028 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5028;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3945 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5030 = _3945.color;\n    float _5032 = _3945.shadow;\n    if ((_3945.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3945.direction;\n        float _3959 = fa_shadow_factor(param_5, param_6);\n        _5032 = _3959;\n        _5030 *= _3959;\n    }\n    else\n    {\n        bool _3970 = _3945.type != 0;\n        bool _3976;\n        if (_3970)\n        {\n            _3976 = _3945.attenuation > 0.0f;\n        }\n        else\n        {\n            _3976 = _3970;\n        }\n        if (_3976)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _3945.direction;\n            float _3988 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _5032 = _3988;\n            _5030 *= _3988;\n        }\n    }\n    LightSample _5047 = { _3945.direction, _5030, _3945.attenuation, _5032, _3945._distance, _3945.type };\n    return _5047;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2062_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3008 = int(_2062_fa_shadow_cfg.x + 0.5f);\n    float _3018 = dot(world - _2062_fa_shadow_eye.xyz, _2062_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3023 = _3008 > 0;\n    bool _3032;\n    if (_3023)\n    {\n        int param = _3008 - 1;\n        _3032 = _3018 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3032 = _3023;\n    }\n    if (_3032)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3038 = _3008 > 1;\n        bool _3045;\n        if (_3038)\n        {\n            _3045 = _3018 > _2062_fa_shadow_split.x;\n        }\n        else\n        {\n            _3045 = _3038;\n        }\n        if (_3045)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3051 = _3008 > 2;\n        bool _3058;\n        if (_3051)\n        {\n            _3058 = _3018 > _2062_fa_shadow_split.y;\n        }\n        else\n        {\n            _3058 = _3051;\n        }\n        if (_3058)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3064 = _3008 > 3;\n        bool _3071;\n        if (_3064)\n        {\n            _3071 = _3018 > _2062_fa_shadow_split.z;\n        }\n        else\n        {\n            _3071 = _3064;\n        }\n        if (_3071)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4739 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4739 = -_4739;\n    }\n    float3 _4374 = normalize(_365_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4752 = { fa_world_pos, _4739, fa_world_tangent, fa_uv, fa_vertex_color, _4374, gl_FrontFacing };\n    SurfaceInput param_1 = _4752;\n    Surface _4382 = fa_standard_surface(param_1);\n    float3 _4778 = _4382.albedo;\n    float _4779 = _4382.alpha;\n    float3 _4780 = _4382.normal;\n    float _4781 = _4382.metallic;\n    float _4782 = _4382.roughness;\n    float _4783 = _4382.occlusion;\n    float3 _4784 = _4382.emission;\n    float _4785 = _4382.clearcoat;\n    float _4786 = _4382.clearcoat_roughness;\n    float3 _4787 = _4382.sheen_color;\n    float _4788 = _4382.sheen_roughness;\n    float _4789 = _4382.anisotropy;\n    float _4790 = _4382.anisotropy_rotation;\n    float _4791 = _4382.specular;\n    float _4792 = _4382.ior;\n    float3 _4793 = _4382.specular_color;\n    SurfaceInput _4760 = { fa_world_pos, _4739, fa_world_tangent, fa_uv, fa_vertex_color, _4374, gl_FrontFacing };\n    SurfaceInput param_2 = _4760;\n    Surface param_3 = _4382;\n    surface(param_2, param_3);\n    _4778 = param_3.albedo;\n    _4779 = param_3.alpha;\n    _4780 = param_3.normal;\n    _4781 = param_3.metallic;\n    _4782 = param_3.roughness;\n    _4783 = param_3.occlusion;\n    _4784 = param_3.emission;\n    _4785 = param_3.clearcoat;\n    _4786 = param_3.clearcoat_roughness;\n    _4787 = param_3.sheen_color;\n    _4788 = param_3.sheen_roughness;\n    _4789 = param_3.anisotropy;\n    _4790 = param_3.anisotropy_rotation;\n    _4791 = param_3.specular;\n    _4792 = param_3.ior;\n    _4793 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4739;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4778 = param_6;\n    _4780 = param_7;\n    float3 result;\n    if (_365_fa_emissive.w > 0.5f)\n    {\n        result = _4778;\n    }\n    else\n    {\n        float3 _4420 = _4780;\n        float3 _4421 = normalize(_4420);\n        _4780 = _4421;\n        float3 param_8 = _4421;\n        SurfaceInput _4768 = { fa_world_pos, _4739, fa_world_tangent, fa_uv, fa_vertex_color, _4374, gl_FrontFacing };\n        SurfaceInput param_9 = _4768;\n        Surface _4859 = { _4778, _4779, _4780, _4781, _4782, _4783, _4784, _4785, _4786, _4787, _4788, _4789, _4790, _4791, _4792, _4793 };\n        Surface param_10 = _4859;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4440 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4440; ln++)\n        {\n            int param_12 = ln;\n            int _4453 = fa_cl_light(param_12);\n            bool _4456 = fa_lm.z > 0.5f;\n            bool _4462;\n            if (_4456)\n            {\n                int param_13 = _4453;\n                _4462 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _4462 = _4456;\n            }\n            if (_4462)\n            {\n                continue;\n            }\n            int param_14 = _4453;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _4739;\n            LightSample _4474 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _4776 = { fa_world_pos, _4739, fa_world_tangent, fa_uv, fa_vertex_color, _4374, gl_FrontFacing };\n            SurfaceInput param_17 = _4776;\n            Surface _4876 = { _4778, _4779, _4780, _4781, _4782, _4783, _4784, _4785, _4786, _4787, _4788, _4789, _4790, _4791, _4792, _4793 };\n            Surface param_18 = _4876;\n            LightSample param_19 = _4474;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4489 = result;\n    float3 _4490 = _4489 + _4784;\n    result = _4490;\n    float3 param_20 = _4490;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4499 = _365_fa_fog.w > 0.0f;\n    bool _4506;\n    if (!_4499)\n    {\n        _4506 = _365_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4506 = _4499;\n    }\n    if (_4506)\n    {\n        float3 _4515 = fa_world_pos - _365_fa_camera_pos.xyz;\n        float _4521 = dot(_4515, _365_fa_fog_c.xyz);\n        bool _4525 = _365_fa_fog_c.w > 0.5f;\n        float _4526;\n        if (_4525)\n        {\n            _4526 = _4521;\n        }\n        else\n        {\n            _4526 = length(_4515);\n        }\n        float _4538 = _4526 - _365_fa_fog_b.x;\n        if (_4538 > 0.0f)\n        {\n            float _4547 = _365_fa_fog.w * _4538;\n            float tau = _4547 * _4547;\n            if (_365_fa_fog_b.y > 0.0f)\n            {\n                float _4563;\n                if (_4525)\n                {\n                    _4563 = fa_world_pos.y - (_365_fa_fog_c.y * _4521);\n                }\n                else\n                {\n                    _4563 = _365_fa_camera_pos.y;\n                }\n                float _4584 = lerp(_4563, fa_world_pos.y, clamp(_365_fa_fog_b.x / _4526, 0.0f, 1.0f));\n                float _4588 = fa_world_pos.y - _4584;\n                float _4593 = _4584 - _365_fa_fog_b.z;\n                float _4598 = fa_world_pos.y - _365_fa_fog_b.z;\n                bool _4601 = _4593 <= 0.0f;\n                bool _4602 = !_4601;\n                bool _4608;\n                if (_4602)\n                {\n                    _4608 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4608 = _4601;\n                }\n                float _4609;\n                if (_4608)\n                {\n                    _4609 = _365_fa_fog_b.y;\n                }\n                else\n                {\n                    _4609 = _365_fa_fog_b.y * exp(-min(_365_fa_fog_b.w * _4593, 80.0f));\n                }\n                bool _4636;\n                if (_4602)\n                {\n                    _4636 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4636 = _4601;\n                }\n                float _4637;\n                if (_4636)\n                {\n                    _4637 = _365_fa_fog_b.y * _4593;\n                }\n                else\n                {\n                    _4637 = (_365_fa_fog_b.y * (1.0f - exp(-min(_365_fa_fog_b.w * _4593, 80.0f)))) / _365_fa_fog_b.w;\n                }\n                bool _4662 = _4598 <= 0.0f;\n                bool _4669;\n                if (!_4662)\n                {\n                    _4669 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4669 = _4662;\n                }\n                float _4670;\n                if (_4669)\n                {\n                    _4670 = _365_fa_fog_b.y * _4598;\n                }\n                else\n                {\n                    _4670 = (_365_fa_fog_b.y * (1.0f - exp(-min(_365_fa_fog_b.w * _4598, 80.0f)))) / _365_fa_fog_b.w;\n                }\n                float _4697;\n                if (abs(_4588) < 0.001000000047497451305389404296875f)\n                {\n                    _4697 = _4609;\n                }\n                else\n                {\n                    _4697 = (_4670 - _4637) / _4588;\n                }\n                tau += (_4538 * max(_4697, 0.0f));\n            }\n            result = lerp(result, _365_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4779);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_365",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2062",
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
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 9
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
              "hlsl_register_t_n": 10
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
              "hlsl_register_t_n": 11
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 11,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _381 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _381;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_388, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3356[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _365_fa_camera_pos : packoffset(c0);\n    float4 _365_fa_ambient : packoffset(c1);\n    float4 _365_fa_base_color : packoffset(c2);\n    float4 _365_fa_emissive : packoffset(c3);\n    float4 _365_fa_model_emissive : packoffset(c4);\n    float4 _365_fa_pbr : packoffset(c5);\n    float4 _365_fa_maps : packoffset(c6);\n    float4 _365_fa_fog : packoffset(c7);\n    float4 _365_fa_fog_b : packoffset(c8);\n    float4 _365_fa_fog_c : packoffset(c9);\n    float4 _365_fa_counts : packoffset(c10);\n    float4 _365_fa_env_sky : packoffset(c11);\n    float4 _365_fa_env_horizon : packoffset(c12);\n    float4 _365_fa_time : packoffset(c13);\n    float4 _365_fa_cl_vpx : packoffset(c14);\n    float4 _365_fa_cl_vpy : packoffset(c15);\n    float4 _365_fa_cl_vpw : packoffset(c16);\n    float4 _365_fa_cl_fwd : packoffset(c17);\n    float4 _365_fa_cl_grid : packoffset(c18);\n    float4 _365_fa_cl_info : packoffset(c19);\n    float4 _365_fa_layers_a : packoffset(c20);\n    float4 _365_fa_layers_b : packoffset(c21);\n    float4 _365_fa_layers_c : packoffset(c22);\n    float4 _365_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2062_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2062_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2062_fa_shadow_info[4] : packoffset(c20);\n    float4 _2062_fa_shadow_split : packoffset(c24);\n    float4 _2062_fa_shadow_cfg : packoffset(c25);\n    float4 _2062_fa_shadow_bias : packoffset(c26);\n    float4 _2062_fa_shadow_eye : packoffset(c27);\n    float4 _2062_fa_shadow_fwd : packoffset(c28);\n    float4 _2062_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1333 = _365_fa_cl_info.x < 0.0f;\n    bool _1340;\n    if (!_1333)\n    {\n        _1340 = _365_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1340 = _1333;\n    }\n    bool _1348;\n    if (!_1340)\n    {\n        _1348 = _365_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1348 = _1340;\n    }\n    bool _1355;\n    if (!_1348)\n    {\n        _1355 = _365_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1355 = _1348;\n    }\n    bool _1362;\n    if (!_1355)\n    {\n        _1362 = _365_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1362 = _1355;\n    }\n    if (_1362)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1372 = float4(world_pos, 1.0f);\n    float _1378 = dot(_365_fa_cl_vpw, _1372);\n    if (!(_1378 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1400 = float2(dot(_365_fa_cl_vpx, _1372), dot(_365_fa_cl_vpy, _1372)) / _1378.xx;\n    int _1404 = int(_365_fa_cl_grid.x);\n    int _1408 = int(_365_fa_cl_grid.y);\n    int param = (int(_365_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_365_fa_cl_fwd.xyz, world_pos) + _365_fa_cl_fwd.w, _365_fa_cl_grid.w) / _365_fa_cl_grid.w) * _365_fa_cl_grid.z)), 0, int(_365_fa_cl_info.y) - 1) * _1408) + clamp(int(floor(((_1400.y * 0.5f) + 0.5f) * _365_fa_cl_grid.y)), 0, _1408 - 1)) * _1404)) + clamp(int(floor(((_1400.x * 0.5f) + 0.5f) * _365_fa_cl_grid.x)), 0, _1404 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1484 = fa_cluster_texel(param);\n    return int2(int(_1484.x), int(_1484.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_365_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3888 = fa_cluster_lookup(param);\n    fa_cl_slot = _3888.x;\n    fa_cl_local = _3888.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4044 = fa_linear_to_srgb(param);\n        c = _4044;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4052 = fa_srgb_to_linear(param_1);\n            c = _4052;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _297;\n    if (i.front_facing)\n    {\n        _297 = i.world_normal;\n    }\n    else\n    {\n        _297 = -i.world_normal;\n    }\n    float3 _321 = normalize(i.world_tangent.xyz - (_297 * dot(_297, i.world_tangent.xyz)));\n    float3 _349 = normalize(((_321 * m.x) + ((cross(_297, _321) * i.world_tangent.w) * m.y)) + (_297 * m.z));\n    float3 _352;\n    if (i.front_facing)\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _365_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4083 = fa_tex_fix(param_2, param_3);\n    float4 _5198 = base_t;\n    _5198.x = _4083.x;\n    _5198.y = _4083.y;\n    _5198.z = _4083.z;\n    base_t = _5198;\n    float4 _4097 = (_5198 * _365_fa_base_color) * i.vertex_color;\n    float3 _5050 = i.world_normal;\n    if (_365_fa_maps.z > 0.5f)\n    {\n        float param_4 = _365_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4129 = fa_tex_fix(param_6, param_7);\n        float3 _4132 = (_4129 * 2.0f) - 1.0f.xxx;\n        float2 _4137 = _4132.xy * _365_fa_maps.x;\n        float3 _5206 = _4132;\n        _5206.x = _4137.x;\n        _5206.y = _4137.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5206;\n        _5050 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _365_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4165 = fa_tex_fix(param_12, param_13);\n    float4 _5209 = mrt;\n    _5209.x = _4165.x;\n    _5209.y = _4165.y;\n    _5209.z = _4165.z;\n    mrt = _5209;\n    float4 _4193 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _365_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4193.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4204 = fa_tex_fix(param_16, param_17);\n    float param_18 = _365_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4234 = fa_tex_fix(param_20, param_21);\n    float _5055 = _365_fa_layers_a.x;\n    float _5056 = _365_fa_layers_a.y;\n    float _5059 = _365_fa_layers_a.z;\n    float _5058 = _365_fa_layers_b.w;\n    float _5061 = _365_fa_layers_c.x;\n    if (_365_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_365_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5055 *= _4204.y;\n            _5056 *= _4204.z;\n            _5058 *= _4193.w;\n        }\n        if (_365_fa_layers_c.z > 1.5f)\n        {\n            _5059 *= mrt.x;\n            _5061 *= mrt.w;\n        }\n    }\n    Surface _5080 = { _4097.xyz, _4097.w, _5050, clamp(_365_fa_pbr.x * _4165.z, 0.0f, 1.0f), clamp(_365_fa_pbr.y * _4165.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_365_fa_maps.y * (_4204.x - 1.0f)), _365_fa_emissive.xyz + (_365_fa_model_emissive.xyz * _4234), _5055, _5056, _365_fa_layers_b.xyz, _5058, _5059, _365_fa_layers_a.w, _5061, _365_fa_layers_c.y, _365_fa_layers_d.xyz };\n    return _5080;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1564 = rect.zw - rect.xy;\n    float2 _1568 = _1564 * atlas;\n    float2 _1572 = ddx * _1568;\n    float2 _1576 = ddy * _1568;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1564), clamp(0.5f * log2(max(max(dot(_1572, _1572), dot(_1576, _1576)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1609 = _365_fa_counts.y < 0.5f;\n    bool _1616;\n    if (!_1609)\n    {\n        _1616 = _365_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1616 = _1609;\n    }\n    if (_1616)\n    {\n        return;\n    }\n    float3 _1622 = ddx(world_pos);\n    float3 _1625 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1629 = fa_cluster_texel(param);\n    int _1633 = int(_1629.w);\n    if (_1633 < 1)\n    {\n        return;\n    }\n    int _1643 = int(_365_fa_counts.y + 0.5f);\n    int param_1 = _1643;\n    float4 _1647 = fa_light_texel(param_1);\n    float2 _1650 = _1647.yz;\n    int _1654 = int(_1647.w);\n    int param_2 = _1643 + 1;\n    float4 _1659 = fa_light_texel(param_2);\n    float _1660 = _1659.x;\n    int _1666 = int(_365_fa_counts.w + 0.5f) - 1;\n    int _1670 = int(_1629.z);\n    float3 _1935;\n    for (int k = 0; k < _1633; k++)\n    {\n        int _1683 = _1670 + k;\n        int param_3 = _1654 + (_1683 >> 2);\n        int _1700 = (_1643 + 2) + (int(fa_light_texel(param_3)[_1683 & 3]) * 7);\n        int param_4 = _1700 + 6;\n        float4 _1705 = fa_light_texel(param_4);\n        if (((int(_1705.w + 0.5f) >> _1666) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1700;\n        float4 _1720 = fa_light_texel(param_5);\n        int param_6 = _1700 + 1;\n        float4 _1725 = fa_light_texel(param_6);\n        int param_7 = _1700 + 2;\n        float4 _1730 = fa_light_texel(param_7);\n        float3 _1733 = _1720.xyz;\n        float _1738 = dot(_1733, world_pos) + _1720.w;\n        float3 _1740 = _1725.xyz;\n        float _1745 = dot(_1740, world_pos) + _1725.w;\n        float3 _1747 = _1730.xyz;\n        float _1752 = dot(_1747, world_pos) + _1730.w;\n        bool _1757 = abs(_1738) > 0.5f;\n        bool _1765;\n        if (!_1757)\n        {\n            _1765 = abs(_1745) > 0.5f;\n        }\n        else\n        {\n            _1765 = _1757;\n        }\n        bool _1773;\n        if (!_1765)\n        {\n            _1773 = abs(_1752) > 0.5f;\n        }\n        else\n        {\n            _1773 = _1765;\n        }\n        if (_1773)\n        {\n            continue;\n        }\n        float _1788 = clamp(dot(geo_normal, normalize(_1747)) * _1705.z, 0.0f, 1.0f);\n        if (_1788 <= 0.0f)\n        {\n            continue;\n        }\n        float _1808 = (clamp((0.5f - abs(_1752)) * 10.0f, 0.0f, 1.0f) * _1788) * _1705.x;\n        float2 _1816 = float2(_1738 + 0.5f, 0.5f - _1745);\n        float2 _1826 = float2(dot(_1733, _1622), dot(_1740, _1622));\n        float2 _1836 = float2(dot(_1733, _1625), dot(_1740, _1625));\n        int param_8 = _1700 + 5;\n        float4 _1841 = fa_light_texel(param_8);\n        int param_9 = _1700 + 3;\n        float4 _1846 = fa_light_texel(param_9);\n        int param_10 = _1700 + 4;\n        float4 _1851 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1841.xyz;\n        bool _1861 = _1846.z > _1846.x;\n        if (_1861)\n        {\n            float4 param_11 = _1846;\n            float2 param_12 = _1816;\n            float2 param_13 = _1650;\n            float2 param_14 = _1826;\n            float2 param_15 = _1836;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1660 > 0.5f) && (_1660 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1887 = fa_dc_to_linear(param_16);\n                float4 _5130 = tx;\n                _5130.x = _1887.x;\n                _5130.y = _1887.y;\n                _5130.z = _1887.z;\n                tx = _5130;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1808 * tex_a) * _1841.w, 0.0f, 1.0f).xxx);\n        if (_1851.z > _1851.x)\n        {\n            float4 param_17 = _1851;\n            float2 param_18 = _1816;\n            float2 param_19 = _1650;\n            float2 param_20 = _1826;\n            float2 param_21 = _1836;\n            float4 _1931 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1660 > 1.5f)\n            {\n                float3 param_22 = _1931.xyz;\n                float3 _1941 = fa_dc_to_srgb(param_22);\n                _1935 = _1941;\n            }\n            else\n            {\n                _1935 = _1931.xyz;\n            }\n            float3 _1950 = (_1935 * 2.0f) - 1.0f.xxx;\n            float2 _1955 = _1950.xy * _1705.y;\n            float3 _1977 = (normalize(_1733) * _1955.x) + (normalize(_1740) * _1955.y);\n            float3 _1980 = normalize(normal);\n            normal = normalize(lerp(_1980, normalize((_1980 * max(_1950.z, 0.0500000007450580596923828125f)) + (_1977 - (_1980 * dot(_1980, _1977)))), clamp(_1808 * (_1861 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_365_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _365_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3281 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3289 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3292 = int(_3281);\n    int _3295 = int(_3289);\n    float _3305 = _3289 - float(_3295);\n    int _3361 = (_3292 * 9) + _3295;\n    int _3381 = ((_3292 + 1) * 9) + _3295;\n    return lerp(lerp(_3356[_3361], _3356[_3361 + 1], _3305), lerp(_3356[_3381], _3356[_3381 + 1], _3305), _3281 - float(_3292));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4909 = false;\n    float _4910 = 1.0f;\n    float _4911 = 1.0f;\n    float _4912 = 1.0f;\n    float _4913 = 0.0f;\n    float _4914 = 0.0f;\n    float _4915 = 0.0f;\n    float _4916 = 0.0f;\n    float _4918 = 1.0f;\n    bool _4919 = false;\n    float3 _4920 = 0.0f.xxx;\n    float _4921 = 1.0f;\n    float _4922 = 1.0f;\n    float _4923 = 1.0f;\n    float _4924 = 0.0f;\n    float _4925 = 0.0f;\n    float3 _4926 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4927 = float3(0.0f, 0.0f, 1.0f);\n    float _4928 = 1.0f;\n    float _4929 = 1.0f;\n    float _3432 = clamp(s.specular, 0.0f, 1.0f);\n    float _3436 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3441 = (_3432 != 1.0f) || (_3436 != 1.5f);\n    bool _3450;\n    if (!_3441)\n    {\n        _3450 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3450 = _3441;\n    }\n    if (_3450)\n    {\n        float _3458 = (_3436 - 1.0f) / (_3436 + 1.0f);\n        f0 = lerp(min((_3458 * _3458).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3432, s.albedo, metallic.xxx);\n        _4910 = lerp(_3432, 1.0f, metallic);\n        _4909 = true;\n    }\n    float _3485 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3485 > 0.0f)\n    {\n        float _3493 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4913 = _3485;\n        _4914 = _3493;\n        float _3500 = _3493 * _3493;\n        _4915 = _3500;\n        _4916 = _3500 * _3500;\n        float _3512 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4918 = _3512;\n        _4911 = 1.0f - (_3485 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3512, 0.0f, 1.0f), 5.0f))));\n        _4909 = true;\n    }\n    float3 _3532 = max(s.sheen_color, 0.0f.xxx);\n    float _3541 = max(_3532.x, max(_3532.y, _3532.z));\n    if (_3541 > 0.0f)\n    {\n        float _3549 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4919 = true;\n        _4920 = _3532;\n        _4921 = _3549;\n        _4922 = _3549 * _3549;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3549;\n        float _3566 = fa_sheen_albedo(param, param_1);\n        _4924 = _3566;\n        _4923 = 1.0f - min(_3541 * _3566, 1.0f);\n        _4909 = true;\n    }\n    _4912 = _4911 * _4923;\n    float _3585 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3585 != 0.0f)\n    {\n        float3 _3600 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3600;\n        if (dot(_3600, _3600) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3612 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3612.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3612.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3612.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3616 = t;\n        float3 _3617 = normalize(_3616);\n        t = _3617;\n        float3 _3642 = normalize((_3617 * cos(s.anisotropy_rotation)) + ((cross(n, _3617) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4926 = _3642;\n        _4927 = cross(n, _3642);\n        float _3652 = roughness * roughness;\n        float _3658 = lerp(_3652, 1.0f, _3585 * _3585);\n        bool _3660 = _3585 > 0.0f;\n        _4928 = _3660 ? _3658 : _3652;\n        _4929 = _3660 ? _3652 : _3658;\n        _4925 = _3585;\n        _4909 = true;\n    }\n    FaLayers _4951 = { _4909, _4910, _4911, _4912, _4913, _4914, _4915, _4916, i.world_normal, _4918, _4919, _4920, _4921, _4922, _4923, _4924, _4925, _4926, _4927, _4928, _4929 };\n    return _4951;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3213 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3216 = _3213.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3216 * _3216, exp2((-9.27999973297119140625f) * ndv)) * _3216) + _3213.y)) + _3213.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_365_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _365_fa_env_horizon.w).xyz;\n    }\n    float _3119 = rough * rough;\n    float _3149 = 0.60000002384185791015625f * _3119;\n    return lerp(lerp(_365_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_365_fa_env_horizon.xyz, _365_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3119)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3149, 0.0500000007450580596923828125f + _3149, d.y).xxx), ((_365_fa_env_sky.xyz + _365_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3119 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3693;\n        if (L.aniso >= 0.0f)\n        {\n            _3693 = L.b;\n        }\n        else\n        {\n            _3693 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3693, v), _3693), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3726 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3726.x) + (L.f90.xxx * _3726.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3781 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3781.x) + _3781.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3255 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3255.x) + _3255.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3810 = clamp(s.metallic, 0.0f, 1.0f);\n    float _3814 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3821 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _3810.xxx);\n    float3 f0 = _3821;\n    float3 _3825 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3825;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3810;\n    float param_5 = _3814;\n    float3 param_6 = _3821;\n    FaLayers _3842 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3842.on)\n    {\n        FaLayers param_7 = _3842;\n        float3 param_8 = _3825;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3814;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3825;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3814;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_365_fa_cl_info.x) + int(_365_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_365_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _427_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _427_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _593 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _606 = (c - (ru * hx)) - p;\n        float3 _612 = ru * (2.0f * hx);\n        float _618 = max(dot(_612, _612), 9.9999999392252902907785028219223e-09f);\n        float _622 = dot(_606, _612);\n        float t = clamp((-_622) / _618, 0.0f, 1.0f);\n        if (_593)\n        {\n            float _637 = dot(r, _612);\n            float _643 = _618 - (_637 * _637);\n            if (abs(_643) > (9.9999997473787516355514526367188e-06f * _618))\n            {\n                t = clamp(((dot(r, _606) * _637) - _622) / _643, 0.0f, 1.0f);\n            }\n        }\n        return (p + _606) + (_612 * t);\n    }\n    float3 q = p;\n    float _675 = dot(r, axis);\n    bool _683;\n    if (_593)\n    {\n        _683 = abs(_675) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _683 = _593;\n    }\n    if (_683)\n    {\n        float _693 = dot(c - p, axis) / _675;\n        if (_693 > 0.0f)\n        {\n            q = p + (r * _693);\n        }\n    }\n    float3 _706 = q - c;\n    float2 xy = float2(dot(_706, ru), dot(_706, uu));\n    if (shape > 0.5f)\n    {\n        float _721 = length(xy);\n        if (_721 > hx)\n        {\n            xy *= (hx / _721);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _514 = abs(d);\n    float _516 = _514.x;\n    float _518 = _514.y;\n    bool _519 = _516 >= _518;\n    bool _527;\n    if (_519)\n    {\n        _527 = _516 >= _514.z;\n    }\n    else\n    {\n        _527 = _519;\n    }\n    int _528;\n    if (_527)\n    {\n        _528 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _541;\n        if (_518 >= _514.z)\n        {\n            _541 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _541 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _528 = _541;\n    }\n    return _528;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _467 = dot(d, right);\n    float _471 = dot(d, up);\n    float _482;\n    if (((_467 * _467) + (_471 * _471)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _482 = atan2(_471, _467) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _482 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_482 - floor(_482)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _759 = fa_light_base(param);\n    bool _763 = _365_fa_ambient.w > 4.5f;\n    int param_1 = _759;\n    float4 _767 = fa_light_texel(param_1);\n    int param_2 = _759 + 1;\n    float4 _772 = fa_light_texel(param_2);\n    float _775 = _772.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _787 = _763 && (_775 > 2.5f);\n    fa_light_is_area = _787;\n    bool _789 = _775 < 0.5f;\n    float3 l;\n    if (_789)\n    {\n        l = normalize(_767.xyz);\n        if (_763)\n        {\n            int param_3 = _759 + 6;\n            float4 _803 = fa_light_texel(param_3);\n            if (_803.z > 0.5f)\n            {\n                int param_4 = _759 + 4;\n                float4 _813 = fa_light_texel(param_4);\n                int param_5 = _759 + 5;\n                float4 _818 = fa_light_texel(param_5);\n                float2 param_6 = _803.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _813.xyz) * _813.w, (-dot(world_pos, _818.xyz)) * _818.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _848 = _767.xyz;\n        float3 _850 = _848 - world_pos;\n        float3 to_light = _850;\n        float _853 = length(_850);\n        float reach = _853;\n        bool front = true;\n        if (_787)\n        {\n            int param_8 = _759 + 7;\n            reach = max(_853 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _759 + 4;\n            float4 _877 = fa_light_texel(param_9);\n            int param_10 = _759 + 5;\n            float4 _882 = fa_light_texel(param_10);\n            int param_11 = _759 + 6;\n            float4 _887 = fa_light_texel(param_11);\n            float _888 = _887.w;\n            int param_12 = _759 + 2;\n            float3 _895 = normalize(fa_light_texel(param_12).xyz);\n            bool _897 = _888 > 1.5f;\n            bool _905;\n            if (!_897)\n            {\n                _905 = dot(_895, to_light) < 0.0f;\n            }\n            else\n            {\n                _905 = _897;\n            }\n            front = _905;\n            float3 r = 0.0f.xxx;\n            if (dot(n, n) > 0.5f)\n            {\n                r = reflect(-normalize(_365_fa_camera_pos.xyz - world_pos), normalize(n));\n            }\n            float3 param_13 = _848;\n            float3 param_14 = _895;\n            float3 param_15 = _877.xyz;\n            float3 param_16 = _882.xyz;\n            float param_17 = _877.w;\n            float param_18 = _882.w;\n            float param_19 = _888;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _952 = length(to_light);\n        dist = _952;\n        l = to_light / max(_952, 9.9999997473787516355514526367188e-05f).xxx;\n        float _966 = reach / max(_767.w, 0.001000000047497451305389404296875f);\n        float _972 = clamp(1.0f - (_966 * _966), 0.0f, 1.0f);\n        float _974;\n        if (front)\n        {\n            _974 = _972 * _972;\n        }\n        else\n        {\n            _974 = 0.0f;\n        }\n        atten = _974;\n        bool _985 = _775 < 2.5f;\n        if ((_775 > 1.5f) && _985)\n        {\n            int param_22 = _759 + 2;\n            float4 _993 = fa_light_texel(param_22);\n            float _1003 = _993.w;\n            int param_23 = _759 + 3;\n            float4 _1008 = fa_light_texel(param_23);\n            float _1009 = _1008.x;\n            float cos_inner = _1009;\n            if (_1009 > 1.5f)\n            {\n                cos_inner = lerp(_1003, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1003, cos_inner, dot(-l, normalize(_993.xyz)));\n        }\n        if (_763 && (_775 < 1.5f))\n        {\n            int param_24 = _759 + 6;\n            float4 _1033 = fa_light_texel(param_24);\n            if (_1033.z > 0.5f)\n            {\n                float3 _1041 = -to_light;\n                int param_25 = _759 + 4;\n                int param_26 = _759 + 5;\n                float3 _1055 = fa_light_texel(param_25).xyz;\n                float3 _1059 = fa_light_texel(param_26).xyz;\n                float3 _1068 = float3(dot(_1041, _1055), dot(_1041, _1059), dot(_1041, cross(_1055, _1059)));\n                float3 param_27 = _1068;\n                int _1072 = fa_cube_face(param_27);\n                int param_28 = _1072;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1099 = float2(dot(_1068, cross(param_29, param_30)), dot(_1068, param_30)) / max(dot(_1068, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1103 = _1072 / 3;\n                float2 param_31 = _1033.xy + (float2(float(_1072 - (_1103 * 3)), float(_1103)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1099.x), 0.5f - (0.5f * _1099.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _759 + 7;\n            float4 _1133 = fa_light_texel(param_33);\n            if (_1133.z > 0.5f)\n            {\n                int param_34 = _759 + 2;\n                int param_35 = _759 + 4;\n                int param_36 = _759 + 5;\n                float2 param_37 = _1133.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_763 && _985)\n            {\n                int param_42 = _759 + 6;\n                float4 _1180 = fa_light_texel(param_42);\n                int param_43 = _759 + 7;\n                float4 _1185 = fa_light_texel(param_43);\n                bool _1188 = _1180.z > 0.5f;\n                bool _1195;\n                if (!_1188)\n                {\n                    _1195 = _1185.z > 0.5f;\n                }\n                else\n                {\n                    _1195 = _1188;\n                }\n                if (_1195)\n                {\n                    int param_44 = _759 + 2;\n                    float4 _1202 = fa_light_texel(param_44);\n                    float3 _1206 = normalize(_1202.xyz);\n                    int param_45 = _759 + 4;\n                    float4 _1211 = fa_light_texel(param_45);\n                    int param_46 = _759 + 5;\n                    float4 _1216 = fa_light_texel(param_46);\n                    if (_1188)\n                    {\n                        float3 _1224 = -to_light;\n                        float _1231 = _1202.w;\n                        float _1247 = 0.5f / max(dot(_1224, _1206) * (sqrt(max(1.0f - (_1231 * _1231), 0.0f)) / max(_1231, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1180.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1224, _1211.xyz) * _1247), 0.5f - (dot(_1224, _1216.xyz) * _1247));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1185.z > 0.5f)\n                    {\n                        float2 param_49 = _1185.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1206;\n                        float3 param_52 = _1211.xyz;\n                        float3 param_53 = _1216.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4897 = _772.xyz * atten;\n    if (_763)\n    {\n        _4897 *= fa_light_tint;\n    }\n    int _1315;\n    if (_789)\n    {\n        _1315 = 0;\n    }\n    else\n    {\n        _1315 = ((_775 > 1.5f) && (_775 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4908 = { l, _4897, atten, 1.0f, dist, _1315 };\n    return _4908;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2052;\n    if (i == 0)\n    {\n        _2052 = _2062_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2068;\n        if (i == 1)\n        {\n            _2068 = _2062_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2076;\n            if (i == 2)\n            {\n                _2076 = _2062_fa_shadow_split.z;\n            }\n            else\n            {\n                _2076 = _2062_fa_shadow_split.w;\n            }\n            _2068 = _2076;\n        }\n        _2052 = _2068;\n    }\n    return _2052;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2109 = fa_shadow_depth(param, param_1);\n    float _2113;\n    if (conv.x < 0.5f)\n    {\n        _2113 = _2109;\n    }\n    else\n    {\n        _2113 = (conv.y * conv.z) / (conv.z - (_2109 * (conv.z - conv.y)));\n    }\n    return _2113;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2040 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2040), sin(_2040)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2159 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2168;\n        if (k < 0.0f)\n        {\n            _2168 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2168 = k;\n        }\n        float _2188 = clamp((_2168 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2159;\n            float2 _2207 = fa_shadow_vogel(param_3, param_4, param_5) * _2188;\n            float2 param_6 = uv + (_2207 * _2062_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2219 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2219 < (zr - (length(_2207) * plane)))\n            {\n                sum += _2219;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2245 = sum / cnt;\n        float _2255;\n        if (k < 0.0f)\n        {\n            _2255 = (-k) / max(_2245, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2255 = k;\n        }\n        radius = clamp(((max(zr - _2245, 0.0f) * unit) * _2255) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2277 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2277; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2277;\n        float param_11 = _2159;\n        float2 _2296 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2296 * _2062_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2296) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2277);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2338 = max(_2062_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2343 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2349 = sqrt(1.0f - (_2343 * _2343));\n    float _2356 = min(_2349 / max(_2343, 0.20000000298023223876953125f), 4.0f);\n    float _2361;\n    if (_2062_fa_shadow_bias.y > 0.0f)\n    {\n        _2361 = _2062_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2361 = 1.5f * _2062_fa_shadow_info[ci].x;\n    }\n    float4 _2386 = mul(float4(world + (n * (_2361 * _2349)), 1.0f), _2062_fa_shadow_mat[ci]);\n    float _2393 = _2386.x;\n    bool _2396 = _2393 < _2062_fa_shadow_rect[ci].x;\n    bool _2405;\n    if (!_2396)\n    {\n        _2405 = _2393 > _2062_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2405 = _2396;\n    }\n    bool _2414;\n    if (!_2405)\n    {\n        _2414 = _2386.y < _2062_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2414 = _2405;\n    }\n    bool _2423;\n    if (!_2414)\n    {\n        _2423 = _2386.y > _2062_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2423 = _2414;\n    }\n    bool _2430;\n    if (!_2423)\n    {\n        _2430 = _2386.z > 1.0f;\n    }\n    else\n    {\n        _2430 = _2423;\n    }\n    if (_2430)\n    {\n        return -1.0f;\n    }\n    float _2438;\n    if (_2062_fa_shadow_bias.x > 0.0f)\n    {\n        _2438 = _2062_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2438 = 1.5f * _2062_fa_shadow_info[ci].x;\n    }\n    float2 param = _2386.xy;\n    float4 param_1 = _2062_fa_shadow_rect[ci];\n    float param_2 = _2386.z - ((_2438 * (1.0f + (0.5f * _2356))) / _2338);\n    float param_3 = _2062_fa_shadow_info[ci].x;\n    float param_4 = _2338;\n    float param_5 = _2338 * 0.25f;\n    float param_6 = ((_2062_fa_shadow_info[ci].x * min(_2356, 3.0f)) * 0.5f) / _2338;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2062_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2062_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_365_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2826 = int(_2062_fa_shadow_cfg.x + 0.5f);\n    if (_2826 < 1)\n    {\n        return 1.0f;\n    }\n    float _2841 = dot(world - _2062_fa_shadow_eye.xyz, _2062_fa_shadow_fwd.xyz);\n    int param = _2826 - 1;\n    if (_2841 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2853 = _2826 > 1;\n    bool _2860;\n    if (_2853)\n    {\n        _2860 = _2841 > _2062_fa_shadow_split.x;\n    }\n    else\n    {\n        _2860 = _2853;\n    }\n    if (_2860)\n    {\n        ci = 1;\n    }\n    bool _2864 = _2826 > 2;\n    bool _2871;\n    if (_2864)\n    {\n        _2871 = _2841 > _2062_fa_shadow_split.y;\n    }\n    else\n    {\n        _2871 = _2864;\n    }\n    if (_2871)\n    {\n        ci = 2;\n    }\n    bool _2875 = _2826 > 3;\n    bool _2882;\n    if (_2875)\n    {\n        _2882 = _2841 > _2062_fa_shadow_split.z;\n    }\n    else\n    {\n        _2882 = _2875;\n    }\n    if (_2882)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2826)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2908 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2908;\n        if (_2908 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2062_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2933;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2933 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2933 = _2062_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2952 = _2062_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2933, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2963 = clamp((_2841 - (fa_shadow_split_at(param_7) - _2952)) / _2952, 0.0f, 1.0f);\n        if (_2963 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2826)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2984 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2984;\n                if (_2984 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2963);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _2496 = _365_fa_pbr.z < 0.5f;\n    bool _2503;\n    if (!_2496)\n    {\n        _2503 = _2062_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2503 = _2496;\n    }\n    if (_2503)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2062_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2516 = fa_light_texel(param);\n    float _2517 = _2516.x;\n    if (_2517 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2526 = int(_2517 + 0.5f);\n    int param_1 = _2526;\n    float4 _2530 = fa_light_texel(param_1);\n    int param_2 = _2526 + 1;\n    float4 _2535 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2538 = _2530.y;\n    if (_2538 > 0.0f)\n    {\n        float _2555 = 1.0f - smoothstep(0.75f * _2538, _2538, length(world - _2062_fa_shadow_eye.xyz));\n        fade = _2555;\n        if (_2555 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2530.x > 1.5f)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        float3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2584 = (_2526 + 2) + (face * 6);\n    int param_6 = _2584;\n    int param_7 = _2584 + 1;\n    int param_8 = _2584 + 3;\n    float4 _2598 = fa_light_texel(param_8);\n    int param_9 = _2584 + 4;\n    float4 _2603 = fa_light_texel(param_9);\n    int param_10 = _2584 + 5;\n    float4 _2608 = fa_light_texel(param_10);\n    float _2620 = _2608.x * max(dot(_2598, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2625 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2648 = clamp(dot(n, _2598.xyz), -1.0f, 1.0f);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2672 = min(sqrt(1.0f - (_2648 * _2648)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2598, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2675 = _2535.y;\n    float _2677;\n    if (_2675 > 0.0f)\n    {\n        _2677 = _2675;\n    }\n    else\n    {\n        _2677 = 1.5f * _2620;\n    }\n    float4 _2697 = float4(world + (n * (_2677 * sqrt(1.0f - (_2625 * _2625)))), 1.0f);\n    float _2701 = dot(_2598, _2697);\n    float _2704 = _2608.y;\n    if (_2701 < _2704)\n    {\n        return 1.0f;\n    }\n    float2 _2719 = float2(dot(fa_light_texel(param_6), _2697), dot(fa_light_texel(param_7), _2697)) / _2701.xx;\n    float _2721 = _2719.x;\n    bool _2724 = _2721 < _2603.x;\n    bool _2733;\n    if (!_2724)\n    {\n        _2733 = _2721 > _2603.z;\n    }\n    else\n    {\n        _2733 = _2724;\n    }\n    bool _2742;\n    if (!_2733)\n    {\n        _2742 = _2719.y < _2603.y;\n    }\n    else\n    {\n        _2742 = _2733;\n    }\n    bool _2751;\n    if (!_2742)\n    {\n        _2751 = _2719.y > _2603.w;\n    }\n    else\n    {\n        _2751 = _2742;\n    }\n    if (_2751)\n    {\n        return 1.0f;\n    }\n    float _2757 = _2535.x;\n    float _2759;\n    if (_2757 > 0.0f)\n    {\n        _2759 = _2757;\n    }\n    else\n    {\n        _2759 = 1.5f * _2620;\n    }\n    float2 param_13 = _2719;\n    float4 param_14 = _2603;\n    float param_15 = _2701 - (_2759 * (1.0f + (0.5f * _2672)));\n    float param_16 = _2620;\n    float param_17 = 1.0f;\n    float param_18 = _2608.z * 0.25f;\n    float param_19 = (_2620 * min(_2672, 3.0f)) * 0.5f;\n    float3 param_20 = float3(1.0f, _2704, _2608.z);\n    int param_21 = int(_2530.z + 0.5f);\n    float param_22 = _2530.w;\n    return lerp(1.0f, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3915 = fa_lm.z > 0.5f;\n    bool _3921;\n    if (_3915)\n    {\n        int param = li;\n        _3921 = fa_light_baked(param);\n    }\n    else\n    {\n        _3921 = _3915;\n    }\n    if (_3921)\n    {\n        int param_1 = li;\n        LightSample _5028 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5028;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3945 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5030 = _3945.color;\n    float _5032 = _3945.shadow;\n    if ((_3945.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3945.direction;\n        float _3959 = fa_shadow_factor(param_5, param_6);\n        _5032 = _3959;\n        _5030 *= _3959;\n    }\n    else\n    {\n        bool _3970 = _3945.type != 0;\n        bool _3976;\n        if (_3970)\n        {\n            _3976 = _3945.attenuation > 0.0f;\n        }\n        else\n        {\n            _3976 = _3970;\n        }\n        if (_3976)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _3945.direction;\n            float _3988 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _5032 = _3988;\n            _5030 *= _3988;\n        }\n    }\n    LightSample _5047 = { _3945.direction, _5030, _3945.attenuation, _5032, _3945._distance, _3945.type };\n    return _5047;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2062_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3008 = int(_2062_fa_shadow_cfg.x + 0.5f);\n    float _3018 = dot(world - _2062_fa_shadow_eye.xyz, _2062_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3023 = _3008 > 0;\n    bool _3032;\n    if (_3023)\n    {\n        int param = _3008 - 1;\n        _3032 = _3018 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3032 = _3023;\n    }\n    if (_3032)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3038 = _3008 > 1;\n        bool _3045;\n        if (_3038)\n        {\n            _3045 = _3018 > _2062_fa_shadow_split.x;\n        }\n        else\n        {\n            _3045 = _3038;\n        }\n        if (_3045)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3051 = _3008 > 2;\n        bool _3058;\n        if (_3051)\n        {\n            _3058 = _3018 > _2062_fa_shadow_split.y;\n        }\n        else\n        {\n            _3058 = _3051;\n        }\n        if (_3058)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3064 = _3008 > 3;\n        bool _3071;\n        if (_3064)\n        {\n            _3071 = _3018 > _2062_fa_shadow_split.z;\n        }\n        else\n        {\n            _3071 = _3064;\n        }\n        if (_3071)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4739 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4739 = -_4739;\n    }\n    float3 _4374 = normalize(_365_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4752 = { fa_world_pos, _4739, fa_world_tangent, fa_uv, fa_vertex_color, _4374, gl_FrontFacing };\n    SurfaceInput param_1 = _4752;\n    Surface _4382 = fa_standard_surface(param_1);\n    float3 _4778 = _4382.albedo;\n    float _4779 = _4382.alpha;\n    float3 _4780 = _4382.normal;\n    float _4781 = _4382.metallic;\n    float _4782 = _4382.roughness;\n    float _4783 = _4382.occlusion;\n    float3 _4784 = _4382.emission;\n    float _4785 = _4382.clearcoat;\n    float _4786 = _4382.clearcoat_roughness;\n    float3 _4787 = _4382.sheen_color;\n    float _4788 = _4382.sheen_roughness;\n    float _4789 = _4382.anisotropy;\n    float _4790 = _4382.anisotropy_rotation;\n    float _4791 = _4382.specular;\n    float _4792 = _4382.ior;\n    float3 _4793 = _4382.specular_color;\n    SurfaceInput _4760 = { fa_world_pos, _4739, fa_world_tangent, fa_uv, fa_vertex_color, _4374, gl_FrontFacing };\n    SurfaceInput param_2 = _4760;\n    Surface param_3 = _4382;\n    surface(param_2, param_3);\n    _4778 = param_3.albedo;\n    _4779 = param_3.alpha;\n    _4780 = param_3.normal;\n    _4781 = param_3.metallic;\n    _4782 = param_3.roughness;\n    _4783 = param_3.occlusion;\n    _4784 = param_3.emission;\n    _4785 = param_3.clearcoat;\n    _4786 = param_3.clearcoat_roughness;\n    _4787 = param_3.sheen_color;\n    _4788 = param_3.sheen_roughness;\n    _4789 = param_3.anisotropy;\n    _4790 = param_3.anisotropy_rotation;\n    _4791 = param_3.specular;\n    _4792 = param_3.ior;\n    _4793 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4739;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4778 = param_6;\n    _4780 = param_7;\n    float3 result;\n    if (_365_fa_emissive.w > 0.5f)\n    {\n        result = _4778;\n    }\n    else\n    {\n        float3 _4420 = _4780;\n        float3 _4421 = normalize(_4420);\n        _4780 = _4421;\n        float3 param_8 = _4421;\n        SurfaceInput _4768 = { fa_world_pos, _4739, fa_world_tangent, fa_uv, fa_vertex_color, _4374, gl_FrontFacing };\n        SurfaceInput param_9 = _4768;\n        Surface _4859 = { _4778, _4779, _4780, _4781, _4782, _4783, _4784, _4785, _4786, _4787, _4788, _4789, _4790, _4791, _4792, _4793 };\n        Surface param_10 = _4859;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4440 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4440; ln++)\n        {\n            int param_12 = ln;\n            int _4453 = fa_cl_light(param_12);\n            bool _4456 = fa_lm.z > 0.5f;\n            bool _4462;\n            if (_4456)\n            {\n                int param_13 = _4453;\n                _4462 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _4462 = _4456;\n            }\n            if (_4462)\n            {\n                continue;\n            }\n            int param_14 = _4453;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _4739;\n            LightSample _4474 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _4776 = { fa_world_pos, _4739, fa_world_tangent, fa_uv, fa_vertex_color, _4374, gl_FrontFacing };\n            SurfaceInput param_17 = _4776;\n            Surface _4876 = { _4778, _4779, _4780, _4781, _4782, _4783, _4784, _4785, _4786, _4787, _4788, _4789, _4790, _4791, _4792, _4793 };\n            Surface param_18 = _4876;\n            LightSample param_19 = _4474;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4489 = result;\n    float3 _4490 = _4489 + _4784;\n    result = _4490;\n    float3 param_20 = _4490;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4499 = _365_fa_fog.w > 0.0f;\n    bool _4506;\n    if (!_4499)\n    {\n        _4506 = _365_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4506 = _4499;\n    }\n    if (_4506)\n    {\n        float3 _4515 = fa_world_pos - _365_fa_camera_pos.xyz;\n        float _4521 = dot(_4515, _365_fa_fog_c.xyz);\n        bool _4525 = _365_fa_fog_c.w > 0.5f;\n        float _4526;\n        if (_4525)\n        {\n            _4526 = _4521;\n        }\n        else\n        {\n            _4526 = length(_4515);\n        }\n        float _4538 = _4526 - _365_fa_fog_b.x;\n        if (_4538 > 0.0f)\n        {\n            float _4547 = _365_fa_fog.w * _4538;\n            float tau = _4547 * _4547;\n            if (_365_fa_fog_b.y > 0.0f)\n            {\n                float _4563;\n                if (_4525)\n                {\n                    _4563 = fa_world_pos.y - (_365_fa_fog_c.y * _4521);\n                }\n                else\n                {\n                    _4563 = _365_fa_camera_pos.y;\n                }\n                float _4584 = lerp(_4563, fa_world_pos.y, clamp(_365_fa_fog_b.x / _4526, 0.0f, 1.0f));\n                float _4588 = fa_world_pos.y - _4584;\n                float _4593 = _4584 - _365_fa_fog_b.z;\n                float _4598 = fa_world_pos.y - _365_fa_fog_b.z;\n                bool _4601 = _4593 <= 0.0f;\n                bool _4602 = !_4601;\n                bool _4608;\n                if (_4602)\n                {\n                    _4608 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4608 = _4601;\n                }\n                float _4609;\n                if (_4608)\n                {\n                    _4609 = _365_fa_fog_b.y;\n                }\n                else\n                {\n                    _4609 = _365_fa_fog_b.y * exp(-min(_365_fa_fog_b.w * _4593, 80.0f));\n                }\n                bool _4636;\n                if (_4602)\n                {\n                    _4636 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4636 = _4601;\n                }\n                float _4637;\n                if (_4636)\n                {\n                    _4637 = _365_fa_fog_b.y * _4593;\n                }\n                else\n                {\n                    _4637 = (_365_fa_fog_b.y * (1.0f - exp(-min(_365_fa_fog_b.w * _4593, 80.0f)))) / _365_fa_fog_b.w;\n                }\n                bool _4662 = _4598 <= 0.0f;\n                bool _4669;\n                if (!_4662)\n                {\n                    _4669 = _365_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4669 = _4662;\n                }\n                float _4670;\n                if (_4669)\n                {\n                    _4670 = _365_fa_fog_b.y * _4598;\n                }\n                else\n                {\n                    _4670 = (_365_fa_fog_b.y * (1.0f - exp(-min(_365_fa_fog_b.w * _4598, 80.0f)))) / _365_fa_fog_b.w;\n                }\n                float _4697;\n                if (abs(_4588) < 0.001000000047497451305389404296875f)\n                {\n                    _4697 = _4609;\n                }\n                else\n                {\n                    _4697 = (_4670 - _4637) / _4588;\n                }\n                tau += (_4538 * max(_4697, 0.0f));\n            }\n            result = lerp(result, _365_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4779);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_365",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2062",
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
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 9
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
              "hlsl_register_t_n": 10
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
              "hlsl_register_t_n": 11
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 11,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _785 = base_t;\n    _785.x = _225.x;\n    _785.y = _225.y;\n    _785.z = _225.z;\n    base_t = _785;\n    float4 _241 = (_785 * _213_fa_base_color) * i.vertex_color;\n    float3 _748 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _793 = _279;\n        _793.x = _284.x;\n        _793.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _796 = mrt;\n    _796.x = _313.x;\n    _796.y = _313.y;\n    _796.z = _313.z;\n    mrt = _796;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _753 = _213_fa_layers_a.x;\n    float _754 = _213_fa_layers_a.y;\n    float _757 = _213_fa_layers_a.z;\n    float _756 = _213_fa_layers_b.w;\n    float _759 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _753 *= _355.y;\n            _754 *= _355.z;\n            _756 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    Surface _778 = { _241.xyz, _241.w, _748, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _753, _754, _213_fa_layers_b.xyz, _756, _757, _213_fa_layers_a.w, _759, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _778;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _672 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _672;\n    SurfaceInput _680 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _680;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _413 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _413;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0f);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _785 = base_t;\n    _785.x = _225.x;\n    _785.y = _225.y;\n    _785.z = _225.z;\n    base_t = _785;\n    float4 _241 = (_785 * _213_fa_base_color) * i.vertex_color;\n    float3 _748 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _793 = _279;\n        _793.x = _284.x;\n        _793.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _796 = mrt;\n    _796.x = _313.x;\n    _796.y = _313.y;\n    _796.z = _313.z;\n    mrt = _796;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _753 = _213_fa_layers_a.x;\n    float _754 = _213_fa_layers_a.y;\n    float _757 = _213_fa_layers_a.z;\n    float _756 = _213_fa_layers_b.w;\n    float _759 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _753 *= _355.y;\n            _754 *= _355.z;\n            _756 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    Surface _778 = { _241.xyz, _241.w, _748, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _753, _754, _213_fa_layers_b.xyz, _756, _757, _213_fa_layers_a.w, _759, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _778;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _672 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _672;\n    SurfaceInput _680 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _680;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
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
    }
  }
}
