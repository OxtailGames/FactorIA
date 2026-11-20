{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "738bdbaa5d236ca82c68b48e7af94b35c54ba5d6311eabf2bcbbc814ba3d221c",
  "slang": "hlsl5",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _261 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _261;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_268, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1863[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _3649 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _286_fa_camera_pos : packoffset(c0);\n    float4 _286_fa_ambient : packoffset(c1);\n    float4 _286_fa_base_color : packoffset(c2);\n    float4 _286_fa_emissive : packoffset(c3);\n    float4 _286_fa_model_emissive : packoffset(c4);\n    float4 _286_fa_pbr : packoffset(c5);\n    float4 _286_fa_maps : packoffset(c6);\n    float4 _286_fa_fog : packoffset(c7);\n    float4 _286_fa_fog_b : packoffset(c8);\n    float4 _286_fa_fog_c : packoffset(c9);\n    float4 _286_fa_counts : packoffset(c10);\n    float4 _286_fa_env_sky : packoffset(c11);\n    float4 _286_fa_env_horizon : packoffset(c12);\n    float4 _286_fa_time : packoffset(c13);\n    float4 _286_fa_cl_vpx : packoffset(c14);\n    float4 _286_fa_cl_vpy : packoffset(c15);\n    float4 _286_fa_cl_vpw : packoffset(c16);\n    float4 _286_fa_cl_fwd : packoffset(c17);\n    float4 _286_fa_cl_grid : packoffset(c18);\n    float4 _286_fa_cl_info : packoffset(c19);\n    float4 _286_fa_layers_a : packoffset(c20);\n    float4 _286_fa_layers_b : packoffset(c21);\n    float4 _286_fa_layers_c : packoffset(c22);\n    float4 _286_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _990_fa_shadow_mat[4] : packoffset(c0);\n    float4 _990_fa_shadow_rect[4] : packoffset(c16);\n    float4 _990_fa_shadow_info[4] : packoffset(c20);\n    float4 _990_fa_shadow_split : packoffset(c24);\n    float4 _990_fa_shadow_cfg : packoffset(c25);\n    float4 _990_fa_shadow_bias : packoffset(c26);\n    float4 _990_fa_shadow_eye : packoffset(c27);\n    float4 _990_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _2586_dark : packoffset(c0);\n    float _2586_fa_pad0 : packoffset(c0.y);\n    float _2586_fa_pad1 : packoffset(c0.z);\n    float _2586_fa_pad2 : packoffset(c0.w);\n    float _2586_skyAmount : packoffset(c1);\n    float _2586_fa_pad3 : packoffset(c1.y);\n    float _2586_fa_pad4 : packoffset(c1.z);\n    float _2586_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _759 = _286_fa_cl_info.x < 0.0f;\n    bool _766;\n    if (!_759)\n    {\n        _766 = _286_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _766 = _759;\n    }\n    bool _774;\n    if (!_766)\n    {\n        _774 = _286_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _774 = _766;\n    }\n    bool _781;\n    if (!_774)\n    {\n        _781 = _286_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _781 = _774;\n    }\n    bool _788;\n    if (!_781)\n    {\n        _788 = _286_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _788 = _781;\n    }\n    if (_788)\n    {\n        return int2(0, 0);\n    }\n    float4 _798 = float4(world_pos, 1.0f);\n    float _805 = dot(_286_fa_cl_vpw, _798);\n    if (!(_805 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _827 = float2(dot(_286_fa_cl_vpx, _798), dot(_286_fa_cl_vpy, _798)) / _805.xx;\n    int _831 = int(_286_fa_cl_grid.x);\n    int _835 = int(_286_fa_cl_grid.y);\n    int param = (int(_286_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_286_fa_cl_fwd.xyz, world_pos) + _286_fa_cl_fwd.w, _286_fa_cl_grid.w) / _286_fa_cl_grid.w) * _286_fa_cl_grid.z)), 0, int(_286_fa_cl_info.y) - 1) * _835) + clamp(int(floor(((_827.y * 0.5f) + 0.5f) * _286_fa_cl_grid.y)), 0, _835 - 1)) * _831)) + clamp(int(floor(((_827.x * 0.5f) + 0.5f) * _286_fa_cl_grid.x)), 0, _831 - 1);\n    float4 _906 = fa_light_texel(param);\n    return int2(int(_906.x), int(_906.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_286_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2411 = fa_cluster_lookup(param);\n    fa_cl_slot = _2411.x;\n    fa_cl_local = _2411.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2658 = fa_linear_to_srgb(param);\n        c = _2658;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2666 = fa_srgb_to_linear(param_1);\n            c = _2666;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _218;\n    if (i.front_facing)\n    {\n        _218 = i.world_normal;\n    }\n    else\n    {\n        _218 = -i.world_normal;\n    }\n    float3 _242 = normalize(i.world_tangent.xyz - (_218 * dot(_218, i.world_tangent.xyz)));\n    float3 _270 = normalize(((_242 * m.x) + ((cross(_218, _242) * i.world_tangent.w) * m.y)) + (_218 * m.z));\n    float3 _273;\n    if (i.front_facing)\n    {\n        _273 = _270;\n    }\n    else\n    {\n        _273 = -_270;\n    }\n    return _273;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _286_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2697 = fa_tex_fix(param_2, param_3);\n    float4 _3619 = base_t;\n    _3619.x = _2697.x;\n    _3619.y = _2697.y;\n    _3619.z = _2697.z;\n    base_t = _3619;\n    float4 _2711 = (_3619 * _286_fa_base_color) * i.vertex_color;\n    float3 _3543 = i.world_normal;\n    if (_286_fa_maps.z > 0.5f)\n    {\n        float param_4 = _286_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2743 = fa_tex_fix(param_6, param_7);\n        float3 _2747 = (_2743 * 2.0f) - 1.0f.xxx;\n        float2 _2752 = _2747.xy * _286_fa_maps.x;\n        float3 _3627 = _2747;\n        _3627.x = _2752.x;\n        _3627.y = _2752.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3627;\n        _3543 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _286_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2780 = fa_tex_fix(param_12, param_13);\n    float4 _3630 = mrt;\n    _3630.x = _2780.x;\n    _3630.y = _2780.y;\n    _3630.z = _2780.z;\n    mrt = _3630;\n    float4 _2808 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _286_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2808.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2820 = fa_tex_fix(param_16, param_17);\n    float param_18 = _286_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2850 = fa_tex_fix(param_20, param_21);\n    float _3548 = _286_fa_layers_a.x;\n    float _3549 = _286_fa_layers_a.y;\n    float _3552 = _286_fa_layers_a.z;\n    float _3551 = _286_fa_layers_b.w;\n    float _3554 = _286_fa_layers_c.x;\n    if (_286_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_286_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3548 *= _2820.y;\n            _3549 *= _2820.z;\n            _3551 *= _2808.w;\n        }\n        if (_286_fa_layers_c.z > 1.5f)\n        {\n            _3552 *= mrt.x;\n            _3554 *= mrt.w;\n        }\n    }\n    Surface _3573 = { _2711.xyz, _2711.w, _3543, clamp(_286_fa_pbr.x * _2780.z, 0.0f, 1.0f), clamp(_286_fa_pbr.y * _2780.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_286_fa_maps.y * (_2820.x - 1.0f)), _286_fa_emissive.xyz + (_286_fa_model_emissive.xyz * _2850), _3548, _3549, _286_fa_layers_b.xyz, _3551, _3552, _286_fa_layers_a.w, _3554, _286_fa_layers_c.y, _286_fa_layers_d.xyz };\n    return _3573;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _3649;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_286_fa_cl_info.x) + int(_286_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_286_fa_counts.y > 4.5f) ? 8 : 4);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _327_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _327_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _367 = dot(d, right);\n    float _371 = dot(d, up);\n    float _382;\n    if (((_367 * _367) + (_371 * _371)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _382 = atan2(_371, _367) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _382 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_382 - floor(_382)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li;\n    int _415 = fa_light_base(param);\n    bool _419 = _286_fa_counts.y > 4.5f;\n    int param_1 = _415;\n    float4 _423 = fa_light_texel(param_1);\n    int param_2 = _415 + 1;\n    float4 _428 = fa_light_texel(param_2);\n    float _431 = _428.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _443 = _419 && (_431 > 2.5f);\n    fa_light_is_area = _443;\n    bool _446 = _431 < 0.5f;\n    float3 l;\n    if (_446)\n    {\n        l = normalize(_423.xyz);\n        if (_419)\n        {\n            int param_3 = _415 + 6;\n            float4 _460 = fa_light_texel(param_3);\n            if (_460.z > 0.5f)\n            {\n                int param_4 = _415 + 4;\n                float4 _470 = fa_light_texel(param_4);\n                int param_5 = _415 + 5;\n                float4 _476 = fa_light_texel(param_5);\n                float2 param_6 = _460.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _470.xyz) * _470.w, (-dot(world_pos, _476.xyz)) * _476.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _508 = _423.xyz - world_pos;\n        float _510 = length(_508);\n        dist = _510;\n        l = _508 / max(_510, 9.9999997473787516355514526367188e-05f).xxx;\n        float reach = _510;\n        if (_443)\n        {\n            int param_8 = _415 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0f);\n        }\n        float _542 = reach / max(_423.w, 0.001000000047497451305389404296875f);\n        float _548 = clamp(1.0f - (_542 * _542), 0.0f, 1.0f);\n        atten = _548 * _548;\n        bool _556 = _431 < 2.5f;\n        if ((_431 > 1.5f) && _556)\n        {\n            int param_9 = _415 + 2;\n            float4 _564 = fa_light_texel(param_9);\n            float _574 = _564.w;\n            int param_10 = _415 + 3;\n            float4 _580 = fa_light_texel(param_10);\n            float _581 = _580.x;\n            float cos_inner = _581;\n            if (_581 > 1.5f)\n            {\n                cos_inner = lerp(_574, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_574, cos_inner, dot(-l, normalize(_564.xyz)));\n        }\n        if (_419 && _556)\n        {\n            int param_11 = _415 + 6;\n            float4 _605 = fa_light_texel(param_11);\n            int param_12 = _415 + 7;\n            float4 _610 = fa_light_texel(param_12);\n            bool _613 = _605.z > 0.5f;\n            bool _620;\n            if (!_613)\n            {\n                _620 = _610.z > 0.5f;\n            }\n            else\n            {\n                _620 = _613;\n            }\n            if (_620)\n            {\n                int param_13 = _415 + 2;\n                float4 _627 = fa_light_texel(param_13);\n                float3 _631 = normalize(_627.xyz);\n                int param_14 = _415 + 4;\n                float4 _636 = fa_light_texel(param_14);\n                int param_15 = _415 + 5;\n                float4 _641 = fa_light_texel(param_15);\n                if (_613)\n                {\n                    float3 _649 = -_508;\n                    float _656 = _627.w;\n                    float _672 = 0.5f / max(dot(_649, _631) * (sqrt(max(1.0f - (_656 * _656), 0.0f)) / max(_656, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                    float2 param_16 = _605.xy;\n                    float2 param_17 = float2(0.5f + (dot(_649, _636.xyz) * _672), 0.5f - (dot(_649, _641.xyz) * _672));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_610.z > 0.5f)\n                {\n                    float2 param_18 = _610.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _631;\n                    float3 param_21 = _636.xyz;\n                    float3 param_22 = _641.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    float3 _3381 = _428.xyz * atten;\n    if (_419)\n    {\n        _3381 *= fa_light_tint;\n    }\n    int _741;\n    if (_446)\n    {\n        _741 = 0;\n    }\n    else\n    {\n        _741 = ((_431 > 1.5f) && (_431 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _3392 = { l, _3381, atten, 1.0f, dist, _741 };\n    return _3392;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _2496 = n < 0;\n    bool _2503;\n    if (!_2496)\n    {\n        _2503 = n >= fa_light_count();\n    }\n    else\n    {\n        _2503 = _2496;\n    }\n    if (_2503)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    LightSample _2515 = fa_light_sample(param_1, param_2);\n    return _2515;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _980;\n    if (i == 0)\n    {\n        _980 = _990_fa_shadow_split.x;\n    }\n    else\n    {\n        float _996;\n        if (i == 1)\n        {\n            _996 = _990_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1004;\n            if (i == 2)\n            {\n                _1004 = _990_fa_shadow_split.z;\n            }\n            else\n            {\n                _1004 = _990_fa_shadow_split.w;\n            }\n            _996 = _1004;\n        }\n        _980 = _996;\n    }\n    return _980;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _968 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_968), sin(_968)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1042 = max(_990_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1047 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1053 = sqrt(1.0f - (_1047 * _1047));\n    float _1061 = min(_1053 / max(_1047, 0.20000000298023223876953125f), 4.0f);\n    float _1066;\n    if (_990_fa_shadow_bias.y > 0.0f)\n    {\n        _1066 = _990_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1066 = 1.5f * _990_fa_shadow_info[ci].x;\n    }\n    float4 _1091 = mul(float4(world + (n * (_1066 * _1053)), 1.0f), _990_fa_shadow_mat[ci]);\n    float _1098 = _1091.x;\n    bool _1101 = _1098 < _990_fa_shadow_rect[ci].x;\n    bool _1110;\n    if (!_1101)\n    {\n        _1110 = _1098 > _990_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1110 = _1101;\n    }\n    bool _1119;\n    if (!_1110)\n    {\n        _1119 = _1091.y < _990_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1119 = _1110;\n    }\n    bool _1128;\n    if (!_1119)\n    {\n        _1128 = _1091.y > _990_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1128 = _1119;\n    }\n    bool _1135;\n    if (!_1128)\n    {\n        _1135 = _1091.z > 1.0f;\n    }\n    else\n    {\n        _1135 = _1128;\n    }\n    if (_1135)\n    {\n        return -1.0f;\n    }\n    float _1143;\n    if (_990_fa_shadow_bias.x > 0.0f)\n    {\n        _1143 = _990_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1143 = 1.5f * _990_fa_shadow_info[ci].x;\n    }\n    float _1162 = _1091.z - ((_1143 * (1.0f + (0.5f * _1061))) / _1042);\n    float _1171 = ((_990_fa_shadow_info[ci].x * min(_1061, 3.0f)) * 0.5f) / _1042;\n    int _1180 = int(_990_fa_shadow_cfg.z + 0.5f);\n    if (_1180 == 1)\n    {\n        float2 param = _1091.xy;\n        float4 param_1 = _990_fa_shadow_rect[ci];\n        float _1191 = fa_shadow_depth(param, param_1);\n        return float(_1162 <= _1191);\n    }\n    float _1198 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _1201 = _1180 == 2;\n    if (_1201)\n    {\n        float _1215 = clamp(((_990_fa_shadow_cfg.w * _1042) * 0.25f) / _990_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1198;\n            float2 _1234 = fa_shadow_vogel(param_2, param_3, param_4) * _1215;\n            float2 param_5 = _1091.xy + (_1234 * _990_fa_shadow_bias.zw);\n            float4 param_6 = _990_fa_shadow_rect[ci];\n            float _1245 = fa_shadow_depth(param_5, param_6);\n            if (_1245 < (_1162 - (length(_1234) * _1171)))\n            {\n                sum += _1245;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_1162 - (sum / cnt), 0.0f) * _1042) * _990_fa_shadow_cfg.w) / _990_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1289 = _1201 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1289; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1289;\n        float param_9 = _1198;\n        float2 _1308 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1091.xy + (_1308 * _990_fa_shadow_bias.zw);\n        float4 param_11 = _990_fa_shadow_rect[ci];\n        float _1319 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1162 - (length(_1308) * _1171)) <= _1319);\n    }\n    return lit / float(_1289);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_286_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1349 = int(_990_fa_shadow_cfg.x + 0.5f);\n    if (_1349 < 1)\n    {\n        return 1.0f;\n    }\n    float _1364 = dot(world - _990_fa_shadow_eye.xyz, _990_fa_shadow_fwd.xyz);\n    int param = _1349 - 1;\n    if (_1364 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1376 = _1349 > 1;\n    bool _1383;\n    if (_1376)\n    {\n        _1383 = _1364 > _990_fa_shadow_split.x;\n    }\n    else\n    {\n        _1383 = _1376;\n    }\n    if (_1383)\n    {\n        ci = 1;\n    }\n    bool _1387 = _1349 > 2;\n    bool _1394;\n    if (_1387)\n    {\n        _1394 = _1364 > _990_fa_shadow_split.y;\n    }\n    else\n    {\n        _1394 = _1387;\n    }\n    if (_1394)\n    {\n        ci = 2;\n    }\n    bool _1398 = _1349 > 3;\n    bool _1405;\n    if (_1398)\n    {\n        _1405 = _1364 > _990_fa_shadow_split.z;\n    }\n    else\n    {\n        _1405 = _1398;\n    }\n    if (_1405)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1349)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1431 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1431;\n        if (_1431 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_990_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1456;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1456 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1456 = _990_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1475 = _990_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1456, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1486 = clamp((_1364 - (fa_shadow_split_at(param_7) - _1475)) / _1475, 0.0f, 1.0f);\n        if (_1486 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1349)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1507 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1507;\n                if (_1507 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1486);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2439 = fa_light_sample(param, param_1);\n    float3 _3514 = _2439.color;\n    float _3516 = _2439.shadow;\n    if ((_2439.type == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2439.direction;\n        float _2453 = fa_shadow_factor(param_2, param_3);\n        _3516 = _2453;\n        _3514 *= _2453;\n    }\n    LightSample _3531 = { _2439.direction, _3514, _2439.attenuation, _3516, _2439._distance, _2439.type };\n    return _3531;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _2470 = n < 0;\n    bool _2477;\n    if (!_2470)\n    {\n        _2477 = n >= fa_light_count();\n    }\n    else\n    {\n        _2477 = _2470;\n    }\n    if (_2477)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _2492 = fa_light_shadowed(param_1, param_2, param_3);\n    return _2492;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1788 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1796 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1799 = int(_1788);\n    int _1802 = int(_1796);\n    float _1812 = _1796 - float(_1802);\n    int _1868 = (_1799 * 9) + _1802;\n    int _1888 = ((_1799 + 1) * 9) + _1802;\n    return lerp(lerp(_1863[_1868], _1863[_1868 + 1], _1812), lerp(_1863[_1888], _1863[_1888 + 1], _1812), _1788 - float(_1799));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3393 = false;\n    float _3394 = 1.0f;\n    float _3395 = 1.0f;\n    float _3396 = 1.0f;\n    float _3397 = 0.0f;\n    float _3398 = 0.0f;\n    float _3399 = 0.0f;\n    float _3400 = 0.0f;\n    float _3402 = 1.0f;\n    bool _3403 = false;\n    float3 _3404 = 0.0f.xxx;\n    float _3405 = 1.0f;\n    float _3406 = 1.0f;\n    float _3407 = 1.0f;\n    float _3408 = 0.0f;\n    float _3409 = 0.0f;\n    float3 _3410 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3411 = float3(0.0f, 0.0f, 1.0f);\n    float _3412 = 1.0f;\n    float _3413 = 1.0f;\n    float _1942 = clamp(s.specular, 0.0f, 1.0f);\n    float _1946 = clamp(s.ior, 1.0f, 3.0f);\n    bool _1951 = (_1942 != 1.0f) || (_1946 != 1.5f);\n    bool _1960;\n    if (!_1951)\n    {\n        _1960 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _1960 = _1951;\n    }\n    if (_1960)\n    {\n        float _1968 = (_1946 - 1.0f) / (_1946 + 1.0f);\n        f0 = lerp(min((_1968 * _1968).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _1942, s.albedo, metallic.xxx);\n        _3394 = lerp(_1942, 1.0f, metallic);\n        _3393 = true;\n    }\n    float _1996 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_1996 > 0.0f)\n    {\n        float _2004 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3397 = _1996;\n        _3398 = _2004;\n        float _2011 = _2004 * _2004;\n        _3399 = _2011;\n        _3400 = _2011 * _2011;\n        float _2023 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3402 = _2023;\n        _3395 = 1.0f - (_1996 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2023, 0.0f, 1.0f), 5.0f))));\n        _3393 = true;\n    }\n    float3 _2043 = max(s.sheen_color, 0.0f.xxx);\n    float _2052 = max(_2043.x, max(_2043.y, _2043.z));\n    if (_2052 > 0.0f)\n    {\n        float _2060 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3403 = true;\n        _3404 = _2043;\n        _3405 = _2060;\n        _3406 = _2060 * _2060;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2060;\n        float _2077 = fa_sheen_albedo(param, param_1);\n        _3408 = _2077;\n        _3407 = 1.0f - min(_2052 * _2077, 1.0f);\n        _3393 = true;\n    }\n    _3396 = _3395 * _3407;\n    float _2096 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2096 != 0.0f)\n    {\n        float3 _2111 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2111;\n        if (dot(_2111, _2111) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2125 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2125.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2125.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2125.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2129 = t;\n        float3 _2130 = normalize(_2129);\n        t = _2130;\n        float3 _2155 = normalize((_2130 * cos(s.anisotropy_rotation)) + ((cross(n, _2130) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3410 = _2155;\n        _3411 = cross(n, _2155);\n        float _2165 = roughness * roughness;\n        float _2171 = lerp(_2165, 1.0f, _2096 * _2096);\n        bool _2173 = _2096 > 0.0f;\n        _3412 = _2173 ? _2171 : _2165;\n        _3413 = _2173 ? _2165 : _2171;\n        _3409 = _2096;\n        _3393 = true;\n    }\n    FaLayers _3435 = { _3393, _3394, _3395, _3396, _3397, _3398, _3399, _3400, i.world_normal, _3402, _3403, _3404, _3405, _3406, _3407, _3408, _3409, _3410, _3411, _3412, _3413 };\n    return _3435;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1720 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1723 = _1720.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1723 * _1723, exp2((-9.27999973297119140625f) * ndv)) * _1723) + _1720.y)) + _1720.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_286_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _286_fa_env_horizon.w).xyz;\n    }\n    float _1643 = rough * rough;\n    float _1673 = 0.60000002384185791015625f * _1643;\n    return lerp(lerp(_286_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_286_fa_env_horizon.xyz, _286_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1643)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1673, 0.0500000007450580596923828125f + _1673, d.y).xxx), ((_286_fa_env_sky.xyz + _286_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1643 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2206;\n        if (L.aniso >= 0.0f)\n        {\n            _2206 = L.b;\n        }\n        else\n        {\n            _2206 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2206, v), _2206), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2239 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2239.x) + (L.f90.xxx * _2239.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2294 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2294.x) + _2294.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1762 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1762.x) + _1762.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2333 = clamp(s.metallic, 0.0f, 1.0f);\n    float _2337 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _2344 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _2333.xxx);\n    float3 f0 = _2344;\n    float3 _2348 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2348;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2333;\n    float param_5 = _2337;\n    float3 param_6 = _2344;\n    FaLayers _2365 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2365.on)\n    {\n        FaLayers param_7 = _2365;\n        float3 param_8 = _2348;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2337;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _2348;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2337;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _2535 = fa_light_unshadowed(param, param_1);\n        float _2543 = dot(_2535.color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_2543 > bestPower)\n        {\n            bestPower = _2543;\n            best = n;\n        }\n    }\n    float3 lit = (_286_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2572 = fa_light(param_2, param_3);\n        float _2580;\n        if (dot(s.normal, _2572.direction) > 0.5f)\n        {\n            _2580 = 1.0f;\n        }\n        else\n        {\n            _2580 = _2586_dark;\n        }\n        lit += ((s.albedo * _2572.color) * _2580);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _2586_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_990_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1531 = int(_990_fa_shadow_cfg.x + 0.5f);\n    float _1541 = dot(world - _990_fa_shadow_eye.xyz, _990_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1546 = _1531 > 0;\n    bool _1555;\n    if (_1546)\n    {\n        int param = _1531 - 1;\n        _1555 = _1541 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1555 = _1546;\n    }\n    if (_1555)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1562 = _1531 > 1;\n        bool _1569;\n        if (_1562)\n        {\n            _1569 = _1541 > _990_fa_shadow_split.x;\n        }\n        else\n        {\n            _1569 = _1562;\n        }\n        if (_1569)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1575 = _1531 > 2;\n        bool _1582;\n        if (_1575)\n        {\n            _1582 = _1541 > _990_fa_shadow_split.y;\n        }\n        else\n        {\n            _1582 = _1575;\n        }\n        if (_1582)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1588 = _1531 > 3;\n        bool _1595;\n        if (_1588)\n        {\n            _1595 = _1541 > _990_fa_shadow_split.z;\n        }\n        else\n        {\n            _1595 = _1588;\n        }\n        if (_1595)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3267 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3267 = -_3267;\n    }\n    float3 _2971 = normalize(_286_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3280 = { fa_world_pos, _3267, fa_world_tangent, fa_uv, fa_vertex_color, _2971, gl_FrontFacing };\n    SurfaceInput param_1 = _3280;\n    Surface _2979 = fa_standard_surface(param_1);\n    float3 _3298 = _2979.albedo;\n    float _3299 = _2979.alpha;\n    float3 _3300 = _2979.normal;\n    float _3301 = _2979.metallic;\n    float _3302 = _2979.roughness;\n    float _3303 = _2979.occlusion;\n    float3 _3304 = _2979.emission;\n    float _3305 = _2979.clearcoat;\n    float _3306 = _2979.clearcoat_roughness;\n    float3 _3307 = _2979.sheen_color;\n    float _3308 = _2979.sheen_roughness;\n    float _3309 = _2979.anisotropy;\n    float _3310 = _2979.anisotropy_rotation;\n    float _3311 = _2979.specular;\n    float _3312 = _2979.ior;\n    float3 _3313 = _2979.specular_color;\n    SurfaceInput _3288 = { fa_world_pos, _3267, fa_world_tangent, fa_uv, fa_vertex_color, _2971, gl_FrontFacing };\n    SurfaceInput param_2 = _3288;\n    Surface param_3 = _2979;\n    surface(param_2, param_3);\n    _3298 = param_3.albedo;\n    _3299 = param_3.alpha;\n    _3300 = param_3.normal;\n    _3301 = param_3.metallic;\n    _3302 = param_3.roughness;\n    _3303 = param_3.occlusion;\n    _3304 = param_3.emission;\n    _3305 = param_3.clearcoat;\n    _3306 = param_3.clearcoat_roughness;\n    _3307 = param_3.sheen_color;\n    _3308 = param_3.sheen_roughness;\n    _3309 = param_3.anisotropy;\n    _3310 = param_3.anisotropy_rotation;\n    _3311 = param_3.specular;\n    _3312 = param_3.ior;\n    _3313 = param_3.specular_color;\n    float3 result;\n    if (_286_fa_emissive.w > 0.5f)\n    {\n        result = _3298;\n    }\n    else\n    {\n        float3 _3000 = _3300;\n        float3 _3001 = normalize(_3000);\n        _3300 = _3001;\n        SurfaceInput _3296 = { fa_world_pos, _3267, fa_world_tangent, fa_uv, fa_vertex_color, _2971, gl_FrontFacing };\n        SurfaceInput param_4 = _3296;\n        Surface _3379 = { _3298, _3299, _3001, _3301, _3302, _3303, _3304, _3305, _3306, _3307, _3308, _3309, _3310, _3311, _3312, _3313 };\n        Surface param_5 = _3379;\n        float3 _3012 = lighting(param_4, param_5);\n        result = _3012;\n    }\n    float3 _3016 = result;\n    float3 _3017 = _3016 + _3304;\n    result = _3017;\n    float3 param_6 = _3017;\n    float3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _3026 = _286_fa_fog.w > 0.0f;\n    bool _3033;\n    if (!_3026)\n    {\n        _3033 = _286_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3033 = _3026;\n    }\n    if (_3033)\n    {\n        float3 _3042 = fa_world_pos - _286_fa_camera_pos.xyz;\n        float _3048 = dot(_3042, _286_fa_fog_c.xyz);\n        bool _3052 = _286_fa_fog_c.w > 0.5f;\n        float _3053;\n        if (_3052)\n        {\n            _3053 = _3048;\n        }\n        else\n        {\n            _3053 = length(_3042);\n        }\n        float _3065 = _3053 - _286_fa_fog_b.x;\n        if (_3065 > 0.0f)\n        {\n            float _3074 = _286_fa_fog.w * _3065;\n            float tau = _3074 * _3074;\n            if (_286_fa_fog_b.y > 0.0f)\n            {\n                float _3090;\n                if (_3052)\n                {\n                    _3090 = fa_world_pos.y - (_286_fa_fog_c.y * _3048);\n                }\n                else\n                {\n                    _3090 = _286_fa_camera_pos.y;\n                }\n                float _3111 = lerp(_3090, fa_world_pos.y, clamp(_286_fa_fog_b.x / _3053, 0.0f, 1.0f));\n                float _3115 = fa_world_pos.y - _3111;\n                float _3120 = _3111 - _286_fa_fog_b.z;\n                float _3125 = fa_world_pos.y - _286_fa_fog_b.z;\n                bool _3128 = _3120 <= 0.0f;\n                bool _3129 = !_3128;\n                bool _3135;\n                if (_3129)\n                {\n                    _3135 = _286_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3135 = _3128;\n                }\n                float _3136;\n                if (_3135)\n                {\n                    _3136 = _286_fa_fog_b.y;\n                }\n                else\n                {\n                    _3136 = _286_fa_fog_b.y * exp(-min(_286_fa_fog_b.w * _3120, 80.0f));\n                }\n                bool _3163;\n                if (_3129)\n                {\n                    _3163 = _286_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3163 = _3128;\n                }\n                float _3164;\n                if (_3163)\n                {\n                    _3164 = _286_fa_fog_b.y * _3120;\n                }\n                else\n                {\n                    _3164 = (_286_fa_fog_b.y * (1.0f - exp(-min(_286_fa_fog_b.w * _3120, 80.0f)))) / _286_fa_fog_b.w;\n                }\n                bool _3189 = _3125 <= 0.0f;\n                bool _3196;\n                if (!_3189)\n                {\n                    _3196 = _286_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3196 = _3189;\n                }\n                float _3197;\n                if (_3196)\n                {\n                    _3197 = _286_fa_fog_b.y * _3125;\n                }\n                else\n                {\n                    _3197 = (_286_fa_fog_b.y * (1.0f - exp(-min(_286_fa_fog_b.w * _3125, 80.0f)))) / _286_fa_fog_b.w;\n                }\n                float _3224;\n                if (abs(_3115) < 0.001000000047497451305389404296875f)\n                {\n                    _3224 = _3136;\n                }\n                else\n                {\n                    _3224 = (_3197 - _3164) / _3115;\n                }\n                tau += (_3065 * max(_3224, 0.0f));\n            }\n            result = lerp(result, _286_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3299);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_286",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_990",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2586",
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 8,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _382 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _382;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _389 = _273.world_pos;\n    fa_world_pos = _389;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_389, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1863[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _3649 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _286_fa_camera_pos : packoffset(c0);\n    float4 _286_fa_ambient : packoffset(c1);\n    float4 _286_fa_base_color : packoffset(c2);\n    float4 _286_fa_emissive : packoffset(c3);\n    float4 _286_fa_model_emissive : packoffset(c4);\n    float4 _286_fa_pbr : packoffset(c5);\n    float4 _286_fa_maps : packoffset(c6);\n    float4 _286_fa_fog : packoffset(c7);\n    float4 _286_fa_fog_b : packoffset(c8);\n    float4 _286_fa_fog_c : packoffset(c9);\n    float4 _286_fa_counts : packoffset(c10);\n    float4 _286_fa_env_sky : packoffset(c11);\n    float4 _286_fa_env_horizon : packoffset(c12);\n    float4 _286_fa_time : packoffset(c13);\n    float4 _286_fa_cl_vpx : packoffset(c14);\n    float4 _286_fa_cl_vpy : packoffset(c15);\n    float4 _286_fa_cl_vpw : packoffset(c16);\n    float4 _286_fa_cl_fwd : packoffset(c17);\n    float4 _286_fa_cl_grid : packoffset(c18);\n    float4 _286_fa_cl_info : packoffset(c19);\n    float4 _286_fa_layers_a : packoffset(c20);\n    float4 _286_fa_layers_b : packoffset(c21);\n    float4 _286_fa_layers_c : packoffset(c22);\n    float4 _286_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _990_fa_shadow_mat[4] : packoffset(c0);\n    float4 _990_fa_shadow_rect[4] : packoffset(c16);\n    float4 _990_fa_shadow_info[4] : packoffset(c20);\n    float4 _990_fa_shadow_split : packoffset(c24);\n    float4 _990_fa_shadow_cfg : packoffset(c25);\n    float4 _990_fa_shadow_bias : packoffset(c26);\n    float4 _990_fa_shadow_eye : packoffset(c27);\n    float4 _990_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _2586_dark : packoffset(c0);\n    float _2586_fa_pad0 : packoffset(c0.y);\n    float _2586_fa_pad1 : packoffset(c0.z);\n    float _2586_fa_pad2 : packoffset(c0.w);\n    float _2586_skyAmount : packoffset(c1);\n    float _2586_fa_pad3 : packoffset(c1.y);\n    float _2586_fa_pad4 : packoffset(c1.z);\n    float _2586_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _759 = _286_fa_cl_info.x < 0.0f;\n    bool _766;\n    if (!_759)\n    {\n        _766 = _286_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _766 = _759;\n    }\n    bool _774;\n    if (!_766)\n    {\n        _774 = _286_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _774 = _766;\n    }\n    bool _781;\n    if (!_774)\n    {\n        _781 = _286_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _781 = _774;\n    }\n    bool _788;\n    if (!_781)\n    {\n        _788 = _286_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _788 = _781;\n    }\n    if (_788)\n    {\n        return int2(0, 0);\n    }\n    float4 _798 = float4(world_pos, 1.0f);\n    float _805 = dot(_286_fa_cl_vpw, _798);\n    if (!(_805 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _827 = float2(dot(_286_fa_cl_vpx, _798), dot(_286_fa_cl_vpy, _798)) / _805.xx;\n    int _831 = int(_286_fa_cl_grid.x);\n    int _835 = int(_286_fa_cl_grid.y);\n    int param = (int(_286_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_286_fa_cl_fwd.xyz, world_pos) + _286_fa_cl_fwd.w, _286_fa_cl_grid.w) / _286_fa_cl_grid.w) * _286_fa_cl_grid.z)), 0, int(_286_fa_cl_info.y) - 1) * _835) + clamp(int(floor(((_827.y * 0.5f) + 0.5f) * _286_fa_cl_grid.y)), 0, _835 - 1)) * _831)) + clamp(int(floor(((_827.x * 0.5f) + 0.5f) * _286_fa_cl_grid.x)), 0, _831 - 1);\n    float4 _906 = fa_light_texel(param);\n    return int2(int(_906.x), int(_906.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_286_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2411 = fa_cluster_lookup(param);\n    fa_cl_slot = _2411.x;\n    fa_cl_local = _2411.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2658 = fa_linear_to_srgb(param);\n        c = _2658;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2666 = fa_srgb_to_linear(param_1);\n            c = _2666;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _218;\n    if (i.front_facing)\n    {\n        _218 = i.world_normal;\n    }\n    else\n    {\n        _218 = -i.world_normal;\n    }\n    float3 _242 = normalize(i.world_tangent.xyz - (_218 * dot(_218, i.world_tangent.xyz)));\n    float3 _270 = normalize(((_242 * m.x) + ((cross(_218, _242) * i.world_tangent.w) * m.y)) + (_218 * m.z));\n    float3 _273;\n    if (i.front_facing)\n    {\n        _273 = _270;\n    }\n    else\n    {\n        _273 = -_270;\n    }\n    return _273;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _286_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2697 = fa_tex_fix(param_2, param_3);\n    float4 _3619 = base_t;\n    _3619.x = _2697.x;\n    _3619.y = _2697.y;\n    _3619.z = _2697.z;\n    base_t = _3619;\n    float4 _2711 = (_3619 * _286_fa_base_color) * i.vertex_color;\n    float3 _3543 = i.world_normal;\n    if (_286_fa_maps.z > 0.5f)\n    {\n        float param_4 = _286_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2743 = fa_tex_fix(param_6, param_7);\n        float3 _2747 = (_2743 * 2.0f) - 1.0f.xxx;\n        float2 _2752 = _2747.xy * _286_fa_maps.x;\n        float3 _3627 = _2747;\n        _3627.x = _2752.x;\n        _3627.y = _2752.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3627;\n        _3543 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _286_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2780 = fa_tex_fix(param_12, param_13);\n    float4 _3630 = mrt;\n    _3630.x = _2780.x;\n    _3630.y = _2780.y;\n    _3630.z = _2780.z;\n    mrt = _3630;\n    float4 _2808 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _286_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2808.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2820 = fa_tex_fix(param_16, param_17);\n    float param_18 = _286_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2850 = fa_tex_fix(param_20, param_21);\n    float _3548 = _286_fa_layers_a.x;\n    float _3549 = _286_fa_layers_a.y;\n    float _3552 = _286_fa_layers_a.z;\n    float _3551 = _286_fa_layers_b.w;\n    float _3554 = _286_fa_layers_c.x;\n    if (_286_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_286_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3548 *= _2820.y;\n            _3549 *= _2820.z;\n            _3551 *= _2808.w;\n        }\n        if (_286_fa_layers_c.z > 1.5f)\n        {\n            _3552 *= mrt.x;\n            _3554 *= mrt.w;\n        }\n    }\n    Surface _3573 = { _2711.xyz, _2711.w, _3543, clamp(_286_fa_pbr.x * _2780.z, 0.0f, 1.0f), clamp(_286_fa_pbr.y * _2780.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_286_fa_maps.y * (_2820.x - 1.0f)), _286_fa_emissive.xyz + (_286_fa_model_emissive.xyz * _2850), _3548, _3549, _286_fa_layers_b.xyz, _3551, _3552, _286_fa_layers_a.w, _3554, _286_fa_layers_c.y, _286_fa_layers_d.xyz };\n    return _3573;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _3649;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_286_fa_cl_info.x) + int(_286_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_286_fa_counts.y > 4.5f) ? 8 : 4);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _327_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _327_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _367 = dot(d, right);\n    float _371 = dot(d, up);\n    float _382;\n    if (((_367 * _367) + (_371 * _371)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _382 = atan2(_371, _367) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _382 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_382 - floor(_382)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li;\n    int _415 = fa_light_base(param);\n    bool _419 = _286_fa_counts.y > 4.5f;\n    int param_1 = _415;\n    float4 _423 = fa_light_texel(param_1);\n    int param_2 = _415 + 1;\n    float4 _428 = fa_light_texel(param_2);\n    float _431 = _428.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _443 = _419 && (_431 > 2.5f);\n    fa_light_is_area = _443;\n    bool _446 = _431 < 0.5f;\n    float3 l;\n    if (_446)\n    {\n        l = normalize(_423.xyz);\n        if (_419)\n        {\n            int param_3 = _415 + 6;\n            float4 _460 = fa_light_texel(param_3);\n            if (_460.z > 0.5f)\n            {\n                int param_4 = _415 + 4;\n                float4 _470 = fa_light_texel(param_4);\n                int param_5 = _415 + 5;\n                float4 _476 = fa_light_texel(param_5);\n                float2 param_6 = _460.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _470.xyz) * _470.w, (-dot(world_pos, _476.xyz)) * _476.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _508 = _423.xyz - world_pos;\n        float _510 = length(_508);\n        dist = _510;\n        l = _508 / max(_510, 9.9999997473787516355514526367188e-05f).xxx;\n        float reach = _510;\n        if (_443)\n        {\n            int param_8 = _415 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0f);\n        }\n        float _542 = reach / max(_423.w, 0.001000000047497451305389404296875f);\n        float _548 = clamp(1.0f - (_542 * _542), 0.0f, 1.0f);\n        atten = _548 * _548;\n        bool _556 = _431 < 2.5f;\n        if ((_431 > 1.5f) && _556)\n        {\n            int param_9 = _415 + 2;\n            float4 _564 = fa_light_texel(param_9);\n            float _574 = _564.w;\n            int param_10 = _415 + 3;\n            float4 _580 = fa_light_texel(param_10);\n            float _581 = _580.x;\n            float cos_inner = _581;\n            if (_581 > 1.5f)\n            {\n                cos_inner = lerp(_574, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_574, cos_inner, dot(-l, normalize(_564.xyz)));\n        }\n        if (_419 && _556)\n        {\n            int param_11 = _415 + 6;\n            float4 _605 = fa_light_texel(param_11);\n            int param_12 = _415 + 7;\n            float4 _610 = fa_light_texel(param_12);\n            bool _613 = _605.z > 0.5f;\n            bool _620;\n            if (!_613)\n            {\n                _620 = _610.z > 0.5f;\n            }\n            else\n            {\n                _620 = _613;\n            }\n            if (_620)\n            {\n                int param_13 = _415 + 2;\n                float4 _627 = fa_light_texel(param_13);\n                float3 _631 = normalize(_627.xyz);\n                int param_14 = _415 + 4;\n                float4 _636 = fa_light_texel(param_14);\n                int param_15 = _415 + 5;\n                float4 _641 = fa_light_texel(param_15);\n                if (_613)\n                {\n                    float3 _649 = -_508;\n                    float _656 = _627.w;\n                    float _672 = 0.5f / max(dot(_649, _631) * (sqrt(max(1.0f - (_656 * _656), 0.0f)) / max(_656, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                    float2 param_16 = _605.xy;\n                    float2 param_17 = float2(0.5f + (dot(_649, _636.xyz) * _672), 0.5f - (dot(_649, _641.xyz) * _672));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_610.z > 0.5f)\n                {\n                    float2 param_18 = _610.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _631;\n                    float3 param_21 = _636.xyz;\n                    float3 param_22 = _641.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    float3 _3381 = _428.xyz * atten;\n    if (_419)\n    {\n        _3381 *= fa_light_tint;\n    }\n    int _741;\n    if (_446)\n    {\n        _741 = 0;\n    }\n    else\n    {\n        _741 = ((_431 > 1.5f) && (_431 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _3392 = { l, _3381, atten, 1.0f, dist, _741 };\n    return _3392;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _2496 = n < 0;\n    bool _2503;\n    if (!_2496)\n    {\n        _2503 = n >= fa_light_count();\n    }\n    else\n    {\n        _2503 = _2496;\n    }\n    if (_2503)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    LightSample _2515 = fa_light_sample(param_1, param_2);\n    return _2515;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _980;\n    if (i == 0)\n    {\n        _980 = _990_fa_shadow_split.x;\n    }\n    else\n    {\n        float _996;\n        if (i == 1)\n        {\n            _996 = _990_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1004;\n            if (i == 2)\n            {\n                _1004 = _990_fa_shadow_split.z;\n            }\n            else\n            {\n                _1004 = _990_fa_shadow_split.w;\n            }\n            _996 = _1004;\n        }\n        _980 = _996;\n    }\n    return _980;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _968 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_968), sin(_968)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1042 = max(_990_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1047 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1053 = sqrt(1.0f - (_1047 * _1047));\n    float _1061 = min(_1053 / max(_1047, 0.20000000298023223876953125f), 4.0f);\n    float _1066;\n    if (_990_fa_shadow_bias.y > 0.0f)\n    {\n        _1066 = _990_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1066 = 1.5f * _990_fa_shadow_info[ci].x;\n    }\n    float4 _1091 = mul(float4(world + (n * (_1066 * _1053)), 1.0f), _990_fa_shadow_mat[ci]);\n    float _1098 = _1091.x;\n    bool _1101 = _1098 < _990_fa_shadow_rect[ci].x;\n    bool _1110;\n    if (!_1101)\n    {\n        _1110 = _1098 > _990_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1110 = _1101;\n    }\n    bool _1119;\n    if (!_1110)\n    {\n        _1119 = _1091.y < _990_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1119 = _1110;\n    }\n    bool _1128;\n    if (!_1119)\n    {\n        _1128 = _1091.y > _990_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1128 = _1119;\n    }\n    bool _1135;\n    if (!_1128)\n    {\n        _1135 = _1091.z > 1.0f;\n    }\n    else\n    {\n        _1135 = _1128;\n    }\n    if (_1135)\n    {\n        return -1.0f;\n    }\n    float _1143;\n    if (_990_fa_shadow_bias.x > 0.0f)\n    {\n        _1143 = _990_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1143 = 1.5f * _990_fa_shadow_info[ci].x;\n    }\n    float _1162 = _1091.z - ((_1143 * (1.0f + (0.5f * _1061))) / _1042);\n    float _1171 = ((_990_fa_shadow_info[ci].x * min(_1061, 3.0f)) * 0.5f) / _1042;\n    int _1180 = int(_990_fa_shadow_cfg.z + 0.5f);\n    if (_1180 == 1)\n    {\n        float2 param = _1091.xy;\n        float4 param_1 = _990_fa_shadow_rect[ci];\n        float _1191 = fa_shadow_depth(param, param_1);\n        return float(_1162 <= _1191);\n    }\n    float _1198 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _1201 = _1180 == 2;\n    if (_1201)\n    {\n        float _1215 = clamp(((_990_fa_shadow_cfg.w * _1042) * 0.25f) / _990_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1198;\n            float2 _1234 = fa_shadow_vogel(param_2, param_3, param_4) * _1215;\n            float2 param_5 = _1091.xy + (_1234 * _990_fa_shadow_bias.zw);\n            float4 param_6 = _990_fa_shadow_rect[ci];\n            float _1245 = fa_shadow_depth(param_5, param_6);\n            if (_1245 < (_1162 - (length(_1234) * _1171)))\n            {\n                sum += _1245;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_1162 - (sum / cnt), 0.0f) * _1042) * _990_fa_shadow_cfg.w) / _990_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1289 = _1201 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1289; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1289;\n        float param_9 = _1198;\n        float2 _1308 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1091.xy + (_1308 * _990_fa_shadow_bias.zw);\n        float4 param_11 = _990_fa_shadow_rect[ci];\n        float _1319 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1162 - (length(_1308) * _1171)) <= _1319);\n    }\n    return lit / float(_1289);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_286_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1349 = int(_990_fa_shadow_cfg.x + 0.5f);\n    if (_1349 < 1)\n    {\n        return 1.0f;\n    }\n    float _1364 = dot(world - _990_fa_shadow_eye.xyz, _990_fa_shadow_fwd.xyz);\n    int param = _1349 - 1;\n    if (_1364 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1376 = _1349 > 1;\n    bool _1383;\n    if (_1376)\n    {\n        _1383 = _1364 > _990_fa_shadow_split.x;\n    }\n    else\n    {\n        _1383 = _1376;\n    }\n    if (_1383)\n    {\n        ci = 1;\n    }\n    bool _1387 = _1349 > 2;\n    bool _1394;\n    if (_1387)\n    {\n        _1394 = _1364 > _990_fa_shadow_split.y;\n    }\n    else\n    {\n        _1394 = _1387;\n    }\n    if (_1394)\n    {\n        ci = 2;\n    }\n    bool _1398 = _1349 > 3;\n    bool _1405;\n    if (_1398)\n    {\n        _1405 = _1364 > _990_fa_shadow_split.z;\n    }\n    else\n    {\n        _1405 = _1398;\n    }\n    if (_1405)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1349)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1431 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1431;\n        if (_1431 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_990_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1456;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1456 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1456 = _990_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1475 = _990_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1456, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1486 = clamp((_1364 - (fa_shadow_split_at(param_7) - _1475)) / _1475, 0.0f, 1.0f);\n        if (_1486 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1349)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1507 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1507;\n                if (_1507 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1486);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2439 = fa_light_sample(param, param_1);\n    float3 _3514 = _2439.color;\n    float _3516 = _2439.shadow;\n    if ((_2439.type == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2439.direction;\n        float _2453 = fa_shadow_factor(param_2, param_3);\n        _3516 = _2453;\n        _3514 *= _2453;\n    }\n    LightSample _3531 = { _2439.direction, _3514, _2439.attenuation, _3516, _2439._distance, _2439.type };\n    return _3531;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _2470 = n < 0;\n    bool _2477;\n    if (!_2470)\n    {\n        _2477 = n >= fa_light_count();\n    }\n    else\n    {\n        _2477 = _2470;\n    }\n    if (_2477)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _2492 = fa_light_shadowed(param_1, param_2, param_3);\n    return _2492;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1788 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1796 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1799 = int(_1788);\n    int _1802 = int(_1796);\n    float _1812 = _1796 - float(_1802);\n    int _1868 = (_1799 * 9) + _1802;\n    int _1888 = ((_1799 + 1) * 9) + _1802;\n    return lerp(lerp(_1863[_1868], _1863[_1868 + 1], _1812), lerp(_1863[_1888], _1863[_1888 + 1], _1812), _1788 - float(_1799));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3393 = false;\n    float _3394 = 1.0f;\n    float _3395 = 1.0f;\n    float _3396 = 1.0f;\n    float _3397 = 0.0f;\n    float _3398 = 0.0f;\n    float _3399 = 0.0f;\n    float _3400 = 0.0f;\n    float _3402 = 1.0f;\n    bool _3403 = false;\n    float3 _3404 = 0.0f.xxx;\n    float _3405 = 1.0f;\n    float _3406 = 1.0f;\n    float _3407 = 1.0f;\n    float _3408 = 0.0f;\n    float _3409 = 0.0f;\n    float3 _3410 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3411 = float3(0.0f, 0.0f, 1.0f);\n    float _3412 = 1.0f;\n    float _3413 = 1.0f;\n    float _1942 = clamp(s.specular, 0.0f, 1.0f);\n    float _1946 = clamp(s.ior, 1.0f, 3.0f);\n    bool _1951 = (_1942 != 1.0f) || (_1946 != 1.5f);\n    bool _1960;\n    if (!_1951)\n    {\n        _1960 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _1960 = _1951;\n    }\n    if (_1960)\n    {\n        float _1968 = (_1946 - 1.0f) / (_1946 + 1.0f);\n        f0 = lerp(min((_1968 * _1968).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _1942, s.albedo, metallic.xxx);\n        _3394 = lerp(_1942, 1.0f, metallic);\n        _3393 = true;\n    }\n    float _1996 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_1996 > 0.0f)\n    {\n        float _2004 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3397 = _1996;\n        _3398 = _2004;\n        float _2011 = _2004 * _2004;\n        _3399 = _2011;\n        _3400 = _2011 * _2011;\n        float _2023 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3402 = _2023;\n        _3395 = 1.0f - (_1996 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2023, 0.0f, 1.0f), 5.0f))));\n        _3393 = true;\n    }\n    float3 _2043 = max(s.sheen_color, 0.0f.xxx);\n    float _2052 = max(_2043.x, max(_2043.y, _2043.z));\n    if (_2052 > 0.0f)\n    {\n        float _2060 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3403 = true;\n        _3404 = _2043;\n        _3405 = _2060;\n        _3406 = _2060 * _2060;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2060;\n        float _2077 = fa_sheen_albedo(param, param_1);\n        _3408 = _2077;\n        _3407 = 1.0f - min(_2052 * _2077, 1.0f);\n        _3393 = true;\n    }\n    _3396 = _3395 * _3407;\n    float _2096 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2096 != 0.0f)\n    {\n        float3 _2111 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2111;\n        if (dot(_2111, _2111) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2125 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2125.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2125.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2125.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2129 = t;\n        float3 _2130 = normalize(_2129);\n        t = _2130;\n        float3 _2155 = normalize((_2130 * cos(s.anisotropy_rotation)) + ((cross(n, _2130) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3410 = _2155;\n        _3411 = cross(n, _2155);\n        float _2165 = roughness * roughness;\n        float _2171 = lerp(_2165, 1.0f, _2096 * _2096);\n        bool _2173 = _2096 > 0.0f;\n        _3412 = _2173 ? _2171 : _2165;\n        _3413 = _2173 ? _2165 : _2171;\n        _3409 = _2096;\n        _3393 = true;\n    }\n    FaLayers _3435 = { _3393, _3394, _3395, _3396, _3397, _3398, _3399, _3400, i.world_normal, _3402, _3403, _3404, _3405, _3406, _3407, _3408, _3409, _3410, _3411, _3412, _3413 };\n    return _3435;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1720 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1723 = _1720.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1723 * _1723, exp2((-9.27999973297119140625f) * ndv)) * _1723) + _1720.y)) + _1720.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_286_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _286_fa_env_horizon.w).xyz;\n    }\n    float _1643 = rough * rough;\n    float _1673 = 0.60000002384185791015625f * _1643;\n    return lerp(lerp(_286_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_286_fa_env_horizon.xyz, _286_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1643)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1673, 0.0500000007450580596923828125f + _1673, d.y).xxx), ((_286_fa_env_sky.xyz + _286_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1643 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2206;\n        if (L.aniso >= 0.0f)\n        {\n            _2206 = L.b;\n        }\n        else\n        {\n            _2206 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2206, v), _2206), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2239 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2239.x) + (L.f90.xxx * _2239.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2294 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2294.x) + _2294.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1762 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1762.x) + _1762.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2333 = clamp(s.metallic, 0.0f, 1.0f);\n    float _2337 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _2344 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _2333.xxx);\n    float3 f0 = _2344;\n    float3 _2348 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2348;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2333;\n    float param_5 = _2337;\n    float3 param_6 = _2344;\n    FaLayers _2365 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2365.on)\n    {\n        FaLayers param_7 = _2365;\n        float3 param_8 = _2348;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2337;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _2348;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2337;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _2535 = fa_light_unshadowed(param, param_1);\n        float _2543 = dot(_2535.color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_2543 > bestPower)\n        {\n            bestPower = _2543;\n            best = n;\n        }\n    }\n    float3 lit = (_286_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2572 = fa_light(param_2, param_3);\n        float _2580;\n        if (dot(s.normal, _2572.direction) > 0.5f)\n        {\n            _2580 = 1.0f;\n        }\n        else\n        {\n            _2580 = _2586_dark;\n        }\n        lit += ((s.albedo * _2572.color) * _2580);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _2586_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_990_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1531 = int(_990_fa_shadow_cfg.x + 0.5f);\n    float _1541 = dot(world - _990_fa_shadow_eye.xyz, _990_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1546 = _1531 > 0;\n    bool _1555;\n    if (_1546)\n    {\n        int param = _1531 - 1;\n        _1555 = _1541 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1555 = _1546;\n    }\n    if (_1555)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1562 = _1531 > 1;\n        bool _1569;\n        if (_1562)\n        {\n            _1569 = _1541 > _990_fa_shadow_split.x;\n        }\n        else\n        {\n            _1569 = _1562;\n        }\n        if (_1569)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1575 = _1531 > 2;\n        bool _1582;\n        if (_1575)\n        {\n            _1582 = _1541 > _990_fa_shadow_split.y;\n        }\n        else\n        {\n            _1582 = _1575;\n        }\n        if (_1582)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1588 = _1531 > 3;\n        bool _1595;\n        if (_1588)\n        {\n            _1595 = _1541 > _990_fa_shadow_split.z;\n        }\n        else\n        {\n            _1595 = _1588;\n        }\n        if (_1595)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3267 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3267 = -_3267;\n    }\n    float3 _2971 = normalize(_286_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3280 = { fa_world_pos, _3267, fa_world_tangent, fa_uv, fa_vertex_color, _2971, gl_FrontFacing };\n    SurfaceInput param_1 = _3280;\n    Surface _2979 = fa_standard_surface(param_1);\n    float3 _3298 = _2979.albedo;\n    float _3299 = _2979.alpha;\n    float3 _3300 = _2979.normal;\n    float _3301 = _2979.metallic;\n    float _3302 = _2979.roughness;\n    float _3303 = _2979.occlusion;\n    float3 _3304 = _2979.emission;\n    float _3305 = _2979.clearcoat;\n    float _3306 = _2979.clearcoat_roughness;\n    float3 _3307 = _2979.sheen_color;\n    float _3308 = _2979.sheen_roughness;\n    float _3309 = _2979.anisotropy;\n    float _3310 = _2979.anisotropy_rotation;\n    float _3311 = _2979.specular;\n    float _3312 = _2979.ior;\n    float3 _3313 = _2979.specular_color;\n    SurfaceInput _3288 = { fa_world_pos, _3267, fa_world_tangent, fa_uv, fa_vertex_color, _2971, gl_FrontFacing };\n    SurfaceInput param_2 = _3288;\n    Surface param_3 = _2979;\n    surface(param_2, param_3);\n    _3298 = param_3.albedo;\n    _3299 = param_3.alpha;\n    _3300 = param_3.normal;\n    _3301 = param_3.metallic;\n    _3302 = param_3.roughness;\n    _3303 = param_3.occlusion;\n    _3304 = param_3.emission;\n    _3305 = param_3.clearcoat;\n    _3306 = param_3.clearcoat_roughness;\n    _3307 = param_3.sheen_color;\n    _3308 = param_3.sheen_roughness;\n    _3309 = param_3.anisotropy;\n    _3310 = param_3.anisotropy_rotation;\n    _3311 = param_3.specular;\n    _3312 = param_3.ior;\n    _3313 = param_3.specular_color;\n    float3 result;\n    if (_286_fa_emissive.w > 0.5f)\n    {\n        result = _3298;\n    }\n    else\n    {\n        float3 _3000 = _3300;\n        float3 _3001 = normalize(_3000);\n        _3300 = _3001;\n        SurfaceInput _3296 = { fa_world_pos, _3267, fa_world_tangent, fa_uv, fa_vertex_color, _2971, gl_FrontFacing };\n        SurfaceInput param_4 = _3296;\n        Surface _3379 = { _3298, _3299, _3001, _3301, _3302, _3303, _3304, _3305, _3306, _3307, _3308, _3309, _3310, _3311, _3312, _3313 };\n        Surface param_5 = _3379;\n        float3 _3012 = lighting(param_4, param_5);\n        result = _3012;\n    }\n    float3 _3016 = result;\n    float3 _3017 = _3016 + _3304;\n    result = _3017;\n    float3 param_6 = _3017;\n    float3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _3026 = _286_fa_fog.w > 0.0f;\n    bool _3033;\n    if (!_3026)\n    {\n        _3033 = _286_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3033 = _3026;\n    }\n    if (_3033)\n    {\n        float3 _3042 = fa_world_pos - _286_fa_camera_pos.xyz;\n        float _3048 = dot(_3042, _286_fa_fog_c.xyz);\n        bool _3052 = _286_fa_fog_c.w > 0.5f;\n        float _3053;\n        if (_3052)\n        {\n            _3053 = _3048;\n        }\n        else\n        {\n            _3053 = length(_3042);\n        }\n        float _3065 = _3053 - _286_fa_fog_b.x;\n        if (_3065 > 0.0f)\n        {\n            float _3074 = _286_fa_fog.w * _3065;\n            float tau = _3074 * _3074;\n            if (_286_fa_fog_b.y > 0.0f)\n            {\n                float _3090;\n                if (_3052)\n                {\n                    _3090 = fa_world_pos.y - (_286_fa_fog_c.y * _3048);\n                }\n                else\n                {\n                    _3090 = _286_fa_camera_pos.y;\n                }\n                float _3111 = lerp(_3090, fa_world_pos.y, clamp(_286_fa_fog_b.x / _3053, 0.0f, 1.0f));\n                float _3115 = fa_world_pos.y - _3111;\n                float _3120 = _3111 - _286_fa_fog_b.z;\n                float _3125 = fa_world_pos.y - _286_fa_fog_b.z;\n                bool _3128 = _3120 <= 0.0f;\n                bool _3129 = !_3128;\n                bool _3135;\n                if (_3129)\n                {\n                    _3135 = _286_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3135 = _3128;\n                }\n                float _3136;\n                if (_3135)\n                {\n                    _3136 = _286_fa_fog_b.y;\n                }\n                else\n                {\n                    _3136 = _286_fa_fog_b.y * exp(-min(_286_fa_fog_b.w * _3120, 80.0f));\n                }\n                bool _3163;\n                if (_3129)\n                {\n                    _3163 = _286_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3163 = _3128;\n                }\n                float _3164;\n                if (_3163)\n                {\n                    _3164 = _286_fa_fog_b.y * _3120;\n                }\n                else\n                {\n                    _3164 = (_286_fa_fog_b.y * (1.0f - exp(-min(_286_fa_fog_b.w * _3120, 80.0f)))) / _286_fa_fog_b.w;\n                }\n                bool _3189 = _3125 <= 0.0f;\n                bool _3196;\n                if (!_3189)\n                {\n                    _3196 = _286_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3196 = _3189;\n                }\n                float _3197;\n                if (_3196)\n                {\n                    _3197 = _286_fa_fog_b.y * _3125;\n                }\n                else\n                {\n                    _3197 = (_286_fa_fog_b.y * (1.0f - exp(-min(_286_fa_fog_b.w * _3125, 80.0f)))) / _286_fa_fog_b.w;\n                }\n                float _3224;\n                if (abs(_3115) < 0.001000000047497451305389404296875f)\n                {\n                    _3224 = _3136;\n                }\n                else\n                {\n                    _3224 = (_3197 - _3164) / _3115;\n                }\n                tau += (_3065 * max(_3224, 0.0f));\n            }\n            result = lerp(result, _286_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3299);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_286",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_990",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2586",
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 8,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _295 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _295;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0f);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _787 = base_t;\n    _787.x = _225.x;\n    _787.y = _225.y;\n    _787.z = _225.z;\n    base_t = _787;\n    float4 _241 = (_787 * _213_fa_base_color) * i.vertex_color;\n    float3 _750 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _795 = _279;\n        _795.x = _284.x;\n        _795.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _798 = mrt;\n    _798.x = _313.x;\n    _798.y = _313.y;\n    _798.z = _313.z;\n    mrt = _798;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _755 = _213_fa_layers_a.x;\n    float _756 = _213_fa_layers_a.y;\n    float _759 = _213_fa_layers_a.z;\n    float _758 = _213_fa_layers_b.w;\n    float _761 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _755 *= _355.y;\n            _756 *= _355.z;\n            _758 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    Surface _780 = { _241.xyz, _241.w, _750, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _755, _756, _213_fa_layers_b.xyz, _758, _759, _213_fa_layers_a.w, _761, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _780;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _661 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _674 = { fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _674;\n    SurfaceInput _682 = { fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _682;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _416 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _416;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0f);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _787 = base_t;\n    _787.x = _225.x;\n    _787.y = _225.y;\n    _787.z = _225.z;\n    base_t = _787;\n    float4 _241 = (_787 * _213_fa_base_color) * i.vertex_color;\n    float3 _750 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _795 = _279;\n        _795.x = _284.x;\n        _795.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _798 = mrt;\n    _798.x = _313.x;\n    _798.y = _313.y;\n    _798.z = _313.z;\n    mrt = _798;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _755 = _213_fa_layers_a.x;\n    float _756 = _213_fa_layers_a.y;\n    float _759 = _213_fa_layers_a.z;\n    float _758 = _213_fa_layers_b.w;\n    float _761 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _755 *= _355.y;\n            _756 *= _355.z;\n            _758 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    Surface _780 = { _241.xyz, _241.w, _750, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _755, _756, _213_fa_layers_b.xyz, _758, _759, _213_fa_layers_a.w, _761, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _780;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _661 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _674 = { fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _674;\n    SurfaceInput _682 = { fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _682;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
