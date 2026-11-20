{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "41c86c92dbb0093951c81b6ee249cbb5aa749f4b053c4954c67a5e43bd66f6f3",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _258 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _258;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_265, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _388_fa_camera_pos : packoffset(c0);\n    float4 _388_fa_ambient : packoffset(c1);\n    float4 _388_fa_base_color : packoffset(c2);\n    float4 _388_fa_emissive : packoffset(c3);\n    float4 _388_fa_model_emissive : packoffset(c4);\n    float4 _388_fa_pbr : packoffset(c5);\n    float4 _388_fa_maps : packoffset(c6);\n    float4 _388_fa_fog : packoffset(c7);\n    float4 _388_fa_fog_b : packoffset(c8);\n    float4 _388_fa_fog_c : packoffset(c9);\n    float4 _388_fa_counts : packoffset(c10);\n    float4 _388_fa_env_sky : packoffset(c11);\n    float4 _388_fa_env_horizon : packoffset(c12);\n    float4 _388_fa_time : packoffset(c13);\n    float4 _388_fa_cl_vpx : packoffset(c14);\n    float4 _388_fa_cl_vpy : packoffset(c15);\n    float4 _388_fa_cl_vpw : packoffset(c16);\n    float4 _388_fa_cl_fwd : packoffset(c17);\n    float4 _388_fa_cl_grid : packoffset(c18);\n    float4 _388_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1128_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1128_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1128_fa_shadow_info[4] : packoffset(c20);\n    float4 _1128_fa_shadow_split : packoffset(c24);\n    float4 _1128_fa_shadow_cfg : packoffset(c25);\n    float4 _1128_fa_shadow_bias : packoffset(c26);\n    float4 _1128_fa_shadow_eye : packoffset(c27);\n    float4 _1128_fa_shadow_fwd : packoffset(c28);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_irr_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _393 = _388_fa_cl_info.x < 0.0f;\n    bool _400;\n    if (!_393)\n    {\n        _400 = _388_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _400 = _393;\n    }\n    bool _408;\n    if (!_400)\n    {\n        _408 = _388_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _408 = _400;\n    }\n    bool _415;\n    if (!_408)\n    {\n        _415 = _388_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _415 = _408;\n    }\n    bool _422;\n    if (!_415)\n    {\n        _422 = _388_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _422 = _415;\n    }\n    if (_422)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _432 = float4(world_pos, 1.0f);\n    float _439 = dot(_388_fa_cl_vpw, _432);\n    if (!(_439 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _461 = float2(dot(_388_fa_cl_vpx, _432), dot(_388_fa_cl_vpy, _432)) / _439.xx;\n    int _465 = int(_388_fa_cl_grid.x);\n    int _469 = int(_388_fa_cl_grid.y);\n    int param = (int(_388_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_388_fa_cl_fwd.xyz, world_pos) + _388_fa_cl_fwd.w, _388_fa_cl_grid.w) / _388_fa_cl_grid.w) * _388_fa_cl_grid.z)), 0, int(_388_fa_cl_info.y) - 1) * _469) + clamp(int(floor(((_461.y * 0.5f) + 0.5f) * _388_fa_cl_grid.y)), 0, _469 - 1)) * _465)) + clamp(int(floor(((_461.x * 0.5f) + 0.5f) * _388_fa_cl_grid.x)), 0, _465 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _545 = fa_cluster_texel(param);\n    return int2(int(_545.x), int(_545.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_388_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1786 = fa_cluster_lookup(param);\n    fa_cl_slot = _1786.x;\n    fa_cl_local = _1786.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1877 = fa_linear_to_srgb(param);\n        c = _1877;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1885 = fa_srgb_to_linear(param_1);\n            c = _1885;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _169;\n    if (i.front_facing)\n    {\n        _169 = i.world_normal;\n    }\n    else\n    {\n        _169 = -i.world_normal;\n    }\n    float3 _193 = normalize(i.world_tangent.xyz - (_169 * dot(_169, i.world_tangent.xyz)));\n    float3 _221 = normalize(((_193 * m.x) + ((cross(_169, _193) * i.world_tangent.w) * m.y)) + (_169 * m.z));\n    float3 _224;\n    if (i.front_facing)\n    {\n        _224 = _221;\n    }\n    else\n    {\n        _224 = -_221;\n    }\n    return _224;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _388_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1916 = fa_tex_fix(param_2, param_3);\n    float4 _2655 = base_t;\n    _2655.x = _1916.x;\n    _2655.y = _1916.y;\n    _2655.z = _1916.z;\n    base_t = _2655;\n    float4 _1930 = (_2655 * _388_fa_base_color) * i.vertex_color;\n    float3 _2585 = i.world_normal;\n    if (_388_fa_maps.z > 0.5f)\n    {\n        float param_4 = _388_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1962 = fa_tex_fix(param_6, param_7);\n        float3 _1965 = (_1962 * 2.0f) - 1.0f.xxx;\n        float2 _1970 = _1965.xy * _388_fa_maps.x;\n        float3 _2663 = _1965;\n        _2663.x = _1970.x;\n        _2663.y = _1970.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2663;\n        _2585 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _388_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1999 = fa_tex_fix(param_12, param_13);\n    float4 _2666 = mrt;\n    _2666.x = _1999.x;\n    _2666.y = _1999.y;\n    _2666.z = _1999.z;\n    mrt = _2666;\n    float param_14 = _388_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2038 = fa_tex_fix(param_16, param_17);\n    float param_18 = _388_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2065 = fa_tex_fix(param_20, param_21);\n    Surface _2597 = { _1930.xyz, _1930.w, _2585, clamp(_388_fa_pbr.x * _1999.z, 0.0f, 1.0f), clamp(_388_fa_pbr.y * _1999.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_388_fa_maps.y * (_2038.x - 1.0f)), _388_fa_emissive.xyz + (_388_fa_model_emissive.xyz * _2065) };\n    return _2597;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _626 = rect.zw - rect.xy;\n    float2 _630 = _626 * atlas;\n    float2 _634 = ddx * _630;\n    float2 _638 = ddy * _630;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _626), clamp(0.5f * log2(max(max(dot(_634, _634), dot(_638, _638)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    float3 _673 = ddx(world_pos);\n    float3 _676 = ddy(world_pos);\n    bool _679 = _388_fa_counts.y < 0.5f;\n    bool _686;\n    if (!_679)\n    {\n        _686 = _388_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _686 = _679;\n    }\n    if (_686)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _693 = fa_cluster_texel(param);\n    int _697 = int(_693.w);\n    if (_697 < 1)\n    {\n        return;\n    }\n    int _707 = int(_388_fa_counts.y + 0.5f);\n    int param_1 = _707;\n    float4 _711 = fa_light_texel(param_1);\n    float2 _714 = _711.yz;\n    int _718 = int(_711.w);\n    int param_2 = _707 + 1;\n    float4 _723 = fa_light_texel(param_2);\n    float _724 = _723.x;\n    int _730 = int(_388_fa_counts.w + 0.5f) - 1;\n    int _734 = int(_693.z);\n    float3 _1000;\n    for (int k = 0; k < _697; k++)\n    {\n        int _747 = _734 + k;\n        int param_3 = _718 + (_747 >> 2);\n        int _765 = (_707 + 2) + (int(fa_light_texel(param_3)[_747 & 3]) * 7);\n        int param_4 = _765 + 6;\n        float4 _770 = fa_light_texel(param_4);\n        if (((int(_770.w + 0.5f) >> _730) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _765;\n        float4 _785 = fa_light_texel(param_5);\n        int param_6 = _765 + 1;\n        float4 _790 = fa_light_texel(param_6);\n        int param_7 = _765 + 2;\n        float4 _795 = fa_light_texel(param_7);\n        float3 _798 = _785.xyz;\n        float _803 = dot(_798, world_pos) + _785.w;\n        float3 _805 = _790.xyz;\n        float _810 = dot(_805, world_pos) + _790.w;\n        float3 _812 = _795.xyz;\n        float _817 = dot(_812, world_pos) + _795.w;\n        bool _822 = abs(_803) > 0.5f;\n        bool _830;\n        if (!_822)\n        {\n            _830 = abs(_810) > 0.5f;\n        }\n        else\n        {\n            _830 = _822;\n        }\n        bool _838;\n        if (!_830)\n        {\n            _838 = abs(_817) > 0.5f;\n        }\n        else\n        {\n            _838 = _830;\n        }\n        if (_838)\n        {\n            continue;\n        }\n        float _853 = clamp(dot(geo_normal, normalize(_812)) * _770.z, 0.0f, 1.0f);\n        if (_853 <= 0.0f)\n        {\n            continue;\n        }\n        float _873 = (clamp((0.5f - abs(_817)) * 10.0f, 0.0f, 1.0f) * _853) * _770.x;\n        float2 _881 = float2(_803 + 0.5f, 0.5f - _810);\n        float2 _891 = float2(dot(_798, _673), dot(_805, _673));\n        float2 _901 = float2(dot(_798, _676), dot(_805, _676));\n        int param_8 = _765 + 5;\n        float4 _906 = fa_light_texel(param_8);\n        int param_9 = _765 + 3;\n        float4 _911 = fa_light_texel(param_9);\n        int param_10 = _765 + 4;\n        float4 _916 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _906.xyz;\n        bool _926 = _911.z > _911.x;\n        if (_926)\n        {\n            float4 param_11 = _911;\n            float2 param_12 = _881;\n            float2 param_13 = _714;\n            float2 param_14 = _891;\n            float2 param_15 = _901;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_724 > 0.5f) && (_724 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _952 = fa_dc_to_linear(param_16);\n                float4 _2623 = tx;\n                _2623.x = _952.x;\n                _2623.y = _952.y;\n                _2623.z = _952.z;\n                tx = _2623;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_873 * tex_a) * _906.w, 0.0f, 1.0f).xxx);\n        if (_916.z > _916.x)\n        {\n            float4 param_17 = _916;\n            float2 param_18 = _881;\n            float2 param_19 = _714;\n            float2 param_20 = _891;\n            float2 param_21 = _901;\n            float4 _996 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_724 > 1.5f)\n            {\n                float3 param_22 = _996.xyz;\n                float3 _1006 = fa_dc_to_srgb(param_22);\n                _1000 = _1006;\n            }\n            else\n            {\n                _1000 = _996.xyz;\n            }\n            float3 _1016 = (_1000 * 2.0f) - 1.0f.xxx;\n            float2 _1021 = _1016.xy * _770.y;\n            float3 _1043 = (normalize(_798) * _1021.x) + (normalize(_805) * _1021.y);\n            float3 _1046 = normalize(normal);\n            normal = normalize(lerp(_1046, normalize((_1046 * max(_1016.z, 0.0500000007450580596923828125f)) + (_1043 - (_1046 * dot(_1046, _1043)))), clamp(_873 * (_926 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_388_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _388_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_388_fa_cl_info.x) + int(_388_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _261 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _267 = fa_light_texel(param_1);\n    float _270 = _267.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _277 = _270 < 0.5f;\n    float3 l;\n    if (_277)\n    {\n        l = normalize(_261.xyz);\n    }\n    else\n    {\n        float3 _289 = _261.xyz - world_pos;\n        float _291 = length(_289);\n        dist = _291;\n        l = _289 / max(_291, 9.9999997473787516355514526367188e-05f).xxx;\n        float _306 = _291 / max(_261.w, 0.001000000047497451305389404296875f);\n        float _312 = clamp(1.0f - (_306 * _306), 0.0f, 1.0f);\n        atten = _312 * _312;\n        if (_270 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _326 = fa_light_texel(param_2);\n            float _336 = _326.w;\n            int param_3 = (li * 4) + 3;\n            float4 _343 = fa_light_texel(param_3);\n            float _344 = _343.x;\n            float cos_inner = _344;\n            if (_344 > 1.5f)\n            {\n                cos_inner = lerp(_336, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_336, cos_inner, dot(-l, normalize(_326.xyz)));\n        }\n    }\n    int _374;\n    if (_277)\n    {\n        _374 = 0;\n    }\n    else\n    {\n        _374 = (_270 > 1.5f) ? 2 : 1;\n    }\n    LightSample _2563 = { l, _267.xyz * atten, atten, 1.0f, dist, _374 };\n    return _2563;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1118;\n    if (i == 0)\n    {\n        _1118 = _1128_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1134;\n        if (i == 1)\n        {\n            _1134 = _1128_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1142;\n            if (i == 2)\n            {\n                _1142 = _1128_fa_shadow_split.z;\n            }\n            else\n            {\n                _1142 = _1128_fa_shadow_split.w;\n            }\n            _1134 = _1142;\n        }\n        _1118 = _1134;\n    }\n    return _1118;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1106 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1106), sin(_1106)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1180 = max(_1128_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1185 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1191 = sqrt(1.0f - (_1185 * _1185));\n    float _1198 = min(_1191 / max(_1185, 0.20000000298023223876953125f), 4.0f);\n    float _1203;\n    if (_1128_fa_shadow_bias.y > 0.0f)\n    {\n        _1203 = _1128_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1203 = 1.5f * _1128_fa_shadow_info[ci].x;\n    }\n    float4 _1228 = mul(float4(world + (n * (_1203 * _1191)), 1.0f), _1128_fa_shadow_mat[ci]);\n    float _1235 = _1228.x;\n    bool _1238 = _1235 < _1128_fa_shadow_rect[ci].x;\n    bool _1247;\n    if (!_1238)\n    {\n        _1247 = _1235 > _1128_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1247 = _1238;\n    }\n    bool _1256;\n    if (!_1247)\n    {\n        _1256 = _1228.y < _1128_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1256 = _1247;\n    }\n    bool _1265;\n    if (!_1256)\n    {\n        _1265 = _1228.y > _1128_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1265 = _1256;\n    }\n    bool _1272;\n    if (!_1265)\n    {\n        _1272 = _1228.z > 1.0f;\n    }\n    else\n    {\n        _1272 = _1265;\n    }\n    if (_1272)\n    {\n        return -1.0f;\n    }\n    float _1281;\n    if (_1128_fa_shadow_bias.x > 0.0f)\n    {\n        _1281 = _1128_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1281 = 1.5f * _1128_fa_shadow_info[ci].x;\n    }\n    float _1300 = _1228.z - ((_1281 * (1.0f + (0.5f * _1198))) / _1180);\n    float _1309 = ((_1128_fa_shadow_info[ci].x * min(_1198, 3.0f)) * 0.5f) / _1180;\n    int _1318 = int(_1128_fa_shadow_cfg.z + 0.5f);\n    if (_1318 == 1)\n    {\n        float2 param = _1228.xy;\n        float4 param_1 = _1128_fa_shadow_rect[ci];\n        float _1329 = fa_shadow_depth(param, param_1);\n        return float(_1300 <= _1329);\n    }\n    float _1336 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _1339 = _1318 == 2;\n    if (_1339)\n    {\n        float _1353 = clamp(((_1128_fa_shadow_cfg.w * _1180) * 0.25f) / _1128_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1336;\n            float2 _1372 = fa_shadow_vogel(param_2, param_3, param_4) * _1353;\n            float2 param_5 = _1228.xy + (_1372 * _1128_fa_shadow_bias.zw);\n            float4 param_6 = _1128_fa_shadow_rect[ci];\n            float _1383 = fa_shadow_depth(param_5, param_6);\n            if (_1383 < (_1300 - (length(_1372) * _1309)))\n            {\n                sum += _1383;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_1300 - (sum / cnt), 0.0f) * _1180) * _1128_fa_shadow_cfg.w) / _1128_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1427 = _1339 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1427; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1427;\n        float param_9 = _1336;\n        float2 _1446 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1228.xy + (_1446 * _1128_fa_shadow_bias.zw);\n        float4 param_11 = _1128_fa_shadow_rect[ci];\n        float _1457 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1300 - (length(_1446) * _1309)) <= _1457);\n    }\n    return lit / float(_1427);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_388_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1487 = int(_1128_fa_shadow_cfg.x + 0.5f);\n    if (_1487 < 1)\n    {\n        return 1.0f;\n    }\n    float _1502 = dot(world - _1128_fa_shadow_eye.xyz, _1128_fa_shadow_fwd.xyz);\n    int param = _1487 - 1;\n    if (_1502 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1514 = _1487 > 1;\n    bool _1521;\n    if (_1514)\n    {\n        _1521 = _1502 > _1128_fa_shadow_split.x;\n    }\n    else\n    {\n        _1521 = _1514;\n    }\n    if (_1521)\n    {\n        ci = 1;\n    }\n    bool _1525 = _1487 > 2;\n    bool _1532;\n    if (_1525)\n    {\n        _1532 = _1502 > _1128_fa_shadow_split.y;\n    }\n    else\n    {\n        _1532 = _1525;\n    }\n    if (_1532)\n    {\n        ci = 2;\n    }\n    bool _1536 = _1487 > 3;\n    bool _1543;\n    if (_1536)\n    {\n        _1543 = _1502 > _1128_fa_shadow_split.z;\n    }\n    else\n    {\n        _1543 = _1536;\n    }\n    if (_1543)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1487)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1569 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1569;\n        if (_1569 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1128_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1594;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1594 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1594 = _1128_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1613 = _1128_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1594, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1624 = clamp((_1502 - (fa_shadow_split_at(param_7) - _1613)) / _1613, 0.0f, 1.0f);\n        if (_1624 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1487)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1645 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1645;\n                if (_1645 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1624);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1814 = fa_light_sample(param, param_1);\n    float3 _2570 = _1814.direction;\n    float3 _2565 = _1814.color;\n    float _2567 = _1814.shadow;\n    int _2575 = _1814.type;\n    if ((_2575 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2570;\n        float _1828 = fa_shadow_factor(param_2, param_3);\n        _2567 = _1828;\n        _2565 *= _1828;\n    }\n    LightSample _2582 = { _2570, _2565, _1814.attenuation, _2567, _1814._distance, _2575 };\n    return _2582;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1128_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1669 = int(_1128_fa_shadow_cfg.x + 0.5f);\n    float _1679 = dot(world - _1128_fa_shadow_eye.xyz, _1128_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1684 = _1669 > 0;\n    bool _1693;\n    if (_1684)\n    {\n        int param = _1669 - 1;\n        _1693 = _1679 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1693 = _1684;\n    }\n    if (_1693)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1700 = _1669 > 1;\n        bool _1707;\n        if (_1700)\n        {\n            _1707 = _1679 > _1128_fa_shadow_split.x;\n        }\n        else\n        {\n            _1707 = _1700;\n        }\n        if (_1707)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1713 = _1669 > 2;\n        bool _1720;\n        if (_1713)\n        {\n            _1720 = _1679 > _1128_fa_shadow_split.y;\n        }\n        else\n        {\n            _1720 = _1713;\n        }\n        if (_1720)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1726 = _1669 > 3;\n        bool _1733;\n        if (_1726)\n        {\n            _1733 = _1679 > _1128_fa_shadow_split.z;\n        }\n        else\n        {\n            _1733 = _1726;\n        }\n        if (_1733)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2464 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2464 = -_2464;\n    }\n    float3 _2108 = normalize(_388_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2477 = { fa_world_pos, _2464, fa_world_tangent, fa_uv, fa_vertex_color, _2108, gl_FrontFacing };\n    SurfaceInput param_1 = _2477;\n    Surface _2116 = fa_standard_surface(param_1);\n    float3 _2495 = _2116.albedo;\n    float _2496 = _2116.alpha;\n    float3 _2497 = _2116.normal;\n    float _2498 = _2116.metallic;\n    float _2499 = _2116.roughness;\n    float _2500 = _2116.occlusion;\n    float3 _2501 = _2116.emission;\n    SurfaceInput _2485 = { fa_world_pos, _2464, fa_world_tangent, fa_uv, fa_vertex_color, _2108, gl_FrontFacing };\n    SurfaceInput param_2 = _2485;\n    Surface param_3 = _2116;\n    surface(param_2, param_3);\n    _2495 = param_3.albedo;\n    _2496 = param_3.alpha;\n    _2497 = param_3.normal;\n    _2498 = param_3.metallic;\n    _2499 = param_3.roughness;\n    _2500 = param_3.occlusion;\n    _2501 = param_3.emission;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _2464;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2495 = param_6;\n    _2497 = param_7;\n    float3 result;\n    if (_388_fa_emissive.w > 0.5f)\n    {\n        result = _2495;\n    }\n    else\n    {\n        float3 _2154 = _2497;\n        float3 _2155 = normalize(_2154);\n        _2497 = _2155;\n        float3 param_8 = _2155;\n        float3 lit = (fa_ambient_light(param_8) * _2495) * _2500;\n        int _2174 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2174; ln++)\n        {\n            int param_9 = ln;\n            int param_10 = fa_cl_light(param_9);\n            float3 param_11 = fa_world_pos;\n            float3 param_12 = _2464;\n            SurfaceInput _2493 = { fa_world_pos, _2464, fa_world_tangent, fa_uv, fa_vertex_color, _2108, gl_FrontFacing };\n            SurfaceInput param_13 = _2493;\n            Surface _2531 = { _2495, _2496, _2497, _2498, _2499, _2500, _2501 };\n            Surface param_14 = _2531;\n            LightSample param_15 = fa_light_shadowed(param_10, param_11, param_12);\n            lit += light(param_13, param_14, param_15);\n        }\n        result = lit;\n    }\n    float3 _2211 = result;\n    float3 _2212 = _2211 + _2501;\n    result = _2212;\n    float3 param_16 = _2212;\n    float3 param_17 = fa_world_pos;\n    result = fa_shadow_debug(param_16, param_17);\n    bool _2221 = _388_fa_fog.w > 0.0f;\n    bool _2229;\n    if (!_2221)\n    {\n        _2229 = _388_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2229 = _2221;\n    }\n    if (_2229)\n    {\n        float3 _2238 = fa_world_pos - _388_fa_camera_pos.xyz;\n        float _2245 = dot(_2238, _388_fa_fog_c.xyz);\n        bool _2249 = _388_fa_fog_c.w > 0.5f;\n        float _2250;\n        if (_2249)\n        {\n            _2250 = _2245;\n        }\n        else\n        {\n            _2250 = length(_2238);\n        }\n        float _2262 = _2250 - _388_fa_fog_b.x;\n        if (_2262 > 0.0f)\n        {\n            float _2271 = _388_fa_fog.w * _2262;\n            float tau = _2271 * _2271;\n            if (_388_fa_fog_b.y > 0.0f)\n            {\n                float _2287;\n                if (_2249)\n                {\n                    _2287 = fa_world_pos.y - (_388_fa_fog_c.y * _2245);\n                }\n                else\n                {\n                    _2287 = _388_fa_camera_pos.y;\n                }\n                float _2308 = lerp(_2287, fa_world_pos.y, clamp(_388_fa_fog_b.x / _2250, 0.0f, 1.0f));\n                float _2312 = fa_world_pos.y - _2308;\n                float _2317 = _2308 - _388_fa_fog_b.z;\n                float _2322 = fa_world_pos.y - _388_fa_fog_b.z;\n                bool _2325 = _2317 <= 0.0f;\n                bool _2326 = !_2325;\n                bool _2332;\n                if (_2326)\n                {\n                    _2332 = _388_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2332 = _2325;\n                }\n                float _2333;\n                if (_2332)\n                {\n                    _2333 = _388_fa_fog_b.y;\n                }\n                else\n                {\n                    _2333 = _388_fa_fog_b.y * exp(-min(_388_fa_fog_b.w * _2317, 80.0f));\n                }\n                bool _2360;\n                if (_2326)\n                {\n                    _2360 = _388_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2360 = _2325;\n                }\n                float _2361;\n                if (_2360)\n                {\n                    _2361 = _388_fa_fog_b.y * _2317;\n                }\n                else\n                {\n                    _2361 = (_388_fa_fog_b.y * (1.0f - exp(-min(_388_fa_fog_b.w * _2317, 80.0f)))) / _388_fa_fog_b.w;\n                }\n                bool _2386 = _2322 <= 0.0f;\n                bool _2393;\n                if (!_2386)\n                {\n                    _2393 = _388_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2393 = _2386;\n                }\n                float _2394;\n                if (_2393)\n                {\n                    _2394 = _388_fa_fog_b.y * _2322;\n                }\n                else\n                {\n                    _2394 = (_388_fa_fog_b.y * (1.0f - exp(-min(_388_fa_fog_b.w * _2322, 80.0f)))) / _388_fa_fog_b.w;\n                }\n                float _2421;\n                if (abs(_2312) < 0.001000000047497451305389404296875f)\n                {\n                    _2421 = _2333;\n                }\n                else\n                {\n                    _2421 = (_2394 - _2361) / _2312;\n                }\n                tau += (_2262 * max(_2421, 0.0f));\n            }\n            result = lerp(result, _388_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2496);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_388",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1128",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
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
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _379 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _379;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_386, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _388_fa_camera_pos : packoffset(c0);\n    float4 _388_fa_ambient : packoffset(c1);\n    float4 _388_fa_base_color : packoffset(c2);\n    float4 _388_fa_emissive : packoffset(c3);\n    float4 _388_fa_model_emissive : packoffset(c4);\n    float4 _388_fa_pbr : packoffset(c5);\n    float4 _388_fa_maps : packoffset(c6);\n    float4 _388_fa_fog : packoffset(c7);\n    float4 _388_fa_fog_b : packoffset(c8);\n    float4 _388_fa_fog_c : packoffset(c9);\n    float4 _388_fa_counts : packoffset(c10);\n    float4 _388_fa_env_sky : packoffset(c11);\n    float4 _388_fa_env_horizon : packoffset(c12);\n    float4 _388_fa_time : packoffset(c13);\n    float4 _388_fa_cl_vpx : packoffset(c14);\n    float4 _388_fa_cl_vpy : packoffset(c15);\n    float4 _388_fa_cl_vpw : packoffset(c16);\n    float4 _388_fa_cl_fwd : packoffset(c17);\n    float4 _388_fa_cl_grid : packoffset(c18);\n    float4 _388_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1128_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1128_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1128_fa_shadow_info[4] : packoffset(c20);\n    float4 _1128_fa_shadow_split : packoffset(c24);\n    float4 _1128_fa_shadow_cfg : packoffset(c25);\n    float4 _1128_fa_shadow_bias : packoffset(c26);\n    float4 _1128_fa_shadow_eye : packoffset(c27);\n    float4 _1128_fa_shadow_fwd : packoffset(c28);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_irr_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _393 = _388_fa_cl_info.x < 0.0f;\n    bool _400;\n    if (!_393)\n    {\n        _400 = _388_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _400 = _393;\n    }\n    bool _408;\n    if (!_400)\n    {\n        _408 = _388_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _408 = _400;\n    }\n    bool _415;\n    if (!_408)\n    {\n        _415 = _388_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _415 = _408;\n    }\n    bool _422;\n    if (!_415)\n    {\n        _422 = _388_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _422 = _415;\n    }\n    if (_422)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _432 = float4(world_pos, 1.0f);\n    float _439 = dot(_388_fa_cl_vpw, _432);\n    if (!(_439 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _461 = float2(dot(_388_fa_cl_vpx, _432), dot(_388_fa_cl_vpy, _432)) / _439.xx;\n    int _465 = int(_388_fa_cl_grid.x);\n    int _469 = int(_388_fa_cl_grid.y);\n    int param = (int(_388_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_388_fa_cl_fwd.xyz, world_pos) + _388_fa_cl_fwd.w, _388_fa_cl_grid.w) / _388_fa_cl_grid.w) * _388_fa_cl_grid.z)), 0, int(_388_fa_cl_info.y) - 1) * _469) + clamp(int(floor(((_461.y * 0.5f) + 0.5f) * _388_fa_cl_grid.y)), 0, _469 - 1)) * _465)) + clamp(int(floor(((_461.x * 0.5f) + 0.5f) * _388_fa_cl_grid.x)), 0, _465 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _545 = fa_cluster_texel(param);\n    return int2(int(_545.x), int(_545.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_388_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1786 = fa_cluster_lookup(param);\n    fa_cl_slot = _1786.x;\n    fa_cl_local = _1786.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1877 = fa_linear_to_srgb(param);\n        c = _1877;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1885 = fa_srgb_to_linear(param_1);\n            c = _1885;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _169;\n    if (i.front_facing)\n    {\n        _169 = i.world_normal;\n    }\n    else\n    {\n        _169 = -i.world_normal;\n    }\n    float3 _193 = normalize(i.world_tangent.xyz - (_169 * dot(_169, i.world_tangent.xyz)));\n    float3 _221 = normalize(((_193 * m.x) + ((cross(_169, _193) * i.world_tangent.w) * m.y)) + (_169 * m.z));\n    float3 _224;\n    if (i.front_facing)\n    {\n        _224 = _221;\n    }\n    else\n    {\n        _224 = -_221;\n    }\n    return _224;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _388_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1916 = fa_tex_fix(param_2, param_3);\n    float4 _2655 = base_t;\n    _2655.x = _1916.x;\n    _2655.y = _1916.y;\n    _2655.z = _1916.z;\n    base_t = _2655;\n    float4 _1930 = (_2655 * _388_fa_base_color) * i.vertex_color;\n    float3 _2585 = i.world_normal;\n    if (_388_fa_maps.z > 0.5f)\n    {\n        float param_4 = _388_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1962 = fa_tex_fix(param_6, param_7);\n        float3 _1965 = (_1962 * 2.0f) - 1.0f.xxx;\n        float2 _1970 = _1965.xy * _388_fa_maps.x;\n        float3 _2663 = _1965;\n        _2663.x = _1970.x;\n        _2663.y = _1970.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2663;\n        _2585 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _388_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1999 = fa_tex_fix(param_12, param_13);\n    float4 _2666 = mrt;\n    _2666.x = _1999.x;\n    _2666.y = _1999.y;\n    _2666.z = _1999.z;\n    mrt = _2666;\n    float param_14 = _388_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2038 = fa_tex_fix(param_16, param_17);\n    float param_18 = _388_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2065 = fa_tex_fix(param_20, param_21);\n    Surface _2597 = { _1930.xyz, _1930.w, _2585, clamp(_388_fa_pbr.x * _1999.z, 0.0f, 1.0f), clamp(_388_fa_pbr.y * _1999.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_388_fa_maps.y * (_2038.x - 1.0f)), _388_fa_emissive.xyz + (_388_fa_model_emissive.xyz * _2065) };\n    return _2597;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _626 = rect.zw - rect.xy;\n    float2 _630 = _626 * atlas;\n    float2 _634 = ddx * _630;\n    float2 _638 = ddy * _630;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _626), clamp(0.5f * log2(max(max(dot(_634, _634), dot(_638, _638)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    float3 _673 = ddx(world_pos);\n    float3 _676 = ddy(world_pos);\n    bool _679 = _388_fa_counts.y < 0.5f;\n    bool _686;\n    if (!_679)\n    {\n        _686 = _388_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _686 = _679;\n    }\n    if (_686)\n    {\n        return;\n    }\n    float3 param = world_pos;\n    float4 _693 = fa_cluster_texel(param);\n    int _697 = int(_693.w);\n    if (_697 < 1)\n    {\n        return;\n    }\n    int _707 = int(_388_fa_counts.y + 0.5f);\n    int param_1 = _707;\n    float4 _711 = fa_light_texel(param_1);\n    float2 _714 = _711.yz;\n    int _718 = int(_711.w);\n    int param_2 = _707 + 1;\n    float4 _723 = fa_light_texel(param_2);\n    float _724 = _723.x;\n    int _730 = int(_388_fa_counts.w + 0.5f) - 1;\n    int _734 = int(_693.z);\n    float3 _1000;\n    for (int k = 0; k < _697; k++)\n    {\n        int _747 = _734 + k;\n        int param_3 = _718 + (_747 >> 2);\n        int _765 = (_707 + 2) + (int(fa_light_texel(param_3)[_747 & 3]) * 7);\n        int param_4 = _765 + 6;\n        float4 _770 = fa_light_texel(param_4);\n        if (((int(_770.w + 0.5f) >> _730) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _765;\n        float4 _785 = fa_light_texel(param_5);\n        int param_6 = _765 + 1;\n        float4 _790 = fa_light_texel(param_6);\n        int param_7 = _765 + 2;\n        float4 _795 = fa_light_texel(param_7);\n        float3 _798 = _785.xyz;\n        float _803 = dot(_798, world_pos) + _785.w;\n        float3 _805 = _790.xyz;\n        float _810 = dot(_805, world_pos) + _790.w;\n        float3 _812 = _795.xyz;\n        float _817 = dot(_812, world_pos) + _795.w;\n        bool _822 = abs(_803) > 0.5f;\n        bool _830;\n        if (!_822)\n        {\n            _830 = abs(_810) > 0.5f;\n        }\n        else\n        {\n            _830 = _822;\n        }\n        bool _838;\n        if (!_830)\n        {\n            _838 = abs(_817) > 0.5f;\n        }\n        else\n        {\n            _838 = _830;\n        }\n        if (_838)\n        {\n            continue;\n        }\n        float _853 = clamp(dot(geo_normal, normalize(_812)) * _770.z, 0.0f, 1.0f);\n        if (_853 <= 0.0f)\n        {\n            continue;\n        }\n        float _873 = (clamp((0.5f - abs(_817)) * 10.0f, 0.0f, 1.0f) * _853) * _770.x;\n        float2 _881 = float2(_803 + 0.5f, 0.5f - _810);\n        float2 _891 = float2(dot(_798, _673), dot(_805, _673));\n        float2 _901 = float2(dot(_798, _676), dot(_805, _676));\n        int param_8 = _765 + 5;\n        float4 _906 = fa_light_texel(param_8);\n        int param_9 = _765 + 3;\n        float4 _911 = fa_light_texel(param_9);\n        int param_10 = _765 + 4;\n        float4 _916 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _906.xyz;\n        bool _926 = _911.z > _911.x;\n        if (_926)\n        {\n            float4 param_11 = _911;\n            float2 param_12 = _881;\n            float2 param_13 = _714;\n            float2 param_14 = _891;\n            float2 param_15 = _901;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_724 > 0.5f) && (_724 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _952 = fa_dc_to_linear(param_16);\n                float4 _2623 = tx;\n                _2623.x = _952.x;\n                _2623.y = _952.y;\n                _2623.z = _952.z;\n                tx = _2623;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_873 * tex_a) * _906.w, 0.0f, 1.0f).xxx);\n        if (_916.z > _916.x)\n        {\n            float4 param_17 = _916;\n            float2 param_18 = _881;\n            float2 param_19 = _714;\n            float2 param_20 = _891;\n            float2 param_21 = _901;\n            float4 _996 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_724 > 1.5f)\n            {\n                float3 param_22 = _996.xyz;\n                float3 _1006 = fa_dc_to_srgb(param_22);\n                _1000 = _1006;\n            }\n            else\n            {\n                _1000 = _996.xyz;\n            }\n            float3 _1016 = (_1000 * 2.0f) - 1.0f.xxx;\n            float2 _1021 = _1016.xy * _770.y;\n            float3 _1043 = (normalize(_798) * _1021.x) + (normalize(_805) * _1021.y);\n            float3 _1046 = normalize(normal);\n            normal = normalize(lerp(_1046, normalize((_1046 * max(_1016.z, 0.0500000007450580596923828125f)) + (_1043 - (_1046 * dot(_1046, _1043)))), clamp(_873 * (_926 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_388_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _388_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_388_fa_cl_info.x) + int(_388_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _261 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _267 = fa_light_texel(param_1);\n    float _270 = _267.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _277 = _270 < 0.5f;\n    float3 l;\n    if (_277)\n    {\n        l = normalize(_261.xyz);\n    }\n    else\n    {\n        float3 _289 = _261.xyz - world_pos;\n        float _291 = length(_289);\n        dist = _291;\n        l = _289 / max(_291, 9.9999997473787516355514526367188e-05f).xxx;\n        float _306 = _291 / max(_261.w, 0.001000000047497451305389404296875f);\n        float _312 = clamp(1.0f - (_306 * _306), 0.0f, 1.0f);\n        atten = _312 * _312;\n        if (_270 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _326 = fa_light_texel(param_2);\n            float _336 = _326.w;\n            int param_3 = (li * 4) + 3;\n            float4 _343 = fa_light_texel(param_3);\n            float _344 = _343.x;\n            float cos_inner = _344;\n            if (_344 > 1.5f)\n            {\n                cos_inner = lerp(_336, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_336, cos_inner, dot(-l, normalize(_326.xyz)));\n        }\n    }\n    int _374;\n    if (_277)\n    {\n        _374 = 0;\n    }\n    else\n    {\n        _374 = (_270 > 1.5f) ? 2 : 1;\n    }\n    LightSample _2563 = { l, _267.xyz * atten, atten, 1.0f, dist, _374 };\n    return _2563;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1118;\n    if (i == 0)\n    {\n        _1118 = _1128_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1134;\n        if (i == 1)\n        {\n            _1134 = _1128_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1142;\n            if (i == 2)\n            {\n                _1142 = _1128_fa_shadow_split.z;\n            }\n            else\n            {\n                _1142 = _1128_fa_shadow_split.w;\n            }\n            _1134 = _1142;\n        }\n        _1118 = _1134;\n    }\n    return _1118;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1106 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1106), sin(_1106)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1180 = max(_1128_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1185 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1191 = sqrt(1.0f - (_1185 * _1185));\n    float _1198 = min(_1191 / max(_1185, 0.20000000298023223876953125f), 4.0f);\n    float _1203;\n    if (_1128_fa_shadow_bias.y > 0.0f)\n    {\n        _1203 = _1128_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1203 = 1.5f * _1128_fa_shadow_info[ci].x;\n    }\n    float4 _1228 = mul(float4(world + (n * (_1203 * _1191)), 1.0f), _1128_fa_shadow_mat[ci]);\n    float _1235 = _1228.x;\n    bool _1238 = _1235 < _1128_fa_shadow_rect[ci].x;\n    bool _1247;\n    if (!_1238)\n    {\n        _1247 = _1235 > _1128_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1247 = _1238;\n    }\n    bool _1256;\n    if (!_1247)\n    {\n        _1256 = _1228.y < _1128_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1256 = _1247;\n    }\n    bool _1265;\n    if (!_1256)\n    {\n        _1265 = _1228.y > _1128_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1265 = _1256;\n    }\n    bool _1272;\n    if (!_1265)\n    {\n        _1272 = _1228.z > 1.0f;\n    }\n    else\n    {\n        _1272 = _1265;\n    }\n    if (_1272)\n    {\n        return -1.0f;\n    }\n    float _1281;\n    if (_1128_fa_shadow_bias.x > 0.0f)\n    {\n        _1281 = _1128_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1281 = 1.5f * _1128_fa_shadow_info[ci].x;\n    }\n    float _1300 = _1228.z - ((_1281 * (1.0f + (0.5f * _1198))) / _1180);\n    float _1309 = ((_1128_fa_shadow_info[ci].x * min(_1198, 3.0f)) * 0.5f) / _1180;\n    int _1318 = int(_1128_fa_shadow_cfg.z + 0.5f);\n    if (_1318 == 1)\n    {\n        float2 param = _1228.xy;\n        float4 param_1 = _1128_fa_shadow_rect[ci];\n        float _1329 = fa_shadow_depth(param, param_1);\n        return float(_1300 <= _1329);\n    }\n    float _1336 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _1339 = _1318 == 2;\n    if (_1339)\n    {\n        float _1353 = clamp(((_1128_fa_shadow_cfg.w * _1180) * 0.25f) / _1128_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1336;\n            float2 _1372 = fa_shadow_vogel(param_2, param_3, param_4) * _1353;\n            float2 param_5 = _1228.xy + (_1372 * _1128_fa_shadow_bias.zw);\n            float4 param_6 = _1128_fa_shadow_rect[ci];\n            float _1383 = fa_shadow_depth(param_5, param_6);\n            if (_1383 < (_1300 - (length(_1372) * _1309)))\n            {\n                sum += _1383;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_1300 - (sum / cnt), 0.0f) * _1180) * _1128_fa_shadow_cfg.w) / _1128_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1427 = _1339 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1427; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1427;\n        float param_9 = _1336;\n        float2 _1446 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1228.xy + (_1446 * _1128_fa_shadow_bias.zw);\n        float4 param_11 = _1128_fa_shadow_rect[ci];\n        float _1457 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1300 - (length(_1446) * _1309)) <= _1457);\n    }\n    return lit / float(_1427);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_388_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1487 = int(_1128_fa_shadow_cfg.x + 0.5f);\n    if (_1487 < 1)\n    {\n        return 1.0f;\n    }\n    float _1502 = dot(world - _1128_fa_shadow_eye.xyz, _1128_fa_shadow_fwd.xyz);\n    int param = _1487 - 1;\n    if (_1502 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1514 = _1487 > 1;\n    bool _1521;\n    if (_1514)\n    {\n        _1521 = _1502 > _1128_fa_shadow_split.x;\n    }\n    else\n    {\n        _1521 = _1514;\n    }\n    if (_1521)\n    {\n        ci = 1;\n    }\n    bool _1525 = _1487 > 2;\n    bool _1532;\n    if (_1525)\n    {\n        _1532 = _1502 > _1128_fa_shadow_split.y;\n    }\n    else\n    {\n        _1532 = _1525;\n    }\n    if (_1532)\n    {\n        ci = 2;\n    }\n    bool _1536 = _1487 > 3;\n    bool _1543;\n    if (_1536)\n    {\n        _1543 = _1502 > _1128_fa_shadow_split.z;\n    }\n    else\n    {\n        _1543 = _1536;\n    }\n    if (_1543)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1487)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1569 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1569;\n        if (_1569 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1128_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1594;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1594 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1594 = _1128_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1613 = _1128_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1594, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1624 = clamp((_1502 - (fa_shadow_split_at(param_7) - _1613)) / _1613, 0.0f, 1.0f);\n        if (_1624 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1487)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1645 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1645;\n                if (_1645 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1624);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1814 = fa_light_sample(param, param_1);\n    float3 _2570 = _1814.direction;\n    float3 _2565 = _1814.color;\n    float _2567 = _1814.shadow;\n    int _2575 = _1814.type;\n    if ((_2575 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2570;\n        float _1828 = fa_shadow_factor(param_2, param_3);\n        _2567 = _1828;\n        _2565 *= _1828;\n    }\n    LightSample _2582 = { _2570, _2565, _1814.attenuation, _2567, _1814._distance, _2575 };\n    return _2582;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1128_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1669 = int(_1128_fa_shadow_cfg.x + 0.5f);\n    float _1679 = dot(world - _1128_fa_shadow_eye.xyz, _1128_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1684 = _1669 > 0;\n    bool _1693;\n    if (_1684)\n    {\n        int param = _1669 - 1;\n        _1693 = _1679 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1693 = _1684;\n    }\n    if (_1693)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1700 = _1669 > 1;\n        bool _1707;\n        if (_1700)\n        {\n            _1707 = _1679 > _1128_fa_shadow_split.x;\n        }\n        else\n        {\n            _1707 = _1700;\n        }\n        if (_1707)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1713 = _1669 > 2;\n        bool _1720;\n        if (_1713)\n        {\n            _1720 = _1679 > _1128_fa_shadow_split.y;\n        }\n        else\n        {\n            _1720 = _1713;\n        }\n        if (_1720)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1726 = _1669 > 3;\n        bool _1733;\n        if (_1726)\n        {\n            _1733 = _1679 > _1128_fa_shadow_split.z;\n        }\n        else\n        {\n            _1733 = _1726;\n        }\n        if (_1733)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2464 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2464 = -_2464;\n    }\n    float3 _2108 = normalize(_388_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2477 = { fa_world_pos, _2464, fa_world_tangent, fa_uv, fa_vertex_color, _2108, gl_FrontFacing };\n    SurfaceInput param_1 = _2477;\n    Surface _2116 = fa_standard_surface(param_1);\n    float3 _2495 = _2116.albedo;\n    float _2496 = _2116.alpha;\n    float3 _2497 = _2116.normal;\n    float _2498 = _2116.metallic;\n    float _2499 = _2116.roughness;\n    float _2500 = _2116.occlusion;\n    float3 _2501 = _2116.emission;\n    SurfaceInput _2485 = { fa_world_pos, _2464, fa_world_tangent, fa_uv, fa_vertex_color, _2108, gl_FrontFacing };\n    SurfaceInput param_2 = _2485;\n    Surface param_3 = _2116;\n    surface(param_2, param_3);\n    _2495 = param_3.albedo;\n    _2496 = param_3.alpha;\n    _2497 = param_3.normal;\n    _2498 = param_3.metallic;\n    _2499 = param_3.roughness;\n    _2500 = param_3.occlusion;\n    _2501 = param_3.emission;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _2464;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2495 = param_6;\n    _2497 = param_7;\n    float3 result;\n    if (_388_fa_emissive.w > 0.5f)\n    {\n        result = _2495;\n    }\n    else\n    {\n        float3 _2154 = _2497;\n        float3 _2155 = normalize(_2154);\n        _2497 = _2155;\n        float3 param_8 = _2155;\n        float3 lit = (fa_ambient_light(param_8) * _2495) * _2500;\n        int _2174 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2174; ln++)\n        {\n            int param_9 = ln;\n            int param_10 = fa_cl_light(param_9);\n            float3 param_11 = fa_world_pos;\n            float3 param_12 = _2464;\n            SurfaceInput _2493 = { fa_world_pos, _2464, fa_world_tangent, fa_uv, fa_vertex_color, _2108, gl_FrontFacing };\n            SurfaceInput param_13 = _2493;\n            Surface _2531 = { _2495, _2496, _2497, _2498, _2499, _2500, _2501 };\n            Surface param_14 = _2531;\n            LightSample param_15 = fa_light_shadowed(param_10, param_11, param_12);\n            lit += light(param_13, param_14, param_15);\n        }\n        result = lit;\n    }\n    float3 _2211 = result;\n    float3 _2212 = _2211 + _2501;\n    result = _2212;\n    float3 param_16 = _2212;\n    float3 param_17 = fa_world_pos;\n    result = fa_shadow_debug(param_16, param_17);\n    bool _2221 = _388_fa_fog.w > 0.0f;\n    bool _2229;\n    if (!_2221)\n    {\n        _2229 = _388_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2229 = _2221;\n    }\n    if (_2229)\n    {\n        float3 _2238 = fa_world_pos - _388_fa_camera_pos.xyz;\n        float _2245 = dot(_2238, _388_fa_fog_c.xyz);\n        bool _2249 = _388_fa_fog_c.w > 0.5f;\n        float _2250;\n        if (_2249)\n        {\n            _2250 = _2245;\n        }\n        else\n        {\n            _2250 = length(_2238);\n        }\n        float _2262 = _2250 - _388_fa_fog_b.x;\n        if (_2262 > 0.0f)\n        {\n            float _2271 = _388_fa_fog.w * _2262;\n            float tau = _2271 * _2271;\n            if (_388_fa_fog_b.y > 0.0f)\n            {\n                float _2287;\n                if (_2249)\n                {\n                    _2287 = fa_world_pos.y - (_388_fa_fog_c.y * _2245);\n                }\n                else\n                {\n                    _2287 = _388_fa_camera_pos.y;\n                }\n                float _2308 = lerp(_2287, fa_world_pos.y, clamp(_388_fa_fog_b.x / _2250, 0.0f, 1.0f));\n                float _2312 = fa_world_pos.y - _2308;\n                float _2317 = _2308 - _388_fa_fog_b.z;\n                float _2322 = fa_world_pos.y - _388_fa_fog_b.z;\n                bool _2325 = _2317 <= 0.0f;\n                bool _2326 = !_2325;\n                bool _2332;\n                if (_2326)\n                {\n                    _2332 = _388_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2332 = _2325;\n                }\n                float _2333;\n                if (_2332)\n                {\n                    _2333 = _388_fa_fog_b.y;\n                }\n                else\n                {\n                    _2333 = _388_fa_fog_b.y * exp(-min(_388_fa_fog_b.w * _2317, 80.0f));\n                }\n                bool _2360;\n                if (_2326)\n                {\n                    _2360 = _388_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2360 = _2325;\n                }\n                float _2361;\n                if (_2360)\n                {\n                    _2361 = _388_fa_fog_b.y * _2317;\n                }\n                else\n                {\n                    _2361 = (_388_fa_fog_b.y * (1.0f - exp(-min(_388_fa_fog_b.w * _2317, 80.0f)))) / _388_fa_fog_b.w;\n                }\n                bool _2386 = _2322 <= 0.0f;\n                bool _2393;\n                if (!_2386)\n                {\n                    _2393 = _388_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2393 = _2386;\n                }\n                float _2394;\n                if (_2393)\n                {\n                    _2394 = _388_fa_fog_b.y * _2322;\n                }\n                else\n                {\n                    _2394 = (_388_fa_fog_b.y * (1.0f - exp(-min(_388_fa_fog_b.w * _2322, 80.0f)))) / _388_fa_fog_b.w;\n                }\n                float _2421;\n                if (abs(_2312) < 0.001000000047497451305389404296875f)\n                {\n                    _2421 = _2333;\n                }\n                else\n                {\n                    _2421 = (_2394 - _2361) / _2312;\n                }\n                tau += (_2262 * max(_2421, 0.0f));\n            }\n            result = lerp(result, _388_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2496);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_388",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1128",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
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
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _588 = base_t;\n    _588.x = _225.x;\n    _588.y = _225.y;\n    _588.z = _225.z;\n    base_t = _588;\n    float4 _241 = (_588 * _213_fa_base_color) * i.vertex_color;\n    float3 _569 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _596 = _279;\n        _596.x = _284.x;\n        _596.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _596;\n        _569 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _599 = mrt;\n    _599.x = _313.x;\n    _599.y = _313.y;\n    _599.z = _313.z;\n    mrt = _599;\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    Surface _581 = { _241.xyz, _241.w, _569, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_354.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _381) };\n    return _581;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _516 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _516 = -_516;\n    }\n    float3 _427 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _529 = { fa_world_pos, _516, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param = _529;\n    SurfaceInput _537 = { fa_world_pos, _516, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param_1 = _537;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _442 = normalize(param_2.normal);\n    float3 _457 = normalize(float3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / ((abs(_457.x) + abs(_457.y)) + abs(_469)).xx;\n    if (_469 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 320,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _588 = base_t;\n    _588.x = _225.x;\n    _588.y = _225.y;\n    _588.z = _225.z;\n    base_t = _588;\n    float4 _241 = (_588 * _213_fa_base_color) * i.vertex_color;\n    float3 _569 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _596 = _279;\n        _596.x = _284.x;\n        _596.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _596;\n        _569 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _599 = mrt;\n    _599.x = _313.x;\n    _599.y = _313.y;\n    _599.z = _313.z;\n    mrt = _599;\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    Surface _581 = { _241.xyz, _241.w, _569, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_354.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _381) };\n    return _581;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _516 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _516 = -_516;\n    }\n    float3 _427 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _529 = { fa_world_pos, _516, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param = _529;\n    SurfaceInput _537 = { fa_world_pos, _516, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param_1 = _537;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _442 = normalize(param_2.normal);\n    float3 _457 = normalize(float3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / ((abs(_457.x) + abs(_457.y)) + abs(_469)).xx;\n    if (_469 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 320,
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
