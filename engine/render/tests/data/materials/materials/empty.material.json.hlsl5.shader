{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "67b1186c6e51021b07dd68cec7aaad42a4febc7364ef358b4473bc1e089911c0",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    float4 _167 = float4(_270, 1.0f);\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_shadow_pos = mul(_167, _131_fa_light_vp);\n    gl_Position = mul(_167, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _790[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _246_fa_light_pos[32] : packoffset(c0);\n    float4 _246_fa_light_color[32] : packoffset(c32);\n    float4 _246_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _364_fa_camera_pos : packoffset(c0);\n    float4 _364_fa_ambient : packoffset(c1);\n    float4 _364_fa_base_color : packoffset(c2);\n    float4 _364_fa_emissive : packoffset(c3);\n    float4 _364_fa_model_emissive : packoffset(c4);\n    float4 _364_fa_pbr : packoffset(c5);\n    float4 _364_fa_maps : packoffset(c6);\n    float4 _364_fa_fog : packoffset(c7);\n    float4 _364_fa_fog_b : packoffset(c8);\n    float4 _364_fa_fog_c : packoffset(c9);\n    float4 _364_fa_counts : packoffset(c10);\n    float4 _364_fa_env_sky : packoffset(c11);\n    float4 _364_fa_env_horizon : packoffset(c12);\n    float4 _364_fa_time : packoffset(c13);\n    float4 _364_fa_layers_a : packoffset(c14);\n    float4 _364_fa_layers_b : packoffset(c15);\n    float4 _364_fa_layers_c : packoffset(c16);\n    float4 _364_fa_layers_d : packoffset(c17);\n};\n\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1691 = fa_linear_to_srgb(param);\n        c = _1691;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1699 = fa_srgb_to_linear(param_1);\n            c = _1699;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _174;\n    if (i.front_facing)\n    {\n        _174 = i.world_normal;\n    }\n    else\n    {\n        _174 = -i.world_normal;\n    }\n    float3 _198 = normalize(i.world_tangent.xyz - (_174 * dot(_174, i.world_tangent.xyz)));\n    float3 _226 = normalize(((_198 * m.x) + ((cross(_174, _198) * i.world_tangent.w) * m.y)) + (_174 * m.z));\n    float3 _229;\n    if (i.front_facing)\n    {\n        _229 = _226;\n    }\n    else\n    {\n        _229 = -_226;\n    }\n    return _229;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _364_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1730 = fa_tex_fix(param_2, param_3);\n    float4 _2887 = base_t;\n    _2887.x = _1730.x;\n    _2887.y = _1730.y;\n    _2887.z = _1730.z;\n    base_t = _2887;\n    float4 _1744 = (_2887 * _364_fa_base_color) * i.vertex_color;\n    float3 _2830 = i.world_normal;\n    if (_364_fa_maps.z > 0.5f)\n    {\n        float param_4 = _364_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1777 = fa_tex_fix(param_6, param_7);\n        float3 _1780 = (_1777 * 2.0f) - 1.0f.xxx;\n        float2 _1785 = _1780.xy * _364_fa_maps.x;\n        float3 _2895 = _1780;\n        _2895.x = _1785.x;\n        _2895.y = _1785.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2895;\n        _2830 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _364_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1814 = fa_tex_fix(param_12, param_13);\n    float4 _2898 = mrt;\n    _2898.x = _1814.x;\n    _2898.y = _1814.y;\n    _2898.z = _1814.z;\n    mrt = _2898;\n    float4 _1842 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _364_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _1842.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1854 = fa_tex_fix(param_16, param_17);\n    float param_18 = _364_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1884 = fa_tex_fix(param_20, param_21);\n    float _2835 = _364_fa_layers_a.x;\n    float _2836 = _364_fa_layers_a.y;\n    float _2839 = _364_fa_layers_a.z;\n    float _2838 = _364_fa_layers_b.w;\n    float _2841 = _364_fa_layers_c.x;\n    if (_364_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_364_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _2835 *= _1854.y;\n            _2836 *= _1854.z;\n            _2838 *= _1842.w;\n        }\n        if (_364_fa_layers_c.z > 1.5f)\n        {\n            _2839 *= mrt.x;\n            _2841 *= mrt.w;\n        }\n    }\n    Surface _2860 = { _1744.xyz, _1744.w, _2830, clamp(_364_fa_pbr.x * _1814.z, 0.0f, 1.0f), clamp(_364_fa_pbr.y * _1814.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_364_fa_maps.y * (_1854.x - 1.0f)), _364_fa_emissive.xyz + (_364_fa_model_emissive.xyz * _1884), _2835, _2836, _364_fa_layers_b.xyz, _2838, _2839, _364_fa_layers_a.w, _2841, _364_fa_layers_c.y, _364_fa_layers_d.xyz };\n    return _2860;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _715 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _723 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _726 = int(_715);\n    int _729 = int(_723);\n    float _739 = _723 - float(_729);\n    int _795 = (_726 * 9) + _729;\n    int _815 = ((_726 + 1) * 9) + _729;\n    return lerp(lerp(_790[_795], _790[_795 + 1], _739), lerp(_790[_815], _790[_815 + 1], _739), _715 - float(_726));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _2766 = false;\n    float _2767 = 1.0f;\n    float _2768 = 1.0f;\n    float _2769 = 1.0f;\n    float _2770 = 0.0f;\n    float _2771 = 0.0f;\n    float _2772 = 0.0f;\n    float _2773 = 0.0f;\n    float _2775 = 1.0f;\n    bool _2776 = false;\n    float3 _2777 = 0.0f.xxx;\n    float _2778 = 1.0f;\n    float _2779 = 1.0f;\n    float _2780 = 1.0f;\n    float _2781 = 0.0f;\n    float _2782 = 0.0f;\n    float3 _2783 = float3(1.0f, 0.0f, 0.0f);\n    float3 _2784 = float3(0.0f, 0.0f, 1.0f);\n    float _2785 = 1.0f;\n    float _2786 = 1.0f;\n    float _877 = clamp(s.specular, 0.0f, 1.0f);\n    float _882 = clamp(s.ior, 1.0f, 3.0f);\n    bool _887 = (_877 != 1.0f) || (_882 != 1.5f);\n    bool _897;\n    if (!_887)\n    {\n        _897 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _897 = _887;\n    }\n    if (_897)\n    {\n        float _905 = (_882 - 1.0f) / (_882 + 1.0f);\n        f0 = lerp(min((_905 * _905).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _877, s.albedo, metallic.xxx);\n        _2767 = lerp(_877, 1.0f, metallic);\n        _2766 = true;\n    }\n    float _933 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_933 > 0.0f)\n    {\n        float _941 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _2770 = _933;\n        _2771 = _941;\n        float _948 = _941 * _941;\n        _2772 = _948;\n        _2773 = _948 * _948;\n        float _960 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _2775 = _960;\n        _2768 = 1.0f - (_933 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _960, 0.0f, 1.0f), 5.0f))));\n        _2766 = true;\n    }\n    float3 _980 = max(s.sheen_color, 0.0f.xxx);\n    float _989 = max(_980.x, max(_980.y, _980.z));\n    if (_989 > 0.0f)\n    {\n        float _997 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _2776 = true;\n        _2777 = _980;\n        _2778 = _997;\n        _2779 = _997 * _997;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _997;\n        float _1014 = fa_sheen_albedo(param, param_1);\n        _2781 = _1014;\n        _2780 = 1.0f - min(_989 * _1014, 1.0f);\n        _2766 = true;\n    }\n    _2769 = _2768 * _2780;\n    float _1033 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_1033 != 0.0f)\n    {\n        float3 _1048 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1048;\n        if (dot(_1048, _1048) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _1062 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_1062.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _1062.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _1062.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _1066 = t;\n        float3 _1067 = normalize(_1066);\n        t = _1067;\n        float3 _1092 = normalize((_1067 * cos(s.anisotropy_rotation)) + ((cross(n, _1067) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _2783 = _1092;\n        _2784 = cross(n, _1092);\n        float _1102 = roughness * roughness;\n        float _1108 = lerp(_1102, 1.0f, _1033 * _1033);\n        bool _1110 = _1033 > 0.0f;\n        _2785 = _1110 ? _1108 : _1102;\n        _2786 = _1110 ? _1102 : _1108;\n        _2782 = _1033;\n        _2766 = true;\n    }\n    FaLayers _2808 = { _2766, _2767, _2768, _2769, _2770, _2771, _2772, _2773, i.world_normal, _2775, _2776, _2777, _2778, _2779, _2780, _2781, _2782, _2783, _2784, _2785, _2786 };\n    return _2808;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_364_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _364_fa_ambient.xyz;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _257 = _246_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_257)\n    {\n        l = normalize(_246_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _275 = _246_fa_light_pos[li].xyz - world_pos;\n        float _277 = length(_275);\n        dist = _277;\n        l = _275 / max(_277, 9.9999997473787516355514526367188e-05f).xxx;\n        float _293 = _277 / max(_246_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _299 = clamp(1.0f - (_293 * _293), 0.0f, 1.0f);\n        atten = _299 * _299;\n        if (_246_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_246_fa_light_dir[li].w, lerp(_246_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_246_fa_light_dir[li].xyz)));\n        }\n    }\n    int _350;\n    if (_257)\n    {\n        _350 = 0;\n    }\n    else\n    {\n        _350 = (_246_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _2765 = { l, _246_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _350 };\n    return _2765;\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_364_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _377 = coord.xyz / coord.w.xxx;\n    float3 p = _377;\n    float2 suv = (_377.xy * 0.5f) + 0.5f.xx;\n    if (_364_fa_counts.z > 0.5f)\n    {\n        float3 _2862 = p;\n        _2862.z = (_2862.z * 0.5f) + 0.5f;\n        p = _2862;\n    }\n    else\n    {\n        float2 _2865 = suv;\n        _2865.y = 1.0f - _2865.y;\n        suv = _2865;\n    }\n    bool _405 = suv.x < 0.0f;\n    bool _412;\n    if (!_405)\n    {\n        _412 = suv.x > 1.0f;\n    }\n    else\n    {\n        _412 = _405;\n    }\n    bool _419;\n    if (!_412)\n    {\n        _419 = suv.y < 0.0f;\n    }\n    else\n    {\n        _419 = _412;\n    }\n    bool _426;\n    if (!_419)\n    {\n        _426 = suv.y > 1.0f;\n    }\n    else\n    {\n        _426 = _419;\n    }\n    bool _433;\n    if (!_426)\n    {\n        _433 = p.z > 1.0f;\n    }\n    else\n    {\n        _433 = _426;\n    }\n    if (_433)\n    {\n        return 1.0f;\n    }\n    float _448 = _364_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _448) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _364_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1614 = fa_light_sample(param, param_1);\n    float3 _2815 = _1614.direction;\n    float3 _2810 = _1614.color;\n    float _2817 = _1614.attenuation;\n    float _2812 = _1614.shadow;\n    int _2820 = _1614.type;\n    if ((_2820 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2815;\n        float _1628 = fa_shadow_factor(param_2, param_3);\n        _2812 = _1628;\n        _2810 = _246_fa_light_color[li].xyz * (_2817 * _1628);\n    }\n    LightSample _2827 = { _2815, _2810, _2817, _2812, _1614._distance, _2820 };\n    return _2827;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _1260 = tdh / at;\n    float _1264 = bdh / ab;\n    float _1276 = ((_1260 * _1260) + (_1264 * _1264)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _1276) * _1276);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _1358 = 1.0f / alpha;\n    return ((2.0f + _1358) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _1358)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _1391 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _1470 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _1470) * _1470);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _1391);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _1391));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _1543 = max(dot(L.nc, l), 0.0f);\n        float _1549 = max(dot(L.nc, h), 0.0f);\n        float _1558 = ((_1549 * _1549) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _1558) * _1558)) * (0.5f / max(lerp((2.0f * _1543) * L.coat_ndv, _1543 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _1543)) * _1543).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _645 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _648 = _645.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_648 * _648, exp2((-9.27999973297119140625f) * ndv)) * _648) + _645.y)) + _645.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_364_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _364_fa_env_horizon.w).xyz;\n    }\n    float _548 = rough * rough;\n    float _579 = 0.60000002384185791015625f * _548;\n    return lerp(lerp(_364_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_364_fa_env_horizon.xyz, _364_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _548)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _579, 0.0500000007450580596923828125f + _579, d.y).xxx), ((_364_fa_env_sky.xyz + _364_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_548 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _1143;\n        if (L.aniso >= 0.0f)\n        {\n            _1143 = L.b;\n        }\n        else\n        {\n            _1143 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_1143, v), _1143), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1176 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _1176.x) + (L.f90.xxx * _1176.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1231 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _1231.x) + _1231.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _687 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _687.x) + _687.y.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2545 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2545 = -_2545;\n    }\n    float3 _2004 = normalize(_364_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _2558 = { fa_world_pos, _2545, fa_world_tangent, fa_uv, fa_vertex_color, _2004, gl_FrontFacing };\n    SurfaceInput param = _2558;\n    Surface _2009 = fa_standard_surface(param);\n    float3 _2576 = _2009.albedo;\n    float _2577 = _2009.alpha;\n    float3 _2578 = _2009.normal;\n    float _2579 = _2009.metallic;\n    float _2580 = _2009.roughness;\n    float _2581 = _2009.occlusion;\n    float3 _2582 = _2009.emission;\n    float _2583 = _2009.clearcoat;\n    float _2584 = _2009.clearcoat_roughness;\n    float3 _2585 = _2009.sheen_color;\n    float _2586 = _2009.sheen_roughness;\n    float _2587 = _2009.anisotropy;\n    float _2588 = _2009.anisotropy_rotation;\n    float _2589 = _2009.specular;\n    float _2590 = _2009.ior;\n    float3 _2591 = _2009.specular_color;\n    SurfaceInput _2566 = { fa_world_pos, _2545, fa_world_tangent, fa_uv, fa_vertex_color, _2004, gl_FrontFacing };\n    SurfaceInput param_1 = _2566;\n    Surface param_2 = _2009;\n    surface(param_1, param_2);\n    _2576 = param_2.albedo;\n    _2577 = param_2.alpha;\n    _2578 = param_2.normal;\n    _2579 = param_2.metallic;\n    _2580 = param_2.roughness;\n    _2581 = param_2.occlusion;\n    _2582 = param_2.emission;\n    _2583 = param_2.clearcoat;\n    _2584 = param_2.clearcoat_roughness;\n    _2585 = param_2.sheen_color;\n    _2586 = param_2.sheen_roughness;\n    _2587 = param_2.anisotropy;\n    _2588 = param_2.anisotropy_rotation;\n    _2589 = param_2.specular;\n    _2590 = param_2.ior;\n    _2591 = param_2.specular_color;\n    float3 result;\n    if (_364_fa_emissive.w > 0.5f)\n    {\n        result = _2576;\n    }\n    else\n    {\n        float3 _2031 = normalize(_2578);\n        float _2038 = clamp(_2579, 0.0f, 1.0f);\n        float _2042 = clamp(_2580, 0.0500000007450580596923828125f, 1.0f);\n        float _2046 = _2042 * _2042;\n        float _2050 = _2046 * _2046;\n        float _2055 = max(dot(_2031, _2004), 9.9999997473787516355514526367188e-05f);\n        float3 _2061 = _2576 * (1.0f - _2038);\n        float3 _2068 = lerp(0.039999999105930328369140625f.xxx, _2576, _2038.xxx);\n        float3 f0 = _2068;\n        SurfaceInput _2574 = { fa_world_pos, _2545, fa_world_tangent, fa_uv, fa_vertex_color, _2004, gl_FrontFacing };\n        SurfaceInput param_3 = _2574;\n        Surface _2657 = { _2576, _2577, _2578, _2579, _2580, _2581, _2582, _2583, _2584, _2585, _2586, _2587, _2588, _2589, _2590, _2591 };\n        Surface param_4 = _2657;\n        float3 param_5 = _2031;\n        float3 param_6 = _2004;\n        float param_7 = _2038;\n        float param_8 = _2042;\n        float3 param_9 = _2068;\n        FaLayers _2084 = fa_layers_setup(param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n        f0 = param_9;\n        float3 param_10 = _2031;\n        float3 lit = (fa_ambient_light(param_10) * _2061) * _2581;\n        if (_2084.on)\n        {\n            lit *= _2084.base_scale;\n        }\n        int _2106 = int(_364_fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _2106)\n            {\n                break;\n            }\n            int param_11 = li;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _2545;\n            LightSample _2130 = fa_light_shadowed(param_11, param_12, param_13);\n            float3 _2750 = _2130.direction;\n            float _2138 = max(dot(_2031, _2750), 0.0f);\n            float _2144 = _2130.attenuation * _2130.shadow;\n            float3 _2149 = normalize(_2750 + _2004);\n            float _2154 = max(dot(_2031, _2149), 0.0f);\n            float _2159 = max(dot(_2004, _2149), 0.0f);\n            if (_2084.on)\n            {\n                FaLayers param_14 = _2084;\n                float3 param_15 = _2061;\n                float3 param_16 = f0;\n                float3 param_17 = _2031;\n                float3 param_18 = _2004;\n                float3 param_19 = _2750;\n                float3 param_20 = _2149;\n                float param_21 = _2138;\n                float param_22 = _2055;\n                float param_23 = _2154;\n                float param_24 = _2159;\n                float param_25 = _2046;\n                float param_26 = _2050;\n                lit += (fa_layers_light(param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26) * (_246_fa_light_color[li].xyz * _2144));\n            }\n            else\n            {\n                float _2208 = ((_2154 * _2154) * (_2050 - 1.0f)) + 1.0f;\n                lit += (((_2061 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _2159, 5.0f))) * (((_2050 / ((3.1415927410125732421875f * _2208) * _2208)) * (0.5f / max(lerp((2.0f * _2138) * _2055, _2138 + _2055, _2046), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2138))) * _246_fa_light_color[li].xyz) * (_2138 * _2144));\n            }\n        }\n        if (_2084.on)\n        {\n            FaLayers param_27 = _2084;\n            float3 param_28 = _2031;\n            float3 param_29 = _2004;\n            float3 param_30 = f0;\n            float param_31 = _2042;\n            lit += (fa_layers_ibl(param_27, param_28, param_29, param_30, param_31) * _2581);\n        }\n        else\n        {\n            float3 param_32 = _2031;\n            float3 param_33 = _2004;\n            float3 param_34 = f0;\n            float param_35 = _2042;\n            lit += (fa_sky_reflection(param_32, param_33, param_34, param_35) * _2581);\n        }\n        result = lit;\n    }\n    result += _2582;\n    bool _2306 = _364_fa_fog.w > 0.0f;\n    bool _2313;\n    if (!_2306)\n    {\n        _2313 = _364_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2313 = _2306;\n    }\n    if (_2313)\n    {\n        float3 _2322 = fa_world_pos - _364_fa_camera_pos.xyz;\n        float _2328 = dot(_2322, _364_fa_fog_c.xyz);\n        bool _2332 = _364_fa_fog_c.w > 0.5f;\n        float _2333;\n        if (_2332)\n        {\n            _2333 = _2328;\n        }\n        else\n        {\n            _2333 = length(_2322);\n        }\n        float _2345 = _2333 - _364_fa_fog_b.x;\n        if (_2345 > 0.0f)\n        {\n            float _2354 = _364_fa_fog.w * _2345;\n            float tau = _2354 * _2354;\n            if (_364_fa_fog_b.y > 0.0f)\n            {\n                float _2370;\n                if (_2332)\n                {\n                    _2370 = fa_world_pos.y - (_364_fa_fog_c.y * _2328);\n                }\n                else\n                {\n                    _2370 = _364_fa_camera_pos.y;\n                }\n                float _2391 = lerp(_2370, fa_world_pos.y, clamp(_364_fa_fog_b.x / _2333, 0.0f, 1.0f));\n                float _2395 = fa_world_pos.y - _2391;\n                float _2400 = _2391 - _364_fa_fog_b.z;\n                float _2405 = fa_world_pos.y - _364_fa_fog_b.z;\n                bool _2408 = _2400 <= 0.0f;\n                bool _2409 = !_2408;\n                bool _2415;\n                if (_2409)\n                {\n                    _2415 = _364_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2415 = _2408;\n                }\n                float _2416;\n                if (_2415)\n                {\n                    _2416 = _364_fa_fog_b.y;\n                }\n                else\n                {\n                    _2416 = _364_fa_fog_b.y * exp(-min(_364_fa_fog_b.w * _2400, 80.0f));\n                }\n                bool _2443;\n                if (_2409)\n                {\n                    _2443 = _364_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2443 = _2408;\n                }\n                float _2444;\n                if (_2443)\n                {\n                    _2444 = _364_fa_fog_b.y * _2400;\n                }\n                else\n                {\n                    _2444 = (_364_fa_fog_b.y * (1.0f - exp(-min(_364_fa_fog_b.w * _2400, 80.0f)))) / _364_fa_fog_b.w;\n                }\n                bool _2469 = _2405 <= 0.0f;\n                bool _2476;\n                if (!_2469)\n                {\n                    _2476 = _364_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2476 = _2469;\n                }\n                float _2477;\n                if (_2476)\n                {\n                    _2477 = _364_fa_fog_b.y * _2405;\n                }\n                else\n                {\n                    _2477 = (_364_fa_fog_b.y * (1.0f - exp(-min(_364_fa_fog_b.w * _2405, 80.0f)))) / _364_fa_fog_b.w;\n                }\n                float _2504;\n                if (abs(_2395) < 0.001000000047497451305389404296875f)\n                {\n                    _2504 = _2416;\n                }\n                else\n                {\n                    _2504 = (_2477 - _2444) / _2395;\n                }\n                tau += (_2345 * max(_2504, 0.0f));\n            }\n            result = lerp(result, _364_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2577);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_246",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_364",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _384 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _384;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _391 = _273.world_pos;\n    float4 _280 = float4(_391, 1.0f);\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_shadow_pos = mul(_280, _136_fa_light_vp);\n    gl_Position = mul(_280, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _790[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _246_fa_light_pos[32] : packoffset(c0);\n    float4 _246_fa_light_color[32] : packoffset(c32);\n    float4 _246_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _364_fa_camera_pos : packoffset(c0);\n    float4 _364_fa_ambient : packoffset(c1);\n    float4 _364_fa_base_color : packoffset(c2);\n    float4 _364_fa_emissive : packoffset(c3);\n    float4 _364_fa_model_emissive : packoffset(c4);\n    float4 _364_fa_pbr : packoffset(c5);\n    float4 _364_fa_maps : packoffset(c6);\n    float4 _364_fa_fog : packoffset(c7);\n    float4 _364_fa_fog_b : packoffset(c8);\n    float4 _364_fa_fog_c : packoffset(c9);\n    float4 _364_fa_counts : packoffset(c10);\n    float4 _364_fa_env_sky : packoffset(c11);\n    float4 _364_fa_env_horizon : packoffset(c12);\n    float4 _364_fa_time : packoffset(c13);\n    float4 _364_fa_layers_a : packoffset(c14);\n    float4 _364_fa_layers_b : packoffset(c15);\n    float4 _364_fa_layers_c : packoffset(c16);\n    float4 _364_fa_layers_d : packoffset(c17);\n};\n\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1691 = fa_linear_to_srgb(param);\n        c = _1691;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1699 = fa_srgb_to_linear(param_1);\n            c = _1699;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _174;\n    if (i.front_facing)\n    {\n        _174 = i.world_normal;\n    }\n    else\n    {\n        _174 = -i.world_normal;\n    }\n    float3 _198 = normalize(i.world_tangent.xyz - (_174 * dot(_174, i.world_tangent.xyz)));\n    float3 _226 = normalize(((_198 * m.x) + ((cross(_174, _198) * i.world_tangent.w) * m.y)) + (_174 * m.z));\n    float3 _229;\n    if (i.front_facing)\n    {\n        _229 = _226;\n    }\n    else\n    {\n        _229 = -_226;\n    }\n    return _229;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _364_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1730 = fa_tex_fix(param_2, param_3);\n    float4 _2887 = base_t;\n    _2887.x = _1730.x;\n    _2887.y = _1730.y;\n    _2887.z = _1730.z;\n    base_t = _2887;\n    float4 _1744 = (_2887 * _364_fa_base_color) * i.vertex_color;\n    float3 _2830 = i.world_normal;\n    if (_364_fa_maps.z > 0.5f)\n    {\n        float param_4 = _364_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1777 = fa_tex_fix(param_6, param_7);\n        float3 _1780 = (_1777 * 2.0f) - 1.0f.xxx;\n        float2 _1785 = _1780.xy * _364_fa_maps.x;\n        float3 _2895 = _1780;\n        _2895.x = _1785.x;\n        _2895.y = _1785.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2895;\n        _2830 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _364_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1814 = fa_tex_fix(param_12, param_13);\n    float4 _2898 = mrt;\n    _2898.x = _1814.x;\n    _2898.y = _1814.y;\n    _2898.z = _1814.z;\n    mrt = _2898;\n    float4 _1842 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _364_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _1842.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1854 = fa_tex_fix(param_16, param_17);\n    float param_18 = _364_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1884 = fa_tex_fix(param_20, param_21);\n    float _2835 = _364_fa_layers_a.x;\n    float _2836 = _364_fa_layers_a.y;\n    float _2839 = _364_fa_layers_a.z;\n    float _2838 = _364_fa_layers_b.w;\n    float _2841 = _364_fa_layers_c.x;\n    if (_364_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_364_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _2835 *= _1854.y;\n            _2836 *= _1854.z;\n            _2838 *= _1842.w;\n        }\n        if (_364_fa_layers_c.z > 1.5f)\n        {\n            _2839 *= mrt.x;\n            _2841 *= mrt.w;\n        }\n    }\n    Surface _2860 = { _1744.xyz, _1744.w, _2830, clamp(_364_fa_pbr.x * _1814.z, 0.0f, 1.0f), clamp(_364_fa_pbr.y * _1814.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_364_fa_maps.y * (_1854.x - 1.0f)), _364_fa_emissive.xyz + (_364_fa_model_emissive.xyz * _1884), _2835, _2836, _364_fa_layers_b.xyz, _2838, _2839, _364_fa_layers_a.w, _2841, _364_fa_layers_c.y, _364_fa_layers_d.xyz };\n    return _2860;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _715 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _723 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _726 = int(_715);\n    int _729 = int(_723);\n    float _739 = _723 - float(_729);\n    int _795 = (_726 * 9) + _729;\n    int _815 = ((_726 + 1) * 9) + _729;\n    return lerp(lerp(_790[_795], _790[_795 + 1], _739), lerp(_790[_815], _790[_815 + 1], _739), _715 - float(_726));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _2766 = false;\n    float _2767 = 1.0f;\n    float _2768 = 1.0f;\n    float _2769 = 1.0f;\n    float _2770 = 0.0f;\n    float _2771 = 0.0f;\n    float _2772 = 0.0f;\n    float _2773 = 0.0f;\n    float _2775 = 1.0f;\n    bool _2776 = false;\n    float3 _2777 = 0.0f.xxx;\n    float _2778 = 1.0f;\n    float _2779 = 1.0f;\n    float _2780 = 1.0f;\n    float _2781 = 0.0f;\n    float _2782 = 0.0f;\n    float3 _2783 = float3(1.0f, 0.0f, 0.0f);\n    float3 _2784 = float3(0.0f, 0.0f, 1.0f);\n    float _2785 = 1.0f;\n    float _2786 = 1.0f;\n    float _877 = clamp(s.specular, 0.0f, 1.0f);\n    float _882 = clamp(s.ior, 1.0f, 3.0f);\n    bool _887 = (_877 != 1.0f) || (_882 != 1.5f);\n    bool _897;\n    if (!_887)\n    {\n        _897 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _897 = _887;\n    }\n    if (_897)\n    {\n        float _905 = (_882 - 1.0f) / (_882 + 1.0f);\n        f0 = lerp(min((_905 * _905).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _877, s.albedo, metallic.xxx);\n        _2767 = lerp(_877, 1.0f, metallic);\n        _2766 = true;\n    }\n    float _933 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_933 > 0.0f)\n    {\n        float _941 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _2770 = _933;\n        _2771 = _941;\n        float _948 = _941 * _941;\n        _2772 = _948;\n        _2773 = _948 * _948;\n        float _960 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _2775 = _960;\n        _2768 = 1.0f - (_933 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _960, 0.0f, 1.0f), 5.0f))));\n        _2766 = true;\n    }\n    float3 _980 = max(s.sheen_color, 0.0f.xxx);\n    float _989 = max(_980.x, max(_980.y, _980.z));\n    if (_989 > 0.0f)\n    {\n        float _997 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _2776 = true;\n        _2777 = _980;\n        _2778 = _997;\n        _2779 = _997 * _997;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _997;\n        float _1014 = fa_sheen_albedo(param, param_1);\n        _2781 = _1014;\n        _2780 = 1.0f - min(_989 * _1014, 1.0f);\n        _2766 = true;\n    }\n    _2769 = _2768 * _2780;\n    float _1033 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_1033 != 0.0f)\n    {\n        float3 _1048 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1048;\n        if (dot(_1048, _1048) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _1062 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_1062.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _1062.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _1062.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _1066 = t;\n        float3 _1067 = normalize(_1066);\n        t = _1067;\n        float3 _1092 = normalize((_1067 * cos(s.anisotropy_rotation)) + ((cross(n, _1067) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _2783 = _1092;\n        _2784 = cross(n, _1092);\n        float _1102 = roughness * roughness;\n        float _1108 = lerp(_1102, 1.0f, _1033 * _1033);\n        bool _1110 = _1033 > 0.0f;\n        _2785 = _1110 ? _1108 : _1102;\n        _2786 = _1110 ? _1102 : _1108;\n        _2782 = _1033;\n        _2766 = true;\n    }\n    FaLayers _2808 = { _2766, _2767, _2768, _2769, _2770, _2771, _2772, _2773, i.world_normal, _2775, _2776, _2777, _2778, _2779, _2780, _2781, _2782, _2783, _2784, _2785, _2786 };\n    return _2808;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_364_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _364_fa_ambient.xyz;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _257 = _246_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_257)\n    {\n        l = normalize(_246_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _275 = _246_fa_light_pos[li].xyz - world_pos;\n        float _277 = length(_275);\n        dist = _277;\n        l = _275 / max(_277, 9.9999997473787516355514526367188e-05f).xxx;\n        float _293 = _277 / max(_246_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _299 = clamp(1.0f - (_293 * _293), 0.0f, 1.0f);\n        atten = _299 * _299;\n        if (_246_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_246_fa_light_dir[li].w, lerp(_246_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_246_fa_light_dir[li].xyz)));\n        }\n    }\n    int _350;\n    if (_257)\n    {\n        _350 = 0;\n    }\n    else\n    {\n        _350 = (_246_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _2765 = { l, _246_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _350 };\n    return _2765;\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_364_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _377 = coord.xyz / coord.w.xxx;\n    float3 p = _377;\n    float2 suv = (_377.xy * 0.5f) + 0.5f.xx;\n    if (_364_fa_counts.z > 0.5f)\n    {\n        float3 _2862 = p;\n        _2862.z = (_2862.z * 0.5f) + 0.5f;\n        p = _2862;\n    }\n    else\n    {\n        float2 _2865 = suv;\n        _2865.y = 1.0f - _2865.y;\n        suv = _2865;\n    }\n    bool _405 = suv.x < 0.0f;\n    bool _412;\n    if (!_405)\n    {\n        _412 = suv.x > 1.0f;\n    }\n    else\n    {\n        _412 = _405;\n    }\n    bool _419;\n    if (!_412)\n    {\n        _419 = suv.y < 0.0f;\n    }\n    else\n    {\n        _419 = _412;\n    }\n    bool _426;\n    if (!_419)\n    {\n        _426 = suv.y > 1.0f;\n    }\n    else\n    {\n        _426 = _419;\n    }\n    bool _433;\n    if (!_426)\n    {\n        _433 = p.z > 1.0f;\n    }\n    else\n    {\n        _433 = _426;\n    }\n    if (_433)\n    {\n        return 1.0f;\n    }\n    float _448 = _364_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _448) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _364_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1614 = fa_light_sample(param, param_1);\n    float3 _2815 = _1614.direction;\n    float3 _2810 = _1614.color;\n    float _2817 = _1614.attenuation;\n    float _2812 = _1614.shadow;\n    int _2820 = _1614.type;\n    if ((_2820 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2815;\n        float _1628 = fa_shadow_factor(param_2, param_3);\n        _2812 = _1628;\n        _2810 = _246_fa_light_color[li].xyz * (_2817 * _1628);\n    }\n    LightSample _2827 = { _2815, _2810, _2817, _2812, _1614._distance, _2820 };\n    return _2827;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _1260 = tdh / at;\n    float _1264 = bdh / ab;\n    float _1276 = ((_1260 * _1260) + (_1264 * _1264)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _1276) * _1276);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _1358 = 1.0f / alpha;\n    return ((2.0f + _1358) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _1358)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _1391 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _1470 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _1470) * _1470);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _1391);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _1391));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _1543 = max(dot(L.nc, l), 0.0f);\n        float _1549 = max(dot(L.nc, h), 0.0f);\n        float _1558 = ((_1549 * _1549) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _1558) * _1558)) * (0.5f / max(lerp((2.0f * _1543) * L.coat_ndv, _1543 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _1543)) * _1543).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _645 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _648 = _645.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_648 * _648, exp2((-9.27999973297119140625f) * ndv)) * _648) + _645.y)) + _645.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_364_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _364_fa_env_horizon.w).xyz;\n    }\n    float _548 = rough * rough;\n    float _579 = 0.60000002384185791015625f * _548;\n    return lerp(lerp(_364_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_364_fa_env_horizon.xyz, _364_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _548)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _579, 0.0500000007450580596923828125f + _579, d.y).xxx), ((_364_fa_env_sky.xyz + _364_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_548 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _1143;\n        if (L.aniso >= 0.0f)\n        {\n            _1143 = L.b;\n        }\n        else\n        {\n            _1143 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_1143, v), _1143), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1176 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _1176.x) + (L.f90.xxx * _1176.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1231 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _1231.x) + _1231.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _687 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _687.x) + _687.y.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2545 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2545 = -_2545;\n    }\n    float3 _2004 = normalize(_364_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _2558 = { fa_world_pos, _2545, fa_world_tangent, fa_uv, fa_vertex_color, _2004, gl_FrontFacing };\n    SurfaceInput param = _2558;\n    Surface _2009 = fa_standard_surface(param);\n    float3 _2576 = _2009.albedo;\n    float _2577 = _2009.alpha;\n    float3 _2578 = _2009.normal;\n    float _2579 = _2009.metallic;\n    float _2580 = _2009.roughness;\n    float _2581 = _2009.occlusion;\n    float3 _2582 = _2009.emission;\n    float _2583 = _2009.clearcoat;\n    float _2584 = _2009.clearcoat_roughness;\n    float3 _2585 = _2009.sheen_color;\n    float _2586 = _2009.sheen_roughness;\n    float _2587 = _2009.anisotropy;\n    float _2588 = _2009.anisotropy_rotation;\n    float _2589 = _2009.specular;\n    float _2590 = _2009.ior;\n    float3 _2591 = _2009.specular_color;\n    SurfaceInput _2566 = { fa_world_pos, _2545, fa_world_tangent, fa_uv, fa_vertex_color, _2004, gl_FrontFacing };\n    SurfaceInput param_1 = _2566;\n    Surface param_2 = _2009;\n    surface(param_1, param_2);\n    _2576 = param_2.albedo;\n    _2577 = param_2.alpha;\n    _2578 = param_2.normal;\n    _2579 = param_2.metallic;\n    _2580 = param_2.roughness;\n    _2581 = param_2.occlusion;\n    _2582 = param_2.emission;\n    _2583 = param_2.clearcoat;\n    _2584 = param_2.clearcoat_roughness;\n    _2585 = param_2.sheen_color;\n    _2586 = param_2.sheen_roughness;\n    _2587 = param_2.anisotropy;\n    _2588 = param_2.anisotropy_rotation;\n    _2589 = param_2.specular;\n    _2590 = param_2.ior;\n    _2591 = param_2.specular_color;\n    float3 result;\n    if (_364_fa_emissive.w > 0.5f)\n    {\n        result = _2576;\n    }\n    else\n    {\n        float3 _2031 = normalize(_2578);\n        float _2038 = clamp(_2579, 0.0f, 1.0f);\n        float _2042 = clamp(_2580, 0.0500000007450580596923828125f, 1.0f);\n        float _2046 = _2042 * _2042;\n        float _2050 = _2046 * _2046;\n        float _2055 = max(dot(_2031, _2004), 9.9999997473787516355514526367188e-05f);\n        float3 _2061 = _2576 * (1.0f - _2038);\n        float3 _2068 = lerp(0.039999999105930328369140625f.xxx, _2576, _2038.xxx);\n        float3 f0 = _2068;\n        SurfaceInput _2574 = { fa_world_pos, _2545, fa_world_tangent, fa_uv, fa_vertex_color, _2004, gl_FrontFacing };\n        SurfaceInput param_3 = _2574;\n        Surface _2657 = { _2576, _2577, _2578, _2579, _2580, _2581, _2582, _2583, _2584, _2585, _2586, _2587, _2588, _2589, _2590, _2591 };\n        Surface param_4 = _2657;\n        float3 param_5 = _2031;\n        float3 param_6 = _2004;\n        float param_7 = _2038;\n        float param_8 = _2042;\n        float3 param_9 = _2068;\n        FaLayers _2084 = fa_layers_setup(param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n        f0 = param_9;\n        float3 param_10 = _2031;\n        float3 lit = (fa_ambient_light(param_10) * _2061) * _2581;\n        if (_2084.on)\n        {\n            lit *= _2084.base_scale;\n        }\n        int _2106 = int(_364_fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _2106)\n            {\n                break;\n            }\n            int param_11 = li;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _2545;\n            LightSample _2130 = fa_light_shadowed(param_11, param_12, param_13);\n            float3 _2750 = _2130.direction;\n            float _2138 = max(dot(_2031, _2750), 0.0f);\n            float _2144 = _2130.attenuation * _2130.shadow;\n            float3 _2149 = normalize(_2750 + _2004);\n            float _2154 = max(dot(_2031, _2149), 0.0f);\n            float _2159 = max(dot(_2004, _2149), 0.0f);\n            if (_2084.on)\n            {\n                FaLayers param_14 = _2084;\n                float3 param_15 = _2061;\n                float3 param_16 = f0;\n                float3 param_17 = _2031;\n                float3 param_18 = _2004;\n                float3 param_19 = _2750;\n                float3 param_20 = _2149;\n                float param_21 = _2138;\n                float param_22 = _2055;\n                float param_23 = _2154;\n                float param_24 = _2159;\n                float param_25 = _2046;\n                float param_26 = _2050;\n                lit += (fa_layers_light(param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26) * (_246_fa_light_color[li].xyz * _2144));\n            }\n            else\n            {\n                float _2208 = ((_2154 * _2154) * (_2050 - 1.0f)) + 1.0f;\n                lit += (((_2061 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _2159, 5.0f))) * (((_2050 / ((3.1415927410125732421875f * _2208) * _2208)) * (0.5f / max(lerp((2.0f * _2138) * _2055, _2138 + _2055, _2046), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2138))) * _246_fa_light_color[li].xyz) * (_2138 * _2144));\n            }\n        }\n        if (_2084.on)\n        {\n            FaLayers param_27 = _2084;\n            float3 param_28 = _2031;\n            float3 param_29 = _2004;\n            float3 param_30 = f0;\n            float param_31 = _2042;\n            lit += (fa_layers_ibl(param_27, param_28, param_29, param_30, param_31) * _2581);\n        }\n        else\n        {\n            float3 param_32 = _2031;\n            float3 param_33 = _2004;\n            float3 param_34 = f0;\n            float param_35 = _2042;\n            lit += (fa_sky_reflection(param_32, param_33, param_34, param_35) * _2581);\n        }\n        result = lit;\n    }\n    result += _2582;\n    bool _2306 = _364_fa_fog.w > 0.0f;\n    bool _2313;\n    if (!_2306)\n    {\n        _2313 = _364_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2313 = _2306;\n    }\n    if (_2313)\n    {\n        float3 _2322 = fa_world_pos - _364_fa_camera_pos.xyz;\n        float _2328 = dot(_2322, _364_fa_fog_c.xyz);\n        bool _2332 = _364_fa_fog_c.w > 0.5f;\n        float _2333;\n        if (_2332)\n        {\n            _2333 = _2328;\n        }\n        else\n        {\n            _2333 = length(_2322);\n        }\n        float _2345 = _2333 - _364_fa_fog_b.x;\n        if (_2345 > 0.0f)\n        {\n            float _2354 = _364_fa_fog.w * _2345;\n            float tau = _2354 * _2354;\n            if (_364_fa_fog_b.y > 0.0f)\n            {\n                float _2370;\n                if (_2332)\n                {\n                    _2370 = fa_world_pos.y - (_364_fa_fog_c.y * _2328);\n                }\n                else\n                {\n                    _2370 = _364_fa_camera_pos.y;\n                }\n                float _2391 = lerp(_2370, fa_world_pos.y, clamp(_364_fa_fog_b.x / _2333, 0.0f, 1.0f));\n                float _2395 = fa_world_pos.y - _2391;\n                float _2400 = _2391 - _364_fa_fog_b.z;\n                float _2405 = fa_world_pos.y - _364_fa_fog_b.z;\n                bool _2408 = _2400 <= 0.0f;\n                bool _2409 = !_2408;\n                bool _2415;\n                if (_2409)\n                {\n                    _2415 = _364_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2415 = _2408;\n                }\n                float _2416;\n                if (_2415)\n                {\n                    _2416 = _364_fa_fog_b.y;\n                }\n                else\n                {\n                    _2416 = _364_fa_fog_b.y * exp(-min(_364_fa_fog_b.w * _2400, 80.0f));\n                }\n                bool _2443;\n                if (_2409)\n                {\n                    _2443 = _364_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2443 = _2408;\n                }\n                float _2444;\n                if (_2443)\n                {\n                    _2444 = _364_fa_fog_b.y * _2400;\n                }\n                else\n                {\n                    _2444 = (_364_fa_fog_b.y * (1.0f - exp(-min(_364_fa_fog_b.w * _2400, 80.0f)))) / _364_fa_fog_b.w;\n                }\n                bool _2469 = _2405 <= 0.0f;\n                bool _2476;\n                if (!_2469)\n                {\n                    _2476 = _364_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2476 = _2469;\n                }\n                float _2477;\n                if (_2476)\n                {\n                    _2477 = _364_fa_fog_b.y * _2405;\n                }\n                else\n                {\n                    _2477 = (_364_fa_fog_b.y * (1.0f - exp(-min(_364_fa_fog_b.w * _2405, 80.0f)))) / _364_fa_fog_b.w;\n                }\n                float _2504;\n                if (abs(_2395) < 0.001000000047497451305389404296875f)\n                {\n                    _2504 = _2416;\n                }\n                else\n                {\n                    _2504 = (_2477 - _2444) / _2395;\n                }\n                tau += (_2345 * max(_2504, 0.0f));\n            }\n            result = lerp(result, _364_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2577);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_246",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_364",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_layers_a : packoffset(c14);\n    float4 _213_fa_layers_b : packoffset(c15);\n    float4 _213_fa_layers_c : packoffset(c16);\n    float4 _213_fa_layers_d : packoffset(c17);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _730 = base_t;\n    _730.x = _225.x;\n    _730.y = _225.y;\n    _730.z = _225.z;\n    base_t = _730;\n    float4 _241 = (_730 * _213_fa_base_color) * i.vertex_color;\n    float3 _693 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _738 = _279;\n        _738.x = _284.x;\n        _738.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _738;\n        _693 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _741 = mrt;\n    _741.x = _313.x;\n    _741.y = _313.y;\n    _741.z = _313.z;\n    mrt = _741;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _698 = _213_fa_layers_a.x;\n    float _699 = _213_fa_layers_a.y;\n    float _702 = _213_fa_layers_a.z;\n    float _701 = _213_fa_layers_b.w;\n    float _704 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _698 *= _355.y;\n            _699 *= _355.z;\n            _701 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _702 *= mrt.x;\n            _704 *= mrt.w;\n        }\n    }\n    Surface _723 = { _241.xyz, _241.w, _693, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _698, _699, _213_fa_layers_b.xyz, _701, _702, _213_fa_layers_a.w, _704, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _723;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _604 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _604 = -_604;\n    }\n    float3 _517 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _617 = { fa_world_pos, _604, fa_world_tangent, fa_uv, fa_vertex_color, _517, gl_FrontFacing };\n    SurfaceInput param = _617;\n    SurfaceInput _625 = { fa_world_pos, _604, fa_world_tangent, fa_uv, fa_vertex_color, _517, gl_FrontFacing };\n    SurfaceInput param_1 = _625;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _532 = normalize(param_2.normal);\n    float3 _547 = normalize(float3(dot(fa_pre_r0, _532), dot(fa_pre_r1, _532), dot(fa_pre_r2, _532)));\n    float _559 = _547.z;\n    float2 e = _547.xy / ((abs(_547.x) + abs(_547.y)) + abs(_559)).xx;\n    if (_559 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _413 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _413;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0f);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_layers_a : packoffset(c14);\n    float4 _213_fa_layers_b : packoffset(c15);\n    float4 _213_fa_layers_c : packoffset(c16);\n    float4 _213_fa_layers_d : packoffset(c17);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _730 = base_t;\n    _730.x = _225.x;\n    _730.y = _225.y;\n    _730.z = _225.z;\n    base_t = _730;\n    float4 _241 = (_730 * _213_fa_base_color) * i.vertex_color;\n    float3 _693 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _738 = _279;\n        _738.x = _284.x;\n        _738.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _738;\n        _693 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _741 = mrt;\n    _741.x = _313.x;\n    _741.y = _313.y;\n    _741.z = _313.z;\n    mrt = _741;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _698 = _213_fa_layers_a.x;\n    float _699 = _213_fa_layers_a.y;\n    float _702 = _213_fa_layers_a.z;\n    float _701 = _213_fa_layers_b.w;\n    float _704 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _698 *= _355.y;\n            _699 *= _355.z;\n            _701 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _702 *= mrt.x;\n            _704 *= mrt.w;\n        }\n    }\n    Surface _723 = { _241.xyz, _241.w, _693, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _698, _699, _213_fa_layers_b.xyz, _701, _702, _213_fa_layers_a.w, _704, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _723;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _604 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _604 = -_604;\n    }\n    float3 _517 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _617 = { fa_world_pos, _604, fa_world_tangent, fa_uv, fa_vertex_color, _517, gl_FrontFacing };\n    SurfaceInput param = _617;\n    SurfaceInput _625 = { fa_world_pos, _604, fa_world_tangent, fa_uv, fa_vertex_color, _517, gl_FrontFacing };\n    SurfaceInput param_1 = _625;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _532 = normalize(param_2.normal);\n    float3 _547 = normalize(float3(dot(fa_pre_r0, _532), dot(fa_pre_r1, _532), dot(fa_pre_r2, _532)));\n    float _559 = _547.z;\n    float2 e = _547.xy / ((abs(_547.x) + abs(_547.y)) + abs(_559)).xx;\n    if (_559 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 288,
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
