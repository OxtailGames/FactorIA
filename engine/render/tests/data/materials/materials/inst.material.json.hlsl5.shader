{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "67b1186c6e51021b07dd68cec7aaad42a4febc7364ef358b4473bc1e089911c0",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _153_fa_view_proj : packoffset(c0);\n    row_major float4x4 _153_fa_light_vp : packoffset(c4);\n    float4 _153_fa_uv_scale : packoffset(c8);\n    float4 _153_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_inst_d0 : TEXCOORD9;\n    float4 fa_inst_d1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float4 fa_shadow_pos : TEXCOORD7;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _305 = { mul(float4(position, 1.0f), model).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153_fa_uv_scale.xy, color, position };\n    return _305;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _193 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = mul(_193, _153_fa_light_vp);\n    gl_Position = mul(_193, _153_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _796[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _252_fa_light_pos[32] : packoffset(c0);\n    float4 _252_fa_light_color[32] : packoffset(c32);\n    float4 _252_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _370_fa_camera_pos : packoffset(c0);\n    float4 _370_fa_ambient : packoffset(c1);\n    float4 _370_fa_base_color : packoffset(c2);\n    float4 _370_fa_emissive : packoffset(c3);\n    float4 _370_fa_model_emissive : packoffset(c4);\n    float4 _370_fa_pbr : packoffset(c5);\n    float4 _370_fa_maps : packoffset(c6);\n    float4 _370_fa_fog : packoffset(c7);\n    float4 _370_fa_fog_b : packoffset(c8);\n    float4 _370_fa_fog_c : packoffset(c9);\n    float4 _370_fa_counts : packoffset(c10);\n    float4 _370_fa_env_sky : packoffset(c11);\n    float4 _370_fa_env_horizon : packoffset(c12);\n    float4 _370_fa_time : packoffset(c13);\n    float4 _370_fa_layers_a : packoffset(c14);\n    float4 _370_fa_layers_b : packoffset(c15);\n    float4 _370_fa_layers_c : packoffset(c16);\n    float4 _370_fa_layers_d : packoffset(c17);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _1664_boost : packoffset(c0);\n    float _1664_fa_pad0 : packoffset(c0.y);\n    float _1664_fa_pad1 : packoffset(c0.z);\n    float _1664_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float4 fa_shadow_pos : TEXCOORD7;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1728 = fa_linear_to_srgb(param);\n        c = _1728;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1736 = fa_srgb_to_linear(param_1);\n            c = _1736;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _180;\n    if (i.front_facing)\n    {\n        _180 = i.world_normal;\n    }\n    else\n    {\n        _180 = -i.world_normal;\n    }\n    float3 _204 = normalize(i.world_tangent.xyz - (_180 * dot(_180, i.world_tangent.xyz)));\n    float3 _232 = normalize(((_204 * m.x) + ((cross(_180, _204) * i.world_tangent.w) * m.y)) + (_180 * m.z));\n    float3 _235;\n    if (i.front_facing)\n    {\n        _235 = _232;\n    }\n    else\n    {\n        _235 = -_232;\n    }\n    return _235;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _370_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1767 = fa_tex_fix(param_2, param_3);\n    float4 _2924 = base_t;\n    _2924.x = _1767.x;\n    _2924.y = _1767.y;\n    _2924.z = _1767.z;\n    base_t = _2924;\n    float4 _1781 = (_2924 * _370_fa_base_color) * i.vertex_color;\n    float3 _2867 = i.world_normal;\n    if (_370_fa_maps.z > 0.5f)\n    {\n        float param_4 = _370_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1814 = fa_tex_fix(param_6, param_7);\n        float3 _1817 = (_1814 * 2.0f) - 1.0f.xxx;\n        float2 _1822 = _1817.xy * _370_fa_maps.x;\n        float3 _2932 = _1817;\n        _2932.x = _1822.x;\n        _2932.y = _1822.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2932;\n        _2867 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _370_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1851 = fa_tex_fix(param_12, param_13);\n    float4 _2935 = mrt;\n    _2935.x = _1851.x;\n    _2935.y = _1851.y;\n    _2935.z = _1851.z;\n    mrt = _2935;\n    float4 _1879 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _370_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _1879.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1891 = fa_tex_fix(param_16, param_17);\n    float param_18 = _370_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1921 = fa_tex_fix(param_20, param_21);\n    float _2872 = _370_fa_layers_a.x;\n    float _2873 = _370_fa_layers_a.y;\n    float _2876 = _370_fa_layers_a.z;\n    float _2875 = _370_fa_layers_b.w;\n    float _2878 = _370_fa_layers_c.x;\n    if (_370_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_370_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _2872 *= _1891.y;\n            _2873 *= _1891.z;\n            _2875 *= _1879.w;\n        }\n        if (_370_fa_layers_c.z > 1.5f)\n        {\n            _2876 *= mrt.x;\n            _2878 *= mrt.w;\n        }\n    }\n    Surface _2897 = { _1781.xyz, _1781.w, _2867, clamp(_370_fa_pbr.x * _1851.z, 0.0f, 1.0f), clamp(_370_fa_pbr.y * _1851.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_370_fa_maps.y * (_1891.x - 1.0f)), _370_fa_emissive.xyz + (_370_fa_model_emissive.xyz * _1921), _2872, _2873, _370_fa_layers_b.xyz, _2875, _2876, _370_fa_layers_a.w, _2878, _370_fa_layers_c.y, _370_fa_layers_d.xyz };\n    return _2897;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _1664_boost);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _721 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _729 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _732 = int(_721);\n    int _735 = int(_729);\n    float _745 = _729 - float(_735);\n    int _801 = (_732 * 9) + _735;\n    int _821 = ((_732 + 1) * 9) + _735;\n    return lerp(lerp(_796[_801], _796[_801 + 1], _745), lerp(_796[_821], _796[_821 + 1], _745), _721 - float(_732));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _2803 = false;\n    float _2804 = 1.0f;\n    float _2805 = 1.0f;\n    float _2806 = 1.0f;\n    float _2807 = 0.0f;\n    float _2808 = 0.0f;\n    float _2809 = 0.0f;\n    float _2810 = 0.0f;\n    float _2812 = 1.0f;\n    bool _2813 = false;\n    float3 _2814 = 0.0f.xxx;\n    float _2815 = 1.0f;\n    float _2816 = 1.0f;\n    float _2817 = 1.0f;\n    float _2818 = 0.0f;\n    float _2819 = 0.0f;\n    float3 _2820 = float3(1.0f, 0.0f, 0.0f);\n    float3 _2821 = float3(0.0f, 0.0f, 1.0f);\n    float _2822 = 1.0f;\n    float _2823 = 1.0f;\n    float _883 = clamp(s.specular, 0.0f, 1.0f);\n    float _888 = clamp(s.ior, 1.0f, 3.0f);\n    bool _893 = (_883 != 1.0f) || (_888 != 1.5f);\n    bool _903;\n    if (!_893)\n    {\n        _903 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _903 = _893;\n    }\n    if (_903)\n    {\n        float _911 = (_888 - 1.0f) / (_888 + 1.0f);\n        f0 = lerp(min((_911 * _911).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _883, s.albedo, metallic.xxx);\n        _2804 = lerp(_883, 1.0f, metallic);\n        _2803 = true;\n    }\n    float _939 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_939 > 0.0f)\n    {\n        float _947 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _2807 = _939;\n        _2808 = _947;\n        float _954 = _947 * _947;\n        _2809 = _954;\n        _2810 = _954 * _954;\n        float _966 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _2812 = _966;\n        _2805 = 1.0f - (_939 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _966, 0.0f, 1.0f), 5.0f))));\n        _2803 = true;\n    }\n    float3 _986 = max(s.sheen_color, 0.0f.xxx);\n    float _995 = max(_986.x, max(_986.y, _986.z));\n    if (_995 > 0.0f)\n    {\n        float _1003 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _2813 = true;\n        _2814 = _986;\n        _2815 = _1003;\n        _2816 = _1003 * _1003;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _1003;\n        float _1020 = fa_sheen_albedo(param, param_1);\n        _2818 = _1020;\n        _2817 = 1.0f - min(_995 * _1020, 1.0f);\n        _2803 = true;\n    }\n    _2806 = _2805 * _2817;\n    float _1039 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_1039 != 0.0f)\n    {\n        float3 _1054 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1054;\n        if (dot(_1054, _1054) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _1068 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_1068.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _1068.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _1068.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _1072 = t;\n        float3 _1073 = normalize(_1072);\n        t = _1073;\n        float3 _1098 = normalize((_1073 * cos(s.anisotropy_rotation)) + ((cross(n, _1073) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _2820 = _1098;\n        _2821 = cross(n, _1098);\n        float _1108 = roughness * roughness;\n        float _1114 = lerp(_1108, 1.0f, _1039 * _1039);\n        bool _1116 = _1039 > 0.0f;\n        _2822 = _1116 ? _1114 : _1108;\n        _2823 = _1116 ? _1108 : _1114;\n        _2819 = _1039;\n        _2803 = true;\n    }\n    FaLayers _2845 = { _2803, _2804, _2805, _2806, _2807, _2808, _2809, _2810, i.world_normal, _2812, _2813, _2814, _2815, _2816, _2817, _2818, _2819, _2820, _2821, _2822, _2823 };\n    return _2845;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_370_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _370_fa_ambient.xyz;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _263 = _252_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_263)\n    {\n        l = normalize(_252_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _281 = _252_fa_light_pos[li].xyz - world_pos;\n        float _283 = length(_281);\n        dist = _283;\n        l = _281 / max(_283, 9.9999997473787516355514526367188e-05f).xxx;\n        float _299 = _283 / max(_252_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _305 = clamp(1.0f - (_299 * _299), 0.0f, 1.0f);\n        atten = _305 * _305;\n        if (_252_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_252_fa_light_dir[li].w, lerp(_252_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_252_fa_light_dir[li].xyz)));\n        }\n    }\n    int _356;\n    if (_263)\n    {\n        _356 = 0;\n    }\n    else\n    {\n        _356 = (_252_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _2802 = { l, _252_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _356 };\n    return _2802;\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_370_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _383 = coord.xyz / coord.w.xxx;\n    float3 p = _383;\n    float2 suv = (_383.xy * 0.5f) + 0.5f.xx;\n    if (_370_fa_counts.z > 0.5f)\n    {\n        float3 _2899 = p;\n        _2899.z = (_2899.z * 0.5f) + 0.5f;\n        p = _2899;\n    }\n    else\n    {\n        float2 _2902 = suv;\n        _2902.y = 1.0f - _2902.y;\n        suv = _2902;\n    }\n    bool _411 = suv.x < 0.0f;\n    bool _418;\n    if (!_411)\n    {\n        _418 = suv.x > 1.0f;\n    }\n    else\n    {\n        _418 = _411;\n    }\n    bool _425;\n    if (!_418)\n    {\n        _425 = suv.y < 0.0f;\n    }\n    else\n    {\n        _425 = _418;\n    }\n    bool _432;\n    if (!_425)\n    {\n        _432 = suv.y > 1.0f;\n    }\n    else\n    {\n        _432 = _425;\n    }\n    bool _439;\n    if (!_432)\n    {\n        _439 = p.z > 1.0f;\n    }\n    else\n    {\n        _439 = _432;\n    }\n    if (_439)\n    {\n        return 1.0f;\n    }\n    float _454 = _370_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _454) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _370_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1620 = fa_light_sample(param, param_1);\n    float3 _2852 = _1620.direction;\n    float3 _2847 = _1620.color;\n    float _2854 = _1620.attenuation;\n    float _2849 = _1620.shadow;\n    int _2857 = _1620.type;\n    if ((_2857 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2852;\n        float _1634 = fa_shadow_factor(param_2, param_3);\n        _2849 = _1634;\n        _2847 = _252_fa_light_color[li].xyz * (_2854 * _1634);\n    }\n    LightSample _2864 = { _2852, _2847, _2854, _2849, _1620._distance, _2857 };\n    return _2864;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _1266 = tdh / at;\n    float _1270 = bdh / ab;\n    float _1282 = ((_1266 * _1266) + (_1270 * _1270)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _1282) * _1282);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _1364 = 1.0f / alpha;\n    return ((2.0f + _1364) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _1364)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _1397 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _1476 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _1476) * _1476);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _1397);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _1397));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _1549 = max(dot(L.nc, l), 0.0f);\n        float _1555 = max(dot(L.nc, h), 0.0f);\n        float _1564 = ((_1555 * _1555) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _1564) * _1564)) * (0.5f / max(lerp((2.0f * _1549) * L.coat_ndv, _1549 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _1549)) * _1549).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _651 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _654 = _651.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_654 * _654, exp2((-9.27999973297119140625f) * ndv)) * _654) + _651.y)) + _651.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_370_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _370_fa_env_horizon.w).xyz;\n    }\n    float _554 = rough * rough;\n    float _585 = 0.60000002384185791015625f * _554;\n    return lerp(lerp(_370_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_370_fa_env_horizon.xyz, _370_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _554)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _585, 0.0500000007450580596923828125f + _585, d.y).xxx), ((_370_fa_env_sky.xyz + _370_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_554 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _1149;\n        if (L.aniso >= 0.0f)\n        {\n            _1149 = L.b;\n        }\n        else\n        {\n            _1149 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_1149, v), _1149), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1182 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _1182.x) + (L.f90.xxx * _1182.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1237 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _1237.x) + _1237.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _693 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _693.x) + _693.y.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2582 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2582 = -_2582;\n    }\n    float3 _2041 = normalize(_370_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _2595 = { fa_world_pos, _2582, fa_world_tangent, fa_uv, fa_vertex_color, _2041, gl_FrontFacing };\n    SurfaceInput param = _2595;\n    Surface _2046 = fa_standard_surface(param);\n    float3 _2613 = _2046.albedo;\n    float _2614 = _2046.alpha;\n    float3 _2615 = _2046.normal;\n    float _2616 = _2046.metallic;\n    float _2617 = _2046.roughness;\n    float _2618 = _2046.occlusion;\n    float3 _2619 = _2046.emission;\n    float _2620 = _2046.clearcoat;\n    float _2621 = _2046.clearcoat_roughness;\n    float3 _2622 = _2046.sheen_color;\n    float _2623 = _2046.sheen_roughness;\n    float _2624 = _2046.anisotropy;\n    float _2625 = _2046.anisotropy_rotation;\n    float _2626 = _2046.specular;\n    float _2627 = _2046.ior;\n    float3 _2628 = _2046.specular_color;\n    SurfaceInput _2603 = { fa_world_pos, _2582, fa_world_tangent, fa_uv, fa_vertex_color, _2041, gl_FrontFacing };\n    SurfaceInput param_1 = _2603;\n    Surface param_2 = _2046;\n    surface(param_1, param_2);\n    _2613 = param_2.albedo;\n    _2614 = param_2.alpha;\n    _2615 = param_2.normal;\n    _2616 = param_2.metallic;\n    _2617 = param_2.roughness;\n    _2618 = param_2.occlusion;\n    _2619 = param_2.emission;\n    _2620 = param_2.clearcoat;\n    _2621 = param_2.clearcoat_roughness;\n    _2622 = param_2.sheen_color;\n    _2623 = param_2.sheen_roughness;\n    _2624 = param_2.anisotropy;\n    _2625 = param_2.anisotropy_rotation;\n    _2626 = param_2.specular;\n    _2627 = param_2.ior;\n    _2628 = param_2.specular_color;\n    float3 result;\n    if (_370_fa_emissive.w > 0.5f)\n    {\n        result = _2613;\n    }\n    else\n    {\n        float3 _2068 = normalize(_2615);\n        float _2075 = clamp(_2616, 0.0f, 1.0f);\n        float _2079 = clamp(_2617, 0.0500000007450580596923828125f, 1.0f);\n        float _2083 = _2079 * _2079;\n        float _2087 = _2083 * _2083;\n        float _2092 = max(dot(_2068, _2041), 9.9999997473787516355514526367188e-05f);\n        float3 _2098 = _2613 * (1.0f - _2075);\n        float3 _2105 = lerp(0.039999999105930328369140625f.xxx, _2613, _2075.xxx);\n        float3 f0 = _2105;\n        SurfaceInput _2611 = { fa_world_pos, _2582, fa_world_tangent, fa_uv, fa_vertex_color, _2041, gl_FrontFacing };\n        SurfaceInput param_3 = _2611;\n        Surface _2694 = { _2613, _2614, _2615, _2616, _2617, _2618, _2619, _2620, _2621, _2622, _2623, _2624, _2625, _2626, _2627, _2628 };\n        Surface param_4 = _2694;\n        float3 param_5 = _2068;\n        float3 param_6 = _2041;\n        float param_7 = _2075;\n        float param_8 = _2079;\n        float3 param_9 = _2105;\n        FaLayers _2121 = fa_layers_setup(param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n        f0 = param_9;\n        float3 param_10 = _2068;\n        float3 lit = (fa_ambient_light(param_10) * _2098) * _2618;\n        if (_2121.on)\n        {\n            lit *= _2121.base_scale;\n        }\n        int _2143 = int(_370_fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _2143)\n            {\n                break;\n            }\n            int param_11 = li;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _2582;\n            LightSample _2167 = fa_light_shadowed(param_11, param_12, param_13);\n            float3 _2787 = _2167.direction;\n            float _2175 = max(dot(_2068, _2787), 0.0f);\n            float _2181 = _2167.attenuation * _2167.shadow;\n            float3 _2186 = normalize(_2787 + _2041);\n            float _2191 = max(dot(_2068, _2186), 0.0f);\n            float _2196 = max(dot(_2041, _2186), 0.0f);\n            if (_2121.on)\n            {\n                FaLayers param_14 = _2121;\n                float3 param_15 = _2098;\n                float3 param_16 = f0;\n                float3 param_17 = _2068;\n                float3 param_18 = _2041;\n                float3 param_19 = _2787;\n                float3 param_20 = _2186;\n                float param_21 = _2175;\n                float param_22 = _2092;\n                float param_23 = _2191;\n                float param_24 = _2196;\n                float param_25 = _2083;\n                float param_26 = _2087;\n                lit += (fa_layers_light(param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26) * (_252_fa_light_color[li].xyz * _2181));\n            }\n            else\n            {\n                float _2245 = ((_2191 * _2191) * (_2087 - 1.0f)) + 1.0f;\n                lit += (((_2098 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _2196, 5.0f))) * (((_2087 / ((3.1415927410125732421875f * _2245) * _2245)) * (0.5f / max(lerp((2.0f * _2175) * _2092, _2175 + _2092, _2083), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2175))) * _252_fa_light_color[li].xyz) * (_2175 * _2181));\n            }\n        }\n        if (_2121.on)\n        {\n            FaLayers param_27 = _2121;\n            float3 param_28 = _2068;\n            float3 param_29 = _2041;\n            float3 param_30 = f0;\n            float param_31 = _2079;\n            lit += (fa_layers_ibl(param_27, param_28, param_29, param_30, param_31) * _2618);\n        }\n        else\n        {\n            float3 param_32 = _2068;\n            float3 param_33 = _2041;\n            float3 param_34 = f0;\n            float param_35 = _2079;\n            lit += (fa_sky_reflection(param_32, param_33, param_34, param_35) * _2618);\n        }\n        result = lit;\n    }\n    result += _2619;\n    bool _2343 = _370_fa_fog.w > 0.0f;\n    bool _2350;\n    if (!_2343)\n    {\n        _2350 = _370_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2350 = _2343;\n    }\n    if (_2350)\n    {\n        float3 _2359 = fa_world_pos - _370_fa_camera_pos.xyz;\n        float _2365 = dot(_2359, _370_fa_fog_c.xyz);\n        bool _2369 = _370_fa_fog_c.w > 0.5f;\n        float _2370;\n        if (_2369)\n        {\n            _2370 = _2365;\n        }\n        else\n        {\n            _2370 = length(_2359);\n        }\n        float _2382 = _2370 - _370_fa_fog_b.x;\n        if (_2382 > 0.0f)\n        {\n            float _2391 = _370_fa_fog.w * _2382;\n            float tau = _2391 * _2391;\n            if (_370_fa_fog_b.y > 0.0f)\n            {\n                float _2407;\n                if (_2369)\n                {\n                    _2407 = fa_world_pos.y - (_370_fa_fog_c.y * _2365);\n                }\n                else\n                {\n                    _2407 = _370_fa_camera_pos.y;\n                }\n                float _2428 = lerp(_2407, fa_world_pos.y, clamp(_370_fa_fog_b.x / _2370, 0.0f, 1.0f));\n                float _2432 = fa_world_pos.y - _2428;\n                float _2437 = _2428 - _370_fa_fog_b.z;\n                float _2442 = fa_world_pos.y - _370_fa_fog_b.z;\n                bool _2445 = _2437 <= 0.0f;\n                bool _2446 = !_2445;\n                bool _2452;\n                if (_2446)\n                {\n                    _2452 = _370_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2452 = _2445;\n                }\n                float _2453;\n                if (_2452)\n                {\n                    _2453 = _370_fa_fog_b.y;\n                }\n                else\n                {\n                    _2453 = _370_fa_fog_b.y * exp(-min(_370_fa_fog_b.w * _2437, 80.0f));\n                }\n                bool _2480;\n                if (_2446)\n                {\n                    _2480 = _370_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2480 = _2445;\n                }\n                float _2481;\n                if (_2480)\n                {\n                    _2481 = _370_fa_fog_b.y * _2437;\n                }\n                else\n                {\n                    _2481 = (_370_fa_fog_b.y * (1.0f - exp(-min(_370_fa_fog_b.w * _2437, 80.0f)))) / _370_fa_fog_b.w;\n                }\n                bool _2506 = _2442 <= 0.0f;\n                bool _2513;\n                if (!_2506)\n                {\n                    _2513 = _370_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2513 = _2506;\n                }\n                float _2514;\n                if (_2513)\n                {\n                    _2514 = _370_fa_fog_b.y * _2442;\n                }\n                else\n                {\n                    _2514 = (_370_fa_fog_b.y * (1.0f - exp(-min(_370_fa_fog_b.w * _2442, 80.0f)))) / _370_fa_fog_b.w;\n                }\n                float _2541;\n                if (abs(_2432) < 0.001000000047497451305389404296875f)\n                {\n                    _2541 = _2453;\n                }\n                else\n                {\n                    _2541 = (_2514 - _2481) / _2432;\n                }\n                tau += (_2382 * max(_2541, 0.0f));\n            }\n            result = lerp(result, _370_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2614);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_153",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_252",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_370",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1664",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 7
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 7,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _158_fa_view_proj : packoffset(c0);\n    row_major float4x4 _158_fa_light_vp : packoffset(c4);\n    float4 _158_fa_uv_scale : packoffset(c8);\n    float4 _158_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _205_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float4 fa_inst_d0 : TEXCOORD11;\n    float4 fa_inst_d1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float4 fa_shadow_pos : TEXCOORD7;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_205_fa_joint_rows[_196] * weights[i]);\n        r1 += (_205_fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205_fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _425 = { mul(float4(position, 1.0f), model).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158_fa_uv_scale.xy, color, position };\n    return _425;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _306 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = mul(_306, _158_fa_light_vp);\n    gl_Position = mul(_306, _158_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _796[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _252_fa_light_pos[32] : packoffset(c0);\n    float4 _252_fa_light_color[32] : packoffset(c32);\n    float4 _252_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _370_fa_camera_pos : packoffset(c0);\n    float4 _370_fa_ambient : packoffset(c1);\n    float4 _370_fa_base_color : packoffset(c2);\n    float4 _370_fa_emissive : packoffset(c3);\n    float4 _370_fa_model_emissive : packoffset(c4);\n    float4 _370_fa_pbr : packoffset(c5);\n    float4 _370_fa_maps : packoffset(c6);\n    float4 _370_fa_fog : packoffset(c7);\n    float4 _370_fa_fog_b : packoffset(c8);\n    float4 _370_fa_fog_c : packoffset(c9);\n    float4 _370_fa_counts : packoffset(c10);\n    float4 _370_fa_env_sky : packoffset(c11);\n    float4 _370_fa_env_horizon : packoffset(c12);\n    float4 _370_fa_time : packoffset(c13);\n    float4 _370_fa_layers_a : packoffset(c14);\n    float4 _370_fa_layers_b : packoffset(c15);\n    float4 _370_fa_layers_c : packoffset(c16);\n    float4 _370_fa_layers_d : packoffset(c17);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _1664_boost : packoffset(c0);\n    float _1664_fa_pad0 : packoffset(c0.y);\n    float _1664_fa_pad1 : packoffset(c0.z);\n    float _1664_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float4 fa_shadow_pos : TEXCOORD7;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1728 = fa_linear_to_srgb(param);\n        c = _1728;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1736 = fa_srgb_to_linear(param_1);\n            c = _1736;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _180;\n    if (i.front_facing)\n    {\n        _180 = i.world_normal;\n    }\n    else\n    {\n        _180 = -i.world_normal;\n    }\n    float3 _204 = normalize(i.world_tangent.xyz - (_180 * dot(_180, i.world_tangent.xyz)));\n    float3 _232 = normalize(((_204 * m.x) + ((cross(_180, _204) * i.world_tangent.w) * m.y)) + (_180 * m.z));\n    float3 _235;\n    if (i.front_facing)\n    {\n        _235 = _232;\n    }\n    else\n    {\n        _235 = -_232;\n    }\n    return _235;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _370_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1767 = fa_tex_fix(param_2, param_3);\n    float4 _2924 = base_t;\n    _2924.x = _1767.x;\n    _2924.y = _1767.y;\n    _2924.z = _1767.z;\n    base_t = _2924;\n    float4 _1781 = (_2924 * _370_fa_base_color) * i.vertex_color;\n    float3 _2867 = i.world_normal;\n    if (_370_fa_maps.z > 0.5f)\n    {\n        float param_4 = _370_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1814 = fa_tex_fix(param_6, param_7);\n        float3 _1817 = (_1814 * 2.0f) - 1.0f.xxx;\n        float2 _1822 = _1817.xy * _370_fa_maps.x;\n        float3 _2932 = _1817;\n        _2932.x = _1822.x;\n        _2932.y = _1822.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2932;\n        _2867 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _370_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1851 = fa_tex_fix(param_12, param_13);\n    float4 _2935 = mrt;\n    _2935.x = _1851.x;\n    _2935.y = _1851.y;\n    _2935.z = _1851.z;\n    mrt = _2935;\n    float4 _1879 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _370_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _1879.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1891 = fa_tex_fix(param_16, param_17);\n    float param_18 = _370_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1921 = fa_tex_fix(param_20, param_21);\n    float _2872 = _370_fa_layers_a.x;\n    float _2873 = _370_fa_layers_a.y;\n    float _2876 = _370_fa_layers_a.z;\n    float _2875 = _370_fa_layers_b.w;\n    float _2878 = _370_fa_layers_c.x;\n    if (_370_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_370_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _2872 *= _1891.y;\n            _2873 *= _1891.z;\n            _2875 *= _1879.w;\n        }\n        if (_370_fa_layers_c.z > 1.5f)\n        {\n            _2876 *= mrt.x;\n            _2878 *= mrt.w;\n        }\n    }\n    Surface _2897 = { _1781.xyz, _1781.w, _2867, clamp(_370_fa_pbr.x * _1851.z, 0.0f, 1.0f), clamp(_370_fa_pbr.y * _1851.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_370_fa_maps.y * (_1891.x - 1.0f)), _370_fa_emissive.xyz + (_370_fa_model_emissive.xyz * _1921), _2872, _2873, _370_fa_layers_b.xyz, _2875, _2876, _370_fa_layers_a.w, _2878, _370_fa_layers_c.y, _370_fa_layers_d.xyz };\n    return _2897;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _1664_boost);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _721 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _729 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _732 = int(_721);\n    int _735 = int(_729);\n    float _745 = _729 - float(_735);\n    int _801 = (_732 * 9) + _735;\n    int _821 = ((_732 + 1) * 9) + _735;\n    return lerp(lerp(_796[_801], _796[_801 + 1], _745), lerp(_796[_821], _796[_821 + 1], _745), _721 - float(_732));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _2803 = false;\n    float _2804 = 1.0f;\n    float _2805 = 1.0f;\n    float _2806 = 1.0f;\n    float _2807 = 0.0f;\n    float _2808 = 0.0f;\n    float _2809 = 0.0f;\n    float _2810 = 0.0f;\n    float _2812 = 1.0f;\n    bool _2813 = false;\n    float3 _2814 = 0.0f.xxx;\n    float _2815 = 1.0f;\n    float _2816 = 1.0f;\n    float _2817 = 1.0f;\n    float _2818 = 0.0f;\n    float _2819 = 0.0f;\n    float3 _2820 = float3(1.0f, 0.0f, 0.0f);\n    float3 _2821 = float3(0.0f, 0.0f, 1.0f);\n    float _2822 = 1.0f;\n    float _2823 = 1.0f;\n    float _883 = clamp(s.specular, 0.0f, 1.0f);\n    float _888 = clamp(s.ior, 1.0f, 3.0f);\n    bool _893 = (_883 != 1.0f) || (_888 != 1.5f);\n    bool _903;\n    if (!_893)\n    {\n        _903 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _903 = _893;\n    }\n    if (_903)\n    {\n        float _911 = (_888 - 1.0f) / (_888 + 1.0f);\n        f0 = lerp(min((_911 * _911).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _883, s.albedo, metallic.xxx);\n        _2804 = lerp(_883, 1.0f, metallic);\n        _2803 = true;\n    }\n    float _939 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_939 > 0.0f)\n    {\n        float _947 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _2807 = _939;\n        _2808 = _947;\n        float _954 = _947 * _947;\n        _2809 = _954;\n        _2810 = _954 * _954;\n        float _966 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _2812 = _966;\n        _2805 = 1.0f - (_939 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _966, 0.0f, 1.0f), 5.0f))));\n        _2803 = true;\n    }\n    float3 _986 = max(s.sheen_color, 0.0f.xxx);\n    float _995 = max(_986.x, max(_986.y, _986.z));\n    if (_995 > 0.0f)\n    {\n        float _1003 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _2813 = true;\n        _2814 = _986;\n        _2815 = _1003;\n        _2816 = _1003 * _1003;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _1003;\n        float _1020 = fa_sheen_albedo(param, param_1);\n        _2818 = _1020;\n        _2817 = 1.0f - min(_995 * _1020, 1.0f);\n        _2803 = true;\n    }\n    _2806 = _2805 * _2817;\n    float _1039 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_1039 != 0.0f)\n    {\n        float3 _1054 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1054;\n        if (dot(_1054, _1054) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _1068 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_1068.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _1068.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _1068.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _1072 = t;\n        float3 _1073 = normalize(_1072);\n        t = _1073;\n        float3 _1098 = normalize((_1073 * cos(s.anisotropy_rotation)) + ((cross(n, _1073) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _2820 = _1098;\n        _2821 = cross(n, _1098);\n        float _1108 = roughness * roughness;\n        float _1114 = lerp(_1108, 1.0f, _1039 * _1039);\n        bool _1116 = _1039 > 0.0f;\n        _2822 = _1116 ? _1114 : _1108;\n        _2823 = _1116 ? _1108 : _1114;\n        _2819 = _1039;\n        _2803 = true;\n    }\n    FaLayers _2845 = { _2803, _2804, _2805, _2806, _2807, _2808, _2809, _2810, i.world_normal, _2812, _2813, _2814, _2815, _2816, _2817, _2818, _2819, _2820, _2821, _2822, _2823 };\n    return _2845;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_370_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _370_fa_ambient.xyz;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _263 = _252_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_263)\n    {\n        l = normalize(_252_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _281 = _252_fa_light_pos[li].xyz - world_pos;\n        float _283 = length(_281);\n        dist = _283;\n        l = _281 / max(_283, 9.9999997473787516355514526367188e-05f).xxx;\n        float _299 = _283 / max(_252_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _305 = clamp(1.0f - (_299 * _299), 0.0f, 1.0f);\n        atten = _305 * _305;\n        if (_252_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_252_fa_light_dir[li].w, lerp(_252_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_252_fa_light_dir[li].xyz)));\n        }\n    }\n    int _356;\n    if (_263)\n    {\n        _356 = 0;\n    }\n    else\n    {\n        _356 = (_252_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _2802 = { l, _252_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _356 };\n    return _2802;\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_370_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _383 = coord.xyz / coord.w.xxx;\n    float3 p = _383;\n    float2 suv = (_383.xy * 0.5f) + 0.5f.xx;\n    if (_370_fa_counts.z > 0.5f)\n    {\n        float3 _2899 = p;\n        _2899.z = (_2899.z * 0.5f) + 0.5f;\n        p = _2899;\n    }\n    else\n    {\n        float2 _2902 = suv;\n        _2902.y = 1.0f - _2902.y;\n        suv = _2902;\n    }\n    bool _411 = suv.x < 0.0f;\n    bool _418;\n    if (!_411)\n    {\n        _418 = suv.x > 1.0f;\n    }\n    else\n    {\n        _418 = _411;\n    }\n    bool _425;\n    if (!_418)\n    {\n        _425 = suv.y < 0.0f;\n    }\n    else\n    {\n        _425 = _418;\n    }\n    bool _432;\n    if (!_425)\n    {\n        _432 = suv.y > 1.0f;\n    }\n    else\n    {\n        _432 = _425;\n    }\n    bool _439;\n    if (!_432)\n    {\n        _439 = p.z > 1.0f;\n    }\n    else\n    {\n        _439 = _432;\n    }\n    if (_439)\n    {\n        return 1.0f;\n    }\n    float _454 = _370_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _454) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _370_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1620 = fa_light_sample(param, param_1);\n    float3 _2852 = _1620.direction;\n    float3 _2847 = _1620.color;\n    float _2854 = _1620.attenuation;\n    float _2849 = _1620.shadow;\n    int _2857 = _1620.type;\n    if ((_2857 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2852;\n        float _1634 = fa_shadow_factor(param_2, param_3);\n        _2849 = _1634;\n        _2847 = _252_fa_light_color[li].xyz * (_2854 * _1634);\n    }\n    LightSample _2864 = { _2852, _2847, _2854, _2849, _1620._distance, _2857 };\n    return _2864;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _1266 = tdh / at;\n    float _1270 = bdh / ab;\n    float _1282 = ((_1266 * _1266) + (_1270 * _1270)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _1282) * _1282);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _1364 = 1.0f / alpha;\n    return ((2.0f + _1364) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _1364)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _1397 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _1476 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _1476) * _1476);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _1397);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _1397));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _1549 = max(dot(L.nc, l), 0.0f);\n        float _1555 = max(dot(L.nc, h), 0.0f);\n        float _1564 = ((_1555 * _1555) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _1564) * _1564)) * (0.5f / max(lerp((2.0f * _1549) * L.coat_ndv, _1549 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _1549)) * _1549).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _651 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _654 = _651.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_654 * _654, exp2((-9.27999973297119140625f) * ndv)) * _654) + _651.y)) + _651.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_370_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _370_fa_env_horizon.w).xyz;\n    }\n    float _554 = rough * rough;\n    float _585 = 0.60000002384185791015625f * _554;\n    return lerp(lerp(_370_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_370_fa_env_horizon.xyz, _370_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _554)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _585, 0.0500000007450580596923828125f + _585, d.y).xxx), ((_370_fa_env_sky.xyz + _370_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_554 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _1149;\n        if (L.aniso >= 0.0f)\n        {\n            _1149 = L.b;\n        }\n        else\n        {\n            _1149 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_1149, v), _1149), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1182 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _1182.x) + (L.f90.xxx * _1182.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1237 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _1237.x) + _1237.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _693 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _693.x) + _693.y.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2582 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2582 = -_2582;\n    }\n    float3 _2041 = normalize(_370_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _2595 = { fa_world_pos, _2582, fa_world_tangent, fa_uv, fa_vertex_color, _2041, gl_FrontFacing };\n    SurfaceInput param = _2595;\n    Surface _2046 = fa_standard_surface(param);\n    float3 _2613 = _2046.albedo;\n    float _2614 = _2046.alpha;\n    float3 _2615 = _2046.normal;\n    float _2616 = _2046.metallic;\n    float _2617 = _2046.roughness;\n    float _2618 = _2046.occlusion;\n    float3 _2619 = _2046.emission;\n    float _2620 = _2046.clearcoat;\n    float _2621 = _2046.clearcoat_roughness;\n    float3 _2622 = _2046.sheen_color;\n    float _2623 = _2046.sheen_roughness;\n    float _2624 = _2046.anisotropy;\n    float _2625 = _2046.anisotropy_rotation;\n    float _2626 = _2046.specular;\n    float _2627 = _2046.ior;\n    float3 _2628 = _2046.specular_color;\n    SurfaceInput _2603 = { fa_world_pos, _2582, fa_world_tangent, fa_uv, fa_vertex_color, _2041, gl_FrontFacing };\n    SurfaceInput param_1 = _2603;\n    Surface param_2 = _2046;\n    surface(param_1, param_2);\n    _2613 = param_2.albedo;\n    _2614 = param_2.alpha;\n    _2615 = param_2.normal;\n    _2616 = param_2.metallic;\n    _2617 = param_2.roughness;\n    _2618 = param_2.occlusion;\n    _2619 = param_2.emission;\n    _2620 = param_2.clearcoat;\n    _2621 = param_2.clearcoat_roughness;\n    _2622 = param_2.sheen_color;\n    _2623 = param_2.sheen_roughness;\n    _2624 = param_2.anisotropy;\n    _2625 = param_2.anisotropy_rotation;\n    _2626 = param_2.specular;\n    _2627 = param_2.ior;\n    _2628 = param_2.specular_color;\n    float3 result;\n    if (_370_fa_emissive.w > 0.5f)\n    {\n        result = _2613;\n    }\n    else\n    {\n        float3 _2068 = normalize(_2615);\n        float _2075 = clamp(_2616, 0.0f, 1.0f);\n        float _2079 = clamp(_2617, 0.0500000007450580596923828125f, 1.0f);\n        float _2083 = _2079 * _2079;\n        float _2087 = _2083 * _2083;\n        float _2092 = max(dot(_2068, _2041), 9.9999997473787516355514526367188e-05f);\n        float3 _2098 = _2613 * (1.0f - _2075);\n        float3 _2105 = lerp(0.039999999105930328369140625f.xxx, _2613, _2075.xxx);\n        float3 f0 = _2105;\n        SurfaceInput _2611 = { fa_world_pos, _2582, fa_world_tangent, fa_uv, fa_vertex_color, _2041, gl_FrontFacing };\n        SurfaceInput param_3 = _2611;\n        Surface _2694 = { _2613, _2614, _2615, _2616, _2617, _2618, _2619, _2620, _2621, _2622, _2623, _2624, _2625, _2626, _2627, _2628 };\n        Surface param_4 = _2694;\n        float3 param_5 = _2068;\n        float3 param_6 = _2041;\n        float param_7 = _2075;\n        float param_8 = _2079;\n        float3 param_9 = _2105;\n        FaLayers _2121 = fa_layers_setup(param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n        f0 = param_9;\n        float3 param_10 = _2068;\n        float3 lit = (fa_ambient_light(param_10) * _2098) * _2618;\n        if (_2121.on)\n        {\n            lit *= _2121.base_scale;\n        }\n        int _2143 = int(_370_fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _2143)\n            {\n                break;\n            }\n            int param_11 = li;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _2582;\n            LightSample _2167 = fa_light_shadowed(param_11, param_12, param_13);\n            float3 _2787 = _2167.direction;\n            float _2175 = max(dot(_2068, _2787), 0.0f);\n            float _2181 = _2167.attenuation * _2167.shadow;\n            float3 _2186 = normalize(_2787 + _2041);\n            float _2191 = max(dot(_2068, _2186), 0.0f);\n            float _2196 = max(dot(_2041, _2186), 0.0f);\n            if (_2121.on)\n            {\n                FaLayers param_14 = _2121;\n                float3 param_15 = _2098;\n                float3 param_16 = f0;\n                float3 param_17 = _2068;\n                float3 param_18 = _2041;\n                float3 param_19 = _2787;\n                float3 param_20 = _2186;\n                float param_21 = _2175;\n                float param_22 = _2092;\n                float param_23 = _2191;\n                float param_24 = _2196;\n                float param_25 = _2083;\n                float param_26 = _2087;\n                lit += (fa_layers_light(param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26) * (_252_fa_light_color[li].xyz * _2181));\n            }\n            else\n            {\n                float _2245 = ((_2191 * _2191) * (_2087 - 1.0f)) + 1.0f;\n                lit += (((_2098 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _2196, 5.0f))) * (((_2087 / ((3.1415927410125732421875f * _2245) * _2245)) * (0.5f / max(lerp((2.0f * _2175) * _2092, _2175 + _2092, _2083), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2175))) * _252_fa_light_color[li].xyz) * (_2175 * _2181));\n            }\n        }\n        if (_2121.on)\n        {\n            FaLayers param_27 = _2121;\n            float3 param_28 = _2068;\n            float3 param_29 = _2041;\n            float3 param_30 = f0;\n            float param_31 = _2079;\n            lit += (fa_layers_ibl(param_27, param_28, param_29, param_30, param_31) * _2618);\n        }\n        else\n        {\n            float3 param_32 = _2068;\n            float3 param_33 = _2041;\n            float3 param_34 = f0;\n            float param_35 = _2079;\n            lit += (fa_sky_reflection(param_32, param_33, param_34, param_35) * _2618);\n        }\n        result = lit;\n    }\n    result += _2619;\n    bool _2343 = _370_fa_fog.w > 0.0f;\n    bool _2350;\n    if (!_2343)\n    {\n        _2350 = _370_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2350 = _2343;\n    }\n    if (_2350)\n    {\n        float3 _2359 = fa_world_pos - _370_fa_camera_pos.xyz;\n        float _2365 = dot(_2359, _370_fa_fog_c.xyz);\n        bool _2369 = _370_fa_fog_c.w > 0.5f;\n        float _2370;\n        if (_2369)\n        {\n            _2370 = _2365;\n        }\n        else\n        {\n            _2370 = length(_2359);\n        }\n        float _2382 = _2370 - _370_fa_fog_b.x;\n        if (_2382 > 0.0f)\n        {\n            float _2391 = _370_fa_fog.w * _2382;\n            float tau = _2391 * _2391;\n            if (_370_fa_fog_b.y > 0.0f)\n            {\n                float _2407;\n                if (_2369)\n                {\n                    _2407 = fa_world_pos.y - (_370_fa_fog_c.y * _2365);\n                }\n                else\n                {\n                    _2407 = _370_fa_camera_pos.y;\n                }\n                float _2428 = lerp(_2407, fa_world_pos.y, clamp(_370_fa_fog_b.x / _2370, 0.0f, 1.0f));\n                float _2432 = fa_world_pos.y - _2428;\n                float _2437 = _2428 - _370_fa_fog_b.z;\n                float _2442 = fa_world_pos.y - _370_fa_fog_b.z;\n                bool _2445 = _2437 <= 0.0f;\n                bool _2446 = !_2445;\n                bool _2452;\n                if (_2446)\n                {\n                    _2452 = _370_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2452 = _2445;\n                }\n                float _2453;\n                if (_2452)\n                {\n                    _2453 = _370_fa_fog_b.y;\n                }\n                else\n                {\n                    _2453 = _370_fa_fog_b.y * exp(-min(_370_fa_fog_b.w * _2437, 80.0f));\n                }\n                bool _2480;\n                if (_2446)\n                {\n                    _2480 = _370_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2480 = _2445;\n                }\n                float _2481;\n                if (_2480)\n                {\n                    _2481 = _370_fa_fog_b.y * _2437;\n                }\n                else\n                {\n                    _2481 = (_370_fa_fog_b.y * (1.0f - exp(-min(_370_fa_fog_b.w * _2437, 80.0f)))) / _370_fa_fog_b.w;\n                }\n                bool _2506 = _2442 <= 0.0f;\n                bool _2513;\n                if (!_2506)\n                {\n                    _2513 = _370_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2513 = _2506;\n                }\n                float _2514;\n                if (_2513)\n                {\n                    _2514 = _370_fa_fog_b.y * _2442;\n                }\n                else\n                {\n                    _2514 = (_370_fa_fog_b.y * (1.0f - exp(-min(_370_fa_fog_b.w * _2442, 80.0f)))) / _370_fa_fog_b.w;\n                }\n                float _2541;\n                if (abs(_2432) < 0.001000000047497451305389404296875f)\n                {\n                    _2541 = _2453;\n                }\n                else\n                {\n                    _2541 = (_2514 - _2481) / _2432;\n                }\n                tau += (_2382 * max(_2541, 0.0f));\n            }\n            result = lerp(result, _370_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2614);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 160,
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_252",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_370",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1664",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 7
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 7,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _153_fa_view_proj : packoffset(c0);\n    row_major float4x4 _153_fa_light_vp : packoffset(c4);\n    float4 _153_fa_uv_scale : packoffset(c8);\n    float4 _153_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_inst_d0 : TEXCOORD9;\n    float4 fa_inst_d1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _334 = { mul(float4(position, 1.0f), model).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * _153_fa_uv_scale.xy, color, position };\n    return _334;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _197 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_197, _153_fa_light_vp).z;\n    fa_pre_r0 = float3(_153_fa_light_vp[0].x, _153_fa_light_vp[1].x, _153_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_153_fa_light_vp[0].y, _153_fa_light_vp[1].y, _153_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_153_fa_light_vp[0].z, _153_fa_light_vp[1].z, _153_fa_light_vp[2].z);\n    gl_Position = mul(_197, _153_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _142_boost : packoffset(c0);\n    float _142_fa_pad0 : packoffset(c0.y);\n    float _142_fa_pad1 : packoffset(c0.z);\n    float _142_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _253_fa_camera_pos : packoffset(c0);\n    float4 _253_fa_ambient : packoffset(c1);\n    float4 _253_fa_base_color : packoffset(c2);\n    float4 _253_fa_emissive : packoffset(c3);\n    float4 _253_fa_model_emissive : packoffset(c4);\n    float4 _253_fa_pbr : packoffset(c5);\n    float4 _253_fa_maps : packoffset(c6);\n    float4 _253_fa_fog : packoffset(c7);\n    float4 _253_fa_fog_b : packoffset(c8);\n    float4 _253_fa_fog_c : packoffset(c9);\n    float4 _253_fa_counts : packoffset(c10);\n    float4 _253_fa_env_sky : packoffset(c11);\n    float4 _253_fa_env_horizon : packoffset(c12);\n    float4 _253_fa_time : packoffset(c13);\n    float4 _253_fa_layers_a : packoffset(c14);\n    float4 _253_fa_layers_b : packoffset(c15);\n    float4 _253_fa_layers_c : packoffset(c16);\n    float4 _253_fa_layers_d : packoffset(c17);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _253_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _767 = base_t;\n    _767.x = _264.x;\n    _767.y = _264.y;\n    _767.z = _264.z;\n    base_t = _767;\n    float4 _280 = (_767 * _253_fa_base_color) * i.vertex_color;\n    float3 _730 = i.world_normal;\n    if (_253_fa_maps.z > 0.5f)\n    {\n        float param_4 = _253_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0f) - 1.0f.xxx;\n        float2 _322 = _317.xy * _253_fa_maps.x;\n        float3 _775 = _317;\n        _775.x = _322.x;\n        _775.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _775;\n        _730 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _253_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _778 = mrt;\n    _778.x = _351.x;\n    _778.y = _351.y;\n    _778.z = _351.z;\n    mrt = _778;\n    float4 _381 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _253_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _423 = fa_tex_fix(param_20, param_21);\n    float _735 = _253_fa_layers_a.x;\n    float _736 = _253_fa_layers_a.y;\n    float _739 = _253_fa_layers_a.z;\n    float _738 = _253_fa_layers_b.w;\n    float _741 = _253_fa_layers_c.x;\n    if (_253_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_253_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _735 *= _393.y;\n            _736 *= _393.z;\n            _738 *= _381.w;\n        }\n        if (_253_fa_layers_c.z > 1.5f)\n        {\n            _739 *= mrt.x;\n            _741 *= mrt.w;\n        }\n    }\n    Surface _760 = { _280.xyz, _280.w, _730, clamp(_253_fa_pbr.x * _351.z, 0.0f, 1.0f), clamp(_253_fa_pbr.y * _351.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_253_fa_maps.y * (_393.x - 1.0f)), _253_fa_emissive.xyz + (_253_fa_model_emissive.xyz * _423), _735, _736, _253_fa_layers_b.xyz, _738, _739, _253_fa_layers_a.w, _741, _253_fa_layers_c.y, _253_fa_layers_d.xyz };\n    return _760;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _142_boost);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _641 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _641 = -_641;\n    }\n    float3 _554 = normalize(_253_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _654 = { fa_world_pos, _641, fa_world_tangent, fa_uv, fa_vertex_color, _554, gl_FrontFacing };\n    SurfaceInput param = _654;\n    SurfaceInput _662 = { fa_world_pos, _641, fa_world_tangent, fa_uv, fa_vertex_color, _554, gl_FrontFacing };\n    SurfaceInput param_1 = _662;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _569 = normalize(param_2.normal);\n    float3 _584 = normalize(float3(dot(fa_pre_r0, _569), dot(fa_pre_r1, _569), dot(fa_pre_r2, _569)));\n    float _596 = _584.z;\n    float2 e = _584.xy / ((abs(_584.x) + abs(_584.y)) + abs(_596)).xx;\n    if (_596 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 160,
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
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _158_fa_view_proj : packoffset(c0);\n    row_major float4x4 _158_fa_light_vp : packoffset(c4);\n    float4 _158_fa_uv_scale : packoffset(c8);\n    float4 _158_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _205_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float4 fa_inst_d0 : TEXCOORD11;\n    float4 fa_inst_d1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_205_fa_joint_rows[_196] * weights[i]);\n        r1 += (_205_fa_joint_rows[_196 + 1] * weights[i]);\n        r2 += (_205_fa_joint_rows[_196 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _454 = { mul(float4(position, 1.0f), model).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _158_fa_uv_scale.xy, color, position };\n    return _454;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _310 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_310, _158_fa_light_vp).z;\n    fa_pre_r0 = float3(_158_fa_light_vp[0].x, _158_fa_light_vp[1].x, _158_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_158_fa_light_vp[0].y, _158_fa_light_vp[1].y, _158_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_158_fa_light_vp[0].z, _158_fa_light_vp[1].z, _158_fa_light_vp[2].z);\n    gl_Position = mul(_310, _158_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _142_boost : packoffset(c0);\n    float _142_fa_pad0 : packoffset(c0.y);\n    float _142_fa_pad1 : packoffset(c0.z);\n    float _142_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _253_fa_camera_pos : packoffset(c0);\n    float4 _253_fa_ambient : packoffset(c1);\n    float4 _253_fa_base_color : packoffset(c2);\n    float4 _253_fa_emissive : packoffset(c3);\n    float4 _253_fa_model_emissive : packoffset(c4);\n    float4 _253_fa_pbr : packoffset(c5);\n    float4 _253_fa_maps : packoffset(c6);\n    float4 _253_fa_fog : packoffset(c7);\n    float4 _253_fa_fog_b : packoffset(c8);\n    float4 _253_fa_fog_c : packoffset(c9);\n    float4 _253_fa_counts : packoffset(c10);\n    float4 _253_fa_env_sky : packoffset(c11);\n    float4 _253_fa_env_horizon : packoffset(c12);\n    float4 _253_fa_time : packoffset(c13);\n    float4 _253_fa_layers_a : packoffset(c14);\n    float4 _253_fa_layers_b : packoffset(c15);\n    float4 _253_fa_layers_c : packoffset(c16);\n    float4 _253_fa_layers_d : packoffset(c17);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    nointerpolation float4 fa_inst_v0 : TEXCOORD0;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD1;\n    float3 fa_world_pos : TEXCOORD2;\n    float3 fa_world_normal : TEXCOORD3;\n    float4 fa_world_tangent : TEXCOORD4;\n    float2 fa_uv : TEXCOORD5;\n    float4 fa_vertex_color : TEXCOORD6;\n    float fa_pre_depth : TEXCOORD7;\n    float3 fa_pre_r0 : TEXCOORD8;\n    float3 fa_pre_r1 : TEXCOORD9;\n    float3 fa_pre_r2 : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    float3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    float3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    float3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _253_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _264 = fa_tex_fix(param_2, param_3);\n    float4 _767 = base_t;\n    _767.x = _264.x;\n    _767.y = _264.y;\n    _767.z = _264.z;\n    base_t = _767;\n    float4 _280 = (_767 * _253_fa_base_color) * i.vertex_color;\n    float3 _730 = i.world_normal;\n    if (_253_fa_maps.z > 0.5f)\n    {\n        float param_4 = _253_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _313 = fa_tex_fix(param_6, param_7);\n        float3 _317 = (_313 * 2.0f) - 1.0f.xxx;\n        float2 _322 = _317.xy * _253_fa_maps.x;\n        float3 _775 = _317;\n        _775.x = _322.x;\n        _775.y = _322.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _775;\n        _730 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _253_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _351 = fa_tex_fix(param_12, param_13);\n    float4 _778 = mrt;\n    _778.x = _351.x;\n    _778.y = _351.y;\n    _778.z = _351.z;\n    mrt = _778;\n    float4 _381 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _253_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = _253_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _423 = fa_tex_fix(param_20, param_21);\n    float _735 = _253_fa_layers_a.x;\n    float _736 = _253_fa_layers_a.y;\n    float _739 = _253_fa_layers_a.z;\n    float _738 = _253_fa_layers_b.w;\n    float _741 = _253_fa_layers_c.x;\n    if (_253_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_253_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _735 *= _393.y;\n            _736 *= _393.z;\n            _738 *= _381.w;\n        }\n        if (_253_fa_layers_c.z > 1.5f)\n        {\n            _739 *= mrt.x;\n            _741 *= mrt.w;\n        }\n    }\n    Surface _760 = { _280.xyz, _280.w, _730, clamp(_253_fa_pbr.x * _351.z, 0.0f, 1.0f), clamp(_253_fa_pbr.y * _351.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_253_fa_maps.y * (_393.x - 1.0f)), _253_fa_emissive.xyz + (_253_fa_model_emissive.xyz * _423), _735, _736, _253_fa_layers_b.xyz, _738, _739, _253_fa_layers_a.w, _741, _253_fa_layers_c.y, _253_fa_layers_d.xyz };\n    return _760;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * _142_boost);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _641 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _641 = -_641;\n    }\n    float3 _554 = normalize(_253_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _654 = { fa_world_pos, _641, fa_world_tangent, fa_uv, fa_vertex_color, _554, gl_FrontFacing };\n    SurfaceInput param = _654;\n    SurfaceInput _662 = { fa_world_pos, _641, fa_world_tangent, fa_uv, fa_vertex_color, _554, gl_FrontFacing };\n    SurfaceInput param_1 = _662;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _569 = normalize(param_2.normal);\n    float3 _584 = normalize(float3(dot(fa_pre_r0, _569), dot(fa_pre_r1, _569), dot(fa_pre_r2, _569)));\n    float _596 = _584.z;\n    float2 e = _584.xy / ((abs(_584.x) + abs(_584.y)) + abs(_596)).xx;\n    if (_596 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 160,
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
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _144_fa_view_proj : packoffset(c0);\n    row_major float4x4 _144_fa_light_vp : packoffset(c4);\n    float4 _144_fa_uv_scale : packoffset(c8);\n    float4 _144_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n    float4 fa_inst_d0 : TEXCOORD9;\n    float4 fa_inst_d1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _85 = cross(model[1].xyz, model[2].xyz);\n    float _91 = (dot(model[0].xyz, _85) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _282 = { mul(float4(position, 1.0f), model).xyz, (((_85 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _91, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _91), texcoord0 * _144_fa_uv_scale.xy, color, position };\n    return _282;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _144_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_144",
            "hlsl_register_b_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _149_fa_view_proj : packoffset(c0);\n    row_major float4x4 _149_fa_light_vp : packoffset(c4);\n    float4 _149_fa_uv_scale : packoffset(c8);\n    float4 _149_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _196_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n    float4 fa_inst_d0 : TEXCOORD11;\n    float4 fa_inst_d1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nstatic float raise;\nstatic float4 tint;\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _187 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_196_fa_joint_rows[_187] * weights[i]);\n        r1 += (_196_fa_joint_rows[_187 + 1] * weights[i]);\n        r2 += (_196_fa_joint_rows[_187 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _90 = cross(model[1].xyz, model[2].xyz);\n    float _96 = (dot(model[0].xyz, _90) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _402 = { mul(float4(position, 1.0f), model).xyz, (((_90 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _96, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _96), texcoord0 * _149_fa_uv_scale.xy, color, position };\n    return _402;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mul(float4(param_8.world_pos, 1.0f), _149_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "size": 160,
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
