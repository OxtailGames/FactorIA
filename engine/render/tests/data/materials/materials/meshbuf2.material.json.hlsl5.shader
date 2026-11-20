{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "cdeb0668828214c74f0c30d588a05ff792b9d23c1a6a8d04f213c29c73527515",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "buffers": [
    {
      "name": "extra",
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
    },
    {
      "name": "points",
      "binding": 1,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t1);\nByteAddressBuffer fa_vs_extra : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _182_fa_view_proj : packoffset(c0);\n    row_major float4x4 _182_fa_light_vp : packoffset(c4);\n    float4 _182_fa_uv_scale : packoffset(c8);\n    float4 _182_fa_time : packoffset(c9);\n    float4 _182_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _252_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _124 = cross(model[1].xyz, model[2].xyz);\n    float _128 = (dot(model[0].xyz, _124) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _293 = { mul(float4(position, 1.0f), model).xyz, (((_124 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _128, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _128), texcoord0 * _182_fa_uv_scale.xy, color, position };\n    return _293;\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _62 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f;\n    bool _77;\n    if (!_62)\n    {\n        _77 = asfloat(fa_vs_extra.Load(gl_InstanceIndex * 32 + 12)) < (-1.0f);\n    }\n    else\n    {\n        _77 = _62;\n    }\n    if (_77)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _182_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = _252_fa_base_model;\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstatic const float _2747[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _555_fa_camera_pos : packoffset(c0);\n    float4 _555_fa_ambient : packoffset(c1);\n    float4 _555_fa_base_color : packoffset(c2);\n    float4 _555_fa_emissive : packoffset(c3);\n    float4 _555_fa_model_emissive : packoffset(c4);\n    float4 _555_fa_pbr : packoffset(c5);\n    float4 _555_fa_maps : packoffset(c6);\n    float4 _555_fa_fog : packoffset(c7);\n    float4 _555_fa_fog_b : packoffset(c8);\n    float4 _555_fa_fog_c : packoffset(c9);\n    float4 _555_fa_counts : packoffset(c10);\n    float4 _555_fa_env_sky : packoffset(c11);\n    float4 _555_fa_env_horizon : packoffset(c12);\n    float4 _555_fa_time : packoffset(c13);\n    float4 _555_fa_cl_vpx : packoffset(c14);\n    float4 _555_fa_cl_vpy : packoffset(c15);\n    float4 _555_fa_cl_vpw : packoffset(c16);\n    float4 _555_fa_cl_fwd : packoffset(c17);\n    float4 _555_fa_cl_grid : packoffset(c18);\n    float4 _555_fa_cl_info : packoffset(c19);\n    float4 _555_fa_layers_a : packoffset(c20);\n    float4 _555_fa_layers_b : packoffset(c21);\n    float4 _555_fa_layers_c : packoffset(c22);\n    float4 _555_fa_layers_d : packoffset(c23);\n    float4 _555_fa_ct_a : packoffset(c24);\n    float4 _555_fa_ct_b : packoffset(c25);\n    float4 _555_fa_ct_vpx : packoffset(c26);\n    float4 _555_fa_ct_vpy : packoffset(c27);\n    float4 _555_fa_ct_vpw : packoffset(c28);\n    float4 _555_fa_ct_fwd : packoffset(c29);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1295_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1295_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1295_fa_shadow_info[4] : packoffset(c20);\n    float4 _1295_fa_shadow_split : packoffset(c24);\n    float4 _1295_fa_shadow_cfg : packoffset(c25);\n    float4 _1295_fa_shadow_bias : packoffset(c26);\n    float4 _1295_fa_shadow_eye : packoffset(c27);\n    float4 _1295_fa_shadow_fwd : packoffset(c28);\n    float4 _1295_fa_shadow_lcfg : packoffset(c29);\n};\n\nByteAddressBuffer points : register(t7);\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t10);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _560 = _555_fa_cl_info.x < 0.0f;\n    bool _567;\n    if (!_560)\n    {\n        _567 = _555_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _567 = _560;\n    }\n    bool _575;\n    if (!_567)\n    {\n        _575 = _555_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _575 = _567;\n    }\n    bool _582;\n    if (!_575)\n    {\n        _582 = _555_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _582 = _575;\n    }\n    bool _589;\n    if (!_582)\n    {\n        _589 = _555_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _589 = _582;\n    }\n    if (_589)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _599 = float4(world_pos, 1.0f);\n    float _606 = dot(_555_fa_cl_vpw, _599);\n    if (!(_606 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _628 = float2(dot(_555_fa_cl_vpx, _599), dot(_555_fa_cl_vpy, _599)) / _606.xx;\n    int _632 = int(_555_fa_cl_grid.x);\n    int _636 = int(_555_fa_cl_grid.y);\n    int param = (int(_555_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_555_fa_cl_fwd.xyz, world_pos) + _555_fa_cl_fwd.w, _555_fa_cl_grid.w) / _555_fa_cl_grid.w) * _555_fa_cl_grid.z)), 0, int(_555_fa_cl_info.y) - 1) * _636) + clamp(int(floor(((_628.y * 0.5f) + 0.5f) * _555_fa_cl_grid.y)), 0, _636 - 1)) * _632)) + clamp(int(floor(((_628.x * 0.5f) + 0.5f) * _555_fa_cl_grid.x)), 0, _632 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _712 = fa_cluster_texel(param);\n    return int2(int(_712.x), int(_712.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_555_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3811 = fa_cluster_lookup(param);\n    fa_cl_slot = _3811.x;\n    fa_cl_local = _3811.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4015 = fa_linear_to_srgb(param);\n        c = _4015;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4023 = fa_srgb_to_linear(param_1);\n            c = _4023;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _311;\n    if (i.front_facing)\n    {\n        _311 = i.world_normal;\n    }\n    else\n    {\n        _311 = -i.world_normal;\n    }\n    float3 _335 = normalize(i.world_tangent.xyz - (_311 * dot(_311, i.world_tangent.xyz)));\n    float3 _362 = normalize(((_335 * m.x) + ((cross(_311, _335) * i.world_tangent.w) * m.y)) + (_311 * m.z));\n    float3 _365;\n    if (i.front_facing)\n    {\n        _365 = _362;\n    }\n    else\n    {\n        _365 = -_362;\n    }\n    return _365;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _555_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4054 = fa_tex_fix(param_2, param_3);\n    float4 _5371 = base_t;\n    _5371.x = _4054.x;\n    _5371.y = _4054.y;\n    _5371.z = _4054.z;\n    base_t = _5371;\n    float4 _4068 = (_5371 * _555_fa_base_color) * i.vertex_color;\n    float3 _5225 = i.world_normal;\n    if (_555_fa_maps.z > 0.5f)\n    {\n        float param_4 = _555_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4100 = fa_tex_fix(param_6, param_7);\n        float3 _4103 = (_4100 * 2.0f) - 1.0f.xxx;\n        float2 _4108 = _4103.xy * _555_fa_maps.x;\n        float3 _5379 = _4103;\n        _5379.x = _4108.x;\n        _5379.y = _4108.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5379;\n        _5225 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _555_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4137 = fa_tex_fix(param_12, param_13);\n    float4 _5382 = mrt;\n    _5382.x = _4137.x;\n    _5382.y = _4137.y;\n    _5382.z = _4137.z;\n    mrt = _5382;\n    float4 _4165 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _555_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4165.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4177 = fa_tex_fix(param_16, param_17);\n    float param_18 = _555_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4207 = fa_tex_fix(param_20, param_21);\n    float _5230 = _555_fa_layers_a.x;\n    float _5231 = _555_fa_layers_a.y;\n    float _5234 = _555_fa_layers_a.z;\n    float _5233 = _555_fa_layers_b.w;\n    float _5236 = _555_fa_layers_c.x;\n    if (_555_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_555_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5230 *= _4177.y;\n            _5231 *= _4177.z;\n            _5233 *= _4165.w;\n        }\n        if (_555_fa_layers_c.z > 1.5f)\n        {\n            _5234 *= mrt.x;\n            _5236 *= mrt.w;\n        }\n    }\n    Surface _5255 = { _4068.xyz, _4068.w, _5225, clamp(_555_fa_pbr.x * _4137.z, 0.0f, 1.0f), clamp(_555_fa_pbr.y * _4137.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_555_fa_maps.y * (_4177.x - 1.0f)), _555_fa_emissive.xyz + (_555_fa_model_emissive.xyz * _4207), _5230, _5231, _555_fa_layers_b.xyz, _5233, _5234, _555_fa_layers_a.w, _5236, _555_fa_layers_c.y, _555_fa_layers_d.xyz };\n    return _5255;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * asfloat(points.Load(28)));\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _793 = rect.zw - rect.xy;\n    float2 _797 = _793 * atlas;\n    float2 _801 = ddx * _797;\n    float2 _805 = ddy * _797;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _793), clamp(0.5f * log2(max(max(dot(_801, _801), dot(_805, _805)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _840 = _555_fa_counts.y < 0.5f;\n    bool _847;\n    if (!_840)\n    {\n        _847 = _555_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _847 = _840;\n    }\n    if (_847)\n    {\n        return;\n    }\n    float3 _853 = ddx(world_pos);\n    float3 _856 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _860 = fa_cluster_texel(param);\n    int _864 = int(_860.w);\n    if (_864 < 1)\n    {\n        return;\n    }\n    int _874 = int(_555_fa_counts.y + 0.5f);\n    int param_1 = _874;\n    float4 _878 = fa_light_texel(param_1);\n    float2 _881 = _878.yz;\n    int _885 = int(_878.w);\n    int param_2 = _874 + 1;\n    float4 _890 = fa_light_texel(param_2);\n    float _891 = _890.x;\n    int _897 = int(_555_fa_counts.w + 0.5f) - 1;\n    int _901 = int(_860.z);\n    float3 _1167;\n    for (int k = 0; k < _864; k++)\n    {\n        int _914 = _901 + k;\n        int param_3 = _885 + (_914 >> 2);\n        int _932 = (_874 + 2) + (int(fa_light_texel(param_3)[_914 & 3]) * 7);\n        int param_4 = _932 + 6;\n        float4 _937 = fa_light_texel(param_4);\n        if (((int(_937.w + 0.5f) >> _897) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _932;\n        float4 _952 = fa_light_texel(param_5);\n        int param_6 = _932 + 1;\n        float4 _957 = fa_light_texel(param_6);\n        int param_7 = _932 + 2;\n        float4 _962 = fa_light_texel(param_7);\n        float3 _965 = _952.xyz;\n        float _970 = dot(_965, world_pos) + _952.w;\n        float3 _972 = _957.xyz;\n        float _977 = dot(_972, world_pos) + _957.w;\n        float3 _979 = _962.xyz;\n        float _984 = dot(_979, world_pos) + _962.w;\n        bool _989 = abs(_970) > 0.5f;\n        bool _997;\n        if (!_989)\n        {\n            _997 = abs(_977) > 0.5f;\n        }\n        else\n        {\n            _997 = _989;\n        }\n        bool _1005;\n        if (!_997)\n        {\n            _1005 = abs(_984) > 0.5f;\n        }\n        else\n        {\n            _1005 = _997;\n        }\n        if (_1005)\n        {\n            continue;\n        }\n        float _1020 = clamp(dot(geo_normal, normalize(_979)) * _937.z, 0.0f, 1.0f);\n        if (_1020 <= 0.0f)\n        {\n            continue;\n        }\n        float _1040 = (clamp((0.5f - abs(_984)) * 10.0f, 0.0f, 1.0f) * _1020) * _937.x;\n        float2 _1048 = float2(_970 + 0.5f, 0.5f - _977);\n        float2 _1058 = float2(dot(_965, _853), dot(_972, _853));\n        float2 _1068 = float2(dot(_965, _856), dot(_972, _856));\n        int param_8 = _932 + 5;\n        float4 _1073 = fa_light_texel(param_8);\n        int param_9 = _932 + 3;\n        float4 _1078 = fa_light_texel(param_9);\n        int param_10 = _932 + 4;\n        float4 _1083 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1073.xyz;\n        bool _1093 = _1078.z > _1078.x;\n        if (_1093)\n        {\n            float4 param_11 = _1078;\n            float2 param_12 = _1048;\n            float2 param_13 = _881;\n            float2 param_14 = _1058;\n            float2 param_15 = _1068;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_891 > 0.5f) && (_891 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1119 = fa_dc_to_linear(param_16);\n                float4 _5281 = tx;\n                _5281.x = _1119.x;\n                _5281.y = _1119.y;\n                _5281.z = _1119.z;\n                tx = _5281;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1040 * tex_a) * _1073.w, 0.0f, 1.0f).xxx);\n        if (_1083.z > _1083.x)\n        {\n            float4 param_17 = _1083;\n            float2 param_18 = _1048;\n            float2 param_19 = _881;\n            float2 param_20 = _1058;\n            float2 param_21 = _1068;\n            float4 _1163 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_891 > 1.5f)\n            {\n                float3 param_22 = _1163.xyz;\n                float3 _1173 = fa_dc_to_srgb(param_22);\n                _1167 = _1173;\n            }\n            else\n            {\n                _1167 = _1163.xyz;\n            }\n            float3 _1183 = (_1167 * 2.0f) - 1.0f.xxx;\n            float2 _1188 = _1183.xy * _937.y;\n            float3 _1210 = (normalize(_965) * _1188.x) + (normalize(_972) * _1188.y);\n            float3 _1213 = normalize(normal);\n            normal = normalize(lerp(_1213, normalize((_1213 * max(_1183.z, 0.0500000007450580596923828125f)) + (_1210 - (_1213 * dot(_1213, _1210)))), clamp(_1040 * (_1093 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2673 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _2680 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _2683 = int(_2673);\n    int _2686 = int(_2680);\n    float _2696 = _2680 - float(_2686);\n    int _2751 = (_2683 * 9) + _2686;\n    int _2771 = ((_2683 + 1) * 9) + _2686;\n    return lerp(lerp(_2747[_2751], _2747[_2751 + 1], _2696), lerp(_2747[_2771], _2747[_2771 + 1], _2696), _2673 - float(_2683));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _5148 = false;\n    float _5149 = 1.0f;\n    float _5150 = 1.0f;\n    float _5151 = 1.0f;\n    float _5152 = 0.0f;\n    float _5153 = 0.0f;\n    float _5154 = 0.0f;\n    float _5155 = 0.0f;\n    float _5157 = 1.0f;\n    bool _5158 = false;\n    float3 _5159 = 0.0f.xxx;\n    float _5160 = 1.0f;\n    float _5161 = 1.0f;\n    float _5162 = 1.0f;\n    float _5163 = 0.0f;\n    float _5164 = 0.0f;\n    float3 _5165 = float3(1.0f, 0.0f, 0.0f);\n    float3 _5166 = float3(0.0f, 0.0f, 1.0f);\n    float _5167 = 1.0f;\n    float _5168 = 1.0f;\n    float _2824 = clamp(s.specular, 0.0f, 1.0f);\n    float _2828 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2833 = (_2824 != 1.0f) || (_2828 != 1.5f);\n    bool _2843;\n    if (!_2833)\n    {\n        _2843 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2843 = _2833;\n    }\n    if (_2843)\n    {\n        float _2851 = (_2828 - 1.0f) / (_2828 + 1.0f);\n        f0 = lerp(min((_2851 * _2851).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2824, s.albedo, metallic.xxx);\n        _5149 = lerp(_2824, 1.0f, metallic);\n        _5148 = true;\n    }\n    float _2879 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2879 > 0.0f)\n    {\n        float _2887 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _5152 = _2879;\n        _5153 = _2887;\n        float _2894 = _2887 * _2887;\n        _5154 = _2894;\n        _5155 = _2894 * _2894;\n        float _2906 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _5157 = _2906;\n        _5150 = 1.0f - (_2879 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2906, 0.0f, 1.0f), 5.0f))));\n        _5148 = true;\n    }\n    float3 _2925 = max(s.sheen_color, 0.0f.xxx);\n    float _2934 = max(_2925.x, max(_2925.y, _2925.z));\n    if (_2934 > 0.0f)\n    {\n        float _2942 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _5158 = true;\n        _5159 = _2925;\n        _5160 = _2942;\n        _5161 = _2942 * _2942;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2942;\n        float _2959 = fa_sheen_albedo(param, param_1);\n        _5163 = _2959;\n        _5162 = 1.0f - min(_2934 * _2959, 1.0f);\n        _5148 = true;\n    }\n    _5151 = _5150 * _5162;\n    float _2978 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2978 != 0.0f)\n    {\n        float3 _2993 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2993;\n        if (dot(_2993, _2993) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3006 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3006.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3006.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3006.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3010 = t;\n        float3 _3011 = normalize(_3010);\n        t = _3011;\n        float3 _3036 = normalize((_3011 * cos(s.anisotropy_rotation)) + ((cross(n, _3011) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _5165 = _3036;\n        _5166 = cross(n, _3036);\n        float _3046 = roughness * roughness;\n        float _3052 = lerp(_3046, 1.0f, _2978 * _2978);\n        bool _3054 = _2978 > 0.0f;\n        _5167 = _3054 ? _3052 : _3046;\n        _5168 = _3054 ? _3046 : _3052;\n        _5164 = _2978;\n        _5148 = true;\n    }\n    FaLayers _5190 = { _5148, _5149, _5150, _5151, _5152, _5153, _5154, _5155, i.world_normal, _5157, _5158, _5159, _5160, _5161, _5162, _5163, _5164, _5165, _5166, _5167, _5168 };\n    return _5190;\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_555_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _2430 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _2430;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_555_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _555_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_555_fa_cl_info.x) + int(_555_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _429 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _435 = fa_light_texel(param_1);\n    float _438 = _435.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _444 = _438 < 0.5f;\n    float3 l;\n    if (_444)\n    {\n        l = normalize(_429.xyz);\n    }\n    else\n    {\n        float3 _456 = _429.xyz - world_pos;\n        float _458 = length(_456);\n        dist = _458;\n        l = _456 / max(_458, 9.9999997473787516355514526367188e-05f).xxx;\n        float _473 = _458 / max(_429.w, 0.001000000047497451305389404296875f);\n        float _479 = clamp(1.0f - (_473 * _473), 0.0f, 1.0f);\n        atten = _479 * _479;\n        if (_438 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _493 = fa_light_texel(param_2);\n            float _503 = _493.w;\n            int param_3 = (li * 4) + 3;\n            float4 _509 = fa_light_texel(param_3);\n            float _510 = _509.x;\n            float cos_inner = _510;\n            if (_510 > 1.5f)\n            {\n                cos_inner = lerp(_503, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_503, cos_inner, dot(-l, normalize(_493.xyz)));\n        }\n    }\n    int _541;\n    if (_444)\n    {\n        _541 = 0;\n    }\n    else\n    {\n        _541 = (_438 > 1.5f) ? 2 : 1;\n    }\n    LightSample _5147 = { l, _435.xyz * atten, atten, 1.0f, dist, _541 };\n    return _5147;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1285;\n    if (i == 0)\n    {\n        _1285 = _1295_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1301;\n        if (i == 1)\n        {\n            _1301 = _1295_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1309;\n            if (i == 2)\n            {\n                _1309 = _1295_fa_shadow_split.z;\n            }\n            else\n            {\n                _1309 = _1295_fa_shadow_split.w;\n            }\n            _1301 = _1309;\n        }\n        _1285 = _1301;\n    }\n    return _1285;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1342 = fa_shadow_depth(param, param_1);\n    float _1346;\n    if (conv.x < 0.5f)\n    {\n        _1346 = _1342;\n    }\n    else\n    {\n        _1346 = (conv.y * conv.z) / (conv.z - (_1342 * (conv.z - conv.y)));\n    }\n    return _1346;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1273 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1273), sin(_1273)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1392 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _1406 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1392;\n            float2 _1425 = fa_shadow_vogel(param_3, param_4, param_5) * _1406;\n            float2 param_6 = uv + (_1425 * _1295_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1437 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1437 < (zr - (length(_1425) * plane)))\n            {\n                sum += _1437;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1481 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1481; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1481;\n        float param_11 = _1392;\n        float2 _1500 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1500 * _1295_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1500) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1481);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1542 = max(_1295_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1547 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1553 = sqrt(1.0f - (_1547 * _1547));\n    float _1560 = min(_1553 / max(_1547, 0.20000000298023223876953125f), 4.0f);\n    float _1565;\n    if (_1295_fa_shadow_bias.y > 0.0f)\n    {\n        _1565 = _1295_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1565 = 1.5f * _1295_fa_shadow_info[ci].x;\n    }\n    float4 _1590 = mul(float4(world + (n * (_1565 * _1553)), 1.0f), _1295_fa_shadow_mat[ci]);\n    float _1597 = _1590.x;\n    bool _1600 = _1597 < _1295_fa_shadow_rect[ci].x;\n    bool _1609;\n    if (!_1600)\n    {\n        _1609 = _1597 > _1295_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1609 = _1600;\n    }\n    bool _1618;\n    if (!_1609)\n    {\n        _1618 = _1590.y < _1295_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1618 = _1609;\n    }\n    bool _1627;\n    if (!_1618)\n    {\n        _1627 = _1590.y > _1295_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1627 = _1618;\n    }\n    bool _1634;\n    if (!_1627)\n    {\n        _1634 = _1590.z > 1.0f;\n    }\n    else\n    {\n        _1634 = _1627;\n    }\n    if (_1634)\n    {\n        return -1.0f;\n    }\n    float _1643;\n    if (_1295_fa_shadow_bias.x > 0.0f)\n    {\n        _1643 = _1295_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1643 = 1.5f * _1295_fa_shadow_info[ci].x;\n    }\n    float2 param = _1590.xy;\n    float4 param_1 = _1295_fa_shadow_rect[ci];\n    float param_2 = _1590.z - ((_1643 * (1.0f + (0.5f * _1560))) / _1542);\n    float param_3 = _1295_fa_shadow_info[ci].x;\n    float param_4 = _1542;\n    float param_5 = _1542 * 0.25f;\n    float param_6 = ((_1295_fa_shadow_info[ci].x * min(_1560, 3.0f)) * 0.5f) / _1542;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_1295_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _1295_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_555_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2070 = int(_1295_fa_shadow_cfg.x + 0.5f);\n    if (_2070 < 1)\n    {\n        return 1.0f;\n    }\n    float _2085 = dot(world - _1295_fa_shadow_eye.xyz, _1295_fa_shadow_fwd.xyz);\n    int param = _2070 - 1;\n    if (_2085 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2097 = _2070 > 1;\n    bool _2104;\n    if (_2097)\n    {\n        _2104 = _2085 > _1295_fa_shadow_split.x;\n    }\n    else\n    {\n        _2104 = _2097;\n    }\n    if (_2104)\n    {\n        ci = 1;\n    }\n    bool _2108 = _2070 > 2;\n    bool _2115;\n    if (_2108)\n    {\n        _2115 = _2085 > _1295_fa_shadow_split.y;\n    }\n    else\n    {\n        _2115 = _2108;\n    }\n    if (_2115)\n    {\n        ci = 2;\n    }\n    bool _2119 = _2070 > 3;\n    bool _2126;\n    if (_2119)\n    {\n        _2126 = _2085 > _1295_fa_shadow_split.z;\n    }\n    else\n    {\n        _2126 = _2119;\n    }\n    if (_2126)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2070)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2152 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2152;\n        if (_2152 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1295_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2177;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2177 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2177 = _1295_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2196 = _1295_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2177, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2207 = clamp((_2085 - (fa_shadow_split_at(param_7) - _2196)) / _2196, 0.0f, 1.0f);\n        if (_2207 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2070)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2228 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2228;\n                if (_2228 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2207);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1701 = _555_fa_pbr.z < 0.5f;\n    bool _1709;\n    if (!_1701)\n    {\n        _1709 = _1295_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1709 = _1701;\n    }\n    if (_1709)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1295_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1722 = fa_light_texel(param);\n    float _1723 = _1722.x;\n    if (_1723 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1732 = int(_1723 + 0.5f);\n    int param_1 = _1732;\n    float4 _1736 = fa_light_texel(param_1);\n    int param_2 = _1732 + 1;\n    float4 _1741 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1744 = _1736.y;\n    if (_1744 > 0.0f)\n    {\n        float _1761 = 1.0f - smoothstep(0.75f * _1744, _1744, length(world - _1295_fa_shadow_eye.xyz));\n        fade = _1761;\n        if (_1761 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1736.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1780 = world - fa_light_texel(param_3).xyz;\n        float3 _1783 = abs(_1780);\n        float _1785 = _1783.x;\n        float _1787 = _1783.y;\n        bool _1788 = _1785 >= _1787;\n        bool _1796;\n        if (_1788)\n        {\n            _1796 = _1785 >= _1783.z;\n        }\n        else\n        {\n            _1796 = _1788;\n        }\n        int _1797;\n        if (_1796)\n        {\n            _1797 = (_1780.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1810;\n            if (_1787 >= _1783.z)\n            {\n                _1810 = (_1780.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1810 = (_1780.z > 0.0f) ? 4 : 5;\n            }\n            _1797 = _1810;\n        }\n        face = _1797;\n    }\n    int _1829 = (_1732 + 2) + (face * 6);\n    int param_4 = _1829;\n    int param_5 = _1829 + 1;\n    int param_6 = _1829 + 3;\n    float4 _1843 = fa_light_texel(param_6);\n    int param_7 = _1829 + 4;\n    float4 _1848 = fa_light_texel(param_7);\n    int param_8 = _1829 + 5;\n    float4 _1853 = fa_light_texel(param_8);\n    float _1865 = _1853.x * max(dot(_1843, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1870 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1893 = clamp(dot(n, _1843.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1916 = min(sqrt(1.0f - (_1893 * _1893)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1843, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1919 = _1741.y;\n    float _1921;\n    if (_1919 > 0.0f)\n    {\n        _1921 = _1919;\n    }\n    else\n    {\n        _1921 = 1.5f * _1865;\n    }\n    float4 _1941 = float4(world + (n * (_1921 * sqrt(1.0f - (_1870 * _1870)))), 1.0f);\n    float _1945 = dot(_1843, _1941);\n    float _1948 = _1853.y;\n    if (_1945 < _1948)\n    {\n        return 1.0f;\n    }\n    float2 _1963 = float2(dot(fa_light_texel(param_4), _1941), dot(fa_light_texel(param_5), _1941)) / _1945.xx;\n    float _1965 = _1963.x;\n    bool _1968 = _1965 < _1848.x;\n    bool _1977;\n    if (!_1968)\n    {\n        _1977 = _1965 > _1848.z;\n    }\n    else\n    {\n        _1977 = _1968;\n    }\n    bool _1986;\n    if (!_1977)\n    {\n        _1986 = _1963.y < _1848.y;\n    }\n    else\n    {\n        _1986 = _1977;\n    }\n    bool _1995;\n    if (!_1986)\n    {\n        _1995 = _1963.y > _1848.w;\n    }\n    else\n    {\n        _1995 = _1986;\n    }\n    if (_1995)\n    {\n        return 1.0f;\n    }\n    float _2001 = _1741.x;\n    float _2003;\n    if (_2001 > 0.0f)\n    {\n        _2003 = _2001;\n    }\n    else\n    {\n        _2003 = 1.5f * _1865;\n    }\n    float2 param_10 = _1963;\n    float4 param_11 = _1848;\n    float param_12 = _1945 - (_2003 * (1.0f + (0.5f * _1916)));\n    float param_13 = _1865;\n    float param_14 = 1.0f;\n    float param_15 = _1853.z * 0.25f;\n    float param_16 = (_1865 * min(_1916, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1948, _1853.z);\n    int param_18 = int(_1736.z + 0.5f);\n    float param_19 = _1736.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3553 = _555_fa_ct_a.x < 0.5f;\n    bool _3560;\n    if (!_3553)\n    {\n        _3560 = _1295_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3560 = _3553;\n    }\n    if (_3560)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1295_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3573 = fa_light_texel(param);\n    float _3574 = _3573.y;\n    float len = _3574;\n    if (_3574 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3586 = length(world - _555_fa_camera_pos.xyz);\n    float _3596 = 1.0f - smoothstep(0.5f * _555_fa_ct_b.x, _555_fa_ct_b.x, _3586);\n    if (_3596 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3602 = len;\n    float _3605 = min(_3602, 0.89999997615814208984375f * dist);\n    len = _3605;\n    float _3610 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3586);\n    float _3615 = _3610 + (0.5f * _3605);\n    float3 _3621 = world + (gn * _3610);\n    float _3623 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3687;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3638 = (float(k) + _3623) * 0.083333335816860198974609375f;\n        float3 _3646 = _3621 + (l * (_3638 * len));\n        float4 _3652 = float4(_3646, 1.0f);\n        float _3658 = dot(_555_fa_ct_vpw, _3652);\n        if (_3658 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3678 = float2(dot(_555_fa_ct_vpx, _3652), dot(_555_fa_ct_vpy, _3652)) / _3658.xx;\n        float _3682 = _3678.x * 0.5f;\n        float _3683 = _3682 + 0.5f;\n        if (_555_fa_ct_a.y > 0.5f)\n        {\n            _3687 = (_3678.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3687 = 0.5f - (_3678.y * 0.5f);\n        }\n        bool _3703 = _3683 < 0.0f;\n        bool _3710;\n        if (!_3703)\n        {\n            _3710 = _3683 >= 1.0f;\n        }\n        else\n        {\n            _3710 = _3703;\n        }\n        bool _3717;\n        if (!_3710)\n        {\n            _3717 = _3687 < 0.0f;\n        }\n        else\n        {\n            _3717 = _3710;\n        }\n        bool _3724;\n        if (!_3717)\n        {\n            _3724 = _3687 >= 1.0f;\n        }\n        else\n        {\n            _3724 = _3717;\n        }\n        if (_3724)\n        {\n            break;\n        }\n        float4 _3743 = fa_screen_tex.Load(int3(int2(float2(_3683, _3687) * _555_fa_ct_a.zw), 0));\n        if (_3743.w < 0.5f)\n        {\n            continue;\n        }\n        float _3762 = (dot(_555_fa_ct_fwd.xyz, _3646) + _555_fa_ct_fwd.w) - _3743.x;\n        if ((_3762 > _3610) && (_3762 < _3615))\n        {\n            occ = max(occ, (1.0f - (_3638 * _3638)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3683, 0.5f - _3682), min(_3687, 1.0f - _3687))));\n        }\n    }\n    return 1.0f - (occ * _3596);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3838 = fa_lm.z > 0.5f;\n    bool _3844;\n    if (_3838)\n    {\n        int param = li;\n        _3844 = fa_light_baked(param);\n    }\n    else\n    {\n        _3844 = _3838;\n    }\n    if (_3844)\n    {\n        int param_1 = li;\n        LightSample _5203 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5203;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3866 = fa_light_sample(param_2, param_3);\n    float3 _5210 = _3866.direction;\n    float3 _5205 = _3866.color;\n    float _5212 = _3866.attenuation;\n    float _5207 = _3866.shadow;\n    float _5214 = _3866._distance;\n    int _5215 = _3866.type;\n    bool _3869 = _5215 == 0;\n    if (_3869 && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _5210;\n        float _3880 = fa_shadow_factor(param_4, param_5);\n        _5207 = _3880;\n        _5205 *= _3880;\n    }\n    else\n    {\n        bool _3891 = _5215 != 0;\n        bool _3897;\n        if (_3891)\n        {\n            _3897 = _5212 > 0.0f;\n        }\n        else\n        {\n            _3897 = _3891;\n        }\n        if (_3897)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _5210;\n            float _3909 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _5207 = _3909;\n            _5205 *= _3909;\n        }\n    }\n    bool _3919 = _555_fa_ct_a.x > 0.5f;\n    bool _3925;\n    if (_3919)\n    {\n        _3925 = _5212 > 0.0f;\n    }\n    else\n    {\n        _3925 = _3919;\n    }\n    if (_3925)\n    {\n        float _3932;\n        if (_3869)\n        {\n            _3932 = 1000000000.0f;\n        }\n        else\n        {\n            _3932 = _5214;\n        }\n        int param_10 = li;\n        float3 param_11 = world_pos;\n        float3 param_12 = gn;\n        float3 param_13 = _5210;\n        float param_14 = _3932;\n        float _3950 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14);\n        _5207 *= _3950;\n        _5205 *= _3950;\n    }\n    LightSample _5222 = { _5210, _5205, _5212, _5207, _5214, _5215 };\n    return _5222;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3204 = tdh / at;\n    float _3208 = bdh / ab;\n    float _3220 = ((_3204 * _3204) + (_3208 * _3208)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _3220) * _3220);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _3301 = 1.0f / alpha;\n    return ((2.0f + _3301) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _3301)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _3333 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3412 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _3412) * _3412);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _3333);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _3333));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _3485 = max(dot(L.nc, l), 0.0f);\n        float _3491 = max(dot(L.nc, h), 0.0f);\n        float _3500 = ((_3491 * _3491) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _3500) * _3500)) * (0.5f / max(lerp((2.0f * _3485) * L.coat_ndv, _3485 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _3485)) * _3485).xxx;\n    }\n    return result;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _2605 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _2608 = _2605.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_2608 * _2608, exp2((-9.27999973297119140625f) * ndv)) * _2608) + _2605.y)) + _2605.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_555_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _555_fa_env_horizon.w).xyz;\n    }\n    float _2459 = rough * rough;\n    float _2489 = 0.60000002384185791015625f * _2459;\n    return lerp(lerp(_555_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_555_fa_env_horizon.xyz, _555_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _2459)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _2489, 0.0500000007450580596923828125f + _2489, d.y).xxx), ((_555_fa_env_sky.xyz + _555_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_2459 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3087;\n        if (L.aniso >= 0.0f)\n        {\n            _3087 = L.b;\n        }\n        else\n        {\n            _3087 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3087, v), _3087), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3120 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3120.x) + (L.f90.xxx * _3120.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3175 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3175.x) + _3175.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2647 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2647.x) + _2647.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1295_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2252 = int(_1295_fa_shadow_cfg.x + 0.5f);\n    float _2262 = dot(world - _1295_fa_shadow_eye.xyz, _1295_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2267 = _2252 > 0;\n    bool _2276;\n    if (_2267)\n    {\n        int param = _2252 - 1;\n        _2276 = _2262 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2276 = _2267;\n    }\n    if (_2276)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2283 = _2252 > 1;\n        bool _2290;\n        if (_2283)\n        {\n            _2290 = _2262 > _1295_fa_shadow_split.x;\n        }\n        else\n        {\n            _2290 = _2283;\n        }\n        if (_2290)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _2296 = _2252 > 2;\n        bool _2303;\n        if (_2296)\n        {\n            _2303 = _2262 > _1295_fa_shadow_split.y;\n        }\n        else\n        {\n            _2303 = _2296;\n        }\n        if (_2303)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _2309 = _2252 > 3;\n        bool _2316;\n        if (_2309)\n        {\n            _2316 = _2262 > _1295_fa_shadow_split.z;\n        }\n        else\n        {\n            _2316 = _2309;\n        }\n        if (_2316)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4927 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4927 = -_4927;\n    }\n    float3 _4347 = normalize(_555_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4940 = { fa_world_pos, _4927, fa_world_tangent, fa_uv, fa_vertex_color, _4347, gl_FrontFacing };\n    SurfaceInput param_1 = _4940;\n    Surface _4355 = fa_standard_surface(param_1);\n    float3 _4958 = _4355.albedo;\n    float _4959 = _4355.alpha;\n    float3 _4960 = _4355.normal;\n    float _4961 = _4355.metallic;\n    float _4962 = _4355.roughness;\n    float _4963 = _4355.occlusion;\n    float3 _4964 = _4355.emission;\n    float _4965 = _4355.clearcoat;\n    float _4966 = _4355.clearcoat_roughness;\n    float3 _4967 = _4355.sheen_color;\n    float _4968 = _4355.sheen_roughness;\n    float _4969 = _4355.anisotropy;\n    float _4970 = _4355.anisotropy_rotation;\n    float _4971 = _4355.specular;\n    float _4972 = _4355.ior;\n    float3 _4973 = _4355.specular_color;\n    SurfaceInput _4948 = { fa_world_pos, _4927, fa_world_tangent, fa_uv, fa_vertex_color, _4347, gl_FrontFacing };\n    SurfaceInput param_2 = _4948;\n    Surface param_3 = _4355;\n    surface(param_2, param_3);\n    _4958 = param_3.albedo;\n    _4959 = param_3.alpha;\n    _4960 = param_3.normal;\n    _4961 = param_3.metallic;\n    _4962 = param_3.roughness;\n    _4963 = param_3.occlusion;\n    _4964 = param_3.emission;\n    _4965 = param_3.clearcoat;\n    _4966 = param_3.clearcoat_roughness;\n    _4967 = param_3.sheen_color;\n    _4968 = param_3.sheen_roughness;\n    _4969 = param_3.anisotropy;\n    _4970 = param_3.anisotropy_rotation;\n    _4971 = param_3.specular;\n    _4972 = param_3.ior;\n    _4973 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4927;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4958 = param_6;\n    _4960 = param_7;\n    float3 result;\n    if (_555_fa_emissive.w > 0.5f)\n    {\n        result = _4958;\n    }\n    else\n    {\n        float3 _4394 = normalize(_4960);\n        float _4401 = clamp(_4961, 0.0f, 1.0f);\n        float _4405 = clamp(_4962, 0.0500000007450580596923828125f, 1.0f);\n        float _4409 = _4405 * _4405;\n        float _4413 = _4409 * _4409;\n        float _4418 = max(dot(_4394, _4347), 9.9999997473787516355514526367188e-05f);\n        float3 _4424 = _4958 * (1.0f - _4401);\n        float3 _4431 = lerp(0.039999999105930328369140625f.xxx, _4958, _4401.xxx);\n        float3 f0 = _4431;\n        SurfaceInput _4956 = { fa_world_pos, _4927, fa_world_tangent, fa_uv, fa_vertex_color, _4347, gl_FrontFacing };\n        SurfaceInput param_8 = _4956;\n        Surface _5039 = { _4958, _4959, _4960, _4961, _4962, _4963, _4964, _4965, _4966, _4967, _4968, _4969, _4970, _4971, _4972, _4973 };\n        Surface param_9 = _5039;\n        float3 param_10 = _4394;\n        float3 param_11 = _4347;\n        float param_12 = _4401;\n        float param_13 = _4405;\n        float3 param_14 = _4431;\n        FaLayers _4447 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _4394;\n        float3 lit = (fa_indirect_diffuse(param_15) * _4424) * _4963;\n        if (_4447.on)\n        {\n            lit *= _4447.base_scale;\n        }\n        int _4469 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4469; ln++)\n        {\n            int param_16 = ln;\n            int _4482 = fa_cl_light(param_16);\n            bool _4485 = fa_lm.z > 0.5f;\n            bool _4491;\n            if (_4485)\n            {\n                int param_17 = _4482;\n                _4491 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _4491 = _4485;\n            }\n            if (_4491)\n            {\n                continue;\n            }\n            int param_18 = _4482;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _4927;\n            LightSample _4503 = fa_light_shadowed(param_18, param_19, param_20);\n            float3 _5132 = _4503.direction;\n            float _4511 = max(dot(_4394, _5132), 0.0f);\n            float _4517 = _4503.attenuation * _4503.shadow;\n            float3 _4522 = normalize(_5132 + _4347);\n            float _4527 = max(dot(_4394, _4522), 0.0f);\n            float _4532 = max(dot(_4347, _4522), 0.0f);\n            if (_4447.on)\n            {\n                FaLayers param_21 = _4447;\n                float3 param_22 = _4424;\n                float3 param_23 = f0;\n                float3 param_24 = _4394;\n                float3 param_25 = _4347;\n                float3 param_26 = _5132;\n                float3 param_27 = _4522;\n                float param_28 = _4511;\n                float param_29 = _4418;\n                float param_30 = _4527;\n                float param_31 = _4532;\n                float param_32 = _4409;\n                float param_33 = _4413;\n                int param_34 = _4482;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34) * _4517));\n            }\n            else\n            {\n                float _4580 = ((_4527 * _4527) * (_4413 - 1.0f)) + 1.0f;\n                int param_35 = _4482;\n                lit += (((_4424 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _4532, 5.0f))) * (((_4413 / ((3.1415927410125732421875f * _4580) * _4580)) * (0.5f / max(lerp((2.0f * _4511) * _4418, _4511 + _4418, _4409), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4511))) * fa_light_rgb(param_35)) * (_4511 * _4517));\n            }\n        }\n        if (_4447.on)\n        {\n            FaLayers param_36 = _4447;\n            float3 param_37 = _4394;\n            float3 param_38 = _4347;\n            float3 param_39 = f0;\n            float param_40 = _4405;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40) * _4963);\n        }\n        else\n        {\n            float3 param_41 = _4394;\n            float3 param_42 = _4347;\n            float3 param_43 = f0;\n            float param_44 = _4405;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44) * _4963);\n        }\n        result = lit;\n    }\n    float3 _4673 = result;\n    float3 _4674 = _4673 + _4964;\n    result = _4674;\n    float3 param_45 = _4674;\n    float3 param_46 = fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46);\n    bool _4683 = _555_fa_fog.w > 0.0f;\n    bool _4690;\n    if (!_4683)\n    {\n        _4690 = _555_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4690 = _4683;\n    }\n    if (_4690)\n    {\n        float3 _4699 = fa_world_pos - _555_fa_camera_pos.xyz;\n        float _4705 = dot(_4699, _555_fa_fog_c.xyz);\n        bool _4709 = _555_fa_fog_c.w > 0.5f;\n        float _4710;\n        if (_4709)\n        {\n            _4710 = _4705;\n        }\n        else\n        {\n            _4710 = length(_4699);\n        }\n        float _4722 = _4710 - _555_fa_fog_b.x;\n        if (_4722 > 0.0f)\n        {\n            float _4731 = _555_fa_fog.w * _4722;\n            float tau = _4731 * _4731;\n            if (_555_fa_fog_b.y > 0.0f)\n            {\n                float _4747;\n                if (_4709)\n                {\n                    _4747 = fa_world_pos.y - (_555_fa_fog_c.y * _4705);\n                }\n                else\n                {\n                    _4747 = _555_fa_camera_pos.y;\n                }\n                float _4768 = lerp(_4747, fa_world_pos.y, clamp(_555_fa_fog_b.x / _4710, 0.0f, 1.0f));\n                float _4772 = fa_world_pos.y - _4768;\n                float _4777 = _4768 - _555_fa_fog_b.z;\n                float _4782 = fa_world_pos.y - _555_fa_fog_b.z;\n                bool _4785 = _4777 <= 0.0f;\n                bool _4786 = !_4785;\n                bool _4792;\n                if (_4786)\n                {\n                    _4792 = _555_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4792 = _4785;\n                }\n                float _4793;\n                if (_4792)\n                {\n                    _4793 = _555_fa_fog_b.y;\n                }\n                else\n                {\n                    _4793 = _555_fa_fog_b.y * exp(-min(_555_fa_fog_b.w * _4777, 80.0f));\n                }\n                bool _4820;\n                if (_4786)\n                {\n                    _4820 = _555_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4820 = _4785;\n                }\n                float _4821;\n                if (_4820)\n                {\n                    _4821 = _555_fa_fog_b.y * _4777;\n                }\n                else\n                {\n                    _4821 = (_555_fa_fog_b.y * (1.0f - exp(-min(_555_fa_fog_b.w * _4777, 80.0f)))) / _555_fa_fog_b.w;\n                }\n                bool _4846 = _4782 <= 0.0f;\n                bool _4853;\n                if (!_4846)\n                {\n                    _4853 = _555_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4853 = _4846;\n                }\n                float _4854;\n                if (_4853)\n                {\n                    _4854 = _555_fa_fog_b.y * _4782;\n                }\n                else\n                {\n                    _4854 = (_555_fa_fog_b.y * (1.0f - exp(-min(_555_fa_fog_b.w * _4782, 80.0f)))) / _555_fa_fog_b.w;\n                }\n                float _4881;\n                if (abs(_4772) < 0.001000000047497451305389404296875f)\n                {\n                    _4881 = _4793;\n                }\n                else\n                {\n                    _4881 = (_4854 - _4821) / _4772;\n                }\n                tau += (_4722 * max(_4881, 0.0f));\n            }\n            result = lerp(result, _555_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4959);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_182",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_252",
            "hlsl_register_b_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_555",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1295",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t1);\nByteAddressBuffer fa_vs_extra : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _187_fa_view_proj : packoffset(c0);\n    row_major float4x4 _187_fa_light_vp : packoffset(c4);\n    float4 _187_fa_uv_scale : packoffset(c8);\n    float4 _187_fa_time : packoffset(c9);\n    float4 _187_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _231_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _364_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _222 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_231_fa_joint_rows[_222] * weights[i]);\n        r1 += (_231_fa_joint_rows[_222 + 1] * weights[i]);\n        r2 += (_231_fa_joint_rows[_222 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _129 = cross(model[1].xyz, model[2].xyz);\n    float _133 = (dot(model[0].xyz, _129) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _413 = { mul(float4(position, 1.0f), model).xyz, (((_129 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _133, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _133), texcoord0 * _187_fa_uv_scale.xy, color, position };\n    return _413;\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _67 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f;\n    bool _82;\n    if (!_67)\n    {\n        _82 = asfloat(fa_vs_extra.Load(gl_InstanceIndex * 32 + 12)) < (-1.0f);\n    }\n    else\n    {\n        _82 = _67;\n    }\n    if (_82)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _187_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), _364_fa_base_model);\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstatic const float _2747[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _555_fa_camera_pos : packoffset(c0);\n    float4 _555_fa_ambient : packoffset(c1);\n    float4 _555_fa_base_color : packoffset(c2);\n    float4 _555_fa_emissive : packoffset(c3);\n    float4 _555_fa_model_emissive : packoffset(c4);\n    float4 _555_fa_pbr : packoffset(c5);\n    float4 _555_fa_maps : packoffset(c6);\n    float4 _555_fa_fog : packoffset(c7);\n    float4 _555_fa_fog_b : packoffset(c8);\n    float4 _555_fa_fog_c : packoffset(c9);\n    float4 _555_fa_counts : packoffset(c10);\n    float4 _555_fa_env_sky : packoffset(c11);\n    float4 _555_fa_env_horizon : packoffset(c12);\n    float4 _555_fa_time : packoffset(c13);\n    float4 _555_fa_cl_vpx : packoffset(c14);\n    float4 _555_fa_cl_vpy : packoffset(c15);\n    float4 _555_fa_cl_vpw : packoffset(c16);\n    float4 _555_fa_cl_fwd : packoffset(c17);\n    float4 _555_fa_cl_grid : packoffset(c18);\n    float4 _555_fa_cl_info : packoffset(c19);\n    float4 _555_fa_layers_a : packoffset(c20);\n    float4 _555_fa_layers_b : packoffset(c21);\n    float4 _555_fa_layers_c : packoffset(c22);\n    float4 _555_fa_layers_d : packoffset(c23);\n    float4 _555_fa_ct_a : packoffset(c24);\n    float4 _555_fa_ct_b : packoffset(c25);\n    float4 _555_fa_ct_vpx : packoffset(c26);\n    float4 _555_fa_ct_vpy : packoffset(c27);\n    float4 _555_fa_ct_vpw : packoffset(c28);\n    float4 _555_fa_ct_fwd : packoffset(c29);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1295_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1295_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1295_fa_shadow_info[4] : packoffset(c20);\n    float4 _1295_fa_shadow_split : packoffset(c24);\n    float4 _1295_fa_shadow_cfg : packoffset(c25);\n    float4 _1295_fa_shadow_bias : packoffset(c26);\n    float4 _1295_fa_shadow_eye : packoffset(c27);\n    float4 _1295_fa_shadow_fwd : packoffset(c28);\n    float4 _1295_fa_shadow_lcfg : packoffset(c29);\n};\n\nByteAddressBuffer points : register(t7);\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t10);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _560 = _555_fa_cl_info.x < 0.0f;\n    bool _567;\n    if (!_560)\n    {\n        _567 = _555_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _567 = _560;\n    }\n    bool _575;\n    if (!_567)\n    {\n        _575 = _555_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _575 = _567;\n    }\n    bool _582;\n    if (!_575)\n    {\n        _582 = _555_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _582 = _575;\n    }\n    bool _589;\n    if (!_582)\n    {\n        _589 = _555_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _589 = _582;\n    }\n    if (_589)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _599 = float4(world_pos, 1.0f);\n    float _606 = dot(_555_fa_cl_vpw, _599);\n    if (!(_606 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _628 = float2(dot(_555_fa_cl_vpx, _599), dot(_555_fa_cl_vpy, _599)) / _606.xx;\n    int _632 = int(_555_fa_cl_grid.x);\n    int _636 = int(_555_fa_cl_grid.y);\n    int param = (int(_555_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_555_fa_cl_fwd.xyz, world_pos) + _555_fa_cl_fwd.w, _555_fa_cl_grid.w) / _555_fa_cl_grid.w) * _555_fa_cl_grid.z)), 0, int(_555_fa_cl_info.y) - 1) * _636) + clamp(int(floor(((_628.y * 0.5f) + 0.5f) * _555_fa_cl_grid.y)), 0, _636 - 1)) * _632)) + clamp(int(floor(((_628.x * 0.5f) + 0.5f) * _555_fa_cl_grid.x)), 0, _632 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _712 = fa_cluster_texel(param);\n    return int2(int(_712.x), int(_712.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_555_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3811 = fa_cluster_lookup(param);\n    fa_cl_slot = _3811.x;\n    fa_cl_local = _3811.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4015 = fa_linear_to_srgb(param);\n        c = _4015;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4023 = fa_srgb_to_linear(param_1);\n            c = _4023;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _311;\n    if (i.front_facing)\n    {\n        _311 = i.world_normal;\n    }\n    else\n    {\n        _311 = -i.world_normal;\n    }\n    float3 _335 = normalize(i.world_tangent.xyz - (_311 * dot(_311, i.world_tangent.xyz)));\n    float3 _362 = normalize(((_335 * m.x) + ((cross(_311, _335) * i.world_tangent.w) * m.y)) + (_311 * m.z));\n    float3 _365;\n    if (i.front_facing)\n    {\n        _365 = _362;\n    }\n    else\n    {\n        _365 = -_362;\n    }\n    return _365;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _555_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4054 = fa_tex_fix(param_2, param_3);\n    float4 _5371 = base_t;\n    _5371.x = _4054.x;\n    _5371.y = _4054.y;\n    _5371.z = _4054.z;\n    base_t = _5371;\n    float4 _4068 = (_5371 * _555_fa_base_color) * i.vertex_color;\n    float3 _5225 = i.world_normal;\n    if (_555_fa_maps.z > 0.5f)\n    {\n        float param_4 = _555_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4100 = fa_tex_fix(param_6, param_7);\n        float3 _4103 = (_4100 * 2.0f) - 1.0f.xxx;\n        float2 _4108 = _4103.xy * _555_fa_maps.x;\n        float3 _5379 = _4103;\n        _5379.x = _4108.x;\n        _5379.y = _4108.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5379;\n        _5225 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _555_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4137 = fa_tex_fix(param_12, param_13);\n    float4 _5382 = mrt;\n    _5382.x = _4137.x;\n    _5382.y = _4137.y;\n    _5382.z = _4137.z;\n    mrt = _5382;\n    float4 _4165 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _555_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4165.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4177 = fa_tex_fix(param_16, param_17);\n    float param_18 = _555_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4207 = fa_tex_fix(param_20, param_21);\n    float _5230 = _555_fa_layers_a.x;\n    float _5231 = _555_fa_layers_a.y;\n    float _5234 = _555_fa_layers_a.z;\n    float _5233 = _555_fa_layers_b.w;\n    float _5236 = _555_fa_layers_c.x;\n    if (_555_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_555_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5230 *= _4177.y;\n            _5231 *= _4177.z;\n            _5233 *= _4165.w;\n        }\n        if (_555_fa_layers_c.z > 1.5f)\n        {\n            _5234 *= mrt.x;\n            _5236 *= mrt.w;\n        }\n    }\n    Surface _5255 = { _4068.xyz, _4068.w, _5225, clamp(_555_fa_pbr.x * _4137.z, 0.0f, 1.0f), clamp(_555_fa_pbr.y * _4137.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_555_fa_maps.y * (_4177.x - 1.0f)), _555_fa_emissive.xyz + (_555_fa_model_emissive.xyz * _4207), _5230, _5231, _555_fa_layers_b.xyz, _5233, _5234, _555_fa_layers_a.w, _5236, _555_fa_layers_c.y, _555_fa_layers_d.xyz };\n    return _5255;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * asfloat(points.Load(28)));\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _793 = rect.zw - rect.xy;\n    float2 _797 = _793 * atlas;\n    float2 _801 = ddx * _797;\n    float2 _805 = ddy * _797;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _793), clamp(0.5f * log2(max(max(dot(_801, _801), dot(_805, _805)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _840 = _555_fa_counts.y < 0.5f;\n    bool _847;\n    if (!_840)\n    {\n        _847 = _555_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _847 = _840;\n    }\n    if (_847)\n    {\n        return;\n    }\n    float3 _853 = ddx(world_pos);\n    float3 _856 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _860 = fa_cluster_texel(param);\n    int _864 = int(_860.w);\n    if (_864 < 1)\n    {\n        return;\n    }\n    int _874 = int(_555_fa_counts.y + 0.5f);\n    int param_1 = _874;\n    float4 _878 = fa_light_texel(param_1);\n    float2 _881 = _878.yz;\n    int _885 = int(_878.w);\n    int param_2 = _874 + 1;\n    float4 _890 = fa_light_texel(param_2);\n    float _891 = _890.x;\n    int _897 = int(_555_fa_counts.w + 0.5f) - 1;\n    int _901 = int(_860.z);\n    float3 _1167;\n    for (int k = 0; k < _864; k++)\n    {\n        int _914 = _901 + k;\n        int param_3 = _885 + (_914 >> 2);\n        int _932 = (_874 + 2) + (int(fa_light_texel(param_3)[_914 & 3]) * 7);\n        int param_4 = _932 + 6;\n        float4 _937 = fa_light_texel(param_4);\n        if (((int(_937.w + 0.5f) >> _897) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _932;\n        float4 _952 = fa_light_texel(param_5);\n        int param_6 = _932 + 1;\n        float4 _957 = fa_light_texel(param_6);\n        int param_7 = _932 + 2;\n        float4 _962 = fa_light_texel(param_7);\n        float3 _965 = _952.xyz;\n        float _970 = dot(_965, world_pos) + _952.w;\n        float3 _972 = _957.xyz;\n        float _977 = dot(_972, world_pos) + _957.w;\n        float3 _979 = _962.xyz;\n        float _984 = dot(_979, world_pos) + _962.w;\n        bool _989 = abs(_970) > 0.5f;\n        bool _997;\n        if (!_989)\n        {\n            _997 = abs(_977) > 0.5f;\n        }\n        else\n        {\n            _997 = _989;\n        }\n        bool _1005;\n        if (!_997)\n        {\n            _1005 = abs(_984) > 0.5f;\n        }\n        else\n        {\n            _1005 = _997;\n        }\n        if (_1005)\n        {\n            continue;\n        }\n        float _1020 = clamp(dot(geo_normal, normalize(_979)) * _937.z, 0.0f, 1.0f);\n        if (_1020 <= 0.0f)\n        {\n            continue;\n        }\n        float _1040 = (clamp((0.5f - abs(_984)) * 10.0f, 0.0f, 1.0f) * _1020) * _937.x;\n        float2 _1048 = float2(_970 + 0.5f, 0.5f - _977);\n        float2 _1058 = float2(dot(_965, _853), dot(_972, _853));\n        float2 _1068 = float2(dot(_965, _856), dot(_972, _856));\n        int param_8 = _932 + 5;\n        float4 _1073 = fa_light_texel(param_8);\n        int param_9 = _932 + 3;\n        float4 _1078 = fa_light_texel(param_9);\n        int param_10 = _932 + 4;\n        float4 _1083 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1073.xyz;\n        bool _1093 = _1078.z > _1078.x;\n        if (_1093)\n        {\n            float4 param_11 = _1078;\n            float2 param_12 = _1048;\n            float2 param_13 = _881;\n            float2 param_14 = _1058;\n            float2 param_15 = _1068;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_891 > 0.5f) && (_891 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1119 = fa_dc_to_linear(param_16);\n                float4 _5281 = tx;\n                _5281.x = _1119.x;\n                _5281.y = _1119.y;\n                _5281.z = _1119.z;\n                tx = _5281;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1040 * tex_a) * _1073.w, 0.0f, 1.0f).xxx);\n        if (_1083.z > _1083.x)\n        {\n            float4 param_17 = _1083;\n            float2 param_18 = _1048;\n            float2 param_19 = _881;\n            float2 param_20 = _1058;\n            float2 param_21 = _1068;\n            float4 _1163 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_891 > 1.5f)\n            {\n                float3 param_22 = _1163.xyz;\n                float3 _1173 = fa_dc_to_srgb(param_22);\n                _1167 = _1173;\n            }\n            else\n            {\n                _1167 = _1163.xyz;\n            }\n            float3 _1183 = (_1167 * 2.0f) - 1.0f.xxx;\n            float2 _1188 = _1183.xy * _937.y;\n            float3 _1210 = (normalize(_965) * _1188.x) + (normalize(_972) * _1188.y);\n            float3 _1213 = normalize(normal);\n            normal = normalize(lerp(_1213, normalize((_1213 * max(_1183.z, 0.0500000007450580596923828125f)) + (_1210 - (_1213 * dot(_1213, _1210)))), clamp(_1040 * (_1093 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2673 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _2680 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _2683 = int(_2673);\n    int _2686 = int(_2680);\n    float _2696 = _2680 - float(_2686);\n    int _2751 = (_2683 * 9) + _2686;\n    int _2771 = ((_2683 + 1) * 9) + _2686;\n    return lerp(lerp(_2747[_2751], _2747[_2751 + 1], _2696), lerp(_2747[_2771], _2747[_2771 + 1], _2696), _2673 - float(_2683));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _5148 = false;\n    float _5149 = 1.0f;\n    float _5150 = 1.0f;\n    float _5151 = 1.0f;\n    float _5152 = 0.0f;\n    float _5153 = 0.0f;\n    float _5154 = 0.0f;\n    float _5155 = 0.0f;\n    float _5157 = 1.0f;\n    bool _5158 = false;\n    float3 _5159 = 0.0f.xxx;\n    float _5160 = 1.0f;\n    float _5161 = 1.0f;\n    float _5162 = 1.0f;\n    float _5163 = 0.0f;\n    float _5164 = 0.0f;\n    float3 _5165 = float3(1.0f, 0.0f, 0.0f);\n    float3 _5166 = float3(0.0f, 0.0f, 1.0f);\n    float _5167 = 1.0f;\n    float _5168 = 1.0f;\n    float _2824 = clamp(s.specular, 0.0f, 1.0f);\n    float _2828 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2833 = (_2824 != 1.0f) || (_2828 != 1.5f);\n    bool _2843;\n    if (!_2833)\n    {\n        _2843 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2843 = _2833;\n    }\n    if (_2843)\n    {\n        float _2851 = (_2828 - 1.0f) / (_2828 + 1.0f);\n        f0 = lerp(min((_2851 * _2851).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2824, s.albedo, metallic.xxx);\n        _5149 = lerp(_2824, 1.0f, metallic);\n        _5148 = true;\n    }\n    float _2879 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2879 > 0.0f)\n    {\n        float _2887 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _5152 = _2879;\n        _5153 = _2887;\n        float _2894 = _2887 * _2887;\n        _5154 = _2894;\n        _5155 = _2894 * _2894;\n        float _2906 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _5157 = _2906;\n        _5150 = 1.0f - (_2879 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2906, 0.0f, 1.0f), 5.0f))));\n        _5148 = true;\n    }\n    float3 _2925 = max(s.sheen_color, 0.0f.xxx);\n    float _2934 = max(_2925.x, max(_2925.y, _2925.z));\n    if (_2934 > 0.0f)\n    {\n        float _2942 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _5158 = true;\n        _5159 = _2925;\n        _5160 = _2942;\n        _5161 = _2942 * _2942;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2942;\n        float _2959 = fa_sheen_albedo(param, param_1);\n        _5163 = _2959;\n        _5162 = 1.0f - min(_2934 * _2959, 1.0f);\n        _5148 = true;\n    }\n    _5151 = _5150 * _5162;\n    float _2978 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2978 != 0.0f)\n    {\n        float3 _2993 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2993;\n        if (dot(_2993, _2993) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3006 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3006.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3006.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3006.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3010 = t;\n        float3 _3011 = normalize(_3010);\n        t = _3011;\n        float3 _3036 = normalize((_3011 * cos(s.anisotropy_rotation)) + ((cross(n, _3011) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _5165 = _3036;\n        _5166 = cross(n, _3036);\n        float _3046 = roughness * roughness;\n        float _3052 = lerp(_3046, 1.0f, _2978 * _2978);\n        bool _3054 = _2978 > 0.0f;\n        _5167 = _3054 ? _3052 : _3046;\n        _5168 = _3054 ? _3046 : _3052;\n        _5164 = _2978;\n        _5148 = true;\n    }\n    FaLayers _5190 = { _5148, _5149, _5150, _5151, _5152, _5153, _5154, _5155, i.world_normal, _5157, _5158, _5159, _5160, _5161, _5162, _5163, _5164, _5165, _5166, _5167, _5168 };\n    return _5190;\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_555_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _2430 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _2430;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_555_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _555_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_555_fa_cl_info.x) + int(_555_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _429 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _435 = fa_light_texel(param_1);\n    float _438 = _435.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _444 = _438 < 0.5f;\n    float3 l;\n    if (_444)\n    {\n        l = normalize(_429.xyz);\n    }\n    else\n    {\n        float3 _456 = _429.xyz - world_pos;\n        float _458 = length(_456);\n        dist = _458;\n        l = _456 / max(_458, 9.9999997473787516355514526367188e-05f).xxx;\n        float _473 = _458 / max(_429.w, 0.001000000047497451305389404296875f);\n        float _479 = clamp(1.0f - (_473 * _473), 0.0f, 1.0f);\n        atten = _479 * _479;\n        if (_438 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _493 = fa_light_texel(param_2);\n            float _503 = _493.w;\n            int param_3 = (li * 4) + 3;\n            float4 _509 = fa_light_texel(param_3);\n            float _510 = _509.x;\n            float cos_inner = _510;\n            if (_510 > 1.5f)\n            {\n                cos_inner = lerp(_503, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_503, cos_inner, dot(-l, normalize(_493.xyz)));\n        }\n    }\n    int _541;\n    if (_444)\n    {\n        _541 = 0;\n    }\n    else\n    {\n        _541 = (_438 > 1.5f) ? 2 : 1;\n    }\n    LightSample _5147 = { l, _435.xyz * atten, atten, 1.0f, dist, _541 };\n    return _5147;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1285;\n    if (i == 0)\n    {\n        _1285 = _1295_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1301;\n        if (i == 1)\n        {\n            _1301 = _1295_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1309;\n            if (i == 2)\n            {\n                _1309 = _1295_fa_shadow_split.z;\n            }\n            else\n            {\n                _1309 = _1295_fa_shadow_split.w;\n            }\n            _1301 = _1309;\n        }\n        _1285 = _1301;\n    }\n    return _1285;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1342 = fa_shadow_depth(param, param_1);\n    float _1346;\n    if (conv.x < 0.5f)\n    {\n        _1346 = _1342;\n    }\n    else\n    {\n        _1346 = (conv.y * conv.z) / (conv.z - (_1342 * (conv.z - conv.y)));\n    }\n    return _1346;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1273 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1273), sin(_1273)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1392 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _1406 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1392;\n            float2 _1425 = fa_shadow_vogel(param_3, param_4, param_5) * _1406;\n            float2 param_6 = uv + (_1425 * _1295_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1437 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1437 < (zr - (length(_1425) * plane)))\n            {\n                sum += _1437;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1481 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1481; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1481;\n        float param_11 = _1392;\n        float2 _1500 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1500 * _1295_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1500) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1481);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1542 = max(_1295_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1547 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1553 = sqrt(1.0f - (_1547 * _1547));\n    float _1560 = min(_1553 / max(_1547, 0.20000000298023223876953125f), 4.0f);\n    float _1565;\n    if (_1295_fa_shadow_bias.y > 0.0f)\n    {\n        _1565 = _1295_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1565 = 1.5f * _1295_fa_shadow_info[ci].x;\n    }\n    float4 _1590 = mul(float4(world + (n * (_1565 * _1553)), 1.0f), _1295_fa_shadow_mat[ci]);\n    float _1597 = _1590.x;\n    bool _1600 = _1597 < _1295_fa_shadow_rect[ci].x;\n    bool _1609;\n    if (!_1600)\n    {\n        _1609 = _1597 > _1295_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1609 = _1600;\n    }\n    bool _1618;\n    if (!_1609)\n    {\n        _1618 = _1590.y < _1295_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1618 = _1609;\n    }\n    bool _1627;\n    if (!_1618)\n    {\n        _1627 = _1590.y > _1295_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1627 = _1618;\n    }\n    bool _1634;\n    if (!_1627)\n    {\n        _1634 = _1590.z > 1.0f;\n    }\n    else\n    {\n        _1634 = _1627;\n    }\n    if (_1634)\n    {\n        return -1.0f;\n    }\n    float _1643;\n    if (_1295_fa_shadow_bias.x > 0.0f)\n    {\n        _1643 = _1295_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1643 = 1.5f * _1295_fa_shadow_info[ci].x;\n    }\n    float2 param = _1590.xy;\n    float4 param_1 = _1295_fa_shadow_rect[ci];\n    float param_2 = _1590.z - ((_1643 * (1.0f + (0.5f * _1560))) / _1542);\n    float param_3 = _1295_fa_shadow_info[ci].x;\n    float param_4 = _1542;\n    float param_5 = _1542 * 0.25f;\n    float param_6 = ((_1295_fa_shadow_info[ci].x * min(_1560, 3.0f)) * 0.5f) / _1542;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_1295_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _1295_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_555_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2070 = int(_1295_fa_shadow_cfg.x + 0.5f);\n    if (_2070 < 1)\n    {\n        return 1.0f;\n    }\n    float _2085 = dot(world - _1295_fa_shadow_eye.xyz, _1295_fa_shadow_fwd.xyz);\n    int param = _2070 - 1;\n    if (_2085 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2097 = _2070 > 1;\n    bool _2104;\n    if (_2097)\n    {\n        _2104 = _2085 > _1295_fa_shadow_split.x;\n    }\n    else\n    {\n        _2104 = _2097;\n    }\n    if (_2104)\n    {\n        ci = 1;\n    }\n    bool _2108 = _2070 > 2;\n    bool _2115;\n    if (_2108)\n    {\n        _2115 = _2085 > _1295_fa_shadow_split.y;\n    }\n    else\n    {\n        _2115 = _2108;\n    }\n    if (_2115)\n    {\n        ci = 2;\n    }\n    bool _2119 = _2070 > 3;\n    bool _2126;\n    if (_2119)\n    {\n        _2126 = _2085 > _1295_fa_shadow_split.z;\n    }\n    else\n    {\n        _2126 = _2119;\n    }\n    if (_2126)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2070)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2152 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2152;\n        if (_2152 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1295_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2177;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2177 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2177 = _1295_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2196 = _1295_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2177, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2207 = clamp((_2085 - (fa_shadow_split_at(param_7) - _2196)) / _2196, 0.0f, 1.0f);\n        if (_2207 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2070)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2228 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2228;\n                if (_2228 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2207);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1701 = _555_fa_pbr.z < 0.5f;\n    bool _1709;\n    if (!_1701)\n    {\n        _1709 = _1295_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1709 = _1701;\n    }\n    if (_1709)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1295_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1722 = fa_light_texel(param);\n    float _1723 = _1722.x;\n    if (_1723 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1732 = int(_1723 + 0.5f);\n    int param_1 = _1732;\n    float4 _1736 = fa_light_texel(param_1);\n    int param_2 = _1732 + 1;\n    float4 _1741 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1744 = _1736.y;\n    if (_1744 > 0.0f)\n    {\n        float _1761 = 1.0f - smoothstep(0.75f * _1744, _1744, length(world - _1295_fa_shadow_eye.xyz));\n        fade = _1761;\n        if (_1761 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1736.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1780 = world - fa_light_texel(param_3).xyz;\n        float3 _1783 = abs(_1780);\n        float _1785 = _1783.x;\n        float _1787 = _1783.y;\n        bool _1788 = _1785 >= _1787;\n        bool _1796;\n        if (_1788)\n        {\n            _1796 = _1785 >= _1783.z;\n        }\n        else\n        {\n            _1796 = _1788;\n        }\n        int _1797;\n        if (_1796)\n        {\n            _1797 = (_1780.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1810;\n            if (_1787 >= _1783.z)\n            {\n                _1810 = (_1780.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1810 = (_1780.z > 0.0f) ? 4 : 5;\n            }\n            _1797 = _1810;\n        }\n        face = _1797;\n    }\n    int _1829 = (_1732 + 2) + (face * 6);\n    int param_4 = _1829;\n    int param_5 = _1829 + 1;\n    int param_6 = _1829 + 3;\n    float4 _1843 = fa_light_texel(param_6);\n    int param_7 = _1829 + 4;\n    float4 _1848 = fa_light_texel(param_7);\n    int param_8 = _1829 + 5;\n    float4 _1853 = fa_light_texel(param_8);\n    float _1865 = _1853.x * max(dot(_1843, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1870 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1893 = clamp(dot(n, _1843.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1916 = min(sqrt(1.0f - (_1893 * _1893)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1843, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1919 = _1741.y;\n    float _1921;\n    if (_1919 > 0.0f)\n    {\n        _1921 = _1919;\n    }\n    else\n    {\n        _1921 = 1.5f * _1865;\n    }\n    float4 _1941 = float4(world + (n * (_1921 * sqrt(1.0f - (_1870 * _1870)))), 1.0f);\n    float _1945 = dot(_1843, _1941);\n    float _1948 = _1853.y;\n    if (_1945 < _1948)\n    {\n        return 1.0f;\n    }\n    float2 _1963 = float2(dot(fa_light_texel(param_4), _1941), dot(fa_light_texel(param_5), _1941)) / _1945.xx;\n    float _1965 = _1963.x;\n    bool _1968 = _1965 < _1848.x;\n    bool _1977;\n    if (!_1968)\n    {\n        _1977 = _1965 > _1848.z;\n    }\n    else\n    {\n        _1977 = _1968;\n    }\n    bool _1986;\n    if (!_1977)\n    {\n        _1986 = _1963.y < _1848.y;\n    }\n    else\n    {\n        _1986 = _1977;\n    }\n    bool _1995;\n    if (!_1986)\n    {\n        _1995 = _1963.y > _1848.w;\n    }\n    else\n    {\n        _1995 = _1986;\n    }\n    if (_1995)\n    {\n        return 1.0f;\n    }\n    float _2001 = _1741.x;\n    float _2003;\n    if (_2001 > 0.0f)\n    {\n        _2003 = _2001;\n    }\n    else\n    {\n        _2003 = 1.5f * _1865;\n    }\n    float2 param_10 = _1963;\n    float4 param_11 = _1848;\n    float param_12 = _1945 - (_2003 * (1.0f + (0.5f * _1916)));\n    float param_13 = _1865;\n    float param_14 = 1.0f;\n    float param_15 = _1853.z * 0.25f;\n    float param_16 = (_1865 * min(_1916, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1948, _1853.z);\n    int param_18 = int(_1736.z + 0.5f);\n    float param_19 = _1736.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3553 = _555_fa_ct_a.x < 0.5f;\n    bool _3560;\n    if (!_3553)\n    {\n        _3560 = _1295_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3560 = _3553;\n    }\n    if (_3560)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1295_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3573 = fa_light_texel(param);\n    float _3574 = _3573.y;\n    float len = _3574;\n    if (_3574 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3586 = length(world - _555_fa_camera_pos.xyz);\n    float _3596 = 1.0f - smoothstep(0.5f * _555_fa_ct_b.x, _555_fa_ct_b.x, _3586);\n    if (_3596 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3602 = len;\n    float _3605 = min(_3602, 0.89999997615814208984375f * dist);\n    len = _3605;\n    float _3610 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3586);\n    float _3615 = _3610 + (0.5f * _3605);\n    float3 _3621 = world + (gn * _3610);\n    float _3623 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3687;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3638 = (float(k) + _3623) * 0.083333335816860198974609375f;\n        float3 _3646 = _3621 + (l * (_3638 * len));\n        float4 _3652 = float4(_3646, 1.0f);\n        float _3658 = dot(_555_fa_ct_vpw, _3652);\n        if (_3658 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3678 = float2(dot(_555_fa_ct_vpx, _3652), dot(_555_fa_ct_vpy, _3652)) / _3658.xx;\n        float _3682 = _3678.x * 0.5f;\n        float _3683 = _3682 + 0.5f;\n        if (_555_fa_ct_a.y > 0.5f)\n        {\n            _3687 = (_3678.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3687 = 0.5f - (_3678.y * 0.5f);\n        }\n        bool _3703 = _3683 < 0.0f;\n        bool _3710;\n        if (!_3703)\n        {\n            _3710 = _3683 >= 1.0f;\n        }\n        else\n        {\n            _3710 = _3703;\n        }\n        bool _3717;\n        if (!_3710)\n        {\n            _3717 = _3687 < 0.0f;\n        }\n        else\n        {\n            _3717 = _3710;\n        }\n        bool _3724;\n        if (!_3717)\n        {\n            _3724 = _3687 >= 1.0f;\n        }\n        else\n        {\n            _3724 = _3717;\n        }\n        if (_3724)\n        {\n            break;\n        }\n        float4 _3743 = fa_screen_tex.Load(int3(int2(float2(_3683, _3687) * _555_fa_ct_a.zw), 0));\n        if (_3743.w < 0.5f)\n        {\n            continue;\n        }\n        float _3762 = (dot(_555_fa_ct_fwd.xyz, _3646) + _555_fa_ct_fwd.w) - _3743.x;\n        if ((_3762 > _3610) && (_3762 < _3615))\n        {\n            occ = max(occ, (1.0f - (_3638 * _3638)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3683, 0.5f - _3682), min(_3687, 1.0f - _3687))));\n        }\n    }\n    return 1.0f - (occ * _3596);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3838 = fa_lm.z > 0.5f;\n    bool _3844;\n    if (_3838)\n    {\n        int param = li;\n        _3844 = fa_light_baked(param);\n    }\n    else\n    {\n        _3844 = _3838;\n    }\n    if (_3844)\n    {\n        int param_1 = li;\n        LightSample _5203 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5203;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3866 = fa_light_sample(param_2, param_3);\n    float3 _5210 = _3866.direction;\n    float3 _5205 = _3866.color;\n    float _5212 = _3866.attenuation;\n    float _5207 = _3866.shadow;\n    float _5214 = _3866._distance;\n    int _5215 = _3866.type;\n    bool _3869 = _5215 == 0;\n    if (_3869 && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _5210;\n        float _3880 = fa_shadow_factor(param_4, param_5);\n        _5207 = _3880;\n        _5205 *= _3880;\n    }\n    else\n    {\n        bool _3891 = _5215 != 0;\n        bool _3897;\n        if (_3891)\n        {\n            _3897 = _5212 > 0.0f;\n        }\n        else\n        {\n            _3897 = _3891;\n        }\n        if (_3897)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _5210;\n            float _3909 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _5207 = _3909;\n            _5205 *= _3909;\n        }\n    }\n    bool _3919 = _555_fa_ct_a.x > 0.5f;\n    bool _3925;\n    if (_3919)\n    {\n        _3925 = _5212 > 0.0f;\n    }\n    else\n    {\n        _3925 = _3919;\n    }\n    if (_3925)\n    {\n        float _3932;\n        if (_3869)\n        {\n            _3932 = 1000000000.0f;\n        }\n        else\n        {\n            _3932 = _5214;\n        }\n        int param_10 = li;\n        float3 param_11 = world_pos;\n        float3 param_12 = gn;\n        float3 param_13 = _5210;\n        float param_14 = _3932;\n        float _3950 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14);\n        _5207 *= _3950;\n        _5205 *= _3950;\n    }\n    LightSample _5222 = { _5210, _5205, _5212, _5207, _5214, _5215 };\n    return _5222;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3204 = tdh / at;\n    float _3208 = bdh / ab;\n    float _3220 = ((_3204 * _3204) + (_3208 * _3208)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _3220) * _3220);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _3301 = 1.0f / alpha;\n    return ((2.0f + _3301) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _3301)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _3333 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3412 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _3412) * _3412);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _3333);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _3333));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _3485 = max(dot(L.nc, l), 0.0f);\n        float _3491 = max(dot(L.nc, h), 0.0f);\n        float _3500 = ((_3491 * _3491) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _3500) * _3500)) * (0.5f / max(lerp((2.0f * _3485) * L.coat_ndv, _3485 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _3485)) * _3485).xxx;\n    }\n    return result;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _2605 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _2608 = _2605.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_2608 * _2608, exp2((-9.27999973297119140625f) * ndv)) * _2608) + _2605.y)) + _2605.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_555_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _555_fa_env_horizon.w).xyz;\n    }\n    float _2459 = rough * rough;\n    float _2489 = 0.60000002384185791015625f * _2459;\n    return lerp(lerp(_555_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_555_fa_env_horizon.xyz, _555_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _2459)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _2489, 0.0500000007450580596923828125f + _2489, d.y).xxx), ((_555_fa_env_sky.xyz + _555_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_2459 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3087;\n        if (L.aniso >= 0.0f)\n        {\n            _3087 = L.b;\n        }\n        else\n        {\n            _3087 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3087, v), _3087), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3120 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3120.x) + (L.f90.xxx * _3120.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3175 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3175.x) + _3175.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2647 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2647.x) + _2647.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1295_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2252 = int(_1295_fa_shadow_cfg.x + 0.5f);\n    float _2262 = dot(world - _1295_fa_shadow_eye.xyz, _1295_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2267 = _2252 > 0;\n    bool _2276;\n    if (_2267)\n    {\n        int param = _2252 - 1;\n        _2276 = _2262 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2276 = _2267;\n    }\n    if (_2276)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2283 = _2252 > 1;\n        bool _2290;\n        if (_2283)\n        {\n            _2290 = _2262 > _1295_fa_shadow_split.x;\n        }\n        else\n        {\n            _2290 = _2283;\n        }\n        if (_2290)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _2296 = _2252 > 2;\n        bool _2303;\n        if (_2296)\n        {\n            _2303 = _2262 > _1295_fa_shadow_split.y;\n        }\n        else\n        {\n            _2303 = _2296;\n        }\n        if (_2303)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _2309 = _2252 > 3;\n        bool _2316;\n        if (_2309)\n        {\n            _2316 = _2262 > _1295_fa_shadow_split.z;\n        }\n        else\n        {\n            _2316 = _2309;\n        }\n        if (_2316)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4927 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4927 = -_4927;\n    }\n    float3 _4347 = normalize(_555_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4940 = { fa_world_pos, _4927, fa_world_tangent, fa_uv, fa_vertex_color, _4347, gl_FrontFacing };\n    SurfaceInput param_1 = _4940;\n    Surface _4355 = fa_standard_surface(param_1);\n    float3 _4958 = _4355.albedo;\n    float _4959 = _4355.alpha;\n    float3 _4960 = _4355.normal;\n    float _4961 = _4355.metallic;\n    float _4962 = _4355.roughness;\n    float _4963 = _4355.occlusion;\n    float3 _4964 = _4355.emission;\n    float _4965 = _4355.clearcoat;\n    float _4966 = _4355.clearcoat_roughness;\n    float3 _4967 = _4355.sheen_color;\n    float _4968 = _4355.sheen_roughness;\n    float _4969 = _4355.anisotropy;\n    float _4970 = _4355.anisotropy_rotation;\n    float _4971 = _4355.specular;\n    float _4972 = _4355.ior;\n    float3 _4973 = _4355.specular_color;\n    SurfaceInput _4948 = { fa_world_pos, _4927, fa_world_tangent, fa_uv, fa_vertex_color, _4347, gl_FrontFacing };\n    SurfaceInput param_2 = _4948;\n    Surface param_3 = _4355;\n    surface(param_2, param_3);\n    _4958 = param_3.albedo;\n    _4959 = param_3.alpha;\n    _4960 = param_3.normal;\n    _4961 = param_3.metallic;\n    _4962 = param_3.roughness;\n    _4963 = param_3.occlusion;\n    _4964 = param_3.emission;\n    _4965 = param_3.clearcoat;\n    _4966 = param_3.clearcoat_roughness;\n    _4967 = param_3.sheen_color;\n    _4968 = param_3.sheen_roughness;\n    _4969 = param_3.anisotropy;\n    _4970 = param_3.anisotropy_rotation;\n    _4971 = param_3.specular;\n    _4972 = param_3.ior;\n    _4973 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4927;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4958 = param_6;\n    _4960 = param_7;\n    float3 result;\n    if (_555_fa_emissive.w > 0.5f)\n    {\n        result = _4958;\n    }\n    else\n    {\n        float3 _4394 = normalize(_4960);\n        float _4401 = clamp(_4961, 0.0f, 1.0f);\n        float _4405 = clamp(_4962, 0.0500000007450580596923828125f, 1.0f);\n        float _4409 = _4405 * _4405;\n        float _4413 = _4409 * _4409;\n        float _4418 = max(dot(_4394, _4347), 9.9999997473787516355514526367188e-05f);\n        float3 _4424 = _4958 * (1.0f - _4401);\n        float3 _4431 = lerp(0.039999999105930328369140625f.xxx, _4958, _4401.xxx);\n        float3 f0 = _4431;\n        SurfaceInput _4956 = { fa_world_pos, _4927, fa_world_tangent, fa_uv, fa_vertex_color, _4347, gl_FrontFacing };\n        SurfaceInput param_8 = _4956;\n        Surface _5039 = { _4958, _4959, _4960, _4961, _4962, _4963, _4964, _4965, _4966, _4967, _4968, _4969, _4970, _4971, _4972, _4973 };\n        Surface param_9 = _5039;\n        float3 param_10 = _4394;\n        float3 param_11 = _4347;\n        float param_12 = _4401;\n        float param_13 = _4405;\n        float3 param_14 = _4431;\n        FaLayers _4447 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _4394;\n        float3 lit = (fa_indirect_diffuse(param_15) * _4424) * _4963;\n        if (_4447.on)\n        {\n            lit *= _4447.base_scale;\n        }\n        int _4469 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4469; ln++)\n        {\n            int param_16 = ln;\n            int _4482 = fa_cl_light(param_16);\n            bool _4485 = fa_lm.z > 0.5f;\n            bool _4491;\n            if (_4485)\n            {\n                int param_17 = _4482;\n                _4491 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _4491 = _4485;\n            }\n            if (_4491)\n            {\n                continue;\n            }\n            int param_18 = _4482;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _4927;\n            LightSample _4503 = fa_light_shadowed(param_18, param_19, param_20);\n            float3 _5132 = _4503.direction;\n            float _4511 = max(dot(_4394, _5132), 0.0f);\n            float _4517 = _4503.attenuation * _4503.shadow;\n            float3 _4522 = normalize(_5132 + _4347);\n            float _4527 = max(dot(_4394, _4522), 0.0f);\n            float _4532 = max(dot(_4347, _4522), 0.0f);\n            if (_4447.on)\n            {\n                FaLayers param_21 = _4447;\n                float3 param_22 = _4424;\n                float3 param_23 = f0;\n                float3 param_24 = _4394;\n                float3 param_25 = _4347;\n                float3 param_26 = _5132;\n                float3 param_27 = _4522;\n                float param_28 = _4511;\n                float param_29 = _4418;\n                float param_30 = _4527;\n                float param_31 = _4532;\n                float param_32 = _4409;\n                float param_33 = _4413;\n                int param_34 = _4482;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34) * _4517));\n            }\n            else\n            {\n                float _4580 = ((_4527 * _4527) * (_4413 - 1.0f)) + 1.0f;\n                int param_35 = _4482;\n                lit += (((_4424 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _4532, 5.0f))) * (((_4413 / ((3.1415927410125732421875f * _4580) * _4580)) * (0.5f / max(lerp((2.0f * _4511) * _4418, _4511 + _4418, _4409), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4511))) * fa_light_rgb(param_35)) * (_4511 * _4517));\n            }\n        }\n        if (_4447.on)\n        {\n            FaLayers param_36 = _4447;\n            float3 param_37 = _4394;\n            float3 param_38 = _4347;\n            float3 param_39 = f0;\n            float param_40 = _4405;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40) * _4963);\n        }\n        else\n        {\n            float3 param_41 = _4394;\n            float3 param_42 = _4347;\n            float3 param_43 = f0;\n            float param_44 = _4405;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44) * _4963);\n        }\n        result = lit;\n    }\n    float3 _4673 = result;\n    float3 _4674 = _4673 + _4964;\n    result = _4674;\n    float3 param_45 = _4674;\n    float3 param_46 = fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46);\n    bool _4683 = _555_fa_fog.w > 0.0f;\n    bool _4690;\n    if (!_4683)\n    {\n        _4690 = _555_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4690 = _4683;\n    }\n    if (_4690)\n    {\n        float3 _4699 = fa_world_pos - _555_fa_camera_pos.xyz;\n        float _4705 = dot(_4699, _555_fa_fog_c.xyz);\n        bool _4709 = _555_fa_fog_c.w > 0.5f;\n        float _4710;\n        if (_4709)\n        {\n            _4710 = _4705;\n        }\n        else\n        {\n            _4710 = length(_4699);\n        }\n        float _4722 = _4710 - _555_fa_fog_b.x;\n        if (_4722 > 0.0f)\n        {\n            float _4731 = _555_fa_fog.w * _4722;\n            float tau = _4731 * _4731;\n            if (_555_fa_fog_b.y > 0.0f)\n            {\n                float _4747;\n                if (_4709)\n                {\n                    _4747 = fa_world_pos.y - (_555_fa_fog_c.y * _4705);\n                }\n                else\n                {\n                    _4747 = _555_fa_camera_pos.y;\n                }\n                float _4768 = lerp(_4747, fa_world_pos.y, clamp(_555_fa_fog_b.x / _4710, 0.0f, 1.0f));\n                float _4772 = fa_world_pos.y - _4768;\n                float _4777 = _4768 - _555_fa_fog_b.z;\n                float _4782 = fa_world_pos.y - _555_fa_fog_b.z;\n                bool _4785 = _4777 <= 0.0f;\n                bool _4786 = !_4785;\n                bool _4792;\n                if (_4786)\n                {\n                    _4792 = _555_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4792 = _4785;\n                }\n                float _4793;\n                if (_4792)\n                {\n                    _4793 = _555_fa_fog_b.y;\n                }\n                else\n                {\n                    _4793 = _555_fa_fog_b.y * exp(-min(_555_fa_fog_b.w * _4777, 80.0f));\n                }\n                bool _4820;\n                if (_4786)\n                {\n                    _4820 = _555_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4820 = _4785;\n                }\n                float _4821;\n                if (_4820)\n                {\n                    _4821 = _555_fa_fog_b.y * _4777;\n                }\n                else\n                {\n                    _4821 = (_555_fa_fog_b.y * (1.0f - exp(-min(_555_fa_fog_b.w * _4777, 80.0f)))) / _555_fa_fog_b.w;\n                }\n                bool _4846 = _4782 <= 0.0f;\n                bool _4853;\n                if (!_4846)\n                {\n                    _4853 = _555_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4853 = _4846;\n                }\n                float _4854;\n                if (_4853)\n                {\n                    _4854 = _555_fa_fog_b.y * _4782;\n                }\n                else\n                {\n                    _4854 = (_555_fa_fog_b.y * (1.0f - exp(-min(_555_fa_fog_b.w * _4782, 80.0f)))) / _555_fa_fog_b.w;\n                }\n                float _4881;\n                if (abs(_4772) < 0.001000000047497451305389404296875f)\n                {\n                    _4881 = _4793;\n                }\n                else\n                {\n                    _4881 = (_4854 - _4821) / _4772;\n                }\n                tau += (_4722 * max(_4881, 0.0f));\n            }\n            result = lerp(result, _555_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4959);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_187",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_231",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_364",
            "hlsl_register_b_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_555",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1295",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t1);\nByteAddressBuffer fa_vs_extra : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _182_fa_view_proj : packoffset(c0);\n    row_major float4x4 _182_fa_light_vp : packoffset(c4);\n    float4 _182_fa_uv_scale : packoffset(c8);\n    float4 _182_fa_time : packoffset(c9);\n    float4 _182_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _286_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _124 = cross(model[1].xyz, model[2].xyz);\n    float _128 = (dot(model[0].xyz, _124) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _325 = { mul(float4(position, 1.0f), model).xyz, (((_124 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _128, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _128), texcoord0 * _182_fa_uv_scale.xy, color, position };\n    return _325;\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _62 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f;\n    bool _77;\n    if (!_62)\n    {\n        _77 = asfloat(fa_vs_extra.Load(gl_InstanceIndex * 32 + 12)) < (-1.0f);\n    }\n    else\n    {\n        _77 = _62;\n    }\n    if (_77)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _224 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_224, _182_fa_light_vp).z;\n    fa_pre_r0 = float3(_182_fa_light_vp[0].x, _182_fa_light_vp[1].x, _182_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_182_fa_light_vp[0].y, _182_fa_light_vp[1].y, _182_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_182_fa_light_vp[0].z, _182_fa_light_vp[1].z, _182_fa_light_vp[2].z);\n    gl_Position = mul(_224, _182_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = _286_fa_base_model;\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer points : register(t5);\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _231_fa_camera_pos : packoffset(c0);\n    float4 _231_fa_ambient : packoffset(c1);\n    float4 _231_fa_base_color : packoffset(c2);\n    float4 _231_fa_emissive : packoffset(c3);\n    float4 _231_fa_model_emissive : packoffset(c4);\n    float4 _231_fa_pbr : packoffset(c5);\n    float4 _231_fa_maps : packoffset(c6);\n    float4 _231_fa_fog : packoffset(c7);\n    float4 _231_fa_fog_b : packoffset(c8);\n    float4 _231_fa_fog_c : packoffset(c9);\n    float4 _231_fa_counts : packoffset(c10);\n    float4 _231_fa_env_sky : packoffset(c11);\n    float4 _231_fa_env_horizon : packoffset(c12);\n    float4 _231_fa_time : packoffset(c13);\n    float4 _231_fa_cl_vpx : packoffset(c14);\n    float4 _231_fa_cl_vpy : packoffset(c15);\n    float4 _231_fa_cl_vpw : packoffset(c16);\n    float4 _231_fa_cl_fwd : packoffset(c17);\n    float4 _231_fa_cl_grid : packoffset(c18);\n    float4 _231_fa_cl_info : packoffset(c19);\n    float4 _231_fa_layers_a : packoffset(c20);\n    float4 _231_fa_layers_b : packoffset(c21);\n    float4 _231_fa_layers_c : packoffset(c22);\n    float4 _231_fa_layers_d : packoffset(c23);\n    float4 _231_fa_ct_a : packoffset(c24);\n    float4 _231_fa_ct_b : packoffset(c25);\n    float4 _231_fa_ct_vpx : packoffset(c26);\n    float4 _231_fa_ct_vpy : packoffset(c27);\n    float4 _231_fa_ct_vpw : packoffset(c28);\n    float4 _231_fa_ct_fwd : packoffset(c29);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _231_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _754 = base_t;\n    _754.x = _242.x;\n    _754.y = _242.y;\n    _754.z = _242.z;\n    base_t = _754;\n    float4 _257 = (_754 * _231_fa_base_color) * i.vertex_color;\n    float3 _717 = i.world_normal;\n    if (_231_fa_maps.z > 0.5f)\n    {\n        float param_4 = _231_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _290 = fa_tex_fix(param_6, param_7);\n        float3 _294 = (_290 * 2.0f) - 1.0f.xxx;\n        float2 _299 = _294.xy * _231_fa_maps.x;\n        float3 _762 = _294;\n        _762.x = _299.x;\n        _762.y = _299.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _762;\n        _717 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _231_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _328 = fa_tex_fix(param_12, param_13);\n    float4 _765 = mrt;\n    _765.x = _328.x;\n    _765.y = _328.y;\n    _765.z = _328.z;\n    mrt = _765;\n    float4 _358 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _231_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = _231_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _400 = fa_tex_fix(param_20, param_21);\n    float _722 = _231_fa_layers_a.x;\n    float _723 = _231_fa_layers_a.y;\n    float _726 = _231_fa_layers_a.z;\n    float _725 = _231_fa_layers_b.w;\n    float _728 = _231_fa_layers_c.x;\n    if (_231_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_231_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _722 *= _370.y;\n            _723 *= _370.z;\n            _725 *= _358.w;\n        }\n        if (_231_fa_layers_c.z > 1.5f)\n        {\n            _726 *= mrt.x;\n            _728 *= mrt.w;\n        }\n    }\n    Surface _747 = { _257.xyz, _257.w, _717, clamp(_231_fa_pbr.x * _328.z, 0.0f, 1.0f), clamp(_231_fa_pbr.y * _328.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_231_fa_maps.y * (_370.x - 1.0f)), _231_fa_emissive.xyz + (_231_fa_model_emissive.xyz * _400), _722, _723, _231_fa_layers_b.xyz, _725, _726, _231_fa_layers_a.w, _728, _231_fa_layers_c.y, _231_fa_layers_d.xyz };\n    return _747;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * asfloat(points.Load(28)));\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _628 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _628 = -_628;\n    }\n    float3 _534 = normalize(_231_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _641 = { fa_world_pos, _628, fa_world_tangent, fa_uv, fa_vertex_color, _534, gl_FrontFacing };\n    SurfaceInput param = _641;\n    SurfaceInput _649 = { fa_world_pos, _628, fa_world_tangent, fa_uv, fa_vertex_color, _534, gl_FrontFacing };\n    SurfaceInput param_1 = _649;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _549 = normalize(param_2.normal);\n    float3 _564 = normalize(float3(dot(fa_pre_r0, _549), dot(fa_pre_r1, _549), dot(fa_pre_r2, _549)));\n    float _576 = _564.z;\n    float2 e = _564.xy / ((abs(_564.x) + abs(_564.y)) + abs(_576)).xx;\n    if (_576 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_182",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_286",
            "hlsl_register_b_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_231",
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
          },
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 5
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t1);\nByteAddressBuffer fa_vs_extra : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _187_fa_view_proj : packoffset(c0);\n    row_major float4x4 _187_fa_light_vp : packoffset(c4);\n    float4 _187_fa_uv_scale : packoffset(c8);\n    float4 _187_fa_time : packoffset(c9);\n    float4 _187_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _231_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _398_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _222 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_231_fa_joint_rows[_222] * weights[i]);\n        r1 += (_231_fa_joint_rows[_222 + 1] * weights[i]);\n        r2 += (_231_fa_joint_rows[_222 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _129 = cross(model[1].xyz, model[2].xyz);\n    float _133 = (dot(model[0].xyz, _129) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _445 = { mul(float4(position, 1.0f), model).xyz, (((_129 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _133, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _133), texcoord0 * _187_fa_uv_scale.xy, color, position };\n    return _445;\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _67 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f;\n    bool _82;\n    if (!_67)\n    {\n        _82 = asfloat(fa_vs_extra.Load(gl_InstanceIndex * 32 + 12)) < (-1.0f);\n    }\n    else\n    {\n        _82 = _67;\n    }\n    if (_82)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _336 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_336, _187_fa_light_vp).z;\n    fa_pre_r0 = float3(_187_fa_light_vp[0].x, _187_fa_light_vp[1].x, _187_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_187_fa_light_vp[0].y, _187_fa_light_vp[1].y, _187_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_187_fa_light_vp[0].z, _187_fa_light_vp[1].z, _187_fa_light_vp[2].z);\n    gl_Position = mul(_336, _187_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), _398_fa_base_model);\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer points : register(t5);\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _231_fa_camera_pos : packoffset(c0);\n    float4 _231_fa_ambient : packoffset(c1);\n    float4 _231_fa_base_color : packoffset(c2);\n    float4 _231_fa_emissive : packoffset(c3);\n    float4 _231_fa_model_emissive : packoffset(c4);\n    float4 _231_fa_pbr : packoffset(c5);\n    float4 _231_fa_maps : packoffset(c6);\n    float4 _231_fa_fog : packoffset(c7);\n    float4 _231_fa_fog_b : packoffset(c8);\n    float4 _231_fa_fog_c : packoffset(c9);\n    float4 _231_fa_counts : packoffset(c10);\n    float4 _231_fa_env_sky : packoffset(c11);\n    float4 _231_fa_env_horizon : packoffset(c12);\n    float4 _231_fa_time : packoffset(c13);\n    float4 _231_fa_cl_vpx : packoffset(c14);\n    float4 _231_fa_cl_vpy : packoffset(c15);\n    float4 _231_fa_cl_vpw : packoffset(c16);\n    float4 _231_fa_cl_fwd : packoffset(c17);\n    float4 _231_fa_cl_grid : packoffset(c18);\n    float4 _231_fa_cl_info : packoffset(c19);\n    float4 _231_fa_layers_a : packoffset(c20);\n    float4 _231_fa_layers_b : packoffset(c21);\n    float4 _231_fa_layers_c : packoffset(c22);\n    float4 _231_fa_layers_d : packoffset(c23);\n    float4 _231_fa_ct_a : packoffset(c24);\n    float4 _231_fa_ct_b : packoffset(c25);\n    float4 _231_fa_ct_vpx : packoffset(c26);\n    float4 _231_fa_ct_vpy : packoffset(c27);\n    float4 _231_fa_ct_vpw : packoffset(c28);\n    float4 _231_fa_ct_fwd : packoffset(c29);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _231_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _754 = base_t;\n    _754.x = _242.x;\n    _754.y = _242.y;\n    _754.z = _242.z;\n    base_t = _754;\n    float4 _257 = (_754 * _231_fa_base_color) * i.vertex_color;\n    float3 _717 = i.world_normal;\n    if (_231_fa_maps.z > 0.5f)\n    {\n        float param_4 = _231_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _290 = fa_tex_fix(param_6, param_7);\n        float3 _294 = (_290 * 2.0f) - 1.0f.xxx;\n        float2 _299 = _294.xy * _231_fa_maps.x;\n        float3 _762 = _294;\n        _762.x = _299.x;\n        _762.y = _299.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _762;\n        _717 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _231_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _328 = fa_tex_fix(param_12, param_13);\n    float4 _765 = mrt;\n    _765.x = _328.x;\n    _765.y = _328.y;\n    _765.z = _328.z;\n    mrt = _765;\n    float4 _358 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _231_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = _231_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _400 = fa_tex_fix(param_20, param_21);\n    float _722 = _231_fa_layers_a.x;\n    float _723 = _231_fa_layers_a.y;\n    float _726 = _231_fa_layers_a.z;\n    float _725 = _231_fa_layers_b.w;\n    float _728 = _231_fa_layers_c.x;\n    if (_231_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_231_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _722 *= _370.y;\n            _723 *= _370.z;\n            _725 *= _358.w;\n        }\n        if (_231_fa_layers_c.z > 1.5f)\n        {\n            _726 *= mrt.x;\n            _728 *= mrt.w;\n        }\n    }\n    Surface _747 = { _257.xyz, _257.w, _717, clamp(_231_fa_pbr.x * _328.z, 0.0f, 1.0f), clamp(_231_fa_pbr.y * _328.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_231_fa_maps.y * (_370.x - 1.0f)), _231_fa_emissive.xyz + (_231_fa_model_emissive.xyz * _400), _722, _723, _231_fa_layers_b.xyz, _725, _726, _231_fa_layers_a.w, _728, _231_fa_layers_c.y, _231_fa_layers_d.xyz };\n    return _747;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * asfloat(points.Load(28)));\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _628 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _628 = -_628;\n    }\n    float3 _534 = normalize(_231_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _641 = { fa_world_pos, _628, fa_world_tangent, fa_uv, fa_vertex_color, _534, gl_FrontFacing };\n    SurfaceInput param = _641;\n    SurfaceInput _649 = { fa_world_pos, _628, fa_world_tangent, fa_uv, fa_vertex_color, _534, gl_FrontFacing };\n    SurfaceInput param_1 = _649;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _549 = normalize(param_2.normal);\n    float3 _564 = normalize(float3(dot(fa_pre_r0, _549), dot(fa_pre_r1, _549), dot(fa_pre_r2, _549)));\n    float _576 = _564.z;\n    float2 e = _564.xy / ((abs(_564.x) + abs(_564.y)) + abs(_576)).xx;\n    if (_576 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_187",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_231",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_398",
            "hlsl_register_b_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_231",
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
          },
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 5
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t1);\nByteAddressBuffer fa_vs_extra : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _173_fa_view_proj : packoffset(c0);\n    row_major float4x4 _173_fa_light_vp : packoffset(c4);\n    float4 _173_fa_uv_scale : packoffset(c8);\n    float4 _173_fa_time : packoffset(c9);\n    float4 _173_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _190_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _115 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _115) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _277 = { mul(float4(position, 1.0f), model).xyz, (((_115 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * _173_fa_uv_scale.xy, color, position };\n    return _277;\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _53 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f;\n    bool _68;\n    if (!_53)\n    {\n        _68 = asfloat(fa_vs_extra.Load(gl_InstanceIndex * 32 + 12)) < (-1.0f);\n    }\n    else\n    {\n        _68 = _53;\n    }\n    if (_68)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = _190_fa_base_model;\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _173_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_173",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_190",
            "hlsl_register_b_n": 6
          }
        ],
        "views": [
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 1
            }
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t1);\nByteAddressBuffer fa_vs_extra : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _178_fa_view_proj : packoffset(c0);\n    row_major float4x4 _178_fa_light_vp : packoffset(c4);\n    float4 _178_fa_uv_scale : packoffset(c8);\n    float4 _178_fa_time : packoffset(c9);\n    float4 _178_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _222_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _302_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _213 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_222_fa_joint_rows[_213] * weights[i]);\n        r1 += (_222_fa_joint_rows[_213 + 1] * weights[i]);\n        r2 += (_222_fa_joint_rows[_213 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _120 = cross(model[1].xyz, model[2].xyz);\n    float _124 = (dot(model[0].xyz, _120) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _397 = { mul(float4(position, 1.0f), model).xyz, (((_120 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _124, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _124), texcoord0 * _178_fa_uv_scale.xy, color, position };\n    return _397;\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _58 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f;\n    bool _73;\n    if (!_58)\n    {\n        _73 = asfloat(fa_vs_extra.Load(gl_InstanceIndex * 32 + 12)) < (-1.0f);\n    }\n    else\n    {\n        _73 = _58;\n    }\n    if (_73)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), _302_fa_base_model);\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mul(float4(param_8.world_pos, 1.0f), _178_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_178",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_222",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_302",
            "hlsl_register_b_n": 6
          }
        ],
        "views": [
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 1
            }
          }
        ]
      }
    }
  }
}
