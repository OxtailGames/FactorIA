{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "550ff47e6dc7e71192661fb1e526df6e96f66de981c805742262dd122b44bf86",
  "slang": "hlsl5",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _153_fa_view_proj : packoffset(c0);\n    row_major float4x4 _153_fa_light_vp : packoffset(c4);\n    float4 _153_fa_uv_scale : packoffset(c8);\n    float4 _153_fa_time : packoffset(c9);\n    float4 _153_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_inst_d0 : TEXCOORD9;\n    float4 fa_inst_d1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float3 fa_lm : TEXCOORD7;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _302 = { mul(float4(position, 1.0f), model).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153_fa_uv_scale.xy, color, position };\n    return _302;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _153_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3663[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _566_fa_camera_pos : packoffset(c0);\n    float4 _566_fa_ambient : packoffset(c1);\n    float4 _566_fa_base_color : packoffset(c2);\n    float4 _566_fa_emissive : packoffset(c3);\n    float4 _566_fa_model_emissive : packoffset(c4);\n    float4 _566_fa_pbr : packoffset(c5);\n    float4 _566_fa_maps : packoffset(c6);\n    float4 _566_fa_fog : packoffset(c7);\n    float4 _566_fa_fog_b : packoffset(c8);\n    float4 _566_fa_fog_c : packoffset(c9);\n    float4 _566_fa_counts : packoffset(c10);\n    float4 _566_fa_env_sky : packoffset(c11);\n    float4 _566_fa_env_horizon : packoffset(c12);\n    float4 _566_fa_time : packoffset(c13);\n    float4 _566_fa_cl_vpx : packoffset(c14);\n    float4 _566_fa_cl_vpy : packoffset(c15);\n    float4 _566_fa_cl_vpw : packoffset(c16);\n    float4 _566_fa_cl_fwd : packoffset(c17);\n    float4 _566_fa_cl_grid : packoffset(c18);\n    float4 _566_fa_cl_info : packoffset(c19);\n    float4 _566_fa_layers_a : packoffset(c20);\n    float4 _566_fa_layers_b : packoffset(c21);\n    float4 _566_fa_layers_c : packoffset(c22);\n    float4 _566_fa_layers_d : packoffset(c23);\n    float4 _566_fa_ct_a : packoffset(c24);\n    float4 _566_fa_ct_b : packoffset(c25);\n    float4 _566_fa_ct_vpx : packoffset(c26);\n    float4 _566_fa_ct_vpy : packoffset(c27);\n    float4 _566_fa_ct_vpw : packoffset(c28);\n    float4 _566_fa_ct_fwd : packoffset(c29);\n    float4 _566_fa_probe_sh[9] : packoffset(c30);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2233_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2233_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2233_fa_shadow_info[4] : packoffset(c20);\n    float4 _2233_fa_shadow_split : packoffset(c24);\n    float4 _2233_fa_shadow_cfg : packoffset(c25);\n    float4 _2233_fa_shadow_bias : packoffset(c26);\n    float4 _2233_fa_shadow_eye : packoffset(c27);\n    float4 _2233_fa_shadow_fwd : packoffset(c28);\n    float4 _2233_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5873_boost : packoffset(c0);\n    float _5873_fa_pad0 : packoffset(c0.y);\n    float _5873_fa_pad1 : packoffset(c0.z);\n    float _5873_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float3 fa_lm : TEXCOORD7;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1504 = _566_fa_cl_info.x < 0.0f;\n    bool _1511;\n    if (!_1504)\n    {\n        _1511 = _566_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1511 = _1504;\n    }\n    bool _1519;\n    if (!_1511)\n    {\n        _1519 = _566_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1519 = _1511;\n    }\n    bool _1526;\n    if (!_1519)\n    {\n        _1526 = _566_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1526 = _1519;\n    }\n    bool _1533;\n    if (!_1526)\n    {\n        _1533 = _566_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1533 = _1526;\n    }\n    if (_1533)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1543 = float4(world_pos, 1.0f);\n    float _1549 = dot(_566_fa_cl_vpw, _1543);\n    if (!(_1549 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1571 = float2(dot(_566_fa_cl_vpx, _1543), dot(_566_fa_cl_vpy, _1543)) / _1549.xx;\n    int _1575 = int(_566_fa_cl_grid.x);\n    int _1579 = int(_566_fa_cl_grid.y);\n    int param = (int(_566_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_566_fa_cl_fwd.xyz, world_pos) + _566_fa_cl_fwd.w, _566_fa_cl_grid.w) / _566_fa_cl_grid.w) * _566_fa_cl_grid.z)), 0, int(_566_fa_cl_info.y) - 1) * _1579) + clamp(int(floor(((_1571.y * 0.5f) + 0.5f) * _566_fa_cl_grid.y)), 0, _1579 - 1)) * _1575)) + clamp(int(floor(((_1571.x * 0.5f) + 0.5f) * _566_fa_cl_grid.x)), 0, _1575 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1655 = fa_cluster_texel(param);\n    return int2(int(_1655.x), int(_1655.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_566_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4761 = fa_cluster_lookup(param);\n    fa_cl_slot = _4761.x;\n    fa_cl_local = _4761.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5925 = fa_linear_to_srgb(param);\n        c = _5925;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5933 = fa_srgb_to_linear(param_1);\n            c = _5933;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _448;\n    if (i.front_facing)\n    {\n        _448 = i.world_normal;\n    }\n    else\n    {\n        _448 = -i.world_normal;\n    }\n    float3 _472 = normalize(i.world_tangent.xyz - (_448 * dot(_448, i.world_tangent.xyz)));\n    float3 _499 = normalize(((_472 * m.x) + ((cross(_448, _472) * i.world_tangent.w) * m.y)) + (_448 * m.z));\n    float3 _502;\n    if (i.front_facing)\n    {\n        _502 = _499;\n    }\n    else\n    {\n        _502 = -_499;\n    }\n    return _502;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _566_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5964 = fa_tex_fix(param_2, param_3);\n    float4 _7424 = base_t;\n    _7424.x = _5964.x;\n    _7424.y = _5964.y;\n    _7424.z = _5964.z;\n    base_t = _7424;\n    float4 _5978 = (_7424 * _566_fa_base_color) * i.vertex_color;\n    float3 _7249 = i.world_normal;\n    if (_566_fa_maps.z > 0.5f)\n    {\n        float param_4 = _566_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _6010 = fa_tex_fix(param_6, param_7);\n        float3 _6013 = (_6010 * 2.0f) - 1.0f.xxx;\n        float2 _6018 = _6013.xy * _566_fa_maps.x;\n        float3 _7432 = _6013;\n        _7432.x = _6018.x;\n        _7432.y = _6018.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _7432;\n        _7249 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _566_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _6046 = fa_tex_fix(param_12, param_13);\n    float4 _7435 = mrt;\n    _7435.x = _6046.x;\n    _7435.y = _6046.y;\n    _7435.z = _6046.z;\n    mrt = _7435;\n    float4 _6074 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _566_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _6074.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _6085 = fa_tex_fix(param_16, param_17);\n    float param_18 = _566_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _6115 = fa_tex_fix(param_20, param_21);\n    float _7254 = _566_fa_layers_a.x;\n    float _7255 = _566_fa_layers_a.y;\n    float _7258 = _566_fa_layers_a.z;\n    float _7257 = _566_fa_layers_b.w;\n    float _7260 = _566_fa_layers_c.x;\n    if (_566_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_566_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _7254 *= _6085.y;\n            _7255 *= _6085.z;\n            _7257 *= _6074.w;\n        }\n        if (_566_fa_layers_c.z > 1.5f)\n        {\n            _7258 *= mrt.x;\n            _7260 *= mrt.w;\n        }\n    }\n    Surface _7279 = { _5978.xyz, _5978.w, _7249, clamp(_566_fa_pbr.x * _6046.z, 0.0f, 1.0f), clamp(_566_fa_pbr.y * _6046.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_566_fa_maps.y * (_6085.x - 1.0f)), _566_fa_emissive.xyz + (_566_fa_model_emissive.xyz * _6115), _7254, _7255, _566_fa_layers_b.xyz, _7257, _7258, _566_fa_layers_a.w, _7260, _566_fa_layers_c.y, _566_fa_layers_d.xyz };\n    return _7279;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _5873_boost);\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1735 = rect.zw - rect.xy;\n    float2 _1739 = _1735 * atlas;\n    float2 _1743 = ddx * _1739;\n    float2 _1747 = ddy * _1739;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1735), clamp(0.5f * log2(max(max(dot(_1743, _1743), dot(_1747, _1747)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1780 = _566_fa_counts.y < 0.5f;\n    bool _1787;\n    if (!_1780)\n    {\n        _1787 = _566_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1787 = _1780;\n    }\n    if (_1787)\n    {\n        return;\n    }\n    float3 _1793 = ddx(world_pos);\n    float3 _1796 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1800 = fa_cluster_texel(param);\n    int _1804 = int(_1800.w);\n    if (_1804 < 1)\n    {\n        return;\n    }\n    int _1814 = int(_566_fa_counts.y + 0.5f);\n    int param_1 = _1814;\n    float4 _1818 = fa_light_texel(param_1);\n    float2 _1821 = _1818.yz;\n    int _1825 = int(_1818.w);\n    int param_2 = _1814 + 1;\n    float4 _1830 = fa_light_texel(param_2);\n    float _1831 = _1830.x;\n    int _1837 = int(_566_fa_counts.w + 0.5f) - 1;\n    int _1841 = int(_1800.z);\n    float3 _2106;\n    for (int k = 0; k < _1804; k++)\n    {\n        int _1854 = _1841 + k;\n        int param_3 = _1825 + (_1854 >> 2);\n        int _1871 = (_1814 + 2) + (int(fa_light_texel(param_3)[_1854 & 3]) * 7);\n        int param_4 = _1871 + 6;\n        float4 _1876 = fa_light_texel(param_4);\n        if (((int(_1876.w + 0.5f) >> _1837) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1871;\n        float4 _1891 = fa_light_texel(param_5);\n        int param_6 = _1871 + 1;\n        float4 _1896 = fa_light_texel(param_6);\n        int param_7 = _1871 + 2;\n        float4 _1901 = fa_light_texel(param_7);\n        float3 _1904 = _1891.xyz;\n        float _1909 = dot(_1904, world_pos) + _1891.w;\n        float3 _1911 = _1896.xyz;\n        float _1916 = dot(_1911, world_pos) + _1896.w;\n        float3 _1918 = _1901.xyz;\n        float _1923 = dot(_1918, world_pos) + _1901.w;\n        bool _1928 = abs(_1909) > 0.5f;\n        bool _1936;\n        if (!_1928)\n        {\n            _1936 = abs(_1916) > 0.5f;\n        }\n        else\n        {\n            _1936 = _1928;\n        }\n        bool _1944;\n        if (!_1936)\n        {\n            _1944 = abs(_1923) > 0.5f;\n        }\n        else\n        {\n            _1944 = _1936;\n        }\n        if (_1944)\n        {\n            continue;\n        }\n        float _1959 = clamp(dot(geo_normal, normalize(_1918)) * _1876.z, 0.0f, 1.0f);\n        if (_1959 <= 0.0f)\n        {\n            continue;\n        }\n        float _1979 = (clamp((0.5f - abs(_1923)) * 10.0f, 0.0f, 1.0f) * _1959) * _1876.x;\n        float2 _1987 = float2(_1909 + 0.5f, 0.5f - _1916);\n        float2 _1997 = float2(dot(_1904, _1793), dot(_1911, _1793));\n        float2 _2007 = float2(dot(_1904, _1796), dot(_1911, _1796));\n        int param_8 = _1871 + 5;\n        float4 _2012 = fa_light_texel(param_8);\n        int param_9 = _1871 + 3;\n        float4 _2017 = fa_light_texel(param_9);\n        int param_10 = _1871 + 4;\n        float4 _2022 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2012.xyz;\n        bool _2032 = _2017.z > _2017.x;\n        if (_2032)\n        {\n            float4 param_11 = _2017;\n            float2 param_12 = _1987;\n            float2 param_13 = _1821;\n            float2 param_14 = _1997;\n            float2 param_15 = _2007;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1831 > 0.5f) && (_1831 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2058 = fa_dc_to_linear(param_16);\n                float4 _7329 = tx;\n                _7329.x = _2058.x;\n                _7329.y = _2058.y;\n                _7329.z = _2058.z;\n                tx = _7329;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1979 * tex_a) * _2012.w, 0.0f, 1.0f).xxx);\n        if (_2022.z > _2022.x)\n        {\n            float4 param_17 = _2022;\n            float2 param_18 = _1987;\n            float2 param_19 = _1821;\n            float2 param_20 = _1997;\n            float2 param_21 = _2007;\n            float4 _2102 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1831 > 1.5f)\n            {\n                float3 param_22 = _2102.xyz;\n                float3 _2112 = fa_dc_to_srgb(param_22);\n                _2106 = _2112;\n            }\n            else\n            {\n                _2106 = _2102.xyz;\n            }\n            float3 _2121 = (_2106 * 2.0f) - 1.0f.xxx;\n            float2 _2126 = _2121.xy * _1876.y;\n            float3 _2148 = (normalize(_1904) * _2126.x) + (normalize(_1911) * _2126.y);\n            float3 _2151 = normalize(normal);\n            normal = normalize(lerp(_2151, normalize((_2151 * max(_2121.z, 0.0500000007450580596923828125f)) + (_2148 - (_2151 * dot(_2151, _2148)))), clamp(_1979 * (_2032 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3589 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3596 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3599 = int(_3589);\n    int _3602 = int(_3596);\n    float _3612 = _3596 - float(_3602);\n    int _3667 = (_3599 * 9) + _3602;\n    int _3687 = ((_3599 + 1) * 9) + _3602;\n    return lerp(lerp(_3663[_3667], _3663[_3667 + 1], _3612), lerp(_3663[_3687], _3663[_3687 + 1], _3612), _3589 - float(_3599));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _7172 = false;\n    float _7173 = 1.0f;\n    float _7174 = 1.0f;\n    float _7175 = 1.0f;\n    float _7176 = 0.0f;\n    float _7177 = 0.0f;\n    float _7178 = 0.0f;\n    float _7179 = 0.0f;\n    float _7181 = 1.0f;\n    bool _7182 = false;\n    float3 _7183 = 0.0f.xxx;\n    float _7184 = 1.0f;\n    float _7185 = 1.0f;\n    float _7186 = 1.0f;\n    float _7187 = 0.0f;\n    float _7188 = 0.0f;\n    float3 _7189 = float3(1.0f, 0.0f, 0.0f);\n    float3 _7190 = float3(0.0f, 0.0f, 1.0f);\n    float _7191 = 1.0f;\n    float _7192 = 1.0f;\n    float _3738 = clamp(s.specular, 0.0f, 1.0f);\n    float _3742 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3747 = (_3738 != 1.0f) || (_3742 != 1.5f);\n    bool _3756;\n    if (!_3747)\n    {\n        _3756 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3756 = _3747;\n    }\n    if (_3756)\n    {\n        float _3764 = (_3742 - 1.0f) / (_3742 + 1.0f);\n        f0 = lerp(min((_3764 * _3764).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3738, s.albedo, metallic.xxx);\n        _7173 = lerp(_3738, 1.0f, metallic);\n        _7172 = true;\n    }\n    float _3791 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3791 > 0.0f)\n    {\n        float _3799 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _7176 = _3791;\n        _7177 = _3799;\n        float _3806 = _3799 * _3799;\n        _7178 = _3806;\n        _7179 = _3806 * _3806;\n        float _3818 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _7181 = _3818;\n        _7174 = 1.0f - (_3791 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3818, 0.0f, 1.0f), 5.0f))));\n        _7172 = true;\n    }\n    float3 _3837 = max(s.sheen_color, 0.0f.xxx);\n    float _3846 = max(_3837.x, max(_3837.y, _3837.z));\n    if (_3846 > 0.0f)\n    {\n        float _3854 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _7182 = true;\n        _7183 = _3837;\n        _7184 = _3854;\n        _7185 = _3854 * _3854;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3854;\n        float _3871 = fa_sheen_albedo(param, param_1);\n        _7187 = _3871;\n        _7186 = 1.0f - min(_3846 * _3871, 1.0f);\n        _7172 = true;\n    }\n    _7175 = _7174 * _7186;\n    float _3890 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3890 != 0.0f)\n    {\n        float3 _3905 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3905;\n        if (dot(_3905, _3905) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3917 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3917.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3917.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3917.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3921 = t;\n        float3 _3922 = normalize(_3921);\n        t = _3922;\n        float3 _3947 = normalize((_3922 * cos(s.anisotropy_rotation)) + ((cross(n, _3922) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _7189 = _3947;\n        _7190 = cross(n, _3947);\n        float _3957 = roughness * roughness;\n        float _3963 = lerp(_3957, 1.0f, _3890 * _3890);\n        bool _3965 = _3890 > 0.0f;\n        _7191 = _3965 ? _3963 : _3957;\n        _7192 = _3965 ? _3957 : _3963;\n        _7188 = _3890;\n        _7172 = true;\n    }\n    FaLayers _7214 = { _7172, _7173, _7174, _7175, _7176, _7177, _7178, _7179, i.world_normal, _7181, _7182, _7183, _7184, _7185, _7186, _7187, _7188, _7189, _7190, _7191, _7192 };\n    return _7214;\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_566_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3346 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3346;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_566_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _566_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_566_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _566_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_566_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_566_fa_cl_info.x) + int(_566_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_566_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4731;\n    if (fa_lm.z > 0.5f)\n    {\n        _4731 = 0.0f;\n    }\n    else\n    {\n        _4731 = 1.0f - clamp(_566_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4742 = _4731 < 1.0f;\n    bool _4748;\n    if (_4742)\n    {\n        int param = li;\n        _4748 = fa_light_baked(param);\n    }\n    else\n    {\n        _4748 = _4742;\n    }\n    return _4748 ? _4731 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _634_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _634_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _753 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _766 = (c - (ru * hx)) - p;\n        float3 _772 = ru * (2.0f * hx);\n        float _778 = max(dot(_772, _772), 9.9999999392252902907785028219223e-09f);\n        float _782 = dot(_766, _772);\n        float t = clamp((-_782) / _778, 0.0f, 1.0f);\n        if (_753)\n        {\n            float _797 = dot(r, _772);\n            float _803 = _778 - (_797 * _797);\n            if (abs(_803) > (9.9999997473787516355514526367188e-06f * _778))\n            {\n                t = clamp(((dot(r, _766) * _797) - _782) / _803, 0.0f, 1.0f);\n            }\n        }\n        return (p + _766) + (_772 * t);\n    }\n    float3 q = p;\n    float _835 = dot(r, axis);\n    bool _843;\n    if (_753)\n    {\n        _843 = abs(_835) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _843 = _753;\n    }\n    if (_843)\n    {\n        float _853 = dot(c - p, axis) / _835;\n        if (_853 > 0.0f)\n        {\n            q = p + (r * _853);\n        }\n    }\n    float3 _866 = q - c;\n    float2 xy = float2(dot(_866, ru), dot(_866, uu));\n    if (shape > 0.5f)\n    {\n        float _881 = length(xy);\n        if (_881 > hx)\n        {\n            xy *= (hx / _881);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _514 = abs(d);\n    float _516 = _514.x;\n    float _518 = _514.y;\n    bool _519 = _516 >= _518;\n    bool _527;\n    if (_519)\n    {\n        _527 = _516 >= _514.z;\n    }\n    else\n    {\n        _527 = _519;\n    }\n    int _528;\n    if (_527)\n    {\n        _528 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _543;\n        if (_518 >= _514.z)\n        {\n            _543 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _543 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _528 = _543;\n    }\n    return _528;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _673 = dot(d, right);\n    float _677 = dot(d, up);\n    float _688;\n    if (((_673 * _673) + (_677 * _677)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _688 = atan2(_677, _673) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _688 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_688 - floor(_688)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _919 = fa_light_base(param);\n    bool _923 = _566_fa_ambient.w > 4.5f;\n    int param_1 = _919;\n    float4 _927 = fa_light_texel(param_1);\n    int param_2 = _919 + 1;\n    float4 _932 = fa_light_texel(param_2);\n    float _935 = _932.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _947 = _923 && (_935 > 2.5f);\n    fa_light_is_area = _947;\n    bool _949 = _935 < 0.5f;\n    float3 l;\n    if (_949)\n    {\n        l = normalize(_927.xyz);\n        if (_923)\n        {\n            int param_3 = _919 + 6;\n            float4 _963 = fa_light_texel(param_3);\n            if (_963.z > 0.5f)\n            {\n                int param_4 = _919 + 4;\n                float4 _973 = fa_light_texel(param_4);\n                int param_5 = _919 + 5;\n                float4 _978 = fa_light_texel(param_5);\n                float2 param_6 = _963.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _973.xyz) * _973.w, (-dot(world_pos, _978.xyz)) * _978.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1008 = _927.xyz;\n        float3 _1010 = _1008 - world_pos;\n        float3 to_light = _1010;\n        float _1013 = length(_1010);\n        float reach = _1013;\n        bool front = true;\n        if (_947)\n        {\n            int param_8 = _919 + 7;\n            reach = max(_1013 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _919 + 4;\n            float4 _1037 = fa_light_texel(param_9);\n            int param_10 = _919 + 5;\n            float4 _1042 = fa_light_texel(param_10);\n            int param_11 = _919 + 6;\n            float4 _1047 = fa_light_texel(param_11);\n            float _1048 = _1047.w;\n            int param_12 = _919 + 2;\n            float3 _1055 = normalize(fa_light_texel(param_12).xyz);\n            bool _1057 = _1048 > 1.5f;\n            bool _1065;\n            if (!_1057)\n            {\n                _1065 = dot(_1055, to_light) < 0.0f;\n            }\n            else\n            {\n                _1065 = _1057;\n            }\n            front = _1065;\n            float3 r = 0.0f.xxx;\n            float3 _1074 = _566_fa_camera_pos.xyz - world_pos;\n            bool _1078 = dot(n, n) > 0.5f;\n            bool _1086;\n            if (_1078)\n            {\n                _1086 = dot(_1074, _1074) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1086 = _1078;\n            }\n            if (_1086)\n            {\n                r = reflect(-normalize(_1074), normalize(n));\n            }\n            float3 param_13 = _1008;\n            float3 param_14 = _1055;\n            float3 param_15 = _1037.xyz;\n            float3 param_16 = _1042.xyz;\n            float param_17 = _1037.w;\n            float param_18 = _1042.w;\n            float param_19 = _1048;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1122 = length(to_light);\n        dist = _1122;\n        l = to_light / max(_1122, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1136 = reach / max(_927.w, 0.001000000047497451305389404296875f);\n        float _1142 = clamp(1.0f - (_1136 * _1136), 0.0f, 1.0f);\n        float _1144;\n        if (front)\n        {\n            _1144 = _1142 * _1142;\n        }\n        else\n        {\n            _1144 = 0.0f;\n        }\n        atten = _1144;\n        bool _1155 = _935 < 2.5f;\n        if ((_935 > 1.5f) && _1155)\n        {\n            int param_22 = _919 + 2;\n            float4 _1163 = fa_light_texel(param_22);\n            float _1173 = _1163.w;\n            int param_23 = _919 + 3;\n            float4 _1178 = fa_light_texel(param_23);\n            float _1179 = _1178.x;\n            float cos_inner = _1179;\n            if (_1179 > 1.5f)\n            {\n                cos_inner = lerp(_1173, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1173, cos_inner, dot(-l, normalize(_1163.xyz)));\n        }\n        if (_923 && (_935 < 1.5f))\n        {\n            int param_24 = _919 + 6;\n            float4 _1203 = fa_light_texel(param_24);\n            if (_1203.z > 0.5f)\n            {\n                float3 _1211 = -to_light;\n                int param_25 = _919 + 4;\n                int param_26 = _919 + 5;\n                float3 _1225 = fa_light_texel(param_25).xyz;\n                float3 _1229 = fa_light_texel(param_26).xyz;\n                float3 _1238 = float3(dot(_1211, _1225), dot(_1211, _1229), dot(_1211, cross(_1225, _1229)));\n                float3 param_27 = _1238;\n                int _1242 = fa_cube_face(param_27);\n                int param_28 = _1242;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1269 = float2(dot(_1238, cross(param_29, param_30)), dot(_1238, param_30)) / max(dot(_1238, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1273 = _1242 / 3;\n                float2 param_31 = _1203.xy + (float2(float(_1242 - (_1273 * 3)), float(_1273)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1269.x), 0.5f - (0.5f * _1269.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _919 + 7;\n            float4 _1303 = fa_light_texel(param_33);\n            if (_1303.z > 0.5f)\n            {\n                int param_34 = _919 + 2;\n                int param_35 = _919 + 4;\n                int param_36 = _919 + 5;\n                float2 param_37 = _1303.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_923 && _1155)\n            {\n                int param_42 = _919 + 6;\n                float4 _1350 = fa_light_texel(param_42);\n                int param_43 = _919 + 7;\n                float4 _1355 = fa_light_texel(param_43);\n                bool _1358 = _1350.z > 0.5f;\n                bool _1365;\n                if (!_1358)\n                {\n                    _1365 = _1355.z > 0.5f;\n                }\n                else\n                {\n                    _1365 = _1358;\n                }\n                if (_1365)\n                {\n                    int param_44 = _919 + 2;\n                    float4 _1372 = fa_light_texel(param_44);\n                    float3 _1376 = normalize(_1372.xyz);\n                    int param_45 = _919 + 4;\n                    float4 _1381 = fa_light_texel(param_45);\n                    int param_46 = _919 + 5;\n                    float4 _1386 = fa_light_texel(param_46);\n                    if (_1358)\n                    {\n                        float3 _1394 = -to_light;\n                        float _1401 = _1372.w;\n                        float _1417 = 0.5f / max(dot(_1394, _1376) * (sqrt(max(1.0f - (_1401 * _1401), 0.0f)) / max(_1401, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1350.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1394, _1381.xyz) * _1417), 0.5f - (dot(_1394, _1386.xyz) * _1417));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1355.z > 0.5f)\n                    {\n                        float2 param_49 = _1355.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1376;\n                        float3 param_52 = _1381.xyz;\n                        float3 param_53 = _1386.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _7160 = _932.xyz * atten;\n    if (_923)\n    {\n        _7160 *= fa_light_tint;\n    }\n    int _1486;\n    if (_949)\n    {\n        _1486 = 0;\n    }\n    else\n    {\n        _1486 = ((_935 > 1.5f) && (_935 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _7171 = { l, _7160, atten, 1.0f, dist, _1486 };\n    return _7171;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2223;\n    if (i == 0)\n    {\n        _2223 = _2233_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2239;\n        if (i == 1)\n        {\n            _2239 = _2233_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2247;\n            if (i == 2)\n            {\n                _2247 = _2233_fa_shadow_split.z;\n            }\n            else\n            {\n                _2247 = _2233_fa_shadow_split.w;\n            }\n            _2239 = _2247;\n        }\n        _2223 = _2239;\n    }\n    return _2223;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2280 = fa_shadow_depth(param, param_1);\n    float _2284;\n    if (conv.x < 0.5f)\n    {\n        _2284 = _2280;\n    }\n    else\n    {\n        _2284 = (conv.y * conv.z) / (conv.z - (_2280 * (conv.z - conv.y)));\n    }\n    return _2284;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2211 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2211), sin(_2211)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2330 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2339;\n        if (k < 0.0f)\n        {\n            _2339 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2339 = k;\n        }\n        float _2359 = clamp((_2339 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2330;\n            float2 _2378 = fa_shadow_vogel(param_3, param_4, param_5) * _2359;\n            float2 param_6 = uv + (_2378 * _2233_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2390 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2390 < (zr - (length(_2378) * plane)))\n            {\n                sum += _2390;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2416 = sum / cnt;\n        float _2426;\n        if (k < 0.0f)\n        {\n            _2426 = (-k) / max(_2416, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2426 = k;\n        }\n        radius = clamp(((max(zr - _2416, 0.0f) * unit) * _2426) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2448 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2448; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2448;\n        float param_11 = _2330;\n        float2 _2467 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2467 * _2233_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2467) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2448);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2509 = max(_2233_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2514 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2520 = sqrt(1.0f - (_2514 * _2514));\n    float _2527 = min(_2520 / max(_2514, 0.20000000298023223876953125f), 4.0f);\n    float _2532;\n    if (_2233_fa_shadow_bias.y > 0.0f)\n    {\n        _2532 = _2233_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2532 = 1.5f * _2233_fa_shadow_info[ci].x;\n    }\n    float4 _2557 = mul(float4(world + (n * (_2532 * _2520)), 1.0f), _2233_fa_shadow_mat[ci]);\n    float _2564 = _2557.x;\n    bool _2567 = _2564 < _2233_fa_shadow_rect[ci].x;\n    bool _2576;\n    if (!_2567)\n    {\n        _2576 = _2564 > _2233_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2576 = _2567;\n    }\n    bool _2585;\n    if (!_2576)\n    {\n        _2585 = _2557.y < _2233_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2585 = _2576;\n    }\n    bool _2594;\n    if (!_2585)\n    {\n        _2594 = _2557.y > _2233_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2594 = _2585;\n    }\n    bool _2601;\n    if (!_2594)\n    {\n        _2601 = _2557.z > 1.0f;\n    }\n    else\n    {\n        _2601 = _2594;\n    }\n    if (_2601)\n    {\n        return -1.0f;\n    }\n    float _2609;\n    if (_2233_fa_shadow_bias.x > 0.0f)\n    {\n        _2609 = _2233_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2609 = 1.5f * _2233_fa_shadow_info[ci].x;\n    }\n    float2 param = _2557.xy;\n    float4 param_1 = _2233_fa_shadow_rect[ci];\n    float param_2 = _2557.z - ((_2609 * (1.0f + (0.5f * _2527))) / _2509);\n    float param_3 = _2233_fa_shadow_info[ci].x;\n    float param_4 = _2509;\n    float param_5 = _2509 * 0.25f;\n    float param_6 = ((_2233_fa_shadow_info[ci].x * min(_2527, 3.0f)) * 0.5f) / _2509;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2233_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2233_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_566_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2987 = int(_2233_fa_shadow_cfg.x + 0.5f);\n    if (_2987 < 1)\n    {\n        return 1.0f;\n    }\n    float _3002 = dot(world - _2233_fa_shadow_eye.xyz, _2233_fa_shadow_fwd.xyz);\n    int param = _2987 - 1;\n    if (_3002 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3014 = _2987 > 1;\n    bool _3021;\n    if (_3014)\n    {\n        _3021 = _3002 > _2233_fa_shadow_split.x;\n    }\n    else\n    {\n        _3021 = _3014;\n    }\n    if (_3021)\n    {\n        ci = 1;\n    }\n    bool _3025 = _2987 > 2;\n    bool _3032;\n    if (_3025)\n    {\n        _3032 = _3002 > _2233_fa_shadow_split.y;\n    }\n    else\n    {\n        _3032 = _3025;\n    }\n    if (_3032)\n    {\n        ci = 2;\n    }\n    bool _3036 = _2987 > 3;\n    bool _3043;\n    if (_3036)\n    {\n        _3043 = _3002 > _2233_fa_shadow_split.z;\n    }\n    else\n    {\n        _3043 = _3036;\n    }\n    if (_3043)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2987)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3069 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3069;\n        if (_3069 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2233_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3094;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3094 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3094 = _2233_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3113 = _2233_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3094, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3124 = clamp((_3002 - (fa_shadow_split_at(param_7) - _3113)) / _3113, 0.0f, 1.0f);\n        if (_3124 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2987)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3145 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3145;\n                if (_3145 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3124);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2667 = _566_fa_pbr.z < 0.5f;\n    bool _2674;\n    if (!_2667)\n    {\n        _2674 = _2233_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2674 = _2667;\n    }\n    if (_2674)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2233_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2687 = fa_light_texel(param);\n    float _2688 = _2687.x;\n    if (_2688 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2697 = int(_2688 + 0.5f);\n    int param_1 = _2697;\n    float4 _2701 = fa_light_texel(param_1);\n    int param_2 = _2697 + 1;\n    float4 _2706 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2709 = _2701.y;\n    if (_2709 > 0.0f)\n    {\n        float _2726 = 1.0f - smoothstep(0.75f * _2709, _2709, length(world - _2233_fa_shadow_eye.xyz));\n        fade = _2726;\n        if (_2726 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2701.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2750 = (_2697 + 2) + (face * 6);\n    int param_4 = _2750;\n    int param_5 = _2750 + 1;\n    int param_6 = _2750 + 3;\n    float4 _2764 = fa_light_texel(param_6);\n    int param_7 = _2750 + 4;\n    float4 _2769 = fa_light_texel(param_7);\n    int param_8 = _2750 + 5;\n    float4 _2774 = fa_light_texel(param_8);\n    float _2786 = _2774.x * max(dot(_2764, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2791 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2814 = clamp(dot(n, _2764.xyz), -1.0f, 1.0f);\n    float _2833 = min(sqrt(1.0f - (_2814 * _2814)) / max(abs(dot(n, world - lpos)) / max(dot(_2764, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2836 = _2706.y;\n    float _2838;\n    if (_2836 > 0.0f)\n    {\n        _2838 = _2836;\n    }\n    else\n    {\n        _2838 = 1.5f * _2786;\n    }\n    float4 _2858 = float4(world + (n * (_2838 * sqrt(1.0f - (_2791 * _2791)))), 1.0f);\n    float _2862 = dot(_2764, _2858);\n    float _2865 = _2774.y;\n    if (_2862 < _2865)\n    {\n        return 1.0f;\n    }\n    float2 _2880 = float2(dot(fa_light_texel(param_4), _2858), dot(fa_light_texel(param_5), _2858)) / _2862.xx;\n    float _2882 = _2880.x;\n    bool _2885 = _2882 < _2769.x;\n    bool _2894;\n    if (!_2885)\n    {\n        _2894 = _2882 > _2769.z;\n    }\n    else\n    {\n        _2894 = _2885;\n    }\n    bool _2903;\n    if (!_2894)\n    {\n        _2903 = _2880.y < _2769.y;\n    }\n    else\n    {\n        _2903 = _2894;\n    }\n    bool _2912;\n    if (!_2903)\n    {\n        _2912 = _2880.y > _2769.w;\n    }\n    else\n    {\n        _2912 = _2903;\n    }\n    if (_2912)\n    {\n        return 1.0f;\n    }\n    float _2918 = _2706.x;\n    float _2920;\n    if (_2918 > 0.0f)\n    {\n        _2920 = _2918;\n    }\n    else\n    {\n        _2920 = 1.5f * _2786;\n    }\n    float2 param_9 = _2880;\n    float4 param_10 = _2769;\n    float param_11 = _2862 - (_2920 * (1.0f + (0.5f * _2833)));\n    float param_12 = _2786;\n    float param_13 = 1.0f;\n    float param_14 = _2774.z * 0.25f;\n    float param_15 = (_2786 * min(_2833, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2865, _2774.z);\n    int param_17 = int(_2701.z + 0.5f);\n    float param_18 = _2701.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4475 = _566_fa_ct_a.x < 0.5f;\n    bool _4482;\n    if (!_4475)\n    {\n        _4482 = _2233_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4482 = _4475;\n    }\n    if (_4482)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2233_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4495 = fa_light_texel(param);\n    float _4496 = _4495.y;\n    float len = _4496;\n    if (_4496 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4508 = length(world - _566_fa_camera_pos.xyz);\n    float _4518 = 1.0f - smoothstep(0.5f * _566_fa_ct_b.x, _566_fa_ct_b.x, _4508);\n    if (_4518 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4524 = len;\n    float _4527 = min(_4524, 0.89999997615814208984375f * dist);\n    len = _4527;\n    float _4532 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4508);\n    float _4537 = _4532 + (0.5f * _4527);\n    float3 _4543 = world + (gn * _4532);\n    float _4545 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4609;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4560 = (float(k) + _4545) * 0.083333335816860198974609375f;\n        float3 _4568 = _4543 + (l * (_4560 * len));\n        float4 _4574 = float4(_4568, 1.0f);\n        float _4580 = dot(_566_fa_ct_vpw, _4574);\n        if (_4580 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4600 = float2(dot(_566_fa_ct_vpx, _4574), dot(_566_fa_ct_vpy, _4574)) / _4580.xx;\n        float _4604 = _4600.x * 0.5f;\n        float _4605 = _4604 + 0.5f;\n        if (_566_fa_ct_a.y > 0.5f)\n        {\n            _4609 = (_4600.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4609 = 0.5f - (_4600.y * 0.5f);\n        }\n        bool _4625 = _4605 < 0.0f;\n        bool _4632;\n        if (!_4625)\n        {\n            _4632 = _4605 >= 1.0f;\n        }\n        else\n        {\n            _4632 = _4625;\n        }\n        bool _4639;\n        if (!_4632)\n        {\n            _4639 = _4609 < 0.0f;\n        }\n        else\n        {\n            _4639 = _4632;\n        }\n        bool _4646;\n        if (!_4639)\n        {\n            _4646 = _4609 >= 1.0f;\n        }\n        else\n        {\n            _4646 = _4639;\n        }\n        if (_4646)\n        {\n            break;\n        }\n        float4 _4665 = fa_screen_tex.Load(int3(int2(float2(_4605, _4609) * _566_fa_ct_a.zw), 0));\n        if (_4665.w < 0.5f)\n        {\n            continue;\n        }\n        float _4684 = (dot(_566_fa_ct_fwd.xyz, _4568) + _566_fa_ct_fwd.w) - _4665.x;\n        if ((_4684 > _4532) && (_4684 < _4537))\n        {\n            occ = max(occ, (1.0f - (_4560 * _4560)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4605, 0.5f - _4604), min(_4609, 1.0f - _4609))));\n        }\n    }\n    return 1.0f - (occ * _4518);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4787 = fa_baked_keep(param);\n    if (_4787 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _7227 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _7227;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4813 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _7229 = _4813.color;\n    float _7230 = _4813.attenuation;\n    float _7231 = _4813.shadow;\n    bool _4816 = _4813.type == 0;\n    if (_4816 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4813.direction;\n        float _4827 = fa_shadow_factor(param_5, param_6);\n        _7231 = _4827;\n        _7229 *= _4827;\n    }\n    else\n    {\n        bool _4838 = _4813.type != 0;\n        bool _4844;\n        if (_4838)\n        {\n            _4844 = _7230 > 0.0f;\n        }\n        else\n        {\n            _4844 = _4838;\n        }\n        if (_4844)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4813.direction;\n            float _4863 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7231 = _4863;\n            _7229 *= _4863;\n        }\n    }\n    bool _4873 = _566_fa_ct_a.x > 0.5f;\n    bool _4879;\n    if (_4873)\n    {\n        _4879 = _7230 > 0.0f;\n    }\n    else\n    {\n        _4879 = _4873;\n    }\n    if (_4879)\n    {\n        float _4886;\n        if (_4816)\n        {\n            _4886 = 1000000000.0f;\n        }\n        else\n        {\n            _4886 = _4813._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4813.direction;\n        float param_18 = _4886;\n        float _4904 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7231 *= _4904;\n        _7229 *= _4904;\n    }\n    float _4917 = _7230;\n    float _4918 = _4917 * _4787;\n    _7230 = _4918;\n    float3 _4922 = _7229;\n    float3 _4923 = _4922 * _4787;\n    _7229 = _4923;\n    LightSample _7246 = { _4813.direction, _4923, _4918, _7231, _4813._distance, _4813.type };\n    return _7246;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _4957 = v - (n * dot(v, n));\n    float3 t = _4957;\n    float _4961 = dot(_4957, _4957);\n    float l2 = _4961;\n    if (_4961 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _4971;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _4971 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _4971 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _4971;\n        l2 = dot(_4971, _4971);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _5006 = dot(a, a);\n    float _5010 = dot(b, b);\n    if ((_5006 < 1.0000000195414813782625560981111e-24f) || (_5010 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _5024 = a * rsqrt(_5006);\n    float3 _5029 = b * rsqrt(_5010);\n    float _5033 = dot(_5024, _5029);\n    float _5036 = abs(_5033);\n    float g = (((((((((((0.0416471660137176513671875f * _5036) - 0.1924748718738555908203125f) * _5036) + 0.4179156124591827392578125f) * _5036) - 0.616057217121124267578125f) * _5036) + 0.777722418308258056640625f) * _5036) - 0.999542415142059326171875f) * _5036) + 1.570791721343994140625f;\n    if (_5033 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_5033 * _5033), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_5024, _5029) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _5093 = a.z > 0.0f;\n    bool _5097 = b.z > 0.0f;\n    if (_5093 && _5097)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5093 != _5097)\n        {\n            float3 _5132 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5132.z = 0.0f;\n            if (_5093)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _5132;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5132;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _5132;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5132;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _5181 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _5207 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _5233 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _5259 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _5181;\n    float3 param_1 = _5207;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _5207;\n    float3 param_7 = _5233;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _5233;\n    float3 param_13 = _5259;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _5259;\n    float3 param_19 = _5181;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _5409 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5433 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5449 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _5409;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _5433;\n    float4 param_9 = m;\n    float3 param_10 = _5409;\n    float3 param_11 = _5433;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _5449;\n    float4 param_14 = m;\n    float3 param_15 = _5409;\n    float3 param_16 = _5449;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5507 = fa_light_base(param);\n    int param_1 = _5507;\n    int param_2 = _5507 + 1;\n    int param_3 = _5507 + 2;\n    int param_4 = _5507 + 4;\n    float4 _5529 = fa_light_texel(param_4);\n    int param_5 = _5507 + 5;\n    float4 _5534 = fa_light_texel(param_5);\n    int param_6 = _5507 + 6;\n    float4 _5539 = fa_light_texel(param_6);\n    float _5540 = _5539.w;\n    float3 _5545 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5547 = _5540 < 1.5f;\n    bool _5554;\n    if (_5547)\n    {\n        _5554 = dot(normalize(fa_light_texel(param_3).xyz), _5545) >= 0.0f;\n    }\n    else\n    {\n        _5554 = _5547;\n    }\n    if (_5554)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5563 = (_5540 > 0.5f) && _5547;\n    float _5567 = _5563 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5570 = _5529.xyz;\n    float _5572 = _5529.w;\n    float3 _5578 = _5534.xyz;\n    float _5580 = _5534.w;\n    float3 up = _5578 * (_5580 * _5567);\n    float _5586;\n    if (_5563)\n    {\n        _5586 = (3.1415927410125732421875f * _5572) * _5572;\n    }\n    else\n    {\n        _5586 = (4.0f * _5572) * _5580;\n    }\n    if (_5540 > 1.5f)\n    {\n        float3 _5612 = cross(_5570, -_5545);\n        float3 perp = _5612;\n        float _5616 = dot(_5612, _5612);\n        float3 _5619;\n        if (_5616 > 1.0000000133514319600180897396058e-10f)\n        {\n            _5619 = perp * rsqrt(_5616);\n        }\n        else\n        {\n            _5619 = _5578;\n        }\n        perp = _5619;\n        up = _5619 * _5580;\n    }\n    float _5640 = max(_5586, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _5650 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _5650;\n    float3 param_10 = n;\n    float3 param_11 = _5545;\n    float3 _5658 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _5650;\n    float3 param_13 = n;\n    float3 param_14 = _5570 * (_5572 * _5567);\n    float3 _5666 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _5650;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _5674 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5540;\n    float3 param_20 = _5658;\n    float3 param_21 = _5666;\n    float3 param_22 = _5674;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _5693 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _5693;\n    float2 param_26 = _5693 + float2(64.0f, 0.0f);\n    float4 _5703 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5540;\n    float3 param_29 = _5658;\n    float3 param_30 = _5666;\n    float3 param_31 = _5674;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5703.x) + ((f90.xxx - f0) * _5703.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5545, _5545)) + _5640) / _5640) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4212 = 1.0f / alpha;\n    return ((2.0f + _4212) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4212)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4247 = max(dot(L.nc, l), 0.0f);\n    float _4253 = max(dot(L.nc, h), 0.0f);\n    float _4262 = ((_4253 * _4253) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4262) * _4262)) * (0.5f / max(lerp((2.0f * _4247) * L.coat_ndv, _4247 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4247)) * _4247;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5771;\n    if (L.sheen_on)\n    {\n        _5771 = L.sheen_scale;\n    }\n    else\n    {\n        _5771 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5771);\n    float3 _5784 = normalize(l + v);\n    int param_10 = li;\n    float3 _5795 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5804 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5784), 0.0f);\n        float param_13 = _5804;\n        float param_14 = ndv;\n        result += ((L.sheen * _5795) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _5804)) * _5804) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _5784;\n        float param_18 = max(dot(v, _5784), 0.0f);\n        result += (_5795 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4115 = tdh / at;\n    float _4119 = bdh / ab;\n    float _4131 = ((_4115 * _4115) + (_4119 * _4119)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4131) * _4131);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4311 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4390 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4390) * _4390);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4311);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4311));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3521 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3524 = _3521.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3524 * _3524, exp2((-9.27999973297119140625f) * ndv)) * _3524) + _3521.y)) + _3521.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_566_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _566_fa_env_horizon.w).xyz;\n    }\n    float _3375 = rough * rough;\n    float _3405 = 0.60000002384185791015625f * _3375;\n    return lerp(lerp(_566_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_566_fa_env_horizon.xyz, _566_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3375)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3405, 0.0500000007450580596923828125f + _3405, d.y).xxx), ((_566_fa_env_sky.xyz + _566_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3375 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3998;\n        if (L.aniso >= 0.0f)\n        {\n            _3998 = L.b;\n        }\n        else\n        {\n            _3998 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3998, v), _3998), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4031 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4031.x) + (L.f90.xxx * _4031.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4086 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4086.x) + _4086.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3563 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3563.x) + _3563.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2233_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3169 = int(_2233_fa_shadow_cfg.x + 0.5f);\n    float _3179 = dot(world - _2233_fa_shadow_eye.xyz, _2233_fa_shadow_fwd.xyz);\n    float3 tint_1 = 0.3499999940395355224609375f.xxx;\n    bool _3184 = _3169 > 0;\n    bool _3193;\n    if (_3184)\n    {\n        int param = _3169 - 1;\n        _3193 = _3179 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3193 = _3184;\n    }\n    if (_3193)\n    {\n        tint_1 = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3199 = _3169 > 1;\n        bool _3206;\n        if (_3199)\n        {\n            _3206 = _3179 > _2233_fa_shadow_split.x;\n        }\n        else\n        {\n            _3206 = _3199;\n        }\n        if (_3206)\n        {\n            tint_1 = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3212 = _3169 > 2;\n        bool _3219;\n        if (_3212)\n        {\n            _3219 = _3179 > _2233_fa_shadow_split.y;\n        }\n        else\n        {\n            _3219 = _3212;\n        }\n        if (_3219)\n        {\n            tint_1 = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3225 = _3169 > 3;\n        bool _3232;\n        if (_3225)\n        {\n            _3232 = _3179 > _2233_fa_shadow_split.z;\n        }\n        else\n        {\n            _3232 = _3225;\n        }\n        if (_3232)\n        {\n            tint_1 = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint_1, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _6929 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6929 = -_6929;\n    }\n    float3 _6292 = normalize(_566_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6942 = { fa_world_pos, _6929, fa_world_tangent, fa_uv, fa_vertex_color, _6292, gl_FrontFacing };\n    SurfaceInput param_1 = _6942;\n    Surface _6300 = fa_standard_surface(param_1);\n    float3 _6960 = _6300.albedo;\n    float _6961 = _6300.alpha;\n    float3 _6962 = _6300.normal;\n    float _6963 = _6300.metallic;\n    float _6964 = _6300.roughness;\n    float _6965 = _6300.occlusion;\n    float3 _6966 = _6300.emission;\n    float _6967 = _6300.clearcoat;\n    float _6968 = _6300.clearcoat_roughness;\n    float3 _6969 = _6300.sheen_color;\n    float _6970 = _6300.sheen_roughness;\n    float _6971 = _6300.anisotropy;\n    float _6972 = _6300.anisotropy_rotation;\n    float _6973 = _6300.specular;\n    float _6974 = _6300.ior;\n    float3 _6975 = _6300.specular_color;\n    SurfaceInput _6950 = { fa_world_pos, _6929, fa_world_tangent, fa_uv, fa_vertex_color, _6292, gl_FrontFacing };\n    SurfaceInput param_2 = _6950;\n    Surface param_3 = _6300;\n    surface(param_2, param_3);\n    _6960 = param_3.albedo;\n    _6961 = param_3.alpha;\n    _6962 = param_3.normal;\n    _6963 = param_3.metallic;\n    _6964 = param_3.roughness;\n    _6965 = param_3.occlusion;\n    _6966 = param_3.emission;\n    _6967 = param_3.clearcoat;\n    _6968 = param_3.clearcoat_roughness;\n    _6969 = param_3.sheen_color;\n    _6970 = param_3.sheen_roughness;\n    _6971 = param_3.anisotropy;\n    _6972 = param_3.anisotropy_rotation;\n    _6973 = param_3.specular;\n    _6974 = param_3.ior;\n    _6975 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6929;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6960 = param_6;\n    _6962 = param_7;\n    float3 result;\n    if (_566_fa_emissive.w > 0.5f)\n    {\n        result = _6960;\n    }\n    else\n    {\n        float3 _6339 = normalize(_6962);\n        float _6346 = clamp(_6963, 0.0f, 1.0f);\n        float _6350 = clamp(_6964, 0.0500000007450580596923828125f, 1.0f);\n        float _6354 = _6350 * _6350;\n        float _6358 = _6354 * _6354;\n        float _6363 = max(dot(_6339, _6292), 9.9999997473787516355514526367188e-05f);\n        float3 _6369 = _6960 * (1.0f - _6346);\n        float3 _6376 = lerp(0.039999999105930328369140625f.xxx, _6960, _6346.xxx);\n        float3 f0 = _6376;\n        SurfaceInput _6958 = { fa_world_pos, _6929, fa_world_tangent, fa_uv, fa_vertex_color, _6292, gl_FrontFacing };\n        SurfaceInput param_8 = _6958;\n        Surface _7041 = { _6960, _6961, _6962, _6963, _6964, _6965, _6966, _6967, _6968, _6969, _6970, _6971, _6972, _6973, _6974, _6975 };\n        Surface param_9 = _7041;\n        float3 param_10 = _6339;\n        float3 param_11 = _6292;\n        float param_12 = _6346;\n        float param_13 = _6350;\n        float3 param_14 = _6376;\n        FaLayers _6392 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _6339;\n        float3 lit = (fa_indirect_diffuse(param_15) * _6369) * _6965;\n        if (_6392.on)\n        {\n            lit *= _6392.base_scale;\n        }\n        int _6414 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6414; ln++)\n        {\n            int param_16 = ln;\n            int _6427 = fa_cl_light(param_16);\n            int param_17 = _6427;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _6427;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _6929;\n            LightSample _6443 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6451 = max(dot(_6339, _6443.direction), 0.0f);\n            float _6457 = _6443.attenuation * _6443.shadow;\n            float3 _6462 = normalize(_6443.direction + _6292);\n            float _6467 = max(dot(_6339, _6462), 0.0f);\n            float _6472 = max(dot(_6292, _6462), 0.0f);\n            bool _6479;\n            if (fa_light_is_area)\n            {\n                _6479 = !_6392.on;\n            }\n            else\n            {\n                _6479 = fa_light_is_area;\n            }\n            if (_6479)\n            {\n                int param_21 = _6427;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _6339;\n                float3 param_24 = _6292;\n                float3 param_25 = _6369;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _6350;\n                float param_29 = _6363;\n                float param_30 = _6457;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6392;\n                    int param_32 = _6427;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _6339;\n                    float3 param_35 = _6292;\n                    float3 param_36 = _6443.direction;\n                    float3 param_37 = _6369;\n                    float3 param_38 = f0;\n                    float param_39 = _6350;\n                    float param_40 = _6363;\n                    float param_41 = _6457;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6392.on)\n                    {\n                        FaLayers param_42 = _6392;\n                        float3 param_43 = _6369;\n                        float3 param_44 = f0;\n                        float3 param_45 = _6339;\n                        float3 param_46 = _6292;\n                        float3 param_47 = _6443.direction;\n                        float3 param_48 = _6462;\n                        float param_49 = _6451;\n                        float param_50 = _6363;\n                        float param_51 = _6467;\n                        float param_52 = _6472;\n                        float param_53 = _6354;\n                        float param_54 = _6358;\n                        int param_55 = _6427;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6457));\n                    }\n                    else\n                    {\n                        float _6585 = ((_6467 * _6467) * (_6358 - 1.0f)) + 1.0f;\n                        int param_56 = _6427;\n                        lit += (((_6369 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _6472, 5.0f))) * (((_6358 / ((3.1415927410125732421875f * _6585) * _6585)) * (0.5f / max(lerp((2.0f * _6451) * _6363, _6451 + _6363, _6354), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _6451))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6451 * _6457));\n                    }\n                }\n            }\n        }\n        if (_6392.on)\n        {\n            FaLayers param_57 = _6392;\n            float3 param_58 = _6339;\n            float3 param_59 = _6292;\n            float3 param_60 = f0;\n            float param_61 = _6350;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6965);\n        }\n        else\n        {\n            float3 param_62 = _6339;\n            float3 param_63 = _6292;\n            float3 param_64 = f0;\n            float param_65 = _6350;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6965);\n        }\n        result = lit;\n    }\n    float3 _6680 = result;\n    float3 _6681 = _6680 + _6966;\n    result = _6681;\n    float3 param_66 = _6681;\n    float3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6690 = _566_fa_fog.w > 0.0f;\n    bool _6697;\n    if (!_6690)\n    {\n        _6697 = _566_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _6697 = _6690;\n    }\n    if (_6697)\n    {\n        float3 _6706 = fa_world_pos - _566_fa_camera_pos.xyz;\n        float _6712 = dot(_6706, _566_fa_fog_c.xyz);\n        bool _6716 = _566_fa_fog_c.w > 0.5f;\n        float _6717;\n        if (_6716)\n        {\n            _6717 = _6712;\n        }\n        else\n        {\n            _6717 = length(_6706);\n        }\n        float _6729 = _6717 - _566_fa_fog_b.x;\n        if (_6729 > 0.0f)\n        {\n            float _6738 = _566_fa_fog.w * _6729;\n            float tau = _6738 * _6738;\n            if (_566_fa_fog_b.y > 0.0f)\n            {\n                float _6754;\n                if (_6716)\n                {\n                    _6754 = fa_world_pos.y - (_566_fa_fog_c.y * _6712);\n                }\n                else\n                {\n                    _6754 = _566_fa_camera_pos.y;\n                }\n                float _6775 = lerp(_6754, fa_world_pos.y, clamp(_566_fa_fog_b.x / _6717, 0.0f, 1.0f));\n                float _6779 = fa_world_pos.y - _6775;\n                float _6784 = _6775 - _566_fa_fog_b.z;\n                float _6789 = fa_world_pos.y - _566_fa_fog_b.z;\n                bool _6792 = _6784 <= 0.0f;\n                bool _6793 = !_6792;\n                bool _6799;\n                if (_6793)\n                {\n                    _6799 = _566_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6799 = _6792;\n                }\n                float _6800;\n                if (_6799)\n                {\n                    _6800 = _566_fa_fog_b.y;\n                }\n                else\n                {\n                    _6800 = _566_fa_fog_b.y * exp(-min(_566_fa_fog_b.w * _6784, 80.0f));\n                }\n                bool _6827;\n                if (_6793)\n                {\n                    _6827 = _566_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6827 = _6792;\n                }\n                float _6828;\n                if (_6827)\n                {\n                    _6828 = _566_fa_fog_b.y * _6784;\n                }\n                else\n                {\n                    _6828 = (_566_fa_fog_b.y * (1.0f - exp(-min(_566_fa_fog_b.w * _6784, 80.0f)))) / _566_fa_fog_b.w;\n                }\n                bool _6853 = _6789 <= 0.0f;\n                bool _6860;\n                if (!_6853)\n                {\n                    _6860 = _566_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6860 = _6853;\n                }\n                float _6861;\n                if (_6860)\n                {\n                    _6861 = _566_fa_fog_b.y * _6789;\n                }\n                else\n                {\n                    _6861 = (_566_fa_fog_b.y * (1.0f - exp(-min(_566_fa_fog_b.w * _6789, 80.0f)))) / _566_fa_fog_b.w;\n                }\n                float _6888;\n                if (abs(_6779) < 0.001000000047497451305389404296875f)\n                {\n                    _6888 = _6800;\n                }\n                else\n                {\n                    _6888 = (_6861 - _6828) / _6779;\n                }\n                tau += (_6729 * max(_6888, 0.0f));\n            }\n            result = lerp(result, _566_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6961);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_153",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_566",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2233",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_5873",
            "hlsl_register_b_n": 5
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
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 7
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
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 10
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _158_fa_view_proj : packoffset(c0);\n    row_major float4x4 _158_fa_light_vp : packoffset(c4);\n    float4 _158_fa_uv_scale : packoffset(c8);\n    float4 _158_fa_time : packoffset(c9);\n    float4 _158_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _205_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float4 fa_inst_d0 : TEXCOORD11;\n    float4 fa_inst_d1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float3 fa_lm : TEXCOORD7;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_205_fa_joint_rows[_196] * weights[i]);\n        r1 += (_205_fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205_fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _422 = { mul(float4(position, 1.0f), model).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158_fa_uv_scale.xy, color, position };\n    return _422;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _158_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3663[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _566_fa_camera_pos : packoffset(c0);\n    float4 _566_fa_ambient : packoffset(c1);\n    float4 _566_fa_base_color : packoffset(c2);\n    float4 _566_fa_emissive : packoffset(c3);\n    float4 _566_fa_model_emissive : packoffset(c4);\n    float4 _566_fa_pbr : packoffset(c5);\n    float4 _566_fa_maps : packoffset(c6);\n    float4 _566_fa_fog : packoffset(c7);\n    float4 _566_fa_fog_b : packoffset(c8);\n    float4 _566_fa_fog_c : packoffset(c9);\n    float4 _566_fa_counts : packoffset(c10);\n    float4 _566_fa_env_sky : packoffset(c11);\n    float4 _566_fa_env_horizon : packoffset(c12);\n    float4 _566_fa_time : packoffset(c13);\n    float4 _566_fa_cl_vpx : packoffset(c14);\n    float4 _566_fa_cl_vpy : packoffset(c15);\n    float4 _566_fa_cl_vpw : packoffset(c16);\n    float4 _566_fa_cl_fwd : packoffset(c17);\n    float4 _566_fa_cl_grid : packoffset(c18);\n    float4 _566_fa_cl_info : packoffset(c19);\n    float4 _566_fa_layers_a : packoffset(c20);\n    float4 _566_fa_layers_b : packoffset(c21);\n    float4 _566_fa_layers_c : packoffset(c22);\n    float4 _566_fa_layers_d : packoffset(c23);\n    float4 _566_fa_ct_a : packoffset(c24);\n    float4 _566_fa_ct_b : packoffset(c25);\n    float4 _566_fa_ct_vpx : packoffset(c26);\n    float4 _566_fa_ct_vpy : packoffset(c27);\n    float4 _566_fa_ct_vpw : packoffset(c28);\n    float4 _566_fa_ct_fwd : packoffset(c29);\n    float4 _566_fa_probe_sh[9] : packoffset(c30);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2233_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2233_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2233_fa_shadow_info[4] : packoffset(c20);\n    float4 _2233_fa_shadow_split : packoffset(c24);\n    float4 _2233_fa_shadow_cfg : packoffset(c25);\n    float4 _2233_fa_shadow_bias : packoffset(c26);\n    float4 _2233_fa_shadow_eye : packoffset(c27);\n    float4 _2233_fa_shadow_fwd : packoffset(c28);\n    float4 _2233_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5873_boost : packoffset(c0);\n    float _5873_fa_pad0 : packoffset(c0.y);\n    float _5873_fa_pad1 : packoffset(c0.z);\n    float _5873_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float3 fa_lm : TEXCOORD7;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1504 = _566_fa_cl_info.x < 0.0f;\n    bool _1511;\n    if (!_1504)\n    {\n        _1511 = _566_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1511 = _1504;\n    }\n    bool _1519;\n    if (!_1511)\n    {\n        _1519 = _566_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1519 = _1511;\n    }\n    bool _1526;\n    if (!_1519)\n    {\n        _1526 = _566_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1526 = _1519;\n    }\n    bool _1533;\n    if (!_1526)\n    {\n        _1533 = _566_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1533 = _1526;\n    }\n    if (_1533)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1543 = float4(world_pos, 1.0f);\n    float _1549 = dot(_566_fa_cl_vpw, _1543);\n    if (!(_1549 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1571 = float2(dot(_566_fa_cl_vpx, _1543), dot(_566_fa_cl_vpy, _1543)) / _1549.xx;\n    int _1575 = int(_566_fa_cl_grid.x);\n    int _1579 = int(_566_fa_cl_grid.y);\n    int param = (int(_566_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_566_fa_cl_fwd.xyz, world_pos) + _566_fa_cl_fwd.w, _566_fa_cl_grid.w) / _566_fa_cl_grid.w) * _566_fa_cl_grid.z)), 0, int(_566_fa_cl_info.y) - 1) * _1579) + clamp(int(floor(((_1571.y * 0.5f) + 0.5f) * _566_fa_cl_grid.y)), 0, _1579 - 1)) * _1575)) + clamp(int(floor(((_1571.x * 0.5f) + 0.5f) * _566_fa_cl_grid.x)), 0, _1575 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1655 = fa_cluster_texel(param);\n    return int2(int(_1655.x), int(_1655.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_566_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4761 = fa_cluster_lookup(param);\n    fa_cl_slot = _4761.x;\n    fa_cl_local = _4761.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5925 = fa_linear_to_srgb(param);\n        c = _5925;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5933 = fa_srgb_to_linear(param_1);\n            c = _5933;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _448;\n    if (i.front_facing)\n    {\n        _448 = i.world_normal;\n    }\n    else\n    {\n        _448 = -i.world_normal;\n    }\n    float3 _472 = normalize(i.world_tangent.xyz - (_448 * dot(_448, i.world_tangent.xyz)));\n    float3 _499 = normalize(((_472 * m.x) + ((cross(_448, _472) * i.world_tangent.w) * m.y)) + (_448 * m.z));\n    float3 _502;\n    if (i.front_facing)\n    {\n        _502 = _499;\n    }\n    else\n    {\n        _502 = -_499;\n    }\n    return _502;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _566_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5964 = fa_tex_fix(param_2, param_3);\n    float4 _7424 = base_t;\n    _7424.x = _5964.x;\n    _7424.y = _5964.y;\n    _7424.z = _5964.z;\n    base_t = _7424;\n    float4 _5978 = (_7424 * _566_fa_base_color) * i.vertex_color;\n    float3 _7249 = i.world_normal;\n    if (_566_fa_maps.z > 0.5f)\n    {\n        float param_4 = _566_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _6010 = fa_tex_fix(param_6, param_7);\n        float3 _6013 = (_6010 * 2.0f) - 1.0f.xxx;\n        float2 _6018 = _6013.xy * _566_fa_maps.x;\n        float3 _7432 = _6013;\n        _7432.x = _6018.x;\n        _7432.y = _6018.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _7432;\n        _7249 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _566_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _6046 = fa_tex_fix(param_12, param_13);\n    float4 _7435 = mrt;\n    _7435.x = _6046.x;\n    _7435.y = _6046.y;\n    _7435.z = _6046.z;\n    mrt = _7435;\n    float4 _6074 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _566_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _6074.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _6085 = fa_tex_fix(param_16, param_17);\n    float param_18 = _566_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _6115 = fa_tex_fix(param_20, param_21);\n    float _7254 = _566_fa_layers_a.x;\n    float _7255 = _566_fa_layers_a.y;\n    float _7258 = _566_fa_layers_a.z;\n    float _7257 = _566_fa_layers_b.w;\n    float _7260 = _566_fa_layers_c.x;\n    if (_566_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_566_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _7254 *= _6085.y;\n            _7255 *= _6085.z;\n            _7257 *= _6074.w;\n        }\n        if (_566_fa_layers_c.z > 1.5f)\n        {\n            _7258 *= mrt.x;\n            _7260 *= mrt.w;\n        }\n    }\n    Surface _7279 = { _5978.xyz, _5978.w, _7249, clamp(_566_fa_pbr.x * _6046.z, 0.0f, 1.0f), clamp(_566_fa_pbr.y * _6046.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_566_fa_maps.y * (_6085.x - 1.0f)), _566_fa_emissive.xyz + (_566_fa_model_emissive.xyz * _6115), _7254, _7255, _566_fa_layers_b.xyz, _7257, _7258, _566_fa_layers_a.w, _7260, _566_fa_layers_c.y, _566_fa_layers_d.xyz };\n    return _7279;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _5873_boost);\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1735 = rect.zw - rect.xy;\n    float2 _1739 = _1735 * atlas;\n    float2 _1743 = ddx * _1739;\n    float2 _1747 = ddy * _1739;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1735), clamp(0.5f * log2(max(max(dot(_1743, _1743), dot(_1747, _1747)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1780 = _566_fa_counts.y < 0.5f;\n    bool _1787;\n    if (!_1780)\n    {\n        _1787 = _566_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1787 = _1780;\n    }\n    if (_1787)\n    {\n        return;\n    }\n    float3 _1793 = ddx(world_pos);\n    float3 _1796 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1800 = fa_cluster_texel(param);\n    int _1804 = int(_1800.w);\n    if (_1804 < 1)\n    {\n        return;\n    }\n    int _1814 = int(_566_fa_counts.y + 0.5f);\n    int param_1 = _1814;\n    float4 _1818 = fa_light_texel(param_1);\n    float2 _1821 = _1818.yz;\n    int _1825 = int(_1818.w);\n    int param_2 = _1814 + 1;\n    float4 _1830 = fa_light_texel(param_2);\n    float _1831 = _1830.x;\n    int _1837 = int(_566_fa_counts.w + 0.5f) - 1;\n    int _1841 = int(_1800.z);\n    float3 _2106;\n    for (int k = 0; k < _1804; k++)\n    {\n        int _1854 = _1841 + k;\n        int param_3 = _1825 + (_1854 >> 2);\n        int _1871 = (_1814 + 2) + (int(fa_light_texel(param_3)[_1854 & 3]) * 7);\n        int param_4 = _1871 + 6;\n        float4 _1876 = fa_light_texel(param_4);\n        if (((int(_1876.w + 0.5f) >> _1837) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1871;\n        float4 _1891 = fa_light_texel(param_5);\n        int param_6 = _1871 + 1;\n        float4 _1896 = fa_light_texel(param_6);\n        int param_7 = _1871 + 2;\n        float4 _1901 = fa_light_texel(param_7);\n        float3 _1904 = _1891.xyz;\n        float _1909 = dot(_1904, world_pos) + _1891.w;\n        float3 _1911 = _1896.xyz;\n        float _1916 = dot(_1911, world_pos) + _1896.w;\n        float3 _1918 = _1901.xyz;\n        float _1923 = dot(_1918, world_pos) + _1901.w;\n        bool _1928 = abs(_1909) > 0.5f;\n        bool _1936;\n        if (!_1928)\n        {\n            _1936 = abs(_1916) > 0.5f;\n        }\n        else\n        {\n            _1936 = _1928;\n        }\n        bool _1944;\n        if (!_1936)\n        {\n            _1944 = abs(_1923) > 0.5f;\n        }\n        else\n        {\n            _1944 = _1936;\n        }\n        if (_1944)\n        {\n            continue;\n        }\n        float _1959 = clamp(dot(geo_normal, normalize(_1918)) * _1876.z, 0.0f, 1.0f);\n        if (_1959 <= 0.0f)\n        {\n            continue;\n        }\n        float _1979 = (clamp((0.5f - abs(_1923)) * 10.0f, 0.0f, 1.0f) * _1959) * _1876.x;\n        float2 _1987 = float2(_1909 + 0.5f, 0.5f - _1916);\n        float2 _1997 = float2(dot(_1904, _1793), dot(_1911, _1793));\n        float2 _2007 = float2(dot(_1904, _1796), dot(_1911, _1796));\n        int param_8 = _1871 + 5;\n        float4 _2012 = fa_light_texel(param_8);\n        int param_9 = _1871 + 3;\n        float4 _2017 = fa_light_texel(param_9);\n        int param_10 = _1871 + 4;\n        float4 _2022 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2012.xyz;\n        bool _2032 = _2017.z > _2017.x;\n        if (_2032)\n        {\n            float4 param_11 = _2017;\n            float2 param_12 = _1987;\n            float2 param_13 = _1821;\n            float2 param_14 = _1997;\n            float2 param_15 = _2007;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1831 > 0.5f) && (_1831 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2058 = fa_dc_to_linear(param_16);\n                float4 _7329 = tx;\n                _7329.x = _2058.x;\n                _7329.y = _2058.y;\n                _7329.z = _2058.z;\n                tx = _7329;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1979 * tex_a) * _2012.w, 0.0f, 1.0f).xxx);\n        if (_2022.z > _2022.x)\n        {\n            float4 param_17 = _2022;\n            float2 param_18 = _1987;\n            float2 param_19 = _1821;\n            float2 param_20 = _1997;\n            float2 param_21 = _2007;\n            float4 _2102 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1831 > 1.5f)\n            {\n                float3 param_22 = _2102.xyz;\n                float3 _2112 = fa_dc_to_srgb(param_22);\n                _2106 = _2112;\n            }\n            else\n            {\n                _2106 = _2102.xyz;\n            }\n            float3 _2121 = (_2106 * 2.0f) - 1.0f.xxx;\n            float2 _2126 = _2121.xy * _1876.y;\n            float3 _2148 = (normalize(_1904) * _2126.x) + (normalize(_1911) * _2126.y);\n            float3 _2151 = normalize(normal);\n            normal = normalize(lerp(_2151, normalize((_2151 * max(_2121.z, 0.0500000007450580596923828125f)) + (_2148 - (_2151 * dot(_2151, _2148)))), clamp(_1979 * (_2032 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3589 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3596 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3599 = int(_3589);\n    int _3602 = int(_3596);\n    float _3612 = _3596 - float(_3602);\n    int _3667 = (_3599 * 9) + _3602;\n    int _3687 = ((_3599 + 1) * 9) + _3602;\n    return lerp(lerp(_3663[_3667], _3663[_3667 + 1], _3612), lerp(_3663[_3687], _3663[_3687 + 1], _3612), _3589 - float(_3599));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _7172 = false;\n    float _7173 = 1.0f;\n    float _7174 = 1.0f;\n    float _7175 = 1.0f;\n    float _7176 = 0.0f;\n    float _7177 = 0.0f;\n    float _7178 = 0.0f;\n    float _7179 = 0.0f;\n    float _7181 = 1.0f;\n    bool _7182 = false;\n    float3 _7183 = 0.0f.xxx;\n    float _7184 = 1.0f;\n    float _7185 = 1.0f;\n    float _7186 = 1.0f;\n    float _7187 = 0.0f;\n    float _7188 = 0.0f;\n    float3 _7189 = float3(1.0f, 0.0f, 0.0f);\n    float3 _7190 = float3(0.0f, 0.0f, 1.0f);\n    float _7191 = 1.0f;\n    float _7192 = 1.0f;\n    float _3738 = clamp(s.specular, 0.0f, 1.0f);\n    float _3742 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3747 = (_3738 != 1.0f) || (_3742 != 1.5f);\n    bool _3756;\n    if (!_3747)\n    {\n        _3756 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3756 = _3747;\n    }\n    if (_3756)\n    {\n        float _3764 = (_3742 - 1.0f) / (_3742 + 1.0f);\n        f0 = lerp(min((_3764 * _3764).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3738, s.albedo, metallic.xxx);\n        _7173 = lerp(_3738, 1.0f, metallic);\n        _7172 = true;\n    }\n    float _3791 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3791 > 0.0f)\n    {\n        float _3799 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _7176 = _3791;\n        _7177 = _3799;\n        float _3806 = _3799 * _3799;\n        _7178 = _3806;\n        _7179 = _3806 * _3806;\n        float _3818 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _7181 = _3818;\n        _7174 = 1.0f - (_3791 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3818, 0.0f, 1.0f), 5.0f))));\n        _7172 = true;\n    }\n    float3 _3837 = max(s.sheen_color, 0.0f.xxx);\n    float _3846 = max(_3837.x, max(_3837.y, _3837.z));\n    if (_3846 > 0.0f)\n    {\n        float _3854 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _7182 = true;\n        _7183 = _3837;\n        _7184 = _3854;\n        _7185 = _3854 * _3854;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3854;\n        float _3871 = fa_sheen_albedo(param, param_1);\n        _7187 = _3871;\n        _7186 = 1.0f - min(_3846 * _3871, 1.0f);\n        _7172 = true;\n    }\n    _7175 = _7174 * _7186;\n    float _3890 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3890 != 0.0f)\n    {\n        float3 _3905 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3905;\n        if (dot(_3905, _3905) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3917 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3917.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3917.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3917.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3921 = t;\n        float3 _3922 = normalize(_3921);\n        t = _3922;\n        float3 _3947 = normalize((_3922 * cos(s.anisotropy_rotation)) + ((cross(n, _3922) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _7189 = _3947;\n        _7190 = cross(n, _3947);\n        float _3957 = roughness * roughness;\n        float _3963 = lerp(_3957, 1.0f, _3890 * _3890);\n        bool _3965 = _3890 > 0.0f;\n        _7191 = _3965 ? _3963 : _3957;\n        _7192 = _3965 ? _3957 : _3963;\n        _7188 = _3890;\n        _7172 = true;\n    }\n    FaLayers _7214 = { _7172, _7173, _7174, _7175, _7176, _7177, _7178, _7179, i.world_normal, _7181, _7182, _7183, _7184, _7185, _7186, _7187, _7188, _7189, _7190, _7191, _7192 };\n    return _7214;\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_566_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3346 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3346;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_566_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _566_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_566_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _566_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_566_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_566_fa_cl_info.x) + int(_566_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_566_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4731;\n    if (fa_lm.z > 0.5f)\n    {\n        _4731 = 0.0f;\n    }\n    else\n    {\n        _4731 = 1.0f - clamp(_566_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4742 = _4731 < 1.0f;\n    bool _4748;\n    if (_4742)\n    {\n        int param = li;\n        _4748 = fa_light_baked(param);\n    }\n    else\n    {\n        _4748 = _4742;\n    }\n    return _4748 ? _4731 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _634_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _634_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _753 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _766 = (c - (ru * hx)) - p;\n        float3 _772 = ru * (2.0f * hx);\n        float _778 = max(dot(_772, _772), 9.9999999392252902907785028219223e-09f);\n        float _782 = dot(_766, _772);\n        float t = clamp((-_782) / _778, 0.0f, 1.0f);\n        if (_753)\n        {\n            float _797 = dot(r, _772);\n            float _803 = _778 - (_797 * _797);\n            if (abs(_803) > (9.9999997473787516355514526367188e-06f * _778))\n            {\n                t = clamp(((dot(r, _766) * _797) - _782) / _803, 0.0f, 1.0f);\n            }\n        }\n        return (p + _766) + (_772 * t);\n    }\n    float3 q = p;\n    float _835 = dot(r, axis);\n    bool _843;\n    if (_753)\n    {\n        _843 = abs(_835) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _843 = _753;\n    }\n    if (_843)\n    {\n        float _853 = dot(c - p, axis) / _835;\n        if (_853 > 0.0f)\n        {\n            q = p + (r * _853);\n        }\n    }\n    float3 _866 = q - c;\n    float2 xy = float2(dot(_866, ru), dot(_866, uu));\n    if (shape > 0.5f)\n    {\n        float _881 = length(xy);\n        if (_881 > hx)\n        {\n            xy *= (hx / _881);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _514 = abs(d);\n    float _516 = _514.x;\n    float _518 = _514.y;\n    bool _519 = _516 >= _518;\n    bool _527;\n    if (_519)\n    {\n        _527 = _516 >= _514.z;\n    }\n    else\n    {\n        _527 = _519;\n    }\n    int _528;\n    if (_527)\n    {\n        _528 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _543;\n        if (_518 >= _514.z)\n        {\n            _543 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _543 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _528 = _543;\n    }\n    return _528;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _673 = dot(d, right);\n    float _677 = dot(d, up);\n    float _688;\n    if (((_673 * _673) + (_677 * _677)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _688 = atan2(_677, _673) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _688 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_688 - floor(_688)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _919 = fa_light_base(param);\n    bool _923 = _566_fa_ambient.w > 4.5f;\n    int param_1 = _919;\n    float4 _927 = fa_light_texel(param_1);\n    int param_2 = _919 + 1;\n    float4 _932 = fa_light_texel(param_2);\n    float _935 = _932.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _947 = _923 && (_935 > 2.5f);\n    fa_light_is_area = _947;\n    bool _949 = _935 < 0.5f;\n    float3 l;\n    if (_949)\n    {\n        l = normalize(_927.xyz);\n        if (_923)\n        {\n            int param_3 = _919 + 6;\n            float4 _963 = fa_light_texel(param_3);\n            if (_963.z > 0.5f)\n            {\n                int param_4 = _919 + 4;\n                float4 _973 = fa_light_texel(param_4);\n                int param_5 = _919 + 5;\n                float4 _978 = fa_light_texel(param_5);\n                float2 param_6 = _963.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _973.xyz) * _973.w, (-dot(world_pos, _978.xyz)) * _978.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1008 = _927.xyz;\n        float3 _1010 = _1008 - world_pos;\n        float3 to_light = _1010;\n        float _1013 = length(_1010);\n        float reach = _1013;\n        bool front = true;\n        if (_947)\n        {\n            int param_8 = _919 + 7;\n            reach = max(_1013 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _919 + 4;\n            float4 _1037 = fa_light_texel(param_9);\n            int param_10 = _919 + 5;\n            float4 _1042 = fa_light_texel(param_10);\n            int param_11 = _919 + 6;\n            float4 _1047 = fa_light_texel(param_11);\n            float _1048 = _1047.w;\n            int param_12 = _919 + 2;\n            float3 _1055 = normalize(fa_light_texel(param_12).xyz);\n            bool _1057 = _1048 > 1.5f;\n            bool _1065;\n            if (!_1057)\n            {\n                _1065 = dot(_1055, to_light) < 0.0f;\n            }\n            else\n            {\n                _1065 = _1057;\n            }\n            front = _1065;\n            float3 r = 0.0f.xxx;\n            float3 _1074 = _566_fa_camera_pos.xyz - world_pos;\n            bool _1078 = dot(n, n) > 0.5f;\n            bool _1086;\n            if (_1078)\n            {\n                _1086 = dot(_1074, _1074) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1086 = _1078;\n            }\n            if (_1086)\n            {\n                r = reflect(-normalize(_1074), normalize(n));\n            }\n            float3 param_13 = _1008;\n            float3 param_14 = _1055;\n            float3 param_15 = _1037.xyz;\n            float3 param_16 = _1042.xyz;\n            float param_17 = _1037.w;\n            float param_18 = _1042.w;\n            float param_19 = _1048;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1122 = length(to_light);\n        dist = _1122;\n        l = to_light / max(_1122, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1136 = reach / max(_927.w, 0.001000000047497451305389404296875f);\n        float _1142 = clamp(1.0f - (_1136 * _1136), 0.0f, 1.0f);\n        float _1144;\n        if (front)\n        {\n            _1144 = _1142 * _1142;\n        }\n        else\n        {\n            _1144 = 0.0f;\n        }\n        atten = _1144;\n        bool _1155 = _935 < 2.5f;\n        if ((_935 > 1.5f) && _1155)\n        {\n            int param_22 = _919 + 2;\n            float4 _1163 = fa_light_texel(param_22);\n            float _1173 = _1163.w;\n            int param_23 = _919 + 3;\n            float4 _1178 = fa_light_texel(param_23);\n            float _1179 = _1178.x;\n            float cos_inner = _1179;\n            if (_1179 > 1.5f)\n            {\n                cos_inner = lerp(_1173, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1173, cos_inner, dot(-l, normalize(_1163.xyz)));\n        }\n        if (_923 && (_935 < 1.5f))\n        {\n            int param_24 = _919 + 6;\n            float4 _1203 = fa_light_texel(param_24);\n            if (_1203.z > 0.5f)\n            {\n                float3 _1211 = -to_light;\n                int param_25 = _919 + 4;\n                int param_26 = _919 + 5;\n                float3 _1225 = fa_light_texel(param_25).xyz;\n                float3 _1229 = fa_light_texel(param_26).xyz;\n                float3 _1238 = float3(dot(_1211, _1225), dot(_1211, _1229), dot(_1211, cross(_1225, _1229)));\n                float3 param_27 = _1238;\n                int _1242 = fa_cube_face(param_27);\n                int param_28 = _1242;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1269 = float2(dot(_1238, cross(param_29, param_30)), dot(_1238, param_30)) / max(dot(_1238, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1273 = _1242 / 3;\n                float2 param_31 = _1203.xy + (float2(float(_1242 - (_1273 * 3)), float(_1273)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1269.x), 0.5f - (0.5f * _1269.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _919 + 7;\n            float4 _1303 = fa_light_texel(param_33);\n            if (_1303.z > 0.5f)\n            {\n                int param_34 = _919 + 2;\n                int param_35 = _919 + 4;\n                int param_36 = _919 + 5;\n                float2 param_37 = _1303.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_923 && _1155)\n            {\n                int param_42 = _919 + 6;\n                float4 _1350 = fa_light_texel(param_42);\n                int param_43 = _919 + 7;\n                float4 _1355 = fa_light_texel(param_43);\n                bool _1358 = _1350.z > 0.5f;\n                bool _1365;\n                if (!_1358)\n                {\n                    _1365 = _1355.z > 0.5f;\n                }\n                else\n                {\n                    _1365 = _1358;\n                }\n                if (_1365)\n                {\n                    int param_44 = _919 + 2;\n                    float4 _1372 = fa_light_texel(param_44);\n                    float3 _1376 = normalize(_1372.xyz);\n                    int param_45 = _919 + 4;\n                    float4 _1381 = fa_light_texel(param_45);\n                    int param_46 = _919 + 5;\n                    float4 _1386 = fa_light_texel(param_46);\n                    if (_1358)\n                    {\n                        float3 _1394 = -to_light;\n                        float _1401 = _1372.w;\n                        float _1417 = 0.5f / max(dot(_1394, _1376) * (sqrt(max(1.0f - (_1401 * _1401), 0.0f)) / max(_1401, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1350.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1394, _1381.xyz) * _1417), 0.5f - (dot(_1394, _1386.xyz) * _1417));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1355.z > 0.5f)\n                    {\n                        float2 param_49 = _1355.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1376;\n                        float3 param_52 = _1381.xyz;\n                        float3 param_53 = _1386.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _7160 = _932.xyz * atten;\n    if (_923)\n    {\n        _7160 *= fa_light_tint;\n    }\n    int _1486;\n    if (_949)\n    {\n        _1486 = 0;\n    }\n    else\n    {\n        _1486 = ((_935 > 1.5f) && (_935 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _7171 = { l, _7160, atten, 1.0f, dist, _1486 };\n    return _7171;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2223;\n    if (i == 0)\n    {\n        _2223 = _2233_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2239;\n        if (i == 1)\n        {\n            _2239 = _2233_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2247;\n            if (i == 2)\n            {\n                _2247 = _2233_fa_shadow_split.z;\n            }\n            else\n            {\n                _2247 = _2233_fa_shadow_split.w;\n            }\n            _2239 = _2247;\n        }\n        _2223 = _2239;\n    }\n    return _2223;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2280 = fa_shadow_depth(param, param_1);\n    float _2284;\n    if (conv.x < 0.5f)\n    {\n        _2284 = _2280;\n    }\n    else\n    {\n        _2284 = (conv.y * conv.z) / (conv.z - (_2280 * (conv.z - conv.y)));\n    }\n    return _2284;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2211 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2211), sin(_2211)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2330 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2339;\n        if (k < 0.0f)\n        {\n            _2339 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2339 = k;\n        }\n        float _2359 = clamp((_2339 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2330;\n            float2 _2378 = fa_shadow_vogel(param_3, param_4, param_5) * _2359;\n            float2 param_6 = uv + (_2378 * _2233_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2390 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2390 < (zr - (length(_2378) * plane)))\n            {\n                sum += _2390;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2416 = sum / cnt;\n        float _2426;\n        if (k < 0.0f)\n        {\n            _2426 = (-k) / max(_2416, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2426 = k;\n        }\n        radius = clamp(((max(zr - _2416, 0.0f) * unit) * _2426) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2448 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2448; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2448;\n        float param_11 = _2330;\n        float2 _2467 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2467 * _2233_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2467) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2448);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2509 = max(_2233_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2514 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2520 = sqrt(1.0f - (_2514 * _2514));\n    float _2527 = min(_2520 / max(_2514, 0.20000000298023223876953125f), 4.0f);\n    float _2532;\n    if (_2233_fa_shadow_bias.y > 0.0f)\n    {\n        _2532 = _2233_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2532 = 1.5f * _2233_fa_shadow_info[ci].x;\n    }\n    float4 _2557 = mul(float4(world + (n * (_2532 * _2520)), 1.0f), _2233_fa_shadow_mat[ci]);\n    float _2564 = _2557.x;\n    bool _2567 = _2564 < _2233_fa_shadow_rect[ci].x;\n    bool _2576;\n    if (!_2567)\n    {\n        _2576 = _2564 > _2233_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2576 = _2567;\n    }\n    bool _2585;\n    if (!_2576)\n    {\n        _2585 = _2557.y < _2233_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2585 = _2576;\n    }\n    bool _2594;\n    if (!_2585)\n    {\n        _2594 = _2557.y > _2233_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2594 = _2585;\n    }\n    bool _2601;\n    if (!_2594)\n    {\n        _2601 = _2557.z > 1.0f;\n    }\n    else\n    {\n        _2601 = _2594;\n    }\n    if (_2601)\n    {\n        return -1.0f;\n    }\n    float _2609;\n    if (_2233_fa_shadow_bias.x > 0.0f)\n    {\n        _2609 = _2233_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2609 = 1.5f * _2233_fa_shadow_info[ci].x;\n    }\n    float2 param = _2557.xy;\n    float4 param_1 = _2233_fa_shadow_rect[ci];\n    float param_2 = _2557.z - ((_2609 * (1.0f + (0.5f * _2527))) / _2509);\n    float param_3 = _2233_fa_shadow_info[ci].x;\n    float param_4 = _2509;\n    float param_5 = _2509 * 0.25f;\n    float param_6 = ((_2233_fa_shadow_info[ci].x * min(_2527, 3.0f)) * 0.5f) / _2509;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2233_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2233_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_566_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2987 = int(_2233_fa_shadow_cfg.x + 0.5f);\n    if (_2987 < 1)\n    {\n        return 1.0f;\n    }\n    float _3002 = dot(world - _2233_fa_shadow_eye.xyz, _2233_fa_shadow_fwd.xyz);\n    int param = _2987 - 1;\n    if (_3002 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3014 = _2987 > 1;\n    bool _3021;\n    if (_3014)\n    {\n        _3021 = _3002 > _2233_fa_shadow_split.x;\n    }\n    else\n    {\n        _3021 = _3014;\n    }\n    if (_3021)\n    {\n        ci = 1;\n    }\n    bool _3025 = _2987 > 2;\n    bool _3032;\n    if (_3025)\n    {\n        _3032 = _3002 > _2233_fa_shadow_split.y;\n    }\n    else\n    {\n        _3032 = _3025;\n    }\n    if (_3032)\n    {\n        ci = 2;\n    }\n    bool _3036 = _2987 > 3;\n    bool _3043;\n    if (_3036)\n    {\n        _3043 = _3002 > _2233_fa_shadow_split.z;\n    }\n    else\n    {\n        _3043 = _3036;\n    }\n    if (_3043)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2987)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3069 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3069;\n        if (_3069 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2233_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3094;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3094 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3094 = _2233_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3113 = _2233_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3094, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3124 = clamp((_3002 - (fa_shadow_split_at(param_7) - _3113)) / _3113, 0.0f, 1.0f);\n        if (_3124 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2987)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3145 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3145;\n                if (_3145 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3124);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2667 = _566_fa_pbr.z < 0.5f;\n    bool _2674;\n    if (!_2667)\n    {\n        _2674 = _2233_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2674 = _2667;\n    }\n    if (_2674)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2233_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2687 = fa_light_texel(param);\n    float _2688 = _2687.x;\n    if (_2688 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2697 = int(_2688 + 0.5f);\n    int param_1 = _2697;\n    float4 _2701 = fa_light_texel(param_1);\n    int param_2 = _2697 + 1;\n    float4 _2706 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2709 = _2701.y;\n    if (_2709 > 0.0f)\n    {\n        float _2726 = 1.0f - smoothstep(0.75f * _2709, _2709, length(world - _2233_fa_shadow_eye.xyz));\n        fade = _2726;\n        if (_2726 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2701.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2750 = (_2697 + 2) + (face * 6);\n    int param_4 = _2750;\n    int param_5 = _2750 + 1;\n    int param_6 = _2750 + 3;\n    float4 _2764 = fa_light_texel(param_6);\n    int param_7 = _2750 + 4;\n    float4 _2769 = fa_light_texel(param_7);\n    int param_8 = _2750 + 5;\n    float4 _2774 = fa_light_texel(param_8);\n    float _2786 = _2774.x * max(dot(_2764, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2791 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2814 = clamp(dot(n, _2764.xyz), -1.0f, 1.0f);\n    float _2833 = min(sqrt(1.0f - (_2814 * _2814)) / max(abs(dot(n, world - lpos)) / max(dot(_2764, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2836 = _2706.y;\n    float _2838;\n    if (_2836 > 0.0f)\n    {\n        _2838 = _2836;\n    }\n    else\n    {\n        _2838 = 1.5f * _2786;\n    }\n    float4 _2858 = float4(world + (n * (_2838 * sqrt(1.0f - (_2791 * _2791)))), 1.0f);\n    float _2862 = dot(_2764, _2858);\n    float _2865 = _2774.y;\n    if (_2862 < _2865)\n    {\n        return 1.0f;\n    }\n    float2 _2880 = float2(dot(fa_light_texel(param_4), _2858), dot(fa_light_texel(param_5), _2858)) / _2862.xx;\n    float _2882 = _2880.x;\n    bool _2885 = _2882 < _2769.x;\n    bool _2894;\n    if (!_2885)\n    {\n        _2894 = _2882 > _2769.z;\n    }\n    else\n    {\n        _2894 = _2885;\n    }\n    bool _2903;\n    if (!_2894)\n    {\n        _2903 = _2880.y < _2769.y;\n    }\n    else\n    {\n        _2903 = _2894;\n    }\n    bool _2912;\n    if (!_2903)\n    {\n        _2912 = _2880.y > _2769.w;\n    }\n    else\n    {\n        _2912 = _2903;\n    }\n    if (_2912)\n    {\n        return 1.0f;\n    }\n    float _2918 = _2706.x;\n    float _2920;\n    if (_2918 > 0.0f)\n    {\n        _2920 = _2918;\n    }\n    else\n    {\n        _2920 = 1.5f * _2786;\n    }\n    float2 param_9 = _2880;\n    float4 param_10 = _2769;\n    float param_11 = _2862 - (_2920 * (1.0f + (0.5f * _2833)));\n    float param_12 = _2786;\n    float param_13 = 1.0f;\n    float param_14 = _2774.z * 0.25f;\n    float param_15 = (_2786 * min(_2833, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2865, _2774.z);\n    int param_17 = int(_2701.z + 0.5f);\n    float param_18 = _2701.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4475 = _566_fa_ct_a.x < 0.5f;\n    bool _4482;\n    if (!_4475)\n    {\n        _4482 = _2233_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4482 = _4475;\n    }\n    if (_4482)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2233_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4495 = fa_light_texel(param);\n    float _4496 = _4495.y;\n    float len = _4496;\n    if (_4496 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4508 = length(world - _566_fa_camera_pos.xyz);\n    float _4518 = 1.0f - smoothstep(0.5f * _566_fa_ct_b.x, _566_fa_ct_b.x, _4508);\n    if (_4518 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4524 = len;\n    float _4527 = min(_4524, 0.89999997615814208984375f * dist);\n    len = _4527;\n    float _4532 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4508);\n    float _4537 = _4532 + (0.5f * _4527);\n    float3 _4543 = world + (gn * _4532);\n    float _4545 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4609;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4560 = (float(k) + _4545) * 0.083333335816860198974609375f;\n        float3 _4568 = _4543 + (l * (_4560 * len));\n        float4 _4574 = float4(_4568, 1.0f);\n        float _4580 = dot(_566_fa_ct_vpw, _4574);\n        if (_4580 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4600 = float2(dot(_566_fa_ct_vpx, _4574), dot(_566_fa_ct_vpy, _4574)) / _4580.xx;\n        float _4604 = _4600.x * 0.5f;\n        float _4605 = _4604 + 0.5f;\n        if (_566_fa_ct_a.y > 0.5f)\n        {\n            _4609 = (_4600.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4609 = 0.5f - (_4600.y * 0.5f);\n        }\n        bool _4625 = _4605 < 0.0f;\n        bool _4632;\n        if (!_4625)\n        {\n            _4632 = _4605 >= 1.0f;\n        }\n        else\n        {\n            _4632 = _4625;\n        }\n        bool _4639;\n        if (!_4632)\n        {\n            _4639 = _4609 < 0.0f;\n        }\n        else\n        {\n            _4639 = _4632;\n        }\n        bool _4646;\n        if (!_4639)\n        {\n            _4646 = _4609 >= 1.0f;\n        }\n        else\n        {\n            _4646 = _4639;\n        }\n        if (_4646)\n        {\n            break;\n        }\n        float4 _4665 = fa_screen_tex.Load(int3(int2(float2(_4605, _4609) * _566_fa_ct_a.zw), 0));\n        if (_4665.w < 0.5f)\n        {\n            continue;\n        }\n        float _4684 = (dot(_566_fa_ct_fwd.xyz, _4568) + _566_fa_ct_fwd.w) - _4665.x;\n        if ((_4684 > _4532) && (_4684 < _4537))\n        {\n            occ = max(occ, (1.0f - (_4560 * _4560)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4605, 0.5f - _4604), min(_4609, 1.0f - _4609))));\n        }\n    }\n    return 1.0f - (occ * _4518);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4787 = fa_baked_keep(param);\n    if (_4787 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _7227 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _7227;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4813 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _7229 = _4813.color;\n    float _7230 = _4813.attenuation;\n    float _7231 = _4813.shadow;\n    bool _4816 = _4813.type == 0;\n    if (_4816 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4813.direction;\n        float _4827 = fa_shadow_factor(param_5, param_6);\n        _7231 = _4827;\n        _7229 *= _4827;\n    }\n    else\n    {\n        bool _4838 = _4813.type != 0;\n        bool _4844;\n        if (_4838)\n        {\n            _4844 = _7230 > 0.0f;\n        }\n        else\n        {\n            _4844 = _4838;\n        }\n        if (_4844)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4813.direction;\n            float _4863 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7231 = _4863;\n            _7229 *= _4863;\n        }\n    }\n    bool _4873 = _566_fa_ct_a.x > 0.5f;\n    bool _4879;\n    if (_4873)\n    {\n        _4879 = _7230 > 0.0f;\n    }\n    else\n    {\n        _4879 = _4873;\n    }\n    if (_4879)\n    {\n        float _4886;\n        if (_4816)\n        {\n            _4886 = 1000000000.0f;\n        }\n        else\n        {\n            _4886 = _4813._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4813.direction;\n        float param_18 = _4886;\n        float _4904 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7231 *= _4904;\n        _7229 *= _4904;\n    }\n    float _4917 = _7230;\n    float _4918 = _4917 * _4787;\n    _7230 = _4918;\n    float3 _4922 = _7229;\n    float3 _4923 = _4922 * _4787;\n    _7229 = _4923;\n    LightSample _7246 = { _4813.direction, _4923, _4918, _7231, _4813._distance, _4813.type };\n    return _7246;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _4957 = v - (n * dot(v, n));\n    float3 t = _4957;\n    float _4961 = dot(_4957, _4957);\n    float l2 = _4961;\n    if (_4961 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _4971;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _4971 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _4971 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _4971;\n        l2 = dot(_4971, _4971);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _5006 = dot(a, a);\n    float _5010 = dot(b, b);\n    if ((_5006 < 1.0000000195414813782625560981111e-24f) || (_5010 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _5024 = a * rsqrt(_5006);\n    float3 _5029 = b * rsqrt(_5010);\n    float _5033 = dot(_5024, _5029);\n    float _5036 = abs(_5033);\n    float g = (((((((((((0.0416471660137176513671875f * _5036) - 0.1924748718738555908203125f) * _5036) + 0.4179156124591827392578125f) * _5036) - 0.616057217121124267578125f) * _5036) + 0.777722418308258056640625f) * _5036) - 0.999542415142059326171875f) * _5036) + 1.570791721343994140625f;\n    if (_5033 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_5033 * _5033), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_5024, _5029) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _5093 = a.z > 0.0f;\n    bool _5097 = b.z > 0.0f;\n    if (_5093 && _5097)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5093 != _5097)\n        {\n            float3 _5132 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5132.z = 0.0f;\n            if (_5093)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _5132;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5132;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _5132;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5132;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _5181 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _5207 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _5233 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _5259 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _5181;\n    float3 param_1 = _5207;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _5207;\n    float3 param_7 = _5233;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _5233;\n    float3 param_13 = _5259;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _5259;\n    float3 param_19 = _5181;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _5409 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5433 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5449 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _5409;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _5433;\n    float4 param_9 = m;\n    float3 param_10 = _5409;\n    float3 param_11 = _5433;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _5449;\n    float4 param_14 = m;\n    float3 param_15 = _5409;\n    float3 param_16 = _5449;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5507 = fa_light_base(param);\n    int param_1 = _5507;\n    int param_2 = _5507 + 1;\n    int param_3 = _5507 + 2;\n    int param_4 = _5507 + 4;\n    float4 _5529 = fa_light_texel(param_4);\n    int param_5 = _5507 + 5;\n    float4 _5534 = fa_light_texel(param_5);\n    int param_6 = _5507 + 6;\n    float4 _5539 = fa_light_texel(param_6);\n    float _5540 = _5539.w;\n    float3 _5545 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5547 = _5540 < 1.5f;\n    bool _5554;\n    if (_5547)\n    {\n        _5554 = dot(normalize(fa_light_texel(param_3).xyz), _5545) >= 0.0f;\n    }\n    else\n    {\n        _5554 = _5547;\n    }\n    if (_5554)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5563 = (_5540 > 0.5f) && _5547;\n    float _5567 = _5563 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5570 = _5529.xyz;\n    float _5572 = _5529.w;\n    float3 _5578 = _5534.xyz;\n    float _5580 = _5534.w;\n    float3 up = _5578 * (_5580 * _5567);\n    float _5586;\n    if (_5563)\n    {\n        _5586 = (3.1415927410125732421875f * _5572) * _5572;\n    }\n    else\n    {\n        _5586 = (4.0f * _5572) * _5580;\n    }\n    if (_5540 > 1.5f)\n    {\n        float3 _5612 = cross(_5570, -_5545);\n        float3 perp = _5612;\n        float _5616 = dot(_5612, _5612);\n        float3 _5619;\n        if (_5616 > 1.0000000133514319600180897396058e-10f)\n        {\n            _5619 = perp * rsqrt(_5616);\n        }\n        else\n        {\n            _5619 = _5578;\n        }\n        perp = _5619;\n        up = _5619 * _5580;\n    }\n    float _5640 = max(_5586, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _5650 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _5650;\n    float3 param_10 = n;\n    float3 param_11 = _5545;\n    float3 _5658 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _5650;\n    float3 param_13 = n;\n    float3 param_14 = _5570 * (_5572 * _5567);\n    float3 _5666 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _5650;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _5674 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5540;\n    float3 param_20 = _5658;\n    float3 param_21 = _5666;\n    float3 param_22 = _5674;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _5693 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _5693;\n    float2 param_26 = _5693 + float2(64.0f, 0.0f);\n    float4 _5703 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5540;\n    float3 param_29 = _5658;\n    float3 param_30 = _5666;\n    float3 param_31 = _5674;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5703.x) + ((f90.xxx - f0) * _5703.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5545, _5545)) + _5640) / _5640) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4212 = 1.0f / alpha;\n    return ((2.0f + _4212) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4212)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4247 = max(dot(L.nc, l), 0.0f);\n    float _4253 = max(dot(L.nc, h), 0.0f);\n    float _4262 = ((_4253 * _4253) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4262) * _4262)) * (0.5f / max(lerp((2.0f * _4247) * L.coat_ndv, _4247 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4247)) * _4247;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5771;\n    if (L.sheen_on)\n    {\n        _5771 = L.sheen_scale;\n    }\n    else\n    {\n        _5771 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5771);\n    float3 _5784 = normalize(l + v);\n    int param_10 = li;\n    float3 _5795 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5804 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5784), 0.0f);\n        float param_13 = _5804;\n        float param_14 = ndv;\n        result += ((L.sheen * _5795) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _5804)) * _5804) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _5784;\n        float param_18 = max(dot(v, _5784), 0.0f);\n        result += (_5795 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4115 = tdh / at;\n    float _4119 = bdh / ab;\n    float _4131 = ((_4115 * _4115) + (_4119 * _4119)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4131) * _4131);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4311 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4390 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4390) * _4390);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4311);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4311));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3521 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3524 = _3521.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3524 * _3524, exp2((-9.27999973297119140625f) * ndv)) * _3524) + _3521.y)) + _3521.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_566_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _566_fa_env_horizon.w).xyz;\n    }\n    float _3375 = rough * rough;\n    float _3405 = 0.60000002384185791015625f * _3375;\n    return lerp(lerp(_566_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_566_fa_env_horizon.xyz, _566_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3375)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3405, 0.0500000007450580596923828125f + _3405, d.y).xxx), ((_566_fa_env_sky.xyz + _566_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3375 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3998;\n        if (L.aniso >= 0.0f)\n        {\n            _3998 = L.b;\n        }\n        else\n        {\n            _3998 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3998, v), _3998), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4031 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4031.x) + (L.f90.xxx * _4031.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4086 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4086.x) + _4086.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3563 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3563.x) + _3563.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2233_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3169 = int(_2233_fa_shadow_cfg.x + 0.5f);\n    float _3179 = dot(world - _2233_fa_shadow_eye.xyz, _2233_fa_shadow_fwd.xyz);\n    float3 tint_1 = 0.3499999940395355224609375f.xxx;\n    bool _3184 = _3169 > 0;\n    bool _3193;\n    if (_3184)\n    {\n        int param = _3169 - 1;\n        _3193 = _3179 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3193 = _3184;\n    }\n    if (_3193)\n    {\n        tint_1 = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3199 = _3169 > 1;\n        bool _3206;\n        if (_3199)\n        {\n            _3206 = _3179 > _2233_fa_shadow_split.x;\n        }\n        else\n        {\n            _3206 = _3199;\n        }\n        if (_3206)\n        {\n            tint_1 = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3212 = _3169 > 2;\n        bool _3219;\n        if (_3212)\n        {\n            _3219 = _3179 > _2233_fa_shadow_split.y;\n        }\n        else\n        {\n            _3219 = _3212;\n        }\n        if (_3219)\n        {\n            tint_1 = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3225 = _3169 > 3;\n        bool _3232;\n        if (_3225)\n        {\n            _3232 = _3179 > _2233_fa_shadow_split.z;\n        }\n        else\n        {\n            _3232 = _3225;\n        }\n        if (_3232)\n        {\n            tint_1 = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint_1, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _6929 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6929 = -_6929;\n    }\n    float3 _6292 = normalize(_566_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6942 = { fa_world_pos, _6929, fa_world_tangent, fa_uv, fa_vertex_color, _6292, gl_FrontFacing };\n    SurfaceInput param_1 = _6942;\n    Surface _6300 = fa_standard_surface(param_1);\n    float3 _6960 = _6300.albedo;\n    float _6961 = _6300.alpha;\n    float3 _6962 = _6300.normal;\n    float _6963 = _6300.metallic;\n    float _6964 = _6300.roughness;\n    float _6965 = _6300.occlusion;\n    float3 _6966 = _6300.emission;\n    float _6967 = _6300.clearcoat;\n    float _6968 = _6300.clearcoat_roughness;\n    float3 _6969 = _6300.sheen_color;\n    float _6970 = _6300.sheen_roughness;\n    float _6971 = _6300.anisotropy;\n    float _6972 = _6300.anisotropy_rotation;\n    float _6973 = _6300.specular;\n    float _6974 = _6300.ior;\n    float3 _6975 = _6300.specular_color;\n    SurfaceInput _6950 = { fa_world_pos, _6929, fa_world_tangent, fa_uv, fa_vertex_color, _6292, gl_FrontFacing };\n    SurfaceInput param_2 = _6950;\n    Surface param_3 = _6300;\n    surface(param_2, param_3);\n    _6960 = param_3.albedo;\n    _6961 = param_3.alpha;\n    _6962 = param_3.normal;\n    _6963 = param_3.metallic;\n    _6964 = param_3.roughness;\n    _6965 = param_3.occlusion;\n    _6966 = param_3.emission;\n    _6967 = param_3.clearcoat;\n    _6968 = param_3.clearcoat_roughness;\n    _6969 = param_3.sheen_color;\n    _6970 = param_3.sheen_roughness;\n    _6971 = param_3.anisotropy;\n    _6972 = param_3.anisotropy_rotation;\n    _6973 = param_3.specular;\n    _6974 = param_3.ior;\n    _6975 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6929;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6960 = param_6;\n    _6962 = param_7;\n    float3 result;\n    if (_566_fa_emissive.w > 0.5f)\n    {\n        result = _6960;\n    }\n    else\n    {\n        float3 _6339 = normalize(_6962);\n        float _6346 = clamp(_6963, 0.0f, 1.0f);\n        float _6350 = clamp(_6964, 0.0500000007450580596923828125f, 1.0f);\n        float _6354 = _6350 * _6350;\n        float _6358 = _6354 * _6354;\n        float _6363 = max(dot(_6339, _6292), 9.9999997473787516355514526367188e-05f);\n        float3 _6369 = _6960 * (1.0f - _6346);\n        float3 _6376 = lerp(0.039999999105930328369140625f.xxx, _6960, _6346.xxx);\n        float3 f0 = _6376;\n        SurfaceInput _6958 = { fa_world_pos, _6929, fa_world_tangent, fa_uv, fa_vertex_color, _6292, gl_FrontFacing };\n        SurfaceInput param_8 = _6958;\n        Surface _7041 = { _6960, _6961, _6962, _6963, _6964, _6965, _6966, _6967, _6968, _6969, _6970, _6971, _6972, _6973, _6974, _6975 };\n        Surface param_9 = _7041;\n        float3 param_10 = _6339;\n        float3 param_11 = _6292;\n        float param_12 = _6346;\n        float param_13 = _6350;\n        float3 param_14 = _6376;\n        FaLayers _6392 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _6339;\n        float3 lit = (fa_indirect_diffuse(param_15) * _6369) * _6965;\n        if (_6392.on)\n        {\n            lit *= _6392.base_scale;\n        }\n        int _6414 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6414; ln++)\n        {\n            int param_16 = ln;\n            int _6427 = fa_cl_light(param_16);\n            int param_17 = _6427;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _6427;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _6929;\n            LightSample _6443 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6451 = max(dot(_6339, _6443.direction), 0.0f);\n            float _6457 = _6443.attenuation * _6443.shadow;\n            float3 _6462 = normalize(_6443.direction + _6292);\n            float _6467 = max(dot(_6339, _6462), 0.0f);\n            float _6472 = max(dot(_6292, _6462), 0.0f);\n            bool _6479;\n            if (fa_light_is_area)\n            {\n                _6479 = !_6392.on;\n            }\n            else\n            {\n                _6479 = fa_light_is_area;\n            }\n            if (_6479)\n            {\n                int param_21 = _6427;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _6339;\n                float3 param_24 = _6292;\n                float3 param_25 = _6369;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _6350;\n                float param_29 = _6363;\n                float param_30 = _6457;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6392;\n                    int param_32 = _6427;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _6339;\n                    float3 param_35 = _6292;\n                    float3 param_36 = _6443.direction;\n                    float3 param_37 = _6369;\n                    float3 param_38 = f0;\n                    float param_39 = _6350;\n                    float param_40 = _6363;\n                    float param_41 = _6457;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6392.on)\n                    {\n                        FaLayers param_42 = _6392;\n                        float3 param_43 = _6369;\n                        float3 param_44 = f0;\n                        float3 param_45 = _6339;\n                        float3 param_46 = _6292;\n                        float3 param_47 = _6443.direction;\n                        float3 param_48 = _6462;\n                        float param_49 = _6451;\n                        float param_50 = _6363;\n                        float param_51 = _6467;\n                        float param_52 = _6472;\n                        float param_53 = _6354;\n                        float param_54 = _6358;\n                        int param_55 = _6427;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6457));\n                    }\n                    else\n                    {\n                        float _6585 = ((_6467 * _6467) * (_6358 - 1.0f)) + 1.0f;\n                        int param_56 = _6427;\n                        lit += (((_6369 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _6472, 5.0f))) * (((_6358 / ((3.1415927410125732421875f * _6585) * _6585)) * (0.5f / max(lerp((2.0f * _6451) * _6363, _6451 + _6363, _6354), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _6451))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6451 * _6457));\n                    }\n                }\n            }\n        }\n        if (_6392.on)\n        {\n            FaLayers param_57 = _6392;\n            float3 param_58 = _6339;\n            float3 param_59 = _6292;\n            float3 param_60 = f0;\n            float param_61 = _6350;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6965);\n        }\n        else\n        {\n            float3 param_62 = _6339;\n            float3 param_63 = _6292;\n            float3 param_64 = f0;\n            float param_65 = _6350;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6965);\n        }\n        result = lit;\n    }\n    float3 _6680 = result;\n    float3 _6681 = _6680 + _6966;\n    result = _6681;\n    float3 param_66 = _6681;\n    float3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6690 = _566_fa_fog.w > 0.0f;\n    bool _6697;\n    if (!_6690)\n    {\n        _6697 = _566_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _6697 = _6690;\n    }\n    if (_6697)\n    {\n        float3 _6706 = fa_world_pos - _566_fa_camera_pos.xyz;\n        float _6712 = dot(_6706, _566_fa_fog_c.xyz);\n        bool _6716 = _566_fa_fog_c.w > 0.5f;\n        float _6717;\n        if (_6716)\n        {\n            _6717 = _6712;\n        }\n        else\n        {\n            _6717 = length(_6706);\n        }\n        float _6729 = _6717 - _566_fa_fog_b.x;\n        if (_6729 > 0.0f)\n        {\n            float _6738 = _566_fa_fog.w * _6729;\n            float tau = _6738 * _6738;\n            if (_566_fa_fog_b.y > 0.0f)\n            {\n                float _6754;\n                if (_6716)\n                {\n                    _6754 = fa_world_pos.y - (_566_fa_fog_c.y * _6712);\n                }\n                else\n                {\n                    _6754 = _566_fa_camera_pos.y;\n                }\n                float _6775 = lerp(_6754, fa_world_pos.y, clamp(_566_fa_fog_b.x / _6717, 0.0f, 1.0f));\n                float _6779 = fa_world_pos.y - _6775;\n                float _6784 = _6775 - _566_fa_fog_b.z;\n                float _6789 = fa_world_pos.y - _566_fa_fog_b.z;\n                bool _6792 = _6784 <= 0.0f;\n                bool _6793 = !_6792;\n                bool _6799;\n                if (_6793)\n                {\n                    _6799 = _566_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6799 = _6792;\n                }\n                float _6800;\n                if (_6799)\n                {\n                    _6800 = _566_fa_fog_b.y;\n                }\n                else\n                {\n                    _6800 = _566_fa_fog_b.y * exp(-min(_566_fa_fog_b.w * _6784, 80.0f));\n                }\n                bool _6827;\n                if (_6793)\n                {\n                    _6827 = _566_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6827 = _6792;\n                }\n                float _6828;\n                if (_6827)\n                {\n                    _6828 = _566_fa_fog_b.y * _6784;\n                }\n                else\n                {\n                    _6828 = (_566_fa_fog_b.y * (1.0f - exp(-min(_566_fa_fog_b.w * _6784, 80.0f)))) / _566_fa_fog_b.w;\n                }\n                bool _6853 = _6789 <= 0.0f;\n                bool _6860;\n                if (!_6853)\n                {\n                    _6860 = _566_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6860 = _6853;\n                }\n                float _6861;\n                if (_6860)\n                {\n                    _6861 = _566_fa_fog_b.y * _6789;\n                }\n                else\n                {\n                    _6861 = (_566_fa_fog_b.y * (1.0f - exp(-min(_566_fa_fog_b.w * _6789, 80.0f)))) / _566_fa_fog_b.w;\n                }\n                float _6888;\n                if (abs(_6779) < 0.001000000047497451305389404296875f)\n                {\n                    _6888 = _6800;\n                }\n                else\n                {\n                    _6888 = (_6861 - _6828) / _6779;\n                }\n                tau += (_6729 * max(_6888, 0.0f));\n            }\n            result = lerp(result, _566_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6961);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec4",
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
            "inst_name": "_158",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_205",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_566",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2233",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_5873",
            "hlsl_register_b_n": 5
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
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 7
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
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 10
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _153_fa_view_proj : packoffset(c0);\n    row_major float4x4 _153_fa_light_vp : packoffset(c4);\n    float4 _153_fa_uv_scale : packoffset(c8);\n    float4 _153_fa_time : packoffset(c9);\n    float4 _153_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_inst_d0 : TEXCOORD9;\n    float4 fa_inst_d1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _334 = { mul(float4(position, 1.0f), model).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153_fa_uv_scale.xy, color, position };\n    return _334;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _197 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_197, _153_fa_light_vp).z;\n    fa_pre_r0 = float3(_153_fa_light_vp[0].x, _153_fa_light_vp[1].x, _153_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_153_fa_light_vp[0].y, _153_fa_light_vp[1].y, _153_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_153_fa_light_vp[0].z, _153_fa_light_vp[1].z, _153_fa_light_vp[2].z);\n    gl_Position = mul(_197, _153_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _142_boost : packoffset(c0);\n    float _142_fa_pad0 : packoffset(c0.y);\n    float _142_fa_pad1 : packoffset(c0.z);\n    float _142_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _255_fa_camera_pos : packoffset(c0);\n    float4 _255_fa_ambient : packoffset(c1);\n    float4 _255_fa_base_color : packoffset(c2);\n    float4 _255_fa_emissive : packoffset(c3);\n    float4 _255_fa_model_emissive : packoffset(c4);\n    float4 _255_fa_pbr : packoffset(c5);\n    float4 _255_fa_maps : packoffset(c6);\n    float4 _255_fa_fog : packoffset(c7);\n    float4 _255_fa_fog_b : packoffset(c8);\n    float4 _255_fa_fog_c : packoffset(c9);\n    float4 _255_fa_counts : packoffset(c10);\n    float4 _255_fa_env_sky : packoffset(c11);\n    float4 _255_fa_env_horizon : packoffset(c12);\n    float4 _255_fa_time : packoffset(c13);\n    float4 _255_fa_cl_vpx : packoffset(c14);\n    float4 _255_fa_cl_vpy : packoffset(c15);\n    float4 _255_fa_cl_vpw : packoffset(c16);\n    float4 _255_fa_cl_fwd : packoffset(c17);\n    float4 _255_fa_cl_grid : packoffset(c18);\n    float4 _255_fa_cl_info : packoffset(c19);\n    float4 _255_fa_layers_a : packoffset(c20);\n    float4 _255_fa_layers_b : packoffset(c21);\n    float4 _255_fa_layers_c : packoffset(c22);\n    float4 _255_fa_layers_d : packoffset(c23);\n    float4 _255_fa_ct_a : packoffset(c24);\n    float4 _255_fa_ct_b : packoffset(c25);\n    float4 _255_fa_ct_vpx : packoffset(c26);\n    float4 _255_fa_ct_vpy : packoffset(c27);\n    float4 _255_fa_ct_vpw : packoffset(c28);\n    float4 _255_fa_ct_fwd : packoffset(c29);\n    float4 _255_fa_probe_sh[9] : packoffset(c30);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _255_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _266 = fa_tex_fix(param_2, param_3);\n    float4 _774 = base_t;\n    _774.x = _266.x;\n    _774.y = _266.y;\n    _774.z = _266.z;\n    base_t = _774;\n    float4 _282 = (_774 * _255_fa_base_color) * i.vertex_color;\n    float3 _737 = i.world_normal;\n    if (_255_fa_maps.z > 0.5f)\n    {\n        float param_4 = _255_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _315 = fa_tex_fix(param_6, param_7);\n        float3 _319 = (_315 * 2.0f) - 1.0f.xxx;\n        float2 _324 = _319.xy * _255_fa_maps.x;\n        float3 _782 = _319;\n        _782.x = _324.x;\n        _782.y = _324.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _782;\n        _737 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _255_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _353 = fa_tex_fix(param_12, param_13);\n    float4 _785 = mrt;\n    _785.x = _353.x;\n    _785.y = _353.y;\n    _785.z = _353.z;\n    mrt = _785;\n    float4 _383 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _255_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _383.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _395 = fa_tex_fix(param_16, param_17);\n    float param_18 = _255_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _425 = fa_tex_fix(param_20, param_21);\n    float _742 = _255_fa_layers_a.x;\n    float _743 = _255_fa_layers_a.y;\n    float _746 = _255_fa_layers_a.z;\n    float _745 = _255_fa_layers_b.w;\n    float _748 = _255_fa_layers_c.x;\n    if (_255_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_255_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _742 *= _395.y;\n            _743 *= _395.z;\n            _745 *= _383.w;\n        }\n        if (_255_fa_layers_c.z > 1.5f)\n        {\n            _746 *= mrt.x;\n            _748 *= mrt.w;\n        }\n    }\n    Surface _767 = { _282.xyz, _282.w, _737, clamp(_255_fa_pbr.x * _353.z, 0.0f, 1.0f), clamp(_255_fa_pbr.y * _353.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_255_fa_maps.y * (_395.x - 1.0f)), _255_fa_emissive.xyz + (_255_fa_model_emissive.xyz * _425), _742, _743, _255_fa_layers_b.xyz, _745, _746, _255_fa_layers_a.w, _748, _255_fa_layers_c.y, _255_fa_layers_d.xyz };\n    return _767;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _142_boost);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _648 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _648 = -_648;\n    }\n    float3 _558 = normalize(_255_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _661 = { fa_world_pos, _648, fa_world_tangent, fa_uv, fa_vertex_color, _558, gl_FrontFacing };\n    SurfaceInput param = _661;\n    SurfaceInput _669 = { fa_world_pos, _648, fa_world_tangent, fa_uv, fa_vertex_color, _558, gl_FrontFacing };\n    SurfaceInput param_1 = _669;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _573 = normalize(param_2.normal);\n    float3 _588 = normalize(float3(dot(fa_pre_r0, _573), dot(fa_pre_r1, _573), dot(fa_pre_r2, _573)));\n    float _600 = _588.z;\n    float2 e = _588.xy / ((abs(_588.x) + abs(_588.y)) + abs(_600)).xx;\n    if (_600 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_153",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_142",
            "hlsl_register_b_n": 5
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_255",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _158_fa_view_proj : packoffset(c0);\n    row_major float4x4 _158_fa_light_vp : packoffset(c4);\n    float4 _158_fa_uv_scale : packoffset(c8);\n    float4 _158_fa_time : packoffset(c9);\n    float4 _158_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _205_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float4 fa_inst_d0 : TEXCOORD11;\n    float4 fa_inst_d1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_205_fa_joint_rows[_196] * weights[i]);\n        r1 += (_205_fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205_fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _454 = { mul(float4(position, 1.0f), model).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158_fa_uv_scale.xy, color, position };\n    return _454;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _310 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_310, _158_fa_light_vp).z;\n    fa_pre_r0 = float3(_158_fa_light_vp[0].x, _158_fa_light_vp[1].x, _158_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_158_fa_light_vp[0].y, _158_fa_light_vp[1].y, _158_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_158_fa_light_vp[0].z, _158_fa_light_vp[1].z, _158_fa_light_vp[2].z);\n    gl_Position = mul(_310, _158_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _142_boost : packoffset(c0);\n    float _142_fa_pad0 : packoffset(c0.y);\n    float _142_fa_pad1 : packoffset(c0.z);\n    float _142_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _255_fa_camera_pos : packoffset(c0);\n    float4 _255_fa_ambient : packoffset(c1);\n    float4 _255_fa_base_color : packoffset(c2);\n    float4 _255_fa_emissive : packoffset(c3);\n    float4 _255_fa_model_emissive : packoffset(c4);\n    float4 _255_fa_pbr : packoffset(c5);\n    float4 _255_fa_maps : packoffset(c6);\n    float4 _255_fa_fog : packoffset(c7);\n    float4 _255_fa_fog_b : packoffset(c8);\n    float4 _255_fa_fog_c : packoffset(c9);\n    float4 _255_fa_counts : packoffset(c10);\n    float4 _255_fa_env_sky : packoffset(c11);\n    float4 _255_fa_env_horizon : packoffset(c12);\n    float4 _255_fa_time : packoffset(c13);\n    float4 _255_fa_cl_vpx : packoffset(c14);\n    float4 _255_fa_cl_vpy : packoffset(c15);\n    float4 _255_fa_cl_vpw : packoffset(c16);\n    float4 _255_fa_cl_fwd : packoffset(c17);\n    float4 _255_fa_cl_grid : packoffset(c18);\n    float4 _255_fa_cl_info : packoffset(c19);\n    float4 _255_fa_layers_a : packoffset(c20);\n    float4 _255_fa_layers_b : packoffset(c21);\n    float4 _255_fa_layers_c : packoffset(c22);\n    float4 _255_fa_layers_d : packoffset(c23);\n    float4 _255_fa_ct_a : packoffset(c24);\n    float4 _255_fa_ct_b : packoffset(c25);\n    float4 _255_fa_ct_vpx : packoffset(c26);\n    float4 _255_fa_ct_vpy : packoffset(c27);\n    float4 _255_fa_ct_vpw : packoffset(c28);\n    float4 _255_fa_ct_fwd : packoffset(c29);\n    float4 _255_fa_probe_sh[9] : packoffset(c30);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _255_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _266 = fa_tex_fix(param_2, param_3);\n    float4 _774 = base_t;\n    _774.x = _266.x;\n    _774.y = _266.y;\n    _774.z = _266.z;\n    base_t = _774;\n    float4 _282 = (_774 * _255_fa_base_color) * i.vertex_color;\n    float3 _737 = i.world_normal;\n    if (_255_fa_maps.z > 0.5f)\n    {\n        float param_4 = _255_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _315 = fa_tex_fix(param_6, param_7);\n        float3 _319 = (_315 * 2.0f) - 1.0f.xxx;\n        float2 _324 = _319.xy * _255_fa_maps.x;\n        float3 _782 = _319;\n        _782.x = _324.x;\n        _782.y = _324.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _782;\n        _737 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _255_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _353 = fa_tex_fix(param_12, param_13);\n    float4 _785 = mrt;\n    _785.x = _353.x;\n    _785.y = _353.y;\n    _785.z = _353.z;\n    mrt = _785;\n    float4 _383 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _255_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _383.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _395 = fa_tex_fix(param_16, param_17);\n    float param_18 = _255_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _425 = fa_tex_fix(param_20, param_21);\n    float _742 = _255_fa_layers_a.x;\n    float _743 = _255_fa_layers_a.y;\n    float _746 = _255_fa_layers_a.z;\n    float _745 = _255_fa_layers_b.w;\n    float _748 = _255_fa_layers_c.x;\n    if (_255_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_255_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _742 *= _395.y;\n            _743 *= _395.z;\n            _745 *= _383.w;\n        }\n        if (_255_fa_layers_c.z > 1.5f)\n        {\n            _746 *= mrt.x;\n            _748 *= mrt.w;\n        }\n    }\n    Surface _767 = { _282.xyz, _282.w, _737, clamp(_255_fa_pbr.x * _353.z, 0.0f, 1.0f), clamp(_255_fa_pbr.y * _353.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_255_fa_maps.y * (_395.x - 1.0f)), _255_fa_emissive.xyz + (_255_fa_model_emissive.xyz * _425), _742, _743, _255_fa_layers_b.xyz, _745, _746, _255_fa_layers_a.w, _748, _255_fa_layers_c.y, _255_fa_layers_d.xyz };\n    return _767;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _142_boost);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _648 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _648 = -_648;\n    }\n    float3 _558 = normalize(_255_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _661 = { fa_world_pos, _648, fa_world_tangent, fa_uv, fa_vertex_color, _558, gl_FrontFacing };\n    SurfaceInput param = _661;\n    SurfaceInput _669 = { fa_world_pos, _648, fa_world_tangent, fa_uv, fa_vertex_color, _558, gl_FrontFacing };\n    SurfaceInput param_1 = _669;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _573 = normalize(param_2.normal);\n    float3 _588 = normalize(float3(dot(fa_pre_r0, _573), dot(fa_pre_r1, _573), dot(fa_pre_r2, _573)));\n    float _600 = _588.z;\n    float2 e = _588.xy / ((abs(_588.x) + abs(_588.y)) + abs(_600)).xx;\n    if (_600 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec4",
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
            "inst_name": "_158",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_205",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_142",
            "hlsl_register_b_n": 5
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_255",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _144_fa_view_proj : packoffset(c0);\n    row_major float4x4 _144_fa_light_vp : packoffset(c4);\n    float4 _144_fa_uv_scale : packoffset(c8);\n    float4 _144_fa_time : packoffset(c9);\n    float4 _144_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n    float4 fa_inst_d0 : TEXCOORD9;\n    float4 fa_inst_d1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _85 = cross(model[1].xyz, model[2].xyz);\n    float _91 = (dot(model[0].xyz, _85) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _282 = { mul(float4(position, 1.0f), model).xyz, (((_85 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _91, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _91), texcoord0 * _144_fa_uv_scale.xy, color, position };\n    return _282;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _144_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "inst_name": "_144",
            "hlsl_register_b_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _149_fa_view_proj : packoffset(c0);\n    row_major float4x4 _149_fa_light_vp : packoffset(c4);\n    float4 _149_fa_uv_scale : packoffset(c8);\n    float4 _149_fa_time : packoffset(c9);\n    float4 _149_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _196_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n    float4 fa_inst_d0 : TEXCOORD11;\n    float4 fa_inst_d1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _187 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_196_fa_joint_rows[_187] * weights[i]);\n        r1 += (_196_fa_joint_rows[_187 + 1] * weights[i]);\n        r2 += (_196_fa_joint_rows[_187 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _90 = cross(model[1].xyz, model[2].xyz);\n    float _96 = (dot(model[0].xyz, _90) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _402 = { mul(float4(position, 1.0f), model).xyz, (((_90 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _96, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _96), texcoord0 * _149_fa_uv_scale.xy, color, position };\n    return _402;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mul(float4(param_8.world_pos, 1.0f), _149_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "type": "vec4",
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
            "inst_name": "_196",
            "hlsl_register_b_n": 3
          }
        ]
      }
    }
  }
}
