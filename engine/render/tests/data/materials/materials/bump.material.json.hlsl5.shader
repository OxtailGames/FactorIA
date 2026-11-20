{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "67b1186c6e51021b07dd68cec7aaad42a4febc7364ef358b4473bc1e089911c0",
  "slang": "hlsl5",
  "params": [
    "lift"
  ],
  "textures": [
    "height"
  ],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _63_lift : packoffset(c0);\n    float _63_fa_pad0 : packoffset(c0.y);\n    float _63_fa_pad1 : packoffset(c0.z);\n    float _63_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _160_fa_view_proj : packoffset(c0);\n    row_major float4x4 _160_fa_light_vp : packoffset(c4);\n    float4 _160_fa_uv_scale : packoffset(c8);\n    float4 _160_fa_time : packoffset(c9);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _103 = cross(model[1].xyz, model[2].xyz);\n    float _108 = (dot(model[0].xyz, _103) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _296 = { mul(float4(position, 1.0f), model).xyz, (((_103 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _108, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _108), texcoord0 * _160_fa_uv_scale.xy, color, position };\n    return _296;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _63_lift);\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _200 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = mul(_200, _160_fa_light_vp);\n    gl_Position = mul(_200, _160_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _790[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _246_fa_light_pos[32] : packoffset(c0);\n    float4 _246_fa_light_color[32] : packoffset(c32);\n    float4 _246_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _364_fa_camera_pos : packoffset(c0);\n    float4 _364_fa_ambient : packoffset(c1);\n    float4 _364_fa_base_color : packoffset(c2);\n    float4 _364_fa_emissive : packoffset(c3);\n    float4 _364_fa_model_emissive : packoffset(c4);\n    float4 _364_fa_pbr : packoffset(c5);\n    float4 _364_fa_maps : packoffset(c6);\n    float4 _364_fa_fog : packoffset(c7);\n    float4 _364_fa_fog_b : packoffset(c8);\n    float4 _364_fa_fog_c : packoffset(c9);\n    float4 _364_fa_counts : packoffset(c10);\n    float4 _364_fa_env_sky : packoffset(c11);\n    float4 _364_fa_env_horizon : packoffset(c12);\n    float4 _364_fa_time : packoffset(c13);\n    float4 _364_fa_layers_a : packoffset(c14);\n    float4 _364_fa_layers_b : packoffset(c15);\n    float4 _364_fa_layers_c : packoffset(c16);\n    float4 _364_fa_layers_d : packoffset(c17);\n};\n\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\nTextureCube<float4> fa_env_tex : register(t7);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t8);\nTexture2D<float4> height : register(t6);\nSamplerState height_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1705 = fa_linear_to_srgb(param);\n        c = _1705;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1713 = fa_srgb_to_linear(param_1);\n            c = _1713;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _174;\n    if (i.front_facing)\n    {\n        _174 = i.world_normal;\n    }\n    else\n    {\n        _174 = -i.world_normal;\n    }\n    float3 _198 = normalize(i.world_tangent.xyz - (_174 * dot(_174, i.world_tangent.xyz)));\n    float3 _226 = normalize(((_198 * m.x) + ((cross(_174, _198) * i.world_tangent.w) * m.y)) + (_174 * m.z));\n    float3 _229;\n    if (i.front_facing)\n    {\n        _229 = _226;\n    }\n    else\n    {\n        _229 = -_226;\n    }\n    return _229;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _364_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1744 = fa_tex_fix(param_2, param_3);\n    float4 _2904 = base_t;\n    _2904.x = _1744.x;\n    _2904.y = _1744.y;\n    _2904.z = _1744.z;\n    base_t = _2904;\n    float4 _1758 = (_2904 * _364_fa_base_color) * i.vertex_color;\n    float3 _2847 = i.world_normal;\n    if (_364_fa_maps.z > 0.5f)\n    {\n        float param_4 = _364_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1791 = fa_tex_fix(param_6, param_7);\n        float3 _1794 = (_1791 * 2.0f) - 1.0f.xxx;\n        float2 _1799 = _1794.xy * _364_fa_maps.x;\n        float3 _2912 = _1794;\n        _2912.x = _1799.x;\n        _2912.y = _1799.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2912;\n        _2847 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _364_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1828 = fa_tex_fix(param_12, param_13);\n    float4 _2915 = mrt;\n    _2915.x = _1828.x;\n    _2915.y = _1828.y;\n    _2915.z = _1828.z;\n    mrt = _2915;\n    float4 _1856 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _364_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _1856.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1868 = fa_tex_fix(param_16, param_17);\n    float param_18 = _364_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1898 = fa_tex_fix(param_20, param_21);\n    float _2852 = _364_fa_layers_a.x;\n    float _2853 = _364_fa_layers_a.y;\n    float _2856 = _364_fa_layers_a.z;\n    float _2855 = _364_fa_layers_b.w;\n    float _2858 = _364_fa_layers_c.x;\n    if (_364_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_364_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _2852 *= _1868.y;\n            _2853 *= _1868.z;\n            _2855 *= _1856.w;\n        }\n        if (_364_fa_layers_c.z > 1.5f)\n        {\n            _2856 *= mrt.x;\n            _2858 *= mrt.w;\n        }\n    }\n    Surface _2877 = { _1758.xyz, _1758.w, _2847, clamp(_364_fa_pbr.x * _1828.z, 0.0f, 1.0f), clamp(_364_fa_pbr.y * _1828.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_364_fa_maps.y * (_1868.x - 1.0f)), _364_fa_emissive.xyz + (_364_fa_model_emissive.xyz * _1898), _2852, _2853, _364_fa_layers_b.xyz, _2855, _2856, _364_fa_layers_a.w, _2858, _364_fa_layers_c.y, _364_fa_layers_d.xyz };\n    return _2877;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= lerp(0.5f, 1.0f, height.Sample(height_smp, i.uv).x);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _715 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _723 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _726 = int(_715);\n    int _729 = int(_723);\n    float _739 = _723 - float(_729);\n    int _795 = (_726 * 9) + _729;\n    int _815 = ((_726 + 1) * 9) + _729;\n    return lerp(lerp(_790[_795], _790[_795 + 1], _739), lerp(_790[_815], _790[_815 + 1], _739), _715 - float(_726));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _2783 = false;\n    float _2784 = 1.0f;\n    float _2785 = 1.0f;\n    float _2786 = 1.0f;\n    float _2787 = 0.0f;\n    float _2788 = 0.0f;\n    float _2789 = 0.0f;\n    float _2790 = 0.0f;\n    float _2792 = 1.0f;\n    bool _2793 = false;\n    float3 _2794 = 0.0f.xxx;\n    float _2795 = 1.0f;\n    float _2796 = 1.0f;\n    float _2797 = 1.0f;\n    float _2798 = 0.0f;\n    float _2799 = 0.0f;\n    float3 _2800 = float3(1.0f, 0.0f, 0.0f);\n    float3 _2801 = float3(0.0f, 0.0f, 1.0f);\n    float _2802 = 1.0f;\n    float _2803 = 1.0f;\n    float _877 = clamp(s.specular, 0.0f, 1.0f);\n    float _882 = clamp(s.ior, 1.0f, 3.0f);\n    bool _887 = (_877 != 1.0f) || (_882 != 1.5f);\n    bool _897;\n    if (!_887)\n    {\n        _897 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _897 = _887;\n    }\n    if (_897)\n    {\n        float _905 = (_882 - 1.0f) / (_882 + 1.0f);\n        f0 = lerp(min((_905 * _905).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _877, s.albedo, metallic.xxx);\n        _2784 = lerp(_877, 1.0f, metallic);\n        _2783 = true;\n    }\n    float _933 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_933 > 0.0f)\n    {\n        float _941 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _2787 = _933;\n        _2788 = _941;\n        float _948 = _941 * _941;\n        _2789 = _948;\n        _2790 = _948 * _948;\n        float _960 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _2792 = _960;\n        _2785 = 1.0f - (_933 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _960, 0.0f, 1.0f), 5.0f))));\n        _2783 = true;\n    }\n    float3 _980 = max(s.sheen_color, 0.0f.xxx);\n    float _989 = max(_980.x, max(_980.y, _980.z));\n    if (_989 > 0.0f)\n    {\n        float _997 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _2793 = true;\n        _2794 = _980;\n        _2795 = _997;\n        _2796 = _997 * _997;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _997;\n        float _1014 = fa_sheen_albedo(param, param_1);\n        _2798 = _1014;\n        _2797 = 1.0f - min(_989 * _1014, 1.0f);\n        _2783 = true;\n    }\n    _2786 = _2785 * _2797;\n    float _1033 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_1033 != 0.0f)\n    {\n        float3 _1048 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1048;\n        if (dot(_1048, _1048) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _1062 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_1062.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _1062.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _1062.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _1066 = t;\n        float3 _1067 = normalize(_1066);\n        t = _1067;\n        float3 _1092 = normalize((_1067 * cos(s.anisotropy_rotation)) + ((cross(n, _1067) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _2800 = _1092;\n        _2801 = cross(n, _1092);\n        float _1102 = roughness * roughness;\n        float _1108 = lerp(_1102, 1.0f, _1033 * _1033);\n        bool _1110 = _1033 > 0.0f;\n        _2802 = _1110 ? _1108 : _1102;\n        _2803 = _1110 ? _1102 : _1108;\n        _2799 = _1033;\n        _2783 = true;\n    }\n    FaLayers _2825 = { _2783, _2784, _2785, _2786, _2787, _2788, _2789, _2790, i.world_normal, _2792, _2793, _2794, _2795, _2796, _2797, _2798, _2799, _2800, _2801, _2802, _2803 };\n    return _2825;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_364_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _364_fa_ambient.xyz;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _257 = _246_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_257)\n    {\n        l = normalize(_246_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _275 = _246_fa_light_pos[li].xyz - world_pos;\n        float _277 = length(_275);\n        dist = _277;\n        l = _275 / max(_277, 9.9999997473787516355514526367188e-05f).xxx;\n        float _293 = _277 / max(_246_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _299 = clamp(1.0f - (_293 * _293), 0.0f, 1.0f);\n        atten = _299 * _299;\n        if (_246_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_246_fa_light_dir[li].w, lerp(_246_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_246_fa_light_dir[li].xyz)));\n        }\n    }\n    int _350;\n    if (_257)\n    {\n        _350 = 0;\n    }\n    else\n    {\n        _350 = (_246_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _2782 = { l, _246_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _350 };\n    return _2782;\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_364_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _377 = coord.xyz / coord.w.xxx;\n    float3 p = _377;\n    float2 suv = (_377.xy * 0.5f) + 0.5f.xx;\n    if (_364_fa_counts.z > 0.5f)\n    {\n        float3 _2879 = p;\n        _2879.z = (_2879.z * 0.5f) + 0.5f;\n        p = _2879;\n    }\n    else\n    {\n        float2 _2882 = suv;\n        _2882.y = 1.0f - _2882.y;\n        suv = _2882;\n    }\n    bool _405 = suv.x < 0.0f;\n    bool _412;\n    if (!_405)\n    {\n        _412 = suv.x > 1.0f;\n    }\n    else\n    {\n        _412 = _405;\n    }\n    bool _419;\n    if (!_412)\n    {\n        _419 = suv.y < 0.0f;\n    }\n    else\n    {\n        _419 = _412;\n    }\n    bool _426;\n    if (!_419)\n    {\n        _426 = suv.y > 1.0f;\n    }\n    else\n    {\n        _426 = _419;\n    }\n    bool _433;\n    if (!_426)\n    {\n        _433 = p.z > 1.0f;\n    }\n    else\n    {\n        _433 = _426;\n    }\n    if (_433)\n    {\n        return 1.0f;\n    }\n    float _448 = _364_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _448) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _364_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1614 = fa_light_sample(param, param_1);\n    float3 _2832 = _1614.direction;\n    float3 _2827 = _1614.color;\n    float _2834 = _1614.attenuation;\n    float _2829 = _1614.shadow;\n    int _2837 = _1614.type;\n    if ((_2837 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2832;\n        float _1628 = fa_shadow_factor(param_2, param_3);\n        _2829 = _1628;\n        _2827 = _246_fa_light_color[li].xyz * (_2834 * _1628);\n    }\n    LightSample _2844 = { _2832, _2827, _2834, _2829, _1614._distance, _2837 };\n    return _2844;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _1260 = tdh / at;\n    float _1264 = bdh / ab;\n    float _1276 = ((_1260 * _1260) + (_1264 * _1264)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _1276) * _1276);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _1358 = 1.0f / alpha;\n    return ((2.0f + _1358) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _1358)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _1391 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _1470 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _1470) * _1470);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _1391);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _1391));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _1543 = max(dot(L.nc, l), 0.0f);\n        float _1549 = max(dot(L.nc, h), 0.0f);\n        float _1558 = ((_1549 * _1549) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _1558) * _1558)) * (0.5f / max(lerp((2.0f * _1543) * L.coat_ndv, _1543 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _1543)) * _1543).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _645 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _648 = _645.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_648 * _648, exp2((-9.27999973297119140625f) * ndv)) * _648) + _645.y)) + _645.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_364_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _364_fa_env_horizon.w).xyz;\n    }\n    float _548 = rough * rough;\n    float _579 = 0.60000002384185791015625f * _548;\n    return lerp(lerp(_364_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_364_fa_env_horizon.xyz, _364_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _548)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _579, 0.0500000007450580596923828125f + _579, d.y).xxx), ((_364_fa_env_sky.xyz + _364_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_548 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _1143;\n        if (L.aniso >= 0.0f)\n        {\n            _1143 = L.b;\n        }\n        else\n        {\n            _1143 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_1143, v), _1143), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1176 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _1176.x) + (L.f90.xxx * _1176.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1231 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _1231.x) + _1231.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _687 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _687.x) + _687.y.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2562 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2562 = -_2562;\n    }\n    float3 _2018 = normalize(_364_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _2575 = { fa_world_pos, _2562, fa_world_tangent, fa_uv, fa_vertex_color, _2018, gl_FrontFacing };\n    SurfaceInput param = _2575;\n    Surface _2023 = fa_standard_surface(param);\n    float3 _2593 = _2023.albedo;\n    float _2594 = _2023.alpha;\n    float3 _2595 = _2023.normal;\n    float _2596 = _2023.metallic;\n    float _2597 = _2023.roughness;\n    float _2598 = _2023.occlusion;\n    float3 _2599 = _2023.emission;\n    float _2600 = _2023.clearcoat;\n    float _2601 = _2023.clearcoat_roughness;\n    float3 _2602 = _2023.sheen_color;\n    float _2603 = _2023.sheen_roughness;\n    float _2604 = _2023.anisotropy;\n    float _2605 = _2023.anisotropy_rotation;\n    float _2606 = _2023.specular;\n    float _2607 = _2023.ior;\n    float3 _2608 = _2023.specular_color;\n    SurfaceInput _2583 = { fa_world_pos, _2562, fa_world_tangent, fa_uv, fa_vertex_color, _2018, gl_FrontFacing };\n    SurfaceInput param_1 = _2583;\n    Surface param_2 = _2023;\n    surface(param_1, param_2);\n    _2593 = param_2.albedo;\n    _2594 = param_2.alpha;\n    _2595 = param_2.normal;\n    _2596 = param_2.metallic;\n    _2597 = param_2.roughness;\n    _2598 = param_2.occlusion;\n    _2599 = param_2.emission;\n    _2600 = param_2.clearcoat;\n    _2601 = param_2.clearcoat_roughness;\n    _2602 = param_2.sheen_color;\n    _2603 = param_2.sheen_roughness;\n    _2604 = param_2.anisotropy;\n    _2605 = param_2.anisotropy_rotation;\n    _2606 = param_2.specular;\n    _2607 = param_2.ior;\n    _2608 = param_2.specular_color;\n    float3 result;\n    if (_364_fa_emissive.w > 0.5f)\n    {\n        result = _2593;\n    }\n    else\n    {\n        float3 _2045 = normalize(_2595);\n        float _2052 = clamp(_2596, 0.0f, 1.0f);\n        float _2056 = clamp(_2597, 0.0500000007450580596923828125f, 1.0f);\n        float _2060 = _2056 * _2056;\n        float _2064 = _2060 * _2060;\n        float _2069 = max(dot(_2045, _2018), 9.9999997473787516355514526367188e-05f);\n        float3 _2075 = _2593 * (1.0f - _2052);\n        float3 _2082 = lerp(0.039999999105930328369140625f.xxx, _2593, _2052.xxx);\n        float3 f0 = _2082;\n        SurfaceInput _2591 = { fa_world_pos, _2562, fa_world_tangent, fa_uv, fa_vertex_color, _2018, gl_FrontFacing };\n        SurfaceInput param_3 = _2591;\n        Surface _2674 = { _2593, _2594, _2595, _2596, _2597, _2598, _2599, _2600, _2601, _2602, _2603, _2604, _2605, _2606, _2607, _2608 };\n        Surface param_4 = _2674;\n        float3 param_5 = _2045;\n        float3 param_6 = _2018;\n        float param_7 = _2052;\n        float param_8 = _2056;\n        float3 param_9 = _2082;\n        FaLayers _2098 = fa_layers_setup(param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n        f0 = param_9;\n        float3 param_10 = _2045;\n        float3 lit = (fa_ambient_light(param_10) * _2075) * _2598;\n        if (_2098.on)\n        {\n            lit *= _2098.base_scale;\n        }\n        int _2120 = int(_364_fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _2120)\n            {\n                break;\n            }\n            int param_11 = li;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _2562;\n            LightSample _2144 = fa_light_shadowed(param_11, param_12, param_13);\n            float3 _2767 = _2144.direction;\n            float _2152 = max(dot(_2045, _2767), 0.0f);\n            float _2158 = _2144.attenuation * _2144.shadow;\n            float3 _2163 = normalize(_2767 + _2018);\n            float _2168 = max(dot(_2045, _2163), 0.0f);\n            float _2173 = max(dot(_2018, _2163), 0.0f);\n            if (_2098.on)\n            {\n                FaLayers param_14 = _2098;\n                float3 param_15 = _2075;\n                float3 param_16 = f0;\n                float3 param_17 = _2045;\n                float3 param_18 = _2018;\n                float3 param_19 = _2767;\n                float3 param_20 = _2163;\n                float param_21 = _2152;\n                float param_22 = _2069;\n                float param_23 = _2168;\n                float param_24 = _2173;\n                float param_25 = _2060;\n                float param_26 = _2064;\n                lit += (fa_layers_light(param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26) * (_246_fa_light_color[li].xyz * _2158));\n            }\n            else\n            {\n                float _2222 = ((_2168 * _2168) * (_2064 - 1.0f)) + 1.0f;\n                lit += (((_2075 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _2173, 5.0f))) * (((_2064 / ((3.1415927410125732421875f * _2222) * _2222)) * (0.5f / max(lerp((2.0f * _2152) * _2069, _2152 + _2069, _2060), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2152))) * _246_fa_light_color[li].xyz) * (_2152 * _2158));\n            }\n        }\n        if (_2098.on)\n        {\n            FaLayers param_27 = _2098;\n            float3 param_28 = _2045;\n            float3 param_29 = _2018;\n            float3 param_30 = f0;\n            float param_31 = _2056;\n            lit += (fa_layers_ibl(param_27, param_28, param_29, param_30, param_31) * _2598);\n        }\n        else\n        {\n            float3 param_32 = _2045;\n            float3 param_33 = _2018;\n            float3 param_34 = f0;\n            float param_35 = _2056;\n            lit += (fa_sky_reflection(param_32, param_33, param_34, param_35) * _2598);\n        }\n        result = lit;\n    }\n    result += _2599;\n    bool _2320 = _364_fa_fog.w > 0.0f;\n    bool _2327;\n    if (!_2320)\n    {\n        _2327 = _364_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2327 = _2320;\n    }\n    if (_2327)\n    {\n        float3 _2336 = fa_world_pos - _364_fa_camera_pos.xyz;\n        float _2342 = dot(_2336, _364_fa_fog_c.xyz);\n        bool _2346 = _364_fa_fog_c.w > 0.5f;\n        float _2347;\n        if (_2346)\n        {\n            _2347 = _2342;\n        }\n        else\n        {\n            _2347 = length(_2336);\n        }\n        float _2359 = _2347 - _364_fa_fog_b.x;\n        if (_2359 > 0.0f)\n        {\n            float _2368 = _364_fa_fog.w * _2359;\n            float tau = _2368 * _2368;\n            if (_364_fa_fog_b.y > 0.0f)\n            {\n                float _2384;\n                if (_2346)\n                {\n                    _2384 = fa_world_pos.y - (_364_fa_fog_c.y * _2342);\n                }\n                else\n                {\n                    _2384 = _364_fa_camera_pos.y;\n                }\n                float _2405 = lerp(_2384, fa_world_pos.y, clamp(_364_fa_fog_b.x / _2347, 0.0f, 1.0f));\n                float _2409 = fa_world_pos.y - _2405;\n                float _2414 = _2405 - _364_fa_fog_b.z;\n                float _2419 = fa_world_pos.y - _364_fa_fog_b.z;\n                bool _2422 = _2414 <= 0.0f;\n                bool _2423 = !_2422;\n                bool _2429;\n                if (_2423)\n                {\n                    _2429 = _364_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2429 = _2422;\n                }\n                float _2430;\n                if (_2429)\n                {\n                    _2430 = _364_fa_fog_b.y;\n                }\n                else\n                {\n                    _2430 = _364_fa_fog_b.y * exp(-min(_364_fa_fog_b.w * _2414, 80.0f));\n                }\n                bool _2457;\n                if (_2423)\n                {\n                    _2457 = _364_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2457 = _2422;\n                }\n                float _2458;\n                if (_2457)\n                {\n                    _2458 = _364_fa_fog_b.y * _2414;\n                }\n                else\n                {\n                    _2458 = (_364_fa_fog_b.y * (1.0f - exp(-min(_364_fa_fog_b.w * _2414, 80.0f)))) / _364_fa_fog_b.w;\n                }\n                bool _2483 = _2419 <= 0.0f;\n                bool _2490;\n                if (!_2483)\n                {\n                    _2490 = _364_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2490 = _2483;\n                }\n                float _2491;\n                if (_2490)\n                {\n                    _2491 = _364_fa_fog_b.y * _2419;\n                }\n                else\n                {\n                    _2491 = (_364_fa_fog_b.y * (1.0f - exp(-min(_364_fa_fog_b.w * _2419, 80.0f)))) / _364_fa_fog_b.w;\n                }\n                float _2518;\n                if (abs(_2409) < 0.001000000047497451305389404296875f)\n                {\n                    _2518 = _2430;\n                }\n                else\n                {\n                    _2518 = (_2491 - _2458) / _2409;\n                }\n                tau += (_2359 * max(_2518, 0.0f));\n            }\n            result = lerp(result, _364_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2594);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_63",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_160",
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
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 6
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
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
              "hlsl_register_t_n": 7
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
              "hlsl_register_t_n": 8
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 6
          },
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
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
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
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _68_lift : packoffset(c0);\n    float _68_fa_pad0 : packoffset(c0.y);\n    float _68_fa_pad1 : packoffset(c0.z);\n    float _68_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _165_fa_view_proj : packoffset(c0);\n    row_major float4x4 _165_fa_light_vp : packoffset(c4);\n    float4 _165_fa_uv_scale : packoffset(c8);\n    float4 _165_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _212_fa_joint_rows[192] : packoffset(c0);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _203 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_212_fa_joint_rows[_203] * weights[i]);\n        r1 += (_212_fa_joint_rows[_203 + 1] * weights[i]);\n        r2 += (_212_fa_joint_rows[_203 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _108 = cross(model[1].xyz, model[2].xyz);\n    float _113 = (dot(model[0].xyz, _108) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _417 = { mul(float4(position, 1.0f), model).xyz, (((_108 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _113, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _113), texcoord0 * _165_fa_uv_scale.xy, color, position };\n    return _417;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _68_lift);\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _313 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = mul(_313, _165_fa_light_vp);\n    gl_Position = mul(_313, _165_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _790[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _246_fa_light_pos[32] : packoffset(c0);\n    float4 _246_fa_light_color[32] : packoffset(c32);\n    float4 _246_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _364_fa_camera_pos : packoffset(c0);\n    float4 _364_fa_ambient : packoffset(c1);\n    float4 _364_fa_base_color : packoffset(c2);\n    float4 _364_fa_emissive : packoffset(c3);\n    float4 _364_fa_model_emissive : packoffset(c4);\n    float4 _364_fa_pbr : packoffset(c5);\n    float4 _364_fa_maps : packoffset(c6);\n    float4 _364_fa_fog : packoffset(c7);\n    float4 _364_fa_fog_b : packoffset(c8);\n    float4 _364_fa_fog_c : packoffset(c9);\n    float4 _364_fa_counts : packoffset(c10);\n    float4 _364_fa_env_sky : packoffset(c11);\n    float4 _364_fa_env_horizon : packoffset(c12);\n    float4 _364_fa_time : packoffset(c13);\n    float4 _364_fa_layers_a : packoffset(c14);\n    float4 _364_fa_layers_b : packoffset(c15);\n    float4 _364_fa_layers_c : packoffset(c16);\n    float4 _364_fa_layers_d : packoffset(c17);\n};\n\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\nTextureCube<float4> fa_env_tex : register(t7);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t8);\nTexture2D<float4> height : register(t6);\nSamplerState height_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1705 = fa_linear_to_srgb(param);\n        c = _1705;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1713 = fa_srgb_to_linear(param_1);\n            c = _1713;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _174;\n    if (i.front_facing)\n    {\n        _174 = i.world_normal;\n    }\n    else\n    {\n        _174 = -i.world_normal;\n    }\n    float3 _198 = normalize(i.world_tangent.xyz - (_174 * dot(_174, i.world_tangent.xyz)));\n    float3 _226 = normalize(((_198 * m.x) + ((cross(_174, _198) * i.world_tangent.w) * m.y)) + (_174 * m.z));\n    float3 _229;\n    if (i.front_facing)\n    {\n        _229 = _226;\n    }\n    else\n    {\n        _229 = -_226;\n    }\n    return _229;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _364_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1744 = fa_tex_fix(param_2, param_3);\n    float4 _2904 = base_t;\n    _2904.x = _1744.x;\n    _2904.y = _1744.y;\n    _2904.z = _1744.z;\n    base_t = _2904;\n    float4 _1758 = (_2904 * _364_fa_base_color) * i.vertex_color;\n    float3 _2847 = i.world_normal;\n    if (_364_fa_maps.z > 0.5f)\n    {\n        float param_4 = _364_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1791 = fa_tex_fix(param_6, param_7);\n        float3 _1794 = (_1791 * 2.0f) - 1.0f.xxx;\n        float2 _1799 = _1794.xy * _364_fa_maps.x;\n        float3 _2912 = _1794;\n        _2912.x = _1799.x;\n        _2912.y = _1799.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2912;\n        _2847 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _364_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1828 = fa_tex_fix(param_12, param_13);\n    float4 _2915 = mrt;\n    _2915.x = _1828.x;\n    _2915.y = _1828.y;\n    _2915.z = _1828.z;\n    mrt = _2915;\n    float4 _1856 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _364_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _1856.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1868 = fa_tex_fix(param_16, param_17);\n    float param_18 = _364_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1898 = fa_tex_fix(param_20, param_21);\n    float _2852 = _364_fa_layers_a.x;\n    float _2853 = _364_fa_layers_a.y;\n    float _2856 = _364_fa_layers_a.z;\n    float _2855 = _364_fa_layers_b.w;\n    float _2858 = _364_fa_layers_c.x;\n    if (_364_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_364_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _2852 *= _1868.y;\n            _2853 *= _1868.z;\n            _2855 *= _1856.w;\n        }\n        if (_364_fa_layers_c.z > 1.5f)\n        {\n            _2856 *= mrt.x;\n            _2858 *= mrt.w;\n        }\n    }\n    Surface _2877 = { _1758.xyz, _1758.w, _2847, clamp(_364_fa_pbr.x * _1828.z, 0.0f, 1.0f), clamp(_364_fa_pbr.y * _1828.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_364_fa_maps.y * (_1868.x - 1.0f)), _364_fa_emissive.xyz + (_364_fa_model_emissive.xyz * _1898), _2852, _2853, _364_fa_layers_b.xyz, _2855, _2856, _364_fa_layers_a.w, _2858, _364_fa_layers_c.y, _364_fa_layers_d.xyz };\n    return _2877;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= lerp(0.5f, 1.0f, height.Sample(height_smp, i.uv).x);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _715 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _723 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _726 = int(_715);\n    int _729 = int(_723);\n    float _739 = _723 - float(_729);\n    int _795 = (_726 * 9) + _729;\n    int _815 = ((_726 + 1) * 9) + _729;\n    return lerp(lerp(_790[_795], _790[_795 + 1], _739), lerp(_790[_815], _790[_815 + 1], _739), _715 - float(_726));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _2783 = false;\n    float _2784 = 1.0f;\n    float _2785 = 1.0f;\n    float _2786 = 1.0f;\n    float _2787 = 0.0f;\n    float _2788 = 0.0f;\n    float _2789 = 0.0f;\n    float _2790 = 0.0f;\n    float _2792 = 1.0f;\n    bool _2793 = false;\n    float3 _2794 = 0.0f.xxx;\n    float _2795 = 1.0f;\n    float _2796 = 1.0f;\n    float _2797 = 1.0f;\n    float _2798 = 0.0f;\n    float _2799 = 0.0f;\n    float3 _2800 = float3(1.0f, 0.0f, 0.0f);\n    float3 _2801 = float3(0.0f, 0.0f, 1.0f);\n    float _2802 = 1.0f;\n    float _2803 = 1.0f;\n    float _877 = clamp(s.specular, 0.0f, 1.0f);\n    float _882 = clamp(s.ior, 1.0f, 3.0f);\n    bool _887 = (_877 != 1.0f) || (_882 != 1.5f);\n    bool _897;\n    if (!_887)\n    {\n        _897 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _897 = _887;\n    }\n    if (_897)\n    {\n        float _905 = (_882 - 1.0f) / (_882 + 1.0f);\n        f0 = lerp(min((_905 * _905).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _877, s.albedo, metallic.xxx);\n        _2784 = lerp(_877, 1.0f, metallic);\n        _2783 = true;\n    }\n    float _933 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_933 > 0.0f)\n    {\n        float _941 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _2787 = _933;\n        _2788 = _941;\n        float _948 = _941 * _941;\n        _2789 = _948;\n        _2790 = _948 * _948;\n        float _960 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _2792 = _960;\n        _2785 = 1.0f - (_933 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _960, 0.0f, 1.0f), 5.0f))));\n        _2783 = true;\n    }\n    float3 _980 = max(s.sheen_color, 0.0f.xxx);\n    float _989 = max(_980.x, max(_980.y, _980.z));\n    if (_989 > 0.0f)\n    {\n        float _997 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _2793 = true;\n        _2794 = _980;\n        _2795 = _997;\n        _2796 = _997 * _997;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _997;\n        float _1014 = fa_sheen_albedo(param, param_1);\n        _2798 = _1014;\n        _2797 = 1.0f - min(_989 * _1014, 1.0f);\n        _2783 = true;\n    }\n    _2786 = _2785 * _2797;\n    float _1033 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_1033 != 0.0f)\n    {\n        float3 _1048 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1048;\n        if (dot(_1048, _1048) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _1062 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_1062.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _1062.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _1062.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _1066 = t;\n        float3 _1067 = normalize(_1066);\n        t = _1067;\n        float3 _1092 = normalize((_1067 * cos(s.anisotropy_rotation)) + ((cross(n, _1067) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _2800 = _1092;\n        _2801 = cross(n, _1092);\n        float _1102 = roughness * roughness;\n        float _1108 = lerp(_1102, 1.0f, _1033 * _1033);\n        bool _1110 = _1033 > 0.0f;\n        _2802 = _1110 ? _1108 : _1102;\n        _2803 = _1110 ? _1102 : _1108;\n        _2799 = _1033;\n        _2783 = true;\n    }\n    FaLayers _2825 = { _2783, _2784, _2785, _2786, _2787, _2788, _2789, _2790, i.world_normal, _2792, _2793, _2794, _2795, _2796, _2797, _2798, _2799, _2800, _2801, _2802, _2803 };\n    return _2825;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_364_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _364_fa_ambient.xyz;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _257 = _246_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_257)\n    {\n        l = normalize(_246_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _275 = _246_fa_light_pos[li].xyz - world_pos;\n        float _277 = length(_275);\n        dist = _277;\n        l = _275 / max(_277, 9.9999997473787516355514526367188e-05f).xxx;\n        float _293 = _277 / max(_246_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _299 = clamp(1.0f - (_293 * _293), 0.0f, 1.0f);\n        atten = _299 * _299;\n        if (_246_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_246_fa_light_dir[li].w, lerp(_246_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_246_fa_light_dir[li].xyz)));\n        }\n    }\n    int _350;\n    if (_257)\n    {\n        _350 = 0;\n    }\n    else\n    {\n        _350 = (_246_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _2782 = { l, _246_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _350 };\n    return _2782;\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_364_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _377 = coord.xyz / coord.w.xxx;\n    float3 p = _377;\n    float2 suv = (_377.xy * 0.5f) + 0.5f.xx;\n    if (_364_fa_counts.z > 0.5f)\n    {\n        float3 _2879 = p;\n        _2879.z = (_2879.z * 0.5f) + 0.5f;\n        p = _2879;\n    }\n    else\n    {\n        float2 _2882 = suv;\n        _2882.y = 1.0f - _2882.y;\n        suv = _2882;\n    }\n    bool _405 = suv.x < 0.0f;\n    bool _412;\n    if (!_405)\n    {\n        _412 = suv.x > 1.0f;\n    }\n    else\n    {\n        _412 = _405;\n    }\n    bool _419;\n    if (!_412)\n    {\n        _419 = suv.y < 0.0f;\n    }\n    else\n    {\n        _419 = _412;\n    }\n    bool _426;\n    if (!_419)\n    {\n        _426 = suv.y > 1.0f;\n    }\n    else\n    {\n        _426 = _419;\n    }\n    bool _433;\n    if (!_426)\n    {\n        _433 = p.z > 1.0f;\n    }\n    else\n    {\n        _433 = _426;\n    }\n    if (_433)\n    {\n        return 1.0f;\n    }\n    float _448 = _364_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _448) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _364_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1614 = fa_light_sample(param, param_1);\n    float3 _2832 = _1614.direction;\n    float3 _2827 = _1614.color;\n    float _2834 = _1614.attenuation;\n    float _2829 = _1614.shadow;\n    int _2837 = _1614.type;\n    if ((_2837 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2832;\n        float _1628 = fa_shadow_factor(param_2, param_3);\n        _2829 = _1628;\n        _2827 = _246_fa_light_color[li].xyz * (_2834 * _1628);\n    }\n    LightSample _2844 = { _2832, _2827, _2834, _2829, _1614._distance, _2837 };\n    return _2844;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _1260 = tdh / at;\n    float _1264 = bdh / ab;\n    float _1276 = ((_1260 * _1260) + (_1264 * _1264)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _1276) * _1276);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _1358 = 1.0f / alpha;\n    return ((2.0f + _1358) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _1358)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _1391 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _1470 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _1470) * _1470);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _1391);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _1391));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _1543 = max(dot(L.nc, l), 0.0f);\n        float _1549 = max(dot(L.nc, h), 0.0f);\n        float _1558 = ((_1549 * _1549) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _1558) * _1558)) * (0.5f / max(lerp((2.0f * _1543) * L.coat_ndv, _1543 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _1543)) * _1543).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _645 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _648 = _645.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_648 * _648, exp2((-9.27999973297119140625f) * ndv)) * _648) + _645.y)) + _645.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_364_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _364_fa_env_horizon.w).xyz;\n    }\n    float _548 = rough * rough;\n    float _579 = 0.60000002384185791015625f * _548;\n    return lerp(lerp(_364_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_364_fa_env_horizon.xyz, _364_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _548)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _579, 0.0500000007450580596923828125f + _579, d.y).xxx), ((_364_fa_env_sky.xyz + _364_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_548 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _1143;\n        if (L.aniso >= 0.0f)\n        {\n            _1143 = L.b;\n        }\n        else\n        {\n            _1143 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_1143, v), _1143), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1176 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _1176.x) + (L.f90.xxx * _1176.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1231 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _1231.x) + _1231.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _687 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _687.x) + _687.y.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2562 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2562 = -_2562;\n    }\n    float3 _2018 = normalize(_364_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _2575 = { fa_world_pos, _2562, fa_world_tangent, fa_uv, fa_vertex_color, _2018, gl_FrontFacing };\n    SurfaceInput param = _2575;\n    Surface _2023 = fa_standard_surface(param);\n    float3 _2593 = _2023.albedo;\n    float _2594 = _2023.alpha;\n    float3 _2595 = _2023.normal;\n    float _2596 = _2023.metallic;\n    float _2597 = _2023.roughness;\n    float _2598 = _2023.occlusion;\n    float3 _2599 = _2023.emission;\n    float _2600 = _2023.clearcoat;\n    float _2601 = _2023.clearcoat_roughness;\n    float3 _2602 = _2023.sheen_color;\n    float _2603 = _2023.sheen_roughness;\n    float _2604 = _2023.anisotropy;\n    float _2605 = _2023.anisotropy_rotation;\n    float _2606 = _2023.specular;\n    float _2607 = _2023.ior;\n    float3 _2608 = _2023.specular_color;\n    SurfaceInput _2583 = { fa_world_pos, _2562, fa_world_tangent, fa_uv, fa_vertex_color, _2018, gl_FrontFacing };\n    SurfaceInput param_1 = _2583;\n    Surface param_2 = _2023;\n    surface(param_1, param_2);\n    _2593 = param_2.albedo;\n    _2594 = param_2.alpha;\n    _2595 = param_2.normal;\n    _2596 = param_2.metallic;\n    _2597 = param_2.roughness;\n    _2598 = param_2.occlusion;\n    _2599 = param_2.emission;\n    _2600 = param_2.clearcoat;\n    _2601 = param_2.clearcoat_roughness;\n    _2602 = param_2.sheen_color;\n    _2603 = param_2.sheen_roughness;\n    _2604 = param_2.anisotropy;\n    _2605 = param_2.anisotropy_rotation;\n    _2606 = param_2.specular;\n    _2607 = param_2.ior;\n    _2608 = param_2.specular_color;\n    float3 result;\n    if (_364_fa_emissive.w > 0.5f)\n    {\n        result = _2593;\n    }\n    else\n    {\n        float3 _2045 = normalize(_2595);\n        float _2052 = clamp(_2596, 0.0f, 1.0f);\n        float _2056 = clamp(_2597, 0.0500000007450580596923828125f, 1.0f);\n        float _2060 = _2056 * _2056;\n        float _2064 = _2060 * _2060;\n        float _2069 = max(dot(_2045, _2018), 9.9999997473787516355514526367188e-05f);\n        float3 _2075 = _2593 * (1.0f - _2052);\n        float3 _2082 = lerp(0.039999999105930328369140625f.xxx, _2593, _2052.xxx);\n        float3 f0 = _2082;\n        SurfaceInput _2591 = { fa_world_pos, _2562, fa_world_tangent, fa_uv, fa_vertex_color, _2018, gl_FrontFacing };\n        SurfaceInput param_3 = _2591;\n        Surface _2674 = { _2593, _2594, _2595, _2596, _2597, _2598, _2599, _2600, _2601, _2602, _2603, _2604, _2605, _2606, _2607, _2608 };\n        Surface param_4 = _2674;\n        float3 param_5 = _2045;\n        float3 param_6 = _2018;\n        float param_7 = _2052;\n        float param_8 = _2056;\n        float3 param_9 = _2082;\n        FaLayers _2098 = fa_layers_setup(param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n        f0 = param_9;\n        float3 param_10 = _2045;\n        float3 lit = (fa_ambient_light(param_10) * _2075) * _2598;\n        if (_2098.on)\n        {\n            lit *= _2098.base_scale;\n        }\n        int _2120 = int(_364_fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _2120)\n            {\n                break;\n            }\n            int param_11 = li;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _2562;\n            LightSample _2144 = fa_light_shadowed(param_11, param_12, param_13);\n            float3 _2767 = _2144.direction;\n            float _2152 = max(dot(_2045, _2767), 0.0f);\n            float _2158 = _2144.attenuation * _2144.shadow;\n            float3 _2163 = normalize(_2767 + _2018);\n            float _2168 = max(dot(_2045, _2163), 0.0f);\n            float _2173 = max(dot(_2018, _2163), 0.0f);\n            if (_2098.on)\n            {\n                FaLayers param_14 = _2098;\n                float3 param_15 = _2075;\n                float3 param_16 = f0;\n                float3 param_17 = _2045;\n                float3 param_18 = _2018;\n                float3 param_19 = _2767;\n                float3 param_20 = _2163;\n                float param_21 = _2152;\n                float param_22 = _2069;\n                float param_23 = _2168;\n                float param_24 = _2173;\n                float param_25 = _2060;\n                float param_26 = _2064;\n                lit += (fa_layers_light(param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26) * (_246_fa_light_color[li].xyz * _2158));\n            }\n            else\n            {\n                float _2222 = ((_2168 * _2168) * (_2064 - 1.0f)) + 1.0f;\n                lit += (((_2075 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _2173, 5.0f))) * (((_2064 / ((3.1415927410125732421875f * _2222) * _2222)) * (0.5f / max(lerp((2.0f * _2152) * _2069, _2152 + _2069, _2060), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2152))) * _246_fa_light_color[li].xyz) * (_2152 * _2158));\n            }\n        }\n        if (_2098.on)\n        {\n            FaLayers param_27 = _2098;\n            float3 param_28 = _2045;\n            float3 param_29 = _2018;\n            float3 param_30 = f0;\n            float param_31 = _2056;\n            lit += (fa_layers_ibl(param_27, param_28, param_29, param_30, param_31) * _2598);\n        }\n        else\n        {\n            float3 param_32 = _2045;\n            float3 param_33 = _2018;\n            float3 param_34 = f0;\n            float param_35 = _2056;\n            lit += (fa_sky_reflection(param_32, param_33, param_34, param_35) * _2598);\n        }\n        result = lit;\n    }\n    result += _2599;\n    bool _2320 = _364_fa_fog.w > 0.0f;\n    bool _2327;\n    if (!_2320)\n    {\n        _2327 = _364_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2327 = _2320;\n    }\n    if (_2327)\n    {\n        float3 _2336 = fa_world_pos - _364_fa_camera_pos.xyz;\n        float _2342 = dot(_2336, _364_fa_fog_c.xyz);\n        bool _2346 = _364_fa_fog_c.w > 0.5f;\n        float _2347;\n        if (_2346)\n        {\n            _2347 = _2342;\n        }\n        else\n        {\n            _2347 = length(_2336);\n        }\n        float _2359 = _2347 - _364_fa_fog_b.x;\n        if (_2359 > 0.0f)\n        {\n            float _2368 = _364_fa_fog.w * _2359;\n            float tau = _2368 * _2368;\n            if (_364_fa_fog_b.y > 0.0f)\n            {\n                float _2384;\n                if (_2346)\n                {\n                    _2384 = fa_world_pos.y - (_364_fa_fog_c.y * _2342);\n                }\n                else\n                {\n                    _2384 = _364_fa_camera_pos.y;\n                }\n                float _2405 = lerp(_2384, fa_world_pos.y, clamp(_364_fa_fog_b.x / _2347, 0.0f, 1.0f));\n                float _2409 = fa_world_pos.y - _2405;\n                float _2414 = _2405 - _364_fa_fog_b.z;\n                float _2419 = fa_world_pos.y - _364_fa_fog_b.z;\n                bool _2422 = _2414 <= 0.0f;\n                bool _2423 = !_2422;\n                bool _2429;\n                if (_2423)\n                {\n                    _2429 = _364_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2429 = _2422;\n                }\n                float _2430;\n                if (_2429)\n                {\n                    _2430 = _364_fa_fog_b.y;\n                }\n                else\n                {\n                    _2430 = _364_fa_fog_b.y * exp(-min(_364_fa_fog_b.w * _2414, 80.0f));\n                }\n                bool _2457;\n                if (_2423)\n                {\n                    _2457 = _364_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2457 = _2422;\n                }\n                float _2458;\n                if (_2457)\n                {\n                    _2458 = _364_fa_fog_b.y * _2414;\n                }\n                else\n                {\n                    _2458 = (_364_fa_fog_b.y * (1.0f - exp(-min(_364_fa_fog_b.w * _2414, 80.0f)))) / _364_fa_fog_b.w;\n                }\n                bool _2483 = _2419 <= 0.0f;\n                bool _2490;\n                if (!_2483)\n                {\n                    _2490 = _364_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2490 = _2483;\n                }\n                float _2491;\n                if (_2490)\n                {\n                    _2491 = _364_fa_fog_b.y * _2419;\n                }\n                else\n                {\n                    _2491 = (_364_fa_fog_b.y * (1.0f - exp(-min(_364_fa_fog_b.w * _2419, 80.0f)))) / _364_fa_fog_b.w;\n                }\n                float _2518;\n                if (abs(_2409) < 0.001000000047497451305389404296875f)\n                {\n                    _2518 = _2430;\n                }\n                else\n                {\n                    _2518 = (_2491 - _2458) / _2409;\n                }\n                tau += (_2359 * max(_2518, 0.0f));\n            }\n            result = lerp(result, _364_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2594);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_68",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_165",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_212",
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
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 6
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
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
              "hlsl_register_t_n": 7
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
              "hlsl_register_t_n": 8
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 6
          },
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
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
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
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _63_lift : packoffset(c0);\n    float _63_fa_pad0 : packoffset(c0.y);\n    float _63_fa_pad1 : packoffset(c0.z);\n    float _63_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _160_fa_view_proj : packoffset(c0);\n    row_major float4x4 _160_fa_light_vp : packoffset(c4);\n    float4 _160_fa_uv_scale : packoffset(c8);\n    float4 _160_fa_time : packoffset(c9);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _103 = cross(model[1].xyz, model[2].xyz);\n    float _108 = (dot(model[0].xyz, _103) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _325 = { mul(float4(position, 1.0f), model).xyz, (((_103 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _108, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _108), texcoord0 * _160_fa_uv_scale.xy, color, position };\n    return _325;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _63_lift);\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _204 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_204, _160_fa_light_vp).z;\n    fa_pre_r0 = float3(_160_fa_light_vp[0].x, _160_fa_light_vp[1].x, _160_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_160_fa_light_vp[0].y, _160_fa_light_vp[1].y, _160_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_160_fa_light_vp[0].z, _160_fa_light_vp[1].z, _160_fa_light_vp[2].z);\n    gl_Position = mul(_204, _160_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _229_fa_camera_pos : packoffset(c0);\n    float4 _229_fa_ambient : packoffset(c1);\n    float4 _229_fa_base_color : packoffset(c2);\n    float4 _229_fa_emissive : packoffset(c3);\n    float4 _229_fa_model_emissive : packoffset(c4);\n    float4 _229_fa_pbr : packoffset(c5);\n    float4 _229_fa_maps : packoffset(c6);\n    float4 _229_fa_fog : packoffset(c7);\n    float4 _229_fa_fog_b : packoffset(c8);\n    float4 _229_fa_fog_c : packoffset(c9);\n    float4 _229_fa_counts : packoffset(c10);\n    float4 _229_fa_env_sky : packoffset(c11);\n    float4 _229_fa_env_horizon : packoffset(c12);\n    float4 _229_fa_time : packoffset(c13);\n    float4 _229_fa_layers_a : packoffset(c14);\n    float4 _229_fa_layers_b : packoffset(c15);\n    float4 _229_fa_layers_c : packoffset(c16);\n    float4 _229_fa_layers_d : packoffset(c17);\n};\n\nTexture2D<float4> height : register(t5);\nSamplerState height_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _196 = fa_linear_to_srgb(param);\n        c = _196;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _204 = fa_srgb_to_linear(param_1);\n            c = _204;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _229_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _240 = fa_tex_fix(param_2, param_3);\n    float4 _747 = base_t;\n    _747.x = _240.x;\n    _747.y = _240.y;\n    _747.z = _240.z;\n    base_t = _747;\n    float4 _256 = (_747 * _229_fa_base_color) * i.vertex_color;\n    float3 _710 = i.world_normal;\n    if (_229_fa_maps.z > 0.5f)\n    {\n        float param_4 = _229_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _293 = (_289 * 2.0f) - 1.0f.xxx;\n        float2 _298 = _293.xy * _229_fa_maps.x;\n        float3 _755 = _293;\n        _755.x = _298.x;\n        _755.y = _298.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _755;\n        _710 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _229_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _327 = fa_tex_fix(param_12, param_13);\n    float4 _758 = mrt;\n    _758.x = _327.x;\n    _758.y = _327.y;\n    _758.z = _327.z;\n    mrt = _758;\n    float4 _357 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _229_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _357.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _369 = fa_tex_fix(param_16, param_17);\n    float param_18 = _229_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _399 = fa_tex_fix(param_20, param_21);\n    float _715 = _229_fa_layers_a.x;\n    float _716 = _229_fa_layers_a.y;\n    float _719 = _229_fa_layers_a.z;\n    float _718 = _229_fa_layers_b.w;\n    float _721 = _229_fa_layers_c.x;\n    if (_229_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_229_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _715 *= _369.y;\n            _716 *= _369.z;\n            _718 *= _357.w;\n        }\n        if (_229_fa_layers_c.z > 1.5f)\n        {\n            _719 *= mrt.x;\n            _721 *= mrt.w;\n        }\n    }\n    Surface _740 = { _256.xyz, _256.w, _710, clamp(_229_fa_pbr.x * _327.z, 0.0f, 1.0f), clamp(_229_fa_pbr.y * _327.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_229_fa_maps.y * (_369.x - 1.0f)), _229_fa_emissive.xyz + (_229_fa_model_emissive.xyz * _399), _715, _716, _229_fa_layers_b.xyz, _718, _719, _229_fa_layers_a.w, _721, _229_fa_layers_c.y, _229_fa_layers_d.xyz };\n    return _740;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= lerp(0.5f, 1.0f, height.Sample(height_smp, i.uv).x);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _621 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _621 = -_621;\n    }\n    float3 _531 = normalize(_229_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _634 = { fa_world_pos, _621, fa_world_tangent, fa_uv, fa_vertex_color, _531, gl_FrontFacing };\n    SurfaceInput param = _634;\n    SurfaceInput _642 = { fa_world_pos, _621, fa_world_tangent, fa_uv, fa_vertex_color, _531, gl_FrontFacing };\n    SurfaceInput param_1 = _642;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _546 = normalize(param_2.normal);\n    float3 _561 = normalize(float3(dot(fa_pre_r0, _546), dot(fa_pre_r1, _546), dot(fa_pre_r2, _546)));\n    float _573 = _561.z;\n    float2 e = _561.xy / ((abs(_561.x) + abs(_561.y)) + abs(_573)).xx;\n    if (_573 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_63",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_160",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_229",
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
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
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
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _68_lift : packoffset(c0);\n    float _68_fa_pad0 : packoffset(c0.y);\n    float _68_fa_pad1 : packoffset(c0.z);\n    float _68_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _165_fa_view_proj : packoffset(c0);\n    row_major float4x4 _165_fa_light_vp : packoffset(c4);\n    float4 _165_fa_uv_scale : packoffset(c8);\n    float4 _165_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _212_fa_joint_rows[192] : packoffset(c0);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _203 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_212_fa_joint_rows[_203] * weights[i]);\n        r1 += (_212_fa_joint_rows[_203 + 1] * weights[i]);\n        r2 += (_212_fa_joint_rows[_203 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _108 = cross(model[1].xyz, model[2].xyz);\n    float _113 = (dot(model[0].xyz, _108) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _446 = { mul(float4(position, 1.0f), model).xyz, (((_108 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _113, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _113), texcoord0 * _165_fa_uv_scale.xy, color, position };\n    return _446;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _68_lift);\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _317 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_317, _165_fa_light_vp).z;\n    fa_pre_r0 = float3(_165_fa_light_vp[0].x, _165_fa_light_vp[1].x, _165_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_165_fa_light_vp[0].y, _165_fa_light_vp[1].y, _165_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_165_fa_light_vp[0].z, _165_fa_light_vp[1].z, _165_fa_light_vp[2].z);\n    gl_Position = mul(_317, _165_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _229_fa_camera_pos : packoffset(c0);\n    float4 _229_fa_ambient : packoffset(c1);\n    float4 _229_fa_base_color : packoffset(c2);\n    float4 _229_fa_emissive : packoffset(c3);\n    float4 _229_fa_model_emissive : packoffset(c4);\n    float4 _229_fa_pbr : packoffset(c5);\n    float4 _229_fa_maps : packoffset(c6);\n    float4 _229_fa_fog : packoffset(c7);\n    float4 _229_fa_fog_b : packoffset(c8);\n    float4 _229_fa_fog_c : packoffset(c9);\n    float4 _229_fa_counts : packoffset(c10);\n    float4 _229_fa_env_sky : packoffset(c11);\n    float4 _229_fa_env_horizon : packoffset(c12);\n    float4 _229_fa_time : packoffset(c13);\n    float4 _229_fa_layers_a : packoffset(c14);\n    float4 _229_fa_layers_b : packoffset(c15);\n    float4 _229_fa_layers_c : packoffset(c16);\n    float4 _229_fa_layers_d : packoffset(c17);\n};\n\nTexture2D<float4> height : register(t5);\nSamplerState height_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _196 = fa_linear_to_srgb(param);\n        c = _196;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _204 = fa_srgb_to_linear(param_1);\n            c = _204;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _229_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _240 = fa_tex_fix(param_2, param_3);\n    float4 _747 = base_t;\n    _747.x = _240.x;\n    _747.y = _240.y;\n    _747.z = _240.z;\n    base_t = _747;\n    float4 _256 = (_747 * _229_fa_base_color) * i.vertex_color;\n    float3 _710 = i.world_normal;\n    if (_229_fa_maps.z > 0.5f)\n    {\n        float param_4 = _229_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _293 = (_289 * 2.0f) - 1.0f.xxx;\n        float2 _298 = _293.xy * _229_fa_maps.x;\n        float3 _755 = _293;\n        _755.x = _298.x;\n        _755.y = _298.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _755;\n        _710 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _229_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _327 = fa_tex_fix(param_12, param_13);\n    float4 _758 = mrt;\n    _758.x = _327.x;\n    _758.y = _327.y;\n    _758.z = _327.z;\n    mrt = _758;\n    float4 _357 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _229_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _357.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _369 = fa_tex_fix(param_16, param_17);\n    float param_18 = _229_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _399 = fa_tex_fix(param_20, param_21);\n    float _715 = _229_fa_layers_a.x;\n    float _716 = _229_fa_layers_a.y;\n    float _719 = _229_fa_layers_a.z;\n    float _718 = _229_fa_layers_b.w;\n    float _721 = _229_fa_layers_c.x;\n    if (_229_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_229_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _715 *= _369.y;\n            _716 *= _369.z;\n            _718 *= _357.w;\n        }\n        if (_229_fa_layers_c.z > 1.5f)\n        {\n            _719 *= mrt.x;\n            _721 *= mrt.w;\n        }\n    }\n    Surface _740 = { _256.xyz, _256.w, _710, clamp(_229_fa_pbr.x * _327.z, 0.0f, 1.0f), clamp(_229_fa_pbr.y * _327.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_229_fa_maps.y * (_369.x - 1.0f)), _229_fa_emissive.xyz + (_229_fa_model_emissive.xyz * _399), _715, _716, _229_fa_layers_b.xyz, _718, _719, _229_fa_layers_a.w, _721, _229_fa_layers_c.y, _229_fa_layers_d.xyz };\n    return _740;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= lerp(0.5f, 1.0f, height.Sample(height_smp, i.uv).x);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _621 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _621 = -_621;\n    }\n    float3 _531 = normalize(_229_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _634 = { fa_world_pos, _621, fa_world_tangent, fa_uv, fa_vertex_color, _531, gl_FrontFacing };\n    SurfaceInput param = _634;\n    SurfaceInput _642 = { fa_world_pos, _621, fa_world_tangent, fa_uv, fa_vertex_color, _531, gl_FrontFacing };\n    SurfaceInput param_1 = _642;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _546 = normalize(param_2.normal);\n    float3 _561 = normalize(float3(dot(fa_pre_r0, _546), dot(fa_pre_r1, _546), dot(fa_pre_r2, _546)));\n    float _573 = _561.z;\n    float2 e = _561.xy / ((abs(_561.x) + abs(_561.y)) + abs(_573)).xx;\n    if (_573 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_68",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_165",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_212",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_229",
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
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
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
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _54_lift : packoffset(c0);\n    float _54_fa_pad0 : packoffset(c0.y);\n    float _54_fa_pad1 : packoffset(c0.z);\n    float _54_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _151_fa_view_proj : packoffset(c0);\n    row_major float4x4 _151_fa_light_vp : packoffset(c4);\n    float4 _151_fa_uv_scale : packoffset(c8);\n    float4 _151_fa_time : packoffset(c9);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _99 = (dot(model[0].xyz, _94) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _277 = { mul(float4(position, 1.0f), model).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _99, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _99), texcoord0 * _151_fa_uv_scale.xy, color, position };\n    return _277;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _54_lift);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _151_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_54",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_151",
            "hlsl_register_b_n": 0
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 6
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _59_lift : packoffset(c0);\n    float _59_fa_pad0 : packoffset(c0.y);\n    float _59_fa_pad1 : packoffset(c0.z);\n    float _59_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _156_fa_view_proj : packoffset(c0);\n    row_major float4x4 _156_fa_light_vp : packoffset(c4);\n    float4 _156_fa_uv_scale : packoffset(c8);\n    float4 _156_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _203_fa_joint_rows[192] : packoffset(c0);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _194 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_203_fa_joint_rows[_194] * weights[i]);\n        r1 += (_203_fa_joint_rows[_194 + 1] * weights[i]);\n        r2 += (_203_fa_joint_rows[_194 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _104 = (dot(model[0].xyz, _99) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _398 = { mul(float4(position, 1.0f), model).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _104, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _104), texcoord0 * _156_fa_uv_scale.xy, color, position };\n    return _398;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _59_lift);\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mul(float4(param_8.world_pos, 1.0f), _156_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_59",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_156",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_203",
            "hlsl_register_b_n": 3
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 6
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          }
        ]
      }
    }
  }
}
