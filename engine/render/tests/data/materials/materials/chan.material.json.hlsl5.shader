{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "4618a1bb4aa617d03f3a79bc8520aaa28381261c509989179d44574ba972e851",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "vertexAttributes": [
    "color1",
    "uv1"
  ],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _144_fa_view_proj : packoffset(c0);\n    row_major float4x4 _144_fa_light_vp : packoffset(c4);\n    float4 _144_fa_uv_scale : packoffset(c8);\n    float4 _144_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float2 fa_attr_uv1 : TEXCOORD9;\n    float4 fa_attr_color1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _283 = { mul(float4(position, 1.0f), model).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _144_fa_uv_scale.xy, color, position };\n    return _283;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _183 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = mul(_183, _144_fa_light_vp);\n    gl_Position = mul(_183, _144_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _354_fa_camera_pos : packoffset(c0);\n    float4 _354_fa_ambient : packoffset(c1);\n    float4 _354_fa_base_color : packoffset(c2);\n    float4 _354_fa_emissive : packoffset(c3);\n    float4 _354_fa_model_emissive : packoffset(c4);\n    float4 _354_fa_pbr : packoffset(c5);\n    float4 _354_fa_maps : packoffset(c6);\n    float4 _354_fa_fog : packoffset(c7);\n    float4 _354_fa_fog_b : packoffset(c8);\n    float4 _354_fa_fog_c : packoffset(c9);\n    float4 _354_fa_counts : packoffset(c10);\n    float4 _354_fa_env_sky : packoffset(c11);\n    float4 _354_fa_env_horizon : packoffset(c12);\n    float4 _354_fa_time : packoffset(c13);\n    float4 _354_fa_cl_vpx : packoffset(c14);\n    float4 _354_fa_cl_vpy : packoffset(c15);\n    float4 _354_fa_cl_vpw : packoffset(c16);\n    float4 _354_fa_cl_fwd : packoffset(c17);\n    float4 _354_fa_cl_grid : packoffset(c18);\n    float4 _354_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    if (_354_fa_cl_info.x < 0.0f)\n    {\n        return int2(0, 0);\n    }\n    float4 _369 = float4(world_pos, 1.0f);\n    float2 _390 = float2(dot(_354_fa_cl_vpx, _369), dot(_354_fa_cl_vpy, _369)) / dot(_354_fa_cl_vpw, _369).xx;\n    int _395 = int(_354_fa_cl_grid.x);\n    int _399 = int(_354_fa_cl_grid.y);\n    int param = (int(_354_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_354_fa_cl_fwd.xyz, world_pos) + _354_fa_cl_fwd.w, _354_fa_cl_grid.w) / _354_fa_cl_grid.w) * _354_fa_cl_grid.z)), 0, int(_354_fa_cl_info.y) - 1) * _399) + clamp(int(floor(((_390.y * 0.5f) + 0.5f) * _354_fa_cl_grid.y)), 0, _399 - 1)) * _395)) + clamp(int(floor(((_390.x * 0.5f) + 0.5f) * _354_fa_cl_grid.x)), 0, _395 - 1);\n    float4 _470 = fa_light_texel(param);\n    return int2(int(_470.x), int(_470.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_354_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _844 = fa_cluster_lookup(param);\n    fa_cl_slot = _844.x;\n    fa_cl_local = _844.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _956 = fa_linear_to_srgb(param);\n        c = _956;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _964 = fa_srgb_to_linear(param_1);\n            c = _964;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _126;\n    if (i.front_facing)\n    {\n        _126 = i.world_normal;\n    }\n    else\n    {\n        _126 = -i.world_normal;\n    }\n    float3 _150 = normalize(i.world_tangent.xyz - (_126 * dot(_126, i.world_tangent.xyz)));\n    float3 _178 = normalize(((_150 * m.x) + ((cross(_126, _150) * i.world_tangent.w) * m.y)) + (_126 * m.z));\n    float3 _181;\n    if (i.front_facing)\n    {\n        _181 = _178;\n    }\n    else\n    {\n        _181 = -_178;\n    }\n    return _181;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _354_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _996 = fa_tex_fix(param_2, param_3);\n    float4 _1787 = base_t;\n    _1787.x = _996.x;\n    _1787.y = _996.y;\n    _1787.z = _996.z;\n    base_t = _1787;\n    float4 _1010 = (_1787 * _354_fa_base_color) * i.vertex_color;\n    float3 _1746 = i.world_normal;\n    if (_354_fa_maps.z > 0.5f)\n    {\n        float param_4 = _354_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1043 = fa_tex_fix(param_6, param_7);\n        float3 _1046 = (_1043 * 2.0f) - 1.0f.xxx;\n        float2 _1051 = _1046.xy * _354_fa_maps.x;\n        float3 _1795 = _1046;\n        _1795.x = _1051.x;\n        _1795.y = _1051.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1795;\n        _1746 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _354_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1080 = fa_tex_fix(param_12, param_13);\n    float4 _1798 = mrt;\n    _1798.x = _1080.x;\n    _1798.y = _1080.y;\n    _1798.z = _1080.z;\n    mrt = _1798;\n    float param_14 = _354_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1119 = fa_tex_fix(param_16, param_17);\n    float param_18 = _354_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1146 = fa_tex_fix(param_20, param_21);\n    Surface _1758 = { _1010.xyz, _1010.w, _1746, clamp(_354_fa_pbr.x * _1080.z, 0.0f, 1.0f), clamp(_354_fa_pbr.y * _1080.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_354_fa_maps.y * (_1119.x - 1.0f)), _354_fa_emissive.xyz + (_354_fa_model_emissive.xyz * _1146) };\n    return _1758;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0f));\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_354_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _354_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_354_fa_cl_info.x) + int(_354_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _226 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _232 = fa_light_texel(param_1);\n    float _235 = _232.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _242 = _235 < 0.5f;\n    float3 l;\n    if (_242)\n    {\n        l = normalize(_226.xyz);\n    }\n    else\n    {\n        float3 _254 = _226.xyz - world_pos;\n        float _256 = length(_254);\n        dist = _256;\n        l = _254 / max(_256, 9.9999997473787516355514526367188e-05f).xxx;\n        float _271 = _256 / max(_226.w, 0.001000000047497451305389404296875f);\n        float _277 = clamp(1.0f - (_271 * _271), 0.0f, 1.0f);\n        atten = _277 * _277;\n        if (_235 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _291 = fa_light_texel(param_2);\n            float _301 = _291.w;\n            int param_3 = (li * 4) + 3;\n            float4 _308 = fa_light_texel(param_3);\n            float _309 = _308.x;\n            float cos_inner = _309;\n            if (_309 > 1.5f)\n            {\n                cos_inner = lerp(_301, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_301, cos_inner, dot(-l, normalize(_291.xyz)));\n        }\n    }\n    int _340;\n    if (_242)\n    {\n        _340 = 0;\n    }\n    else\n    {\n        _340 = (_235 > 1.5f) ? 2 : 1;\n    }\n    LightSample _1724 = { l, _232.xyz * atten, atten, 1.0f, dist, _340 };\n    return _1724;\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_354_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _516 = coord.xyz / coord.w.xxx;\n    float3 p = _516;\n    float2 suv = (_516.xy * 0.5f) + 0.5f.xx;\n    if (_354_fa_counts.z > 0.5f)\n    {\n        float3 _1767 = p;\n        _1767.z = (_1767.z * 0.5f) + 0.5f;\n        p = _1767;\n    }\n    else\n    {\n        float2 _1770 = suv;\n        _1770.y = 1.0f - _1770.y;\n        suv = _1770;\n    }\n    bool _542 = suv.x < 0.0f;\n    bool _549;\n    if (!_542)\n    {\n        _549 = suv.x > 1.0f;\n    }\n    else\n    {\n        _549 = _542;\n    }\n    bool _556;\n    if (!_549)\n    {\n        _556 = suv.y < 0.0f;\n    }\n    else\n    {\n        _556 = _549;\n    }\n    bool _563;\n    if (!_556)\n    {\n        _563 = suv.y > 1.0f;\n    }\n    else\n    {\n        _563 = _556;\n    }\n    bool _570;\n    if (!_563)\n    {\n        _570 = p.z > 1.0f;\n    }\n    else\n    {\n        _570 = _563;\n    }\n    if (_570)\n    {\n        return 1.0f;\n    }\n    float _585 = _354_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _585) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _354_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _872 = fa_light_sample(param, param_1);\n    float3 _1731 = _872.direction;\n    float3 _1726 = _872.color;\n    float _1728 = _872.shadow;\n    int _1736 = _872.type;\n    if ((_1736 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1731;\n        float _886 = fa_shadow_factor(param_2, param_3);\n        _1728 = _886;\n        _1726 *= _886;\n    }\n    LightSample _1743 = { _1731, _1726, _872.attenuation, _1728, _872._distance, _1736 };\n    return _1743;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _776 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _779 = _776.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_779 * _779, exp2((-9.27999973297119140625f) * ndv)) * _779) + _776.y)) + _776.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_354_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _354_fa_env_horizon.w).xyz;\n    }\n    float _679 = rough * rough;\n    float _710 = 0.60000002384185791015625f * _679;\n    return lerp(lerp(_354_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_354_fa_env_horizon.xyz, _354_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _679)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _710, 0.0500000007450580596923828125f + _710, d.y).xxx), ((_354_fa_env_sky.xyz + _354_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_679 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _818 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _818.x) + _818.y.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _1651 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1651 = -_1651;\n    }\n    float3 _1191 = normalize(_354_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _1664 = { fa_world_pos, _1651, fa_world_tangent, fa_uv, fa_vertex_color, _1191, gl_FrontFacing };\n    SurfaceInput param_1 = _1664;\n    Surface _1199 = fa_standard_surface(param_1);\n    float3 _1674 = _1199.albedo;\n    float _1675 = _1199.alpha;\n    float3 _1676 = _1199.normal;\n    float _1677 = _1199.metallic;\n    float _1678 = _1199.roughness;\n    float _1679 = _1199.occlusion;\n    float3 _1680 = _1199.emission;\n    SurfaceInput _1672 = { fa_world_pos, _1651, fa_world_tangent, fa_uv, fa_vertex_color, _1191, gl_FrontFacing };\n    SurfaceInput param_2 = _1672;\n    Surface param_3 = _1199;\n    surface(param_2, param_3);\n    _1674 = param_3.albedo;\n    _1675 = param_3.alpha;\n    _1676 = param_3.normal;\n    _1677 = param_3.metallic;\n    _1678 = param_3.roughness;\n    _1679 = param_3.occlusion;\n    _1680 = param_3.emission;\n    float3 result;\n    if (_354_fa_emissive.w > 0.5f)\n    {\n        result = _1674;\n    }\n    else\n    {\n        float3 _1221 = normalize(_1676);\n        float _1228 = clamp(_1677, 0.0f, 1.0f);\n        float _1232 = clamp(_1678, 0.0500000007450580596923828125f, 1.0f);\n        float _1236 = _1232 * _1232;\n        float _1240 = _1236 * _1236;\n        float _1245 = max(dot(_1221, _1191), 9.9999997473787516355514526367188e-05f);\n        float3 _1251 = _1674 * (1.0f - _1228);\n        float3 _1259 = lerp(0.039999999105930328369140625f.xxx, _1674, _1228.xxx);\n        float3 param_4 = _1221;\n        float3 lit = (fa_ambient_light(param_4) * _1251) * _1679;\n        int _1272 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1272; ln++)\n        {\n            int param_5 = ln;\n            int _1285 = fa_cl_light(param_5);\n            int param_6 = _1285;\n            float3 param_7 = fa_world_pos;\n            float3 param_8 = _1651;\n            LightSample _1294 = fa_light_shadowed(param_6, param_7, param_8);\n            float3 _1709 = _1294.direction;\n            float _1302 = max(dot(_1221, _1709), 0.0f);\n            float3 _1313 = normalize(_1709 + _1191);\n            float _1318 = max(dot(_1221, _1313), 0.0f);\n            float _1331 = ((_1318 * _1318) * (_1240 - 1.0f)) + 1.0f;\n            int param_9 = _1285;\n            lit += (((_1251 + (((_1259 + ((1.0f.xxx - _1259) * pow(1.0f - max(dot(_1191, _1313), 0.0f), 5.0f))) * (((_1240 / ((3.1415927410125732421875f * _1331) * _1331)) * (0.5f / max(lerp((2.0f * _1302) * _1245, _1302 + _1245, _1236), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _1302))) * fa_light_rgb(param_9)) * (_1302 * (_1294.attenuation * _1294.shadow)));\n        }\n        float3 param_10 = _1221;\n        float3 param_11 = _1191;\n        float3 param_12 = _1259;\n        float param_13 = _1232;\n        float3 _1400 = lit;\n        float3 _1401 = _1400 + (fa_sky_reflection(param_10, param_11, param_12, param_13) * _1679);\n        lit = _1401;\n        result = _1401;\n    }\n    result += _1680;\n    bool _1410 = _354_fa_fog.w > 0.0f;\n    bool _1418;\n    if (!_1410)\n    {\n        _1418 = _354_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1418 = _1410;\n    }\n    if (_1418)\n    {\n        float3 _1427 = fa_world_pos - _354_fa_camera_pos.xyz;\n        float _1434 = dot(_1427, _354_fa_fog_c.xyz);\n        bool _1438 = _354_fa_fog_c.w > 0.5f;\n        float _1439;\n        if (_1438)\n        {\n            _1439 = _1434;\n        }\n        else\n        {\n            _1439 = length(_1427);\n        }\n        float _1451 = _1439 - _354_fa_fog_b.x;\n        if (_1451 > 0.0f)\n        {\n            float _1460 = _354_fa_fog.w * _1451;\n            float tau = _1460 * _1460;\n            if (_354_fa_fog_b.y > 0.0f)\n            {\n                float _1476;\n                if (_1438)\n                {\n                    _1476 = fa_world_pos.y - (_354_fa_fog_c.y * _1434);\n                }\n                else\n                {\n                    _1476 = _354_fa_camera_pos.y;\n                }\n                float _1497 = lerp(_1476, fa_world_pos.y, clamp(_354_fa_fog_b.x / _1439, 0.0f, 1.0f));\n                float _1501 = fa_world_pos.y - _1497;\n                float _1506 = _1497 - _354_fa_fog_b.z;\n                float _1511 = fa_world_pos.y - _354_fa_fog_b.z;\n                bool _1514 = _1506 <= 0.0f;\n                bool _1515 = !_1514;\n                bool _1521;\n                if (_1515)\n                {\n                    _1521 = _354_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1521 = _1514;\n                }\n                float _1522;\n                if (_1521)\n                {\n                    _1522 = _354_fa_fog_b.y;\n                }\n                else\n                {\n                    _1522 = _354_fa_fog_b.y * exp(-min(_354_fa_fog_b.w * _1506, 80.0f));\n                }\n                bool _1549;\n                if (_1515)\n                {\n                    _1549 = _354_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1549 = _1514;\n                }\n                float _1550;\n                if (_1549)\n                {\n                    _1550 = _354_fa_fog_b.y * _1506;\n                }\n                else\n                {\n                    _1550 = (_354_fa_fog_b.y * (1.0f - exp(-min(_354_fa_fog_b.w * _1506, 80.0f)))) / _354_fa_fog_b.w;\n                }\n                bool _1575 = _1511 <= 0.0f;\n                bool _1582;\n                if (!_1575)\n                {\n                    _1582 = _354_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1582 = _1575;\n                }\n                float _1583;\n                if (_1582)\n                {\n                    _1583 = _354_fa_fog_b.y * _1511;\n                }\n                else\n                {\n                    _1583 = (_354_fa_fog_b.y * (1.0f - exp(-min(_354_fa_fog_b.w * _1511, 80.0f)))) / _354_fa_fog_b.w;\n                }\n                float _1610;\n                if (abs(_1501) < 0.001000000047497451305389404296875f)\n                {\n                    _1610 = _1522;\n                }\n                else\n                {\n                    _1610 = (_1583 - _1550) / _1501;\n                }\n                tau += (_1451 * max(_1610, 0.0f));\n            }\n            result = lerp(result, _354_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _1675);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_144",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_354",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _149_fa_view_proj : packoffset(c0);\n    row_major float4x4 _149_fa_light_vp : packoffset(c4);\n    float4 _149_fa_uv_scale : packoffset(c8);\n    float4 _149_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _195_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float2 fa_attr_uv1 : TEXCOORD11;\n    float4 fa_attr_color1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _186 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_195_fa_joint_rows[_186] * weights[i]);\n        r1 += (_195_fa_joint_rows[_186 + 1] * weights[i]);\n        r2 += (_195_fa_joint_rows[_186 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _404 = { mul(float4(position, 1.0f), model).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _149_fa_uv_scale.xy, color, position };\n    return _404;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _296 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = mul(_296, _149_fa_light_vp);\n    gl_Position = mul(_296, _149_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _354_fa_camera_pos : packoffset(c0);\n    float4 _354_fa_ambient : packoffset(c1);\n    float4 _354_fa_base_color : packoffset(c2);\n    float4 _354_fa_emissive : packoffset(c3);\n    float4 _354_fa_model_emissive : packoffset(c4);\n    float4 _354_fa_pbr : packoffset(c5);\n    float4 _354_fa_maps : packoffset(c6);\n    float4 _354_fa_fog : packoffset(c7);\n    float4 _354_fa_fog_b : packoffset(c8);\n    float4 _354_fa_fog_c : packoffset(c9);\n    float4 _354_fa_counts : packoffset(c10);\n    float4 _354_fa_env_sky : packoffset(c11);\n    float4 _354_fa_env_horizon : packoffset(c12);\n    float4 _354_fa_time : packoffset(c13);\n    float4 _354_fa_cl_vpx : packoffset(c14);\n    float4 _354_fa_cl_vpy : packoffset(c15);\n    float4 _354_fa_cl_vpw : packoffset(c16);\n    float4 _354_fa_cl_fwd : packoffset(c17);\n    float4 _354_fa_cl_grid : packoffset(c18);\n    float4 _354_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    if (_354_fa_cl_info.x < 0.0f)\n    {\n        return int2(0, 0);\n    }\n    float4 _369 = float4(world_pos, 1.0f);\n    float2 _390 = float2(dot(_354_fa_cl_vpx, _369), dot(_354_fa_cl_vpy, _369)) / dot(_354_fa_cl_vpw, _369).xx;\n    int _395 = int(_354_fa_cl_grid.x);\n    int _399 = int(_354_fa_cl_grid.y);\n    int param = (int(_354_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_354_fa_cl_fwd.xyz, world_pos) + _354_fa_cl_fwd.w, _354_fa_cl_grid.w) / _354_fa_cl_grid.w) * _354_fa_cl_grid.z)), 0, int(_354_fa_cl_info.y) - 1) * _399) + clamp(int(floor(((_390.y * 0.5f) + 0.5f) * _354_fa_cl_grid.y)), 0, _399 - 1)) * _395)) + clamp(int(floor(((_390.x * 0.5f) + 0.5f) * _354_fa_cl_grid.x)), 0, _395 - 1);\n    float4 _470 = fa_light_texel(param);\n    return int2(int(_470.x), int(_470.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_354_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _844 = fa_cluster_lookup(param);\n    fa_cl_slot = _844.x;\n    fa_cl_local = _844.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _956 = fa_linear_to_srgb(param);\n        c = _956;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _964 = fa_srgb_to_linear(param_1);\n            c = _964;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _126;\n    if (i.front_facing)\n    {\n        _126 = i.world_normal;\n    }\n    else\n    {\n        _126 = -i.world_normal;\n    }\n    float3 _150 = normalize(i.world_tangent.xyz - (_126 * dot(_126, i.world_tangent.xyz)));\n    float3 _178 = normalize(((_150 * m.x) + ((cross(_126, _150) * i.world_tangent.w) * m.y)) + (_126 * m.z));\n    float3 _181;\n    if (i.front_facing)\n    {\n        _181 = _178;\n    }\n    else\n    {\n        _181 = -_178;\n    }\n    return _181;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _354_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _996 = fa_tex_fix(param_2, param_3);\n    float4 _1787 = base_t;\n    _1787.x = _996.x;\n    _1787.y = _996.y;\n    _1787.z = _996.z;\n    base_t = _1787;\n    float4 _1010 = (_1787 * _354_fa_base_color) * i.vertex_color;\n    float3 _1746 = i.world_normal;\n    if (_354_fa_maps.z > 0.5f)\n    {\n        float param_4 = _354_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1043 = fa_tex_fix(param_6, param_7);\n        float3 _1046 = (_1043 * 2.0f) - 1.0f.xxx;\n        float2 _1051 = _1046.xy * _354_fa_maps.x;\n        float3 _1795 = _1046;\n        _1795.x = _1051.x;\n        _1795.y = _1051.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1795;\n        _1746 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _354_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1080 = fa_tex_fix(param_12, param_13);\n    float4 _1798 = mrt;\n    _1798.x = _1080.x;\n    _1798.y = _1080.y;\n    _1798.z = _1080.z;\n    mrt = _1798;\n    float param_14 = _354_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1119 = fa_tex_fix(param_16, param_17);\n    float param_18 = _354_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1146 = fa_tex_fix(param_20, param_21);\n    Surface _1758 = { _1010.xyz, _1010.w, _1746, clamp(_354_fa_pbr.x * _1080.z, 0.0f, 1.0f), clamp(_354_fa_pbr.y * _1080.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_354_fa_maps.y * (_1119.x - 1.0f)), _354_fa_emissive.xyz + (_354_fa_model_emissive.xyz * _1146) };\n    return _1758;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0f));\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_354_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _354_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_354_fa_cl_info.x) + int(_354_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _226 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _232 = fa_light_texel(param_1);\n    float _235 = _232.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _242 = _235 < 0.5f;\n    float3 l;\n    if (_242)\n    {\n        l = normalize(_226.xyz);\n    }\n    else\n    {\n        float3 _254 = _226.xyz - world_pos;\n        float _256 = length(_254);\n        dist = _256;\n        l = _254 / max(_256, 9.9999997473787516355514526367188e-05f).xxx;\n        float _271 = _256 / max(_226.w, 0.001000000047497451305389404296875f);\n        float _277 = clamp(1.0f - (_271 * _271), 0.0f, 1.0f);\n        atten = _277 * _277;\n        if (_235 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _291 = fa_light_texel(param_2);\n            float _301 = _291.w;\n            int param_3 = (li * 4) + 3;\n            float4 _308 = fa_light_texel(param_3);\n            float _309 = _308.x;\n            float cos_inner = _309;\n            if (_309 > 1.5f)\n            {\n                cos_inner = lerp(_301, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_301, cos_inner, dot(-l, normalize(_291.xyz)));\n        }\n    }\n    int _340;\n    if (_242)\n    {\n        _340 = 0;\n    }\n    else\n    {\n        _340 = (_235 > 1.5f) ? 2 : 1;\n    }\n    LightSample _1724 = { l, _232.xyz * atten, atten, 1.0f, dist, _340 };\n    return _1724;\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_354_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _516 = coord.xyz / coord.w.xxx;\n    float3 p = _516;\n    float2 suv = (_516.xy * 0.5f) + 0.5f.xx;\n    if (_354_fa_counts.z > 0.5f)\n    {\n        float3 _1767 = p;\n        _1767.z = (_1767.z * 0.5f) + 0.5f;\n        p = _1767;\n    }\n    else\n    {\n        float2 _1770 = suv;\n        _1770.y = 1.0f - _1770.y;\n        suv = _1770;\n    }\n    bool _542 = suv.x < 0.0f;\n    bool _549;\n    if (!_542)\n    {\n        _549 = suv.x > 1.0f;\n    }\n    else\n    {\n        _549 = _542;\n    }\n    bool _556;\n    if (!_549)\n    {\n        _556 = suv.y < 0.0f;\n    }\n    else\n    {\n        _556 = _549;\n    }\n    bool _563;\n    if (!_556)\n    {\n        _563 = suv.y > 1.0f;\n    }\n    else\n    {\n        _563 = _556;\n    }\n    bool _570;\n    if (!_563)\n    {\n        _570 = p.z > 1.0f;\n    }\n    else\n    {\n        _570 = _563;\n    }\n    if (_570)\n    {\n        return 1.0f;\n    }\n    float _585 = _354_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _585) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _354_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _872 = fa_light_sample(param, param_1);\n    float3 _1731 = _872.direction;\n    float3 _1726 = _872.color;\n    float _1728 = _872.shadow;\n    int _1736 = _872.type;\n    if ((_1736 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1731;\n        float _886 = fa_shadow_factor(param_2, param_3);\n        _1728 = _886;\n        _1726 *= _886;\n    }\n    LightSample _1743 = { _1731, _1726, _872.attenuation, _1728, _872._distance, _1736 };\n    return _1743;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _776 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _779 = _776.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_779 * _779, exp2((-9.27999973297119140625f) * ndv)) * _779) + _776.y)) + _776.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_354_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _354_fa_env_horizon.w).xyz;\n    }\n    float _679 = rough * rough;\n    float _710 = 0.60000002384185791015625f * _679;\n    return lerp(lerp(_354_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_354_fa_env_horizon.xyz, _354_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _679)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _710, 0.0500000007450580596923828125f + _710, d.y).xxx), ((_354_fa_env_sky.xyz + _354_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_679 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _818 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _818.x) + _818.y.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _1651 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1651 = -_1651;\n    }\n    float3 _1191 = normalize(_354_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _1664 = { fa_world_pos, _1651, fa_world_tangent, fa_uv, fa_vertex_color, _1191, gl_FrontFacing };\n    SurfaceInput param_1 = _1664;\n    Surface _1199 = fa_standard_surface(param_1);\n    float3 _1674 = _1199.albedo;\n    float _1675 = _1199.alpha;\n    float3 _1676 = _1199.normal;\n    float _1677 = _1199.metallic;\n    float _1678 = _1199.roughness;\n    float _1679 = _1199.occlusion;\n    float3 _1680 = _1199.emission;\n    SurfaceInput _1672 = { fa_world_pos, _1651, fa_world_tangent, fa_uv, fa_vertex_color, _1191, gl_FrontFacing };\n    SurfaceInput param_2 = _1672;\n    Surface param_3 = _1199;\n    surface(param_2, param_3);\n    _1674 = param_3.albedo;\n    _1675 = param_3.alpha;\n    _1676 = param_3.normal;\n    _1677 = param_3.metallic;\n    _1678 = param_3.roughness;\n    _1679 = param_3.occlusion;\n    _1680 = param_3.emission;\n    float3 result;\n    if (_354_fa_emissive.w > 0.5f)\n    {\n        result = _1674;\n    }\n    else\n    {\n        float3 _1221 = normalize(_1676);\n        float _1228 = clamp(_1677, 0.0f, 1.0f);\n        float _1232 = clamp(_1678, 0.0500000007450580596923828125f, 1.0f);\n        float _1236 = _1232 * _1232;\n        float _1240 = _1236 * _1236;\n        float _1245 = max(dot(_1221, _1191), 9.9999997473787516355514526367188e-05f);\n        float3 _1251 = _1674 * (1.0f - _1228);\n        float3 _1259 = lerp(0.039999999105930328369140625f.xxx, _1674, _1228.xxx);\n        float3 param_4 = _1221;\n        float3 lit = (fa_ambient_light(param_4) * _1251) * _1679;\n        int _1272 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1272; ln++)\n        {\n            int param_5 = ln;\n            int _1285 = fa_cl_light(param_5);\n            int param_6 = _1285;\n            float3 param_7 = fa_world_pos;\n            float3 param_8 = _1651;\n            LightSample _1294 = fa_light_shadowed(param_6, param_7, param_8);\n            float3 _1709 = _1294.direction;\n            float _1302 = max(dot(_1221, _1709), 0.0f);\n            float3 _1313 = normalize(_1709 + _1191);\n            float _1318 = max(dot(_1221, _1313), 0.0f);\n            float _1331 = ((_1318 * _1318) * (_1240 - 1.0f)) + 1.0f;\n            int param_9 = _1285;\n            lit += (((_1251 + (((_1259 + ((1.0f.xxx - _1259) * pow(1.0f - max(dot(_1191, _1313), 0.0f), 5.0f))) * (((_1240 / ((3.1415927410125732421875f * _1331) * _1331)) * (0.5f / max(lerp((2.0f * _1302) * _1245, _1302 + _1245, _1236), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _1302))) * fa_light_rgb(param_9)) * (_1302 * (_1294.attenuation * _1294.shadow)));\n        }\n        float3 param_10 = _1221;\n        float3 param_11 = _1191;\n        float3 param_12 = _1259;\n        float param_13 = _1232;\n        float3 _1400 = lit;\n        float3 _1401 = _1400 + (fa_sky_reflection(param_10, param_11, param_12, param_13) * _1679);\n        lit = _1401;\n        result = _1401;\n    }\n    result += _1680;\n    bool _1410 = _354_fa_fog.w > 0.0f;\n    bool _1418;\n    if (!_1410)\n    {\n        _1418 = _354_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1418 = _1410;\n    }\n    if (_1418)\n    {\n        float3 _1427 = fa_world_pos - _354_fa_camera_pos.xyz;\n        float _1434 = dot(_1427, _354_fa_fog_c.xyz);\n        bool _1438 = _354_fa_fog_c.w > 0.5f;\n        float _1439;\n        if (_1438)\n        {\n            _1439 = _1434;\n        }\n        else\n        {\n            _1439 = length(_1427);\n        }\n        float _1451 = _1439 - _354_fa_fog_b.x;\n        if (_1451 > 0.0f)\n        {\n            float _1460 = _354_fa_fog.w * _1451;\n            float tau = _1460 * _1460;\n            if (_354_fa_fog_b.y > 0.0f)\n            {\n                float _1476;\n                if (_1438)\n                {\n                    _1476 = fa_world_pos.y - (_354_fa_fog_c.y * _1434);\n                }\n                else\n                {\n                    _1476 = _354_fa_camera_pos.y;\n                }\n                float _1497 = lerp(_1476, fa_world_pos.y, clamp(_354_fa_fog_b.x / _1439, 0.0f, 1.0f));\n                float _1501 = fa_world_pos.y - _1497;\n                float _1506 = _1497 - _354_fa_fog_b.z;\n                float _1511 = fa_world_pos.y - _354_fa_fog_b.z;\n                bool _1514 = _1506 <= 0.0f;\n                bool _1515 = !_1514;\n                bool _1521;\n                if (_1515)\n                {\n                    _1521 = _354_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1521 = _1514;\n                }\n                float _1522;\n                if (_1521)\n                {\n                    _1522 = _354_fa_fog_b.y;\n                }\n                else\n                {\n                    _1522 = _354_fa_fog_b.y * exp(-min(_354_fa_fog_b.w * _1506, 80.0f));\n                }\n                bool _1549;\n                if (_1515)\n                {\n                    _1549 = _354_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1549 = _1514;\n                }\n                float _1550;\n                if (_1549)\n                {\n                    _1550 = _354_fa_fog_b.y * _1506;\n                }\n                else\n                {\n                    _1550 = (_354_fa_fog_b.y * (1.0f - exp(-min(_354_fa_fog_b.w * _1506, 80.0f)))) / _354_fa_fog_b.w;\n                }\n                bool _1575 = _1511 <= 0.0f;\n                bool _1582;\n                if (!_1575)\n                {\n                    _1582 = _354_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1582 = _1575;\n                }\n                float _1583;\n                if (_1582)\n                {\n                    _1583 = _354_fa_fog_b.y * _1511;\n                }\n                else\n                {\n                    _1583 = (_354_fa_fog_b.y * (1.0f - exp(-min(_354_fa_fog_b.w * _1511, 80.0f)))) / _354_fa_fog_b.w;\n                }\n                float _1610;\n                if (abs(_1501) < 0.001000000047497451305389404296875f)\n                {\n                    _1610 = _1522;\n                }\n                else\n                {\n                    _1610 = (_1583 - _1550) / _1501;\n                }\n                tau += (_1451 * max(_1610, 0.0f));\n            }\n            result = lerp(result, _354_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _1675);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_195",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_354",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _144_fa_view_proj : packoffset(c0);\n    row_major float4x4 _144_fa_light_vp : packoffset(c4);\n    float4 _144_fa_uv_scale : packoffset(c8);\n    float4 _144_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float2 fa_attr_uv1 : TEXCOORD9;\n    float4 fa_attr_color1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _312 = { mul(float4(position, 1.0f), model).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _144_fa_uv_scale.xy, color, position };\n    return _312;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _187 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_187, _144_fa_light_vp).z;\n    fa_pre_r0 = float3(_144_fa_light_vp[0].x, _144_fa_light_vp[1].x, _144_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_144_fa_light_vp[0].y, _144_fa_light_vp[1].y, _144_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_144_fa_light_vp[0].z, _144_fa_light_vp[1].z, _144_fa_light_vp[2].z);\n    gl_Position = mul(_187, _144_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _226_fa_camera_pos : packoffset(c0);\n    float4 _226_fa_ambient : packoffset(c1);\n    float4 _226_fa_base_color : packoffset(c2);\n    float4 _226_fa_emissive : packoffset(c3);\n    float4 _226_fa_model_emissive : packoffset(c4);\n    float4 _226_fa_pbr : packoffset(c5);\n    float4 _226_fa_maps : packoffset(c6);\n    float4 _226_fa_fog : packoffset(c7);\n    float4 _226_fa_fog_b : packoffset(c8);\n    float4 _226_fa_fog_c : packoffset(c9);\n    float4 _226_fa_counts : packoffset(c10);\n    float4 _226_fa_env_sky : packoffset(c11);\n    float4 _226_fa_env_horizon : packoffset(c12);\n    float4 _226_fa_time : packoffset(c13);\n    float4 _226_fa_cl_vpx : packoffset(c14);\n    float4 _226_fa_cl_vpy : packoffset(c15);\n    float4 _226_fa_cl_vpw : packoffset(c16);\n    float4 _226_fa_cl_fwd : packoffset(c17);\n    float4 _226_fa_cl_grid : packoffset(c18);\n    float4 _226_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _186 = fa_linear_to_srgb(param);\n        c = _186;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _195 = fa_srgb_to_linear(param_1);\n            c = _195;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _226_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _238 = fa_tex_fix(param_2, param_3);\n    float4 _598 = base_t;\n    _598.x = _238.x;\n    _598.y = _238.y;\n    _598.z = _238.z;\n    base_t = _598;\n    float4 _253 = (_598 * _226_fa_base_color) * i.vertex_color;\n    float3 _579 = i.world_normal;\n    if (_226_fa_maps.z > 0.5f)\n    {\n        float param_4 = _226_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _226_fa_maps.x;\n        float3 _606 = _290;\n        _606.x = _295.x;\n        _606.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _606;\n        _579 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _226_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _609 = mrt;\n    _609.x = _324.x;\n    _609.y = _324.y;\n    _609.z = _324.z;\n    mrt = _609;\n    float param_14 = _226_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _365 = fa_tex_fix(param_16, param_17);\n    float param_18 = _226_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _392 = fa_tex_fix(param_20, param_21);\n    Surface _591 = { _253.xyz, _253.w, _579, clamp(_226_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_226_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_226_fa_maps.y * (_365.x - 1.0f)), _226_fa_emissive.xyz + (_226_fa_model_emissive.xyz * _392) };\n    return _591;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0f));\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _526 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _526 = -_526;\n    }\n    float3 _438 = normalize(_226_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _539 = { fa_world_pos, _526, fa_world_tangent, fa_uv, fa_vertex_color, _438, gl_FrontFacing };\n    SurfaceInput param = _539;\n    SurfaceInput _547 = { fa_world_pos, _526, fa_world_tangent, fa_uv, fa_vertex_color, _438, gl_FrontFacing };\n    SurfaceInput param_1 = _547;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _453 = normalize(param_2.normal);\n    float3 _468 = normalize(float3(dot(fa_pre_r0, _453), dot(fa_pre_r1, _453), dot(fa_pre_r2, _453)));\n    float _480 = _468.z;\n    float2 e = _468.xy / ((abs(_468.x) + abs(_468.y)) + abs(_480)).xx;\n    if (_480 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_144",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _149_fa_view_proj : packoffset(c0);\n    row_major float4x4 _149_fa_light_vp : packoffset(c4);\n    float4 _149_fa_uv_scale : packoffset(c8);\n    float4 _149_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _195_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float2 fa_attr_uv1 : TEXCOORD11;\n    float4 fa_attr_color1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _186 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_195_fa_joint_rows[_186] * weights[i]);\n        r1 += (_195_fa_joint_rows[_186 + 1] * weights[i]);\n        r2 += (_195_fa_joint_rows[_186 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _433 = { mul(float4(position, 1.0f), model).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _149_fa_uv_scale.xy, color, position };\n    return _433;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _300 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_300, _149_fa_light_vp).z;\n    fa_pre_r0 = float3(_149_fa_light_vp[0].x, _149_fa_light_vp[1].x, _149_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_149_fa_light_vp[0].y, _149_fa_light_vp[1].y, _149_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_149_fa_light_vp[0].z, _149_fa_light_vp[1].z, _149_fa_light_vp[2].z);\n    gl_Position = mul(_300, _149_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _226_fa_camera_pos : packoffset(c0);\n    float4 _226_fa_ambient : packoffset(c1);\n    float4 _226_fa_base_color : packoffset(c2);\n    float4 _226_fa_emissive : packoffset(c3);\n    float4 _226_fa_model_emissive : packoffset(c4);\n    float4 _226_fa_pbr : packoffset(c5);\n    float4 _226_fa_maps : packoffset(c6);\n    float4 _226_fa_fog : packoffset(c7);\n    float4 _226_fa_fog_b : packoffset(c8);\n    float4 _226_fa_fog_c : packoffset(c9);\n    float4 _226_fa_counts : packoffset(c10);\n    float4 _226_fa_env_sky : packoffset(c11);\n    float4 _226_fa_env_horizon : packoffset(c12);\n    float4 _226_fa_time : packoffset(c13);\n    float4 _226_fa_cl_vpx : packoffset(c14);\n    float4 _226_fa_cl_vpy : packoffset(c15);\n    float4 _226_fa_cl_vpw : packoffset(c16);\n    float4 _226_fa_cl_fwd : packoffset(c17);\n    float4 _226_fa_cl_grid : packoffset(c18);\n    float4 _226_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _186 = fa_linear_to_srgb(param);\n        c = _186;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _195 = fa_srgb_to_linear(param_1);\n            c = _195;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _226_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _238 = fa_tex_fix(param_2, param_3);\n    float4 _598 = base_t;\n    _598.x = _238.x;\n    _598.y = _238.y;\n    _598.z = _238.z;\n    base_t = _598;\n    float4 _253 = (_598 * _226_fa_base_color) * i.vertex_color;\n    float3 _579 = i.world_normal;\n    if (_226_fa_maps.z > 0.5f)\n    {\n        float param_4 = _226_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _226_fa_maps.x;\n        float3 _606 = _290;\n        _606.x = _295.x;\n        _606.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _606;\n        _579 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _226_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _609 = mrt;\n    _609.x = _324.x;\n    _609.y = _324.y;\n    _609.z = _324.z;\n    mrt = _609;\n    float param_14 = _226_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _365 = fa_tex_fix(param_16, param_17);\n    float param_18 = _226_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _392 = fa_tex_fix(param_20, param_21);\n    Surface _591 = { _253.xyz, _253.w, _579, clamp(_226_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_226_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_226_fa_maps.y * (_365.x - 1.0f)), _226_fa_emissive.xyz + (_226_fa_model_emissive.xyz * _392) };\n    return _591;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0f));\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _526 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _526 = -_526;\n    }\n    float3 _438 = normalize(_226_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _539 = { fa_world_pos, _526, fa_world_tangent, fa_uv, fa_vertex_color, _438, gl_FrontFacing };\n    SurfaceInput param = _539;\n    SurfaceInput _547 = { fa_world_pos, _526, fa_world_tangent, fa_uv, fa_vertex_color, _438, gl_FrontFacing };\n    SurfaceInput param_1 = _547;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _453 = normalize(param_2.normal);\n    float3 _468 = normalize(float3(dot(fa_pre_r0, _453), dot(fa_pre_r1, _453), dot(fa_pre_r2, _453)));\n    float _480 = _468.z;\n    float2 e = _468.xy / ((abs(_468.x) + abs(_468.y)) + abs(_480)).xx;\n    if (_480 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_195",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _135_fa_view_proj : packoffset(c0);\n    row_major float4x4 _135_fa_light_vp : packoffset(c4);\n    float4 _135_fa_uv_scale : packoffset(c8);\n    float4 _135_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n    float2 fa_attr_uv1 : TEXCOORD9;\n    float4 fa_attr_color1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _264 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _135_fa_uv_scale.xy, color, position };\n    return _264;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _135_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_135",
            "hlsl_register_b_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _140_fa_view_proj : packoffset(c0);\n    row_major float4x4 _140_fa_light_vp : packoffset(c4);\n    float4 _140_fa_uv_scale : packoffset(c8);\n    float4 _140_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _186_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n    float2 fa_attr_uv1 : TEXCOORD11;\n    float4 fa_attr_color1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _177 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_186_fa_joint_rows[_177] * weights[i]);\n        r1 += (_186_fa_joint_rows[_177 + 1] * weights[i]);\n        r2 += (_186_fa_joint_rows[_177 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _79 = cross(model[1].xyz, model[2].xyz);\n    float _85 = (dot(model[0].xyz, _79) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _385 = { mul(float4(position, 1.0f), model).xyz, (((_79 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _85, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _85), texcoord0 * _140_fa_uv_scale.xy, color, position };\n    return _385;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mul(float4(param_8.world_pos, 1.0f), _140_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "size": 160,
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
