{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "f33a36e751e8501a5c7167efe23b832a4315ec133394a3a234e9f06584552465",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "buffers": [
    {
      "name": "points",
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
    }
  ],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _168_fa_view_proj : packoffset(c0);\n    row_major float4x4 _168_fa_light_vp : packoffset(c4);\n    float4 _168_fa_uv_scale : packoffset(c8);\n    float4 _168_fa_time : packoffset(c9);\n    float4 _168_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _243_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float3 fa_lm : TEXCOORD6;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _109 = cross(model[1].xyz, model[2].xyz);\n    float _114 = (dot(model[0].xyz, _109) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _284 = { mul(float4(position, 1.0f), model).xyz, (((_109 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _114, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _114), texcoord0 * _168_fa_uv_scale.xy, color, position };\n    return _284;\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _206 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = mul(_206, _168_fa_light_vp);\n    gl_Position = mul(_206, _168_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = _243_fa_base_model;\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _175_fa_light_pos[32] : packoffset(c0);\n    float4 _175_fa_light_color[32] : packoffset(c32);\n    float4 _175_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _293_fa_camera_pos : packoffset(c0);\n    float4 _293_fa_ambient : packoffset(c1);\n    float4 _293_fa_base_color : packoffset(c2);\n    float4 _293_fa_emissive : packoffset(c3);\n    float4 _293_fa_model_emissive : packoffset(c4);\n    float4 _293_fa_pbr : packoffset(c5);\n    float4 _293_fa_maps : packoffset(c6);\n    float4 _293_fa_fog : packoffset(c7);\n    float4 _293_fa_fog_b : packoffset(c8);\n    float4 _293_fa_fog_c : packoffset(c9);\n    float4 _293_fa_counts : packoffset(c10);\n    float4 _293_fa_env_sky : packoffset(c11);\n    float4 _293_fa_env_horizon : packoffset(c12);\n    float4 _293_fa_time : packoffset(c13);\n};\n\nByteAddressBuffer points : register(t8);\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float3 fa_lm : TEXCOORD6;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _731 = fa_linear_to_srgb(param);\n        c = _731;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _739 = fa_srgb_to_linear(param_1);\n            c = _739;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _103;\n    if (i.front_facing)\n    {\n        _103 = i.world_normal;\n    }\n    else\n    {\n        _103 = -i.world_normal;\n    }\n    float3 _127 = normalize(i.world_tangent.xyz - (_103 * dot(_103, i.world_tangent.xyz)));\n    float3 _155 = normalize(((_127 * m.x) + ((cross(_103, _127) * i.world_tangent.w) * m.y)) + (_103 * m.z));\n    float3 _158;\n    if (i.front_facing)\n    {\n        _158 = _155;\n    }\n    else\n    {\n        _158 = -_155;\n    }\n    return _158;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _293_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _771 = fa_tex_fix(param_2, param_3);\n    float4 _1574 = base_t;\n    _1574.x = _771.x;\n    _1574.y = _771.y;\n    _1574.z = _771.z;\n    base_t = _1574;\n    float4 _785 = (_1574 * _293_fa_base_color) * i.vertex_color;\n    float3 _1542 = i.world_normal;\n    if (_293_fa_maps.z > 0.5f)\n    {\n        float param_4 = _293_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _818 = fa_tex_fix(param_6, param_7);\n        float3 _821 = (_818 * 2.0f) - 1.0f.xxx;\n        float2 _826 = _821.xy * _293_fa_maps.x;\n        float3 _1582 = _821;\n        _1582.x = _826.x;\n        _1582.y = _826.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1582;\n        _1542 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _293_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _855 = fa_tex_fix(param_12, param_13);\n    float4 _1585 = mrt;\n    _1585.x = _855.x;\n    _1585.y = _855.y;\n    _1585.z = _855.z;\n    mrt = _1585;\n    float param_14 = _293_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _894 = fa_tex_fix(param_16, param_17);\n    float param_18 = _293_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _921 = fa_tex_fix(param_20, param_21);\n    Surface _1554 = { _785.xyz, _785.w, _1542, clamp(_293_fa_pbr.x * _855.z, 0.0f, 1.0f), clamp(_293_fa_pbr.y * _855.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_293_fa_maps.y * (_894.x - 1.0f)), _293_fa_emissive.xyz + (_293_fa_model_emissive.xyz * _921) };\n    return _1554;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * asfloat(points.Load(28)));\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_293_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _293_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _186 = _175_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_186)\n    {\n        l = normalize(_175_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _204 = _175_fa_light_pos[li].xyz - world_pos;\n        float _206 = length(_204);\n        dist = _206;\n        l = _204 / max(_206, 9.9999997473787516355514526367188e-05f).xxx;\n        float _222 = _206 / max(_175_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _228 = clamp(1.0f - (_222 * _222), 0.0f, 1.0f);\n        atten = _228 * _228;\n        if (_175_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_175_fa_light_dir[li].w, lerp(_175_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_175_fa_light_dir[li].xyz)));\n        }\n    }\n    int _279;\n    if (_186)\n    {\n        _279 = 0;\n    }\n    else\n    {\n        _279 = (_175_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _1520 = { l, _175_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _279 };\n    return _1520;\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_293_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _306 = coord.xyz / coord.w.xxx;\n    float3 p = _306;\n    float2 suv = (_306.xy * 0.5f) + 0.5f.xx;\n    if (_293_fa_counts.z > 0.5f)\n    {\n        float3 _1556 = p;\n        _1556.z = (_1556.z * 0.5f) + 0.5f;\n        p = _1556;\n    }\n    else\n    {\n        float2 _1559 = suv;\n        _1559.y = 1.0f - _1559.y;\n        suv = _1559;\n    }\n    bool _334 = suv.x < 0.0f;\n    bool _341;\n    if (!_334)\n    {\n        _341 = suv.x > 1.0f;\n    }\n    else\n    {\n        _341 = _334;\n    }\n    bool _348;\n    if (!_341)\n    {\n        _348 = suv.y < 0.0f;\n    }\n    else\n    {\n        _348 = _341;\n    }\n    bool _355;\n    if (!_348)\n    {\n        _355 = suv.y > 1.0f;\n    }\n    else\n    {\n        _355 = _348;\n    }\n    bool _362;\n    if (!_355)\n    {\n        _362 = p.z > 1.0f;\n    }\n    else\n    {\n        _362 = _355;\n    }\n    if (_362)\n    {\n        return 1.0f;\n    }\n    float _377 = _293_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _377) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _293_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _638 = fa_light_sample(param, param_1);\n    float3 _1527 = _638.direction;\n    float3 _1522 = _638.color;\n    float _1529 = _638.attenuation;\n    float _1524 = _638.shadow;\n    int _1532 = _638.type;\n    if ((_1532 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1527;\n        float _652 = fa_shadow_factor(param_2, param_3);\n        _1524 = _652;\n        _1522 = _175_fa_light_color[li].xyz * (_1529 * _652);\n    }\n    LightSample _1539 = { _1527, _1522, _1529, _1524, _638._distance, _1532 };\n    return _1539;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _574 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _577 = _574.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_577 * _577, exp2((-9.27999973297119140625f) * ndv)) * _577) + _574.y)) + _574.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_293_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _293_fa_env_horizon.w).xyz;\n    }\n    float _477 = rough * rough;\n    float _508 = 0.60000002384185791015625f * _477;\n    return lerp(lerp(_293_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_293_fa_env_horizon.xyz, _293_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _477)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _508, 0.0500000007450580596923828125f + _508, d.y).xxx), ((_293_fa_env_sky.xyz + _293_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_477 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _616 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _616.x) + _616.y.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _1447 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1447 = -_1447;\n    }\n    float3 _987 = normalize(_293_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _1460 = { fa_world_pos, _1447, fa_world_tangent, fa_uv, fa_vertex_color, _987, gl_FrontFacing };\n    SurfaceInput param = _1460;\n    Surface _992 = fa_standard_surface(param);\n    float3 _1470 = _992.albedo;\n    float _1471 = _992.alpha;\n    float3 _1472 = _992.normal;\n    float _1473 = _992.metallic;\n    float _1474 = _992.roughness;\n    float _1475 = _992.occlusion;\n    float3 _1476 = _992.emission;\n    SurfaceInput _1468 = { fa_world_pos, _1447, fa_world_tangent, fa_uv, fa_vertex_color, _987, gl_FrontFacing };\n    SurfaceInput param_1 = _1468;\n    Surface param_2 = _992;\n    surface(param_1, param_2);\n    _1470 = param_2.albedo;\n    _1471 = param_2.alpha;\n    _1472 = param_2.normal;\n    _1473 = param_2.metallic;\n    _1474 = param_2.roughness;\n    _1475 = param_2.occlusion;\n    _1476 = param_2.emission;\n    float3 result;\n    if (_293_fa_emissive.w > 0.5f)\n    {\n        result = _1470;\n    }\n    else\n    {\n        float3 _1014 = normalize(_1472);\n        float _1021 = clamp(_1473, 0.0f, 1.0f);\n        float _1025 = clamp(_1474, 0.0500000007450580596923828125f, 1.0f);\n        float _1029 = _1025 * _1025;\n        float _1033 = _1029 * _1029;\n        float _1038 = max(dot(_1014, _987), 9.9999997473787516355514526367188e-05f);\n        float3 _1044 = _1470 * (1.0f - _1021);\n        float3 _1052 = lerp(0.039999999105930328369140625f.xxx, _1470, _1021.xxx);\n        float3 param_3 = _1014;\n        float3 lit = (fa_indirect_diffuse(param_3) * _1044) * _1475;\n        int _1065 = int(_293_fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1065)\n            {\n                break;\n            }\n            int param_4 = li;\n            float3 param_5 = fa_world_pos;\n            float3 param_6 = _1447;\n            LightSample _1089 = fa_light_shadowed(param_4, param_5, param_6);\n            float3 _1505 = _1089.direction;\n            float _1097 = max(dot(_1014, _1505), 0.0f);\n            float3 _1108 = normalize(_1505 + _987);\n            float _1113 = max(dot(_1014, _1108), 0.0f);\n            float _1126 = ((_1113 * _1113) * (_1033 - 1.0f)) + 1.0f;\n            lit += (((_1044 + (((_1052 + ((1.0f.xxx - _1052) * pow(1.0f - max(dot(_987, _1108), 0.0f), 5.0f))) * (((_1033 / ((3.1415927410125732421875f * _1126) * _1126)) * (0.5f / max(lerp((2.0f * _1097) * _1038, _1097 + _1038, _1029), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _1097))) * _175_fa_light_color[li].xyz) * (_1097 * (_1089.attenuation * _1089.shadow)));\n        }\n        float3 param_7 = _1014;\n        float3 param_8 = _987;\n        float3 param_9 = _1052;\n        float param_10 = _1025;\n        float3 _1196 = lit;\n        float3 _1197 = _1196 + (fa_sky_reflection(param_7, param_8, param_9, param_10) * _1475);\n        lit = _1197;\n        result = _1197;\n    }\n    result += _1476;\n    bool _1206 = _293_fa_fog.w > 0.0f;\n    bool _1214;\n    if (!_1206)\n    {\n        _1214 = _293_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1214 = _1206;\n    }\n    if (_1214)\n    {\n        float3 _1223 = fa_world_pos - _293_fa_camera_pos.xyz;\n        float _1230 = dot(_1223, _293_fa_fog_c.xyz);\n        bool _1234 = _293_fa_fog_c.w > 0.5f;\n        float _1235;\n        if (_1234)\n        {\n            _1235 = _1230;\n        }\n        else\n        {\n            _1235 = length(_1223);\n        }\n        float _1247 = _1235 - _293_fa_fog_b.x;\n        if (_1247 > 0.0f)\n        {\n            float _1256 = _293_fa_fog.w * _1247;\n            float tau = _1256 * _1256;\n            if (_293_fa_fog_b.y > 0.0f)\n            {\n                float _1272;\n                if (_1234)\n                {\n                    _1272 = fa_world_pos.y - (_293_fa_fog_c.y * _1230);\n                }\n                else\n                {\n                    _1272 = _293_fa_camera_pos.y;\n                }\n                float _1293 = lerp(_1272, fa_world_pos.y, clamp(_293_fa_fog_b.x / _1235, 0.0f, 1.0f));\n                float _1297 = fa_world_pos.y - _1293;\n                float _1302 = _1293 - _293_fa_fog_b.z;\n                float _1307 = fa_world_pos.y - _293_fa_fog_b.z;\n                bool _1310 = _1302 <= 0.0f;\n                bool _1311 = !_1310;\n                bool _1317;\n                if (_1311)\n                {\n                    _1317 = _293_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1317 = _1310;\n                }\n                float _1318;\n                if (_1317)\n                {\n                    _1318 = _293_fa_fog_b.y;\n                }\n                else\n                {\n                    _1318 = _293_fa_fog_b.y * exp(-min(_293_fa_fog_b.w * _1302, 80.0f));\n                }\n                bool _1345;\n                if (_1311)\n                {\n                    _1345 = _293_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1345 = _1310;\n                }\n                float _1346;\n                if (_1345)\n                {\n                    _1346 = _293_fa_fog_b.y * _1302;\n                }\n                else\n                {\n                    _1346 = (_293_fa_fog_b.y * (1.0f - exp(-min(_293_fa_fog_b.w * _1302, 80.0f)))) / _293_fa_fog_b.w;\n                }\n                bool _1371 = _1307 <= 0.0f;\n                bool _1378;\n                if (!_1371)\n                {\n                    _1378 = _293_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1378 = _1371;\n                }\n                float _1379;\n                if (_1378)\n                {\n                    _1379 = _293_fa_fog_b.y * _1307;\n                }\n                else\n                {\n                    _1379 = (_293_fa_fog_b.y * (1.0f - exp(-min(_293_fa_fog_b.w * _1307, 80.0f)))) / _293_fa_fog_b.w;\n                }\n                float _1406;\n                if (abs(_1297) < 0.001000000047497451305389404296875f)\n                {\n                    _1406 = _1318;\n                }\n                else\n                {\n                    _1406 = (_1379 - _1346) / _1297;\n                }\n                tau += (_1247 * max(_1406, 0.0f));\n            }\n            result = lerp(result, _293_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _1471);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_168",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_243",
            "hlsl_register_b_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_175",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_293",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _173_fa_view_proj : packoffset(c0);\n    row_major float4x4 _173_fa_light_vp : packoffset(c4);\n    float4 _173_fa_uv_scale : packoffset(c8);\n    float4 _173_fa_time : packoffset(c9);\n    float4 _173_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _217_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _355_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float3 fa_lm : TEXCOORD6;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _208 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_217_fa_joint_rows[_208] * weights[i]);\n        r1 += (_217_fa_joint_rows[_208 + 1] * weights[i]);\n        r2 += (_217_fa_joint_rows[_208 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _114 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _114) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _404 = { mul(float4(position, 1.0f), model).xyz, (((_114 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * _173_fa_uv_scale.xy, color, position };\n    return _404;\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _318 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = mul(_318, _173_fa_light_vp);\n    gl_Position = mul(_318, _173_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), _355_fa_base_model);\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _175_fa_light_pos[32] : packoffset(c0);\n    float4 _175_fa_light_color[32] : packoffset(c32);\n    float4 _175_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _293_fa_camera_pos : packoffset(c0);\n    float4 _293_fa_ambient : packoffset(c1);\n    float4 _293_fa_base_color : packoffset(c2);\n    float4 _293_fa_emissive : packoffset(c3);\n    float4 _293_fa_model_emissive : packoffset(c4);\n    float4 _293_fa_pbr : packoffset(c5);\n    float4 _293_fa_maps : packoffset(c6);\n    float4 _293_fa_fog : packoffset(c7);\n    float4 _293_fa_fog_b : packoffset(c8);\n    float4 _293_fa_fog_c : packoffset(c9);\n    float4 _293_fa_counts : packoffset(c10);\n    float4 _293_fa_env_sky : packoffset(c11);\n    float4 _293_fa_env_horizon : packoffset(c12);\n    float4 _293_fa_time : packoffset(c13);\n};\n\nByteAddressBuffer points : register(t8);\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float3 fa_lm : TEXCOORD6;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _731 = fa_linear_to_srgb(param);\n        c = _731;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _739 = fa_srgb_to_linear(param_1);\n            c = _739;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _103;\n    if (i.front_facing)\n    {\n        _103 = i.world_normal;\n    }\n    else\n    {\n        _103 = -i.world_normal;\n    }\n    float3 _127 = normalize(i.world_tangent.xyz - (_103 * dot(_103, i.world_tangent.xyz)));\n    float3 _155 = normalize(((_127 * m.x) + ((cross(_103, _127) * i.world_tangent.w) * m.y)) + (_103 * m.z));\n    float3 _158;\n    if (i.front_facing)\n    {\n        _158 = _155;\n    }\n    else\n    {\n        _158 = -_155;\n    }\n    return _158;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _293_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _771 = fa_tex_fix(param_2, param_3);\n    float4 _1574 = base_t;\n    _1574.x = _771.x;\n    _1574.y = _771.y;\n    _1574.z = _771.z;\n    base_t = _1574;\n    float4 _785 = (_1574 * _293_fa_base_color) * i.vertex_color;\n    float3 _1542 = i.world_normal;\n    if (_293_fa_maps.z > 0.5f)\n    {\n        float param_4 = _293_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _818 = fa_tex_fix(param_6, param_7);\n        float3 _821 = (_818 * 2.0f) - 1.0f.xxx;\n        float2 _826 = _821.xy * _293_fa_maps.x;\n        float3 _1582 = _821;\n        _1582.x = _826.x;\n        _1582.y = _826.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1582;\n        _1542 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _293_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _855 = fa_tex_fix(param_12, param_13);\n    float4 _1585 = mrt;\n    _1585.x = _855.x;\n    _1585.y = _855.y;\n    _1585.z = _855.z;\n    mrt = _1585;\n    float param_14 = _293_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _894 = fa_tex_fix(param_16, param_17);\n    float param_18 = _293_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _921 = fa_tex_fix(param_20, param_21);\n    Surface _1554 = { _785.xyz, _785.w, _1542, clamp(_293_fa_pbr.x * _855.z, 0.0f, 1.0f), clamp(_293_fa_pbr.y * _855.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_293_fa_maps.y * (_894.x - 1.0f)), _293_fa_emissive.xyz + (_293_fa_model_emissive.xyz * _921) };\n    return _1554;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * asfloat(points.Load(28)));\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_293_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _293_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _186 = _175_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_186)\n    {\n        l = normalize(_175_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _204 = _175_fa_light_pos[li].xyz - world_pos;\n        float _206 = length(_204);\n        dist = _206;\n        l = _204 / max(_206, 9.9999997473787516355514526367188e-05f).xxx;\n        float _222 = _206 / max(_175_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _228 = clamp(1.0f - (_222 * _222), 0.0f, 1.0f);\n        atten = _228 * _228;\n        if (_175_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_175_fa_light_dir[li].w, lerp(_175_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_175_fa_light_dir[li].xyz)));\n        }\n    }\n    int _279;\n    if (_186)\n    {\n        _279 = 0;\n    }\n    else\n    {\n        _279 = (_175_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _1520 = { l, _175_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _279 };\n    return _1520;\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_293_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _306 = coord.xyz / coord.w.xxx;\n    float3 p = _306;\n    float2 suv = (_306.xy * 0.5f) + 0.5f.xx;\n    if (_293_fa_counts.z > 0.5f)\n    {\n        float3 _1556 = p;\n        _1556.z = (_1556.z * 0.5f) + 0.5f;\n        p = _1556;\n    }\n    else\n    {\n        float2 _1559 = suv;\n        _1559.y = 1.0f - _1559.y;\n        suv = _1559;\n    }\n    bool _334 = suv.x < 0.0f;\n    bool _341;\n    if (!_334)\n    {\n        _341 = suv.x > 1.0f;\n    }\n    else\n    {\n        _341 = _334;\n    }\n    bool _348;\n    if (!_341)\n    {\n        _348 = suv.y < 0.0f;\n    }\n    else\n    {\n        _348 = _341;\n    }\n    bool _355;\n    if (!_348)\n    {\n        _355 = suv.y > 1.0f;\n    }\n    else\n    {\n        _355 = _348;\n    }\n    bool _362;\n    if (!_355)\n    {\n        _362 = p.z > 1.0f;\n    }\n    else\n    {\n        _362 = _355;\n    }\n    if (_362)\n    {\n        return 1.0f;\n    }\n    float _377 = _293_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _377) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _293_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _638 = fa_light_sample(param, param_1);\n    float3 _1527 = _638.direction;\n    float3 _1522 = _638.color;\n    float _1529 = _638.attenuation;\n    float _1524 = _638.shadow;\n    int _1532 = _638.type;\n    if ((_1532 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1527;\n        float _652 = fa_shadow_factor(param_2, param_3);\n        _1524 = _652;\n        _1522 = _175_fa_light_color[li].xyz * (_1529 * _652);\n    }\n    LightSample _1539 = { _1527, _1522, _1529, _1524, _638._distance, _1532 };\n    return _1539;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _574 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _577 = _574.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_577 * _577, exp2((-9.27999973297119140625f) * ndv)) * _577) + _574.y)) + _574.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_293_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _293_fa_env_horizon.w).xyz;\n    }\n    float _477 = rough * rough;\n    float _508 = 0.60000002384185791015625f * _477;\n    return lerp(lerp(_293_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_293_fa_env_horizon.xyz, _293_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _477)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _508, 0.0500000007450580596923828125f + _508, d.y).xxx), ((_293_fa_env_sky.xyz + _293_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_477 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _616 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _616.x) + _616.y.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _1447 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1447 = -_1447;\n    }\n    float3 _987 = normalize(_293_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _1460 = { fa_world_pos, _1447, fa_world_tangent, fa_uv, fa_vertex_color, _987, gl_FrontFacing };\n    SurfaceInput param = _1460;\n    Surface _992 = fa_standard_surface(param);\n    float3 _1470 = _992.albedo;\n    float _1471 = _992.alpha;\n    float3 _1472 = _992.normal;\n    float _1473 = _992.metallic;\n    float _1474 = _992.roughness;\n    float _1475 = _992.occlusion;\n    float3 _1476 = _992.emission;\n    SurfaceInput _1468 = { fa_world_pos, _1447, fa_world_tangent, fa_uv, fa_vertex_color, _987, gl_FrontFacing };\n    SurfaceInput param_1 = _1468;\n    Surface param_2 = _992;\n    surface(param_1, param_2);\n    _1470 = param_2.albedo;\n    _1471 = param_2.alpha;\n    _1472 = param_2.normal;\n    _1473 = param_2.metallic;\n    _1474 = param_2.roughness;\n    _1475 = param_2.occlusion;\n    _1476 = param_2.emission;\n    float3 result;\n    if (_293_fa_emissive.w > 0.5f)\n    {\n        result = _1470;\n    }\n    else\n    {\n        float3 _1014 = normalize(_1472);\n        float _1021 = clamp(_1473, 0.0f, 1.0f);\n        float _1025 = clamp(_1474, 0.0500000007450580596923828125f, 1.0f);\n        float _1029 = _1025 * _1025;\n        float _1033 = _1029 * _1029;\n        float _1038 = max(dot(_1014, _987), 9.9999997473787516355514526367188e-05f);\n        float3 _1044 = _1470 * (1.0f - _1021);\n        float3 _1052 = lerp(0.039999999105930328369140625f.xxx, _1470, _1021.xxx);\n        float3 param_3 = _1014;\n        float3 lit = (fa_indirect_diffuse(param_3) * _1044) * _1475;\n        int _1065 = int(_293_fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1065)\n            {\n                break;\n            }\n            int param_4 = li;\n            float3 param_5 = fa_world_pos;\n            float3 param_6 = _1447;\n            LightSample _1089 = fa_light_shadowed(param_4, param_5, param_6);\n            float3 _1505 = _1089.direction;\n            float _1097 = max(dot(_1014, _1505), 0.0f);\n            float3 _1108 = normalize(_1505 + _987);\n            float _1113 = max(dot(_1014, _1108), 0.0f);\n            float _1126 = ((_1113 * _1113) * (_1033 - 1.0f)) + 1.0f;\n            lit += (((_1044 + (((_1052 + ((1.0f.xxx - _1052) * pow(1.0f - max(dot(_987, _1108), 0.0f), 5.0f))) * (((_1033 / ((3.1415927410125732421875f * _1126) * _1126)) * (0.5f / max(lerp((2.0f * _1097) * _1038, _1097 + _1038, _1029), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _1097))) * _175_fa_light_color[li].xyz) * (_1097 * (_1089.attenuation * _1089.shadow)));\n        }\n        float3 param_7 = _1014;\n        float3 param_8 = _987;\n        float3 param_9 = _1052;\n        float param_10 = _1025;\n        float3 _1196 = lit;\n        float3 _1197 = _1196 + (fa_sky_reflection(param_7, param_8, param_9, param_10) * _1475);\n        lit = _1197;\n        result = _1197;\n    }\n    result += _1476;\n    bool _1206 = _293_fa_fog.w > 0.0f;\n    bool _1214;\n    if (!_1206)\n    {\n        _1214 = _293_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1214 = _1206;\n    }\n    if (_1214)\n    {\n        float3 _1223 = fa_world_pos - _293_fa_camera_pos.xyz;\n        float _1230 = dot(_1223, _293_fa_fog_c.xyz);\n        bool _1234 = _293_fa_fog_c.w > 0.5f;\n        float _1235;\n        if (_1234)\n        {\n            _1235 = _1230;\n        }\n        else\n        {\n            _1235 = length(_1223);\n        }\n        float _1247 = _1235 - _293_fa_fog_b.x;\n        if (_1247 > 0.0f)\n        {\n            float _1256 = _293_fa_fog.w * _1247;\n            float tau = _1256 * _1256;\n            if (_293_fa_fog_b.y > 0.0f)\n            {\n                float _1272;\n                if (_1234)\n                {\n                    _1272 = fa_world_pos.y - (_293_fa_fog_c.y * _1230);\n                }\n                else\n                {\n                    _1272 = _293_fa_camera_pos.y;\n                }\n                float _1293 = lerp(_1272, fa_world_pos.y, clamp(_293_fa_fog_b.x / _1235, 0.0f, 1.0f));\n                float _1297 = fa_world_pos.y - _1293;\n                float _1302 = _1293 - _293_fa_fog_b.z;\n                float _1307 = fa_world_pos.y - _293_fa_fog_b.z;\n                bool _1310 = _1302 <= 0.0f;\n                bool _1311 = !_1310;\n                bool _1317;\n                if (_1311)\n                {\n                    _1317 = _293_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1317 = _1310;\n                }\n                float _1318;\n                if (_1317)\n                {\n                    _1318 = _293_fa_fog_b.y;\n                }\n                else\n                {\n                    _1318 = _293_fa_fog_b.y * exp(-min(_293_fa_fog_b.w * _1302, 80.0f));\n                }\n                bool _1345;\n                if (_1311)\n                {\n                    _1345 = _293_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1345 = _1310;\n                }\n                float _1346;\n                if (_1345)\n                {\n                    _1346 = _293_fa_fog_b.y * _1302;\n                }\n                else\n                {\n                    _1346 = (_293_fa_fog_b.y * (1.0f - exp(-min(_293_fa_fog_b.w * _1302, 80.0f)))) / _293_fa_fog_b.w;\n                }\n                bool _1371 = _1307 <= 0.0f;\n                bool _1378;\n                if (!_1371)\n                {\n                    _1378 = _293_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1378 = _1371;\n                }\n                float _1379;\n                if (_1378)\n                {\n                    _1379 = _293_fa_fog_b.y * _1307;\n                }\n                else\n                {\n                    _1379 = (_293_fa_fog_b.y * (1.0f - exp(-min(_293_fa_fog_b.w * _1307, 80.0f)))) / _293_fa_fog_b.w;\n                }\n                float _1406;\n                if (abs(_1297) < 0.001000000047497451305389404296875f)\n                {\n                    _1406 = _1318;\n                }\n                else\n                {\n                    _1406 = (_1379 - _1346) / _1297;\n                }\n                tau += (_1247 * max(_1406, 0.0f));\n            }\n            result = lerp(result, _293_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _1471);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_173",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_217",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_355",
            "hlsl_register_b_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_175",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_293",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _168_fa_view_proj : packoffset(c0);\n    row_major float4x4 _168_fa_light_vp : packoffset(c4);\n    float4 _168_fa_uv_scale : packoffset(c8);\n    float4 _168_fa_time : packoffset(c9);\n    float4 _168_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _272_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _109 = cross(model[1].xyz, model[2].xyz);\n    float _114 = (dot(model[0].xyz, _109) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _311 = { mul(float4(position, 1.0f), model).xyz, (((_109 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _114, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _114), texcoord0 * _168_fa_uv_scale.xy, color, position };\n    return _311;\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _210 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_210, _168_fa_light_vp).z;\n    fa_pre_r0 = float3(_168_fa_light_vp[0].x, _168_fa_light_vp[1].x, _168_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_168_fa_light_vp[0].y, _168_fa_light_vp[1].y, _168_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_168_fa_light_vp[0].z, _168_fa_light_vp[1].z, _168_fa_light_vp[2].z);\n    gl_Position = mul(_210, _168_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = _272_fa_base_model;\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer points : register(t5);\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _231_fa_camera_pos : packoffset(c0);\n    float4 _231_fa_ambient : packoffset(c1);\n    float4 _231_fa_base_color : packoffset(c2);\n    float4 _231_fa_emissive : packoffset(c3);\n    float4 _231_fa_model_emissive : packoffset(c4);\n    float4 _231_fa_pbr : packoffset(c5);\n    float4 _231_fa_maps : packoffset(c6);\n    float4 _231_fa_fog : packoffset(c7);\n    float4 _231_fa_fog_b : packoffset(c8);\n    float4 _231_fa_fog_c : packoffset(c9);\n    float4 _231_fa_counts : packoffset(c10);\n    float4 _231_fa_env_sky : packoffset(c11);\n    float4 _231_fa_env_horizon : packoffset(c12);\n    float4 _231_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _231_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _601 = base_t;\n    _601.x = _242.x;\n    _601.y = _242.y;\n    _601.z = _242.z;\n    base_t = _601;\n    float4 _257 = (_601 * _231_fa_base_color) * i.vertex_color;\n    float3 _582 = i.world_normal;\n    if (_231_fa_maps.z > 0.5f)\n    {\n        float param_4 = _231_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _290 = fa_tex_fix(param_6, param_7);\n        float3 _294 = (_290 * 2.0f) - 1.0f.xxx;\n        float2 _299 = _294.xy * _231_fa_maps.x;\n        float3 _609 = _294;\n        _609.x = _299.x;\n        _609.y = _299.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _609;\n        _582 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _231_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _328 = fa_tex_fix(param_12, param_13);\n    float4 _612 = mrt;\n    _612.x = _328.x;\n    _612.y = _328.y;\n    _612.z = _328.z;\n    mrt = _612;\n    float param_14 = _231_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _369 = fa_tex_fix(param_16, param_17);\n    float param_18 = _231_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    Surface _594 = { _257.xyz, _257.w, _582, clamp(_231_fa_pbr.x * _328.z, 0.0f, 1.0f), clamp(_231_fa_pbr.y * _328.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_231_fa_maps.y * (_369.x - 1.0f)), _231_fa_emissive.xyz + (_231_fa_model_emissive.xyz * _396) };\n    return _594;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * asfloat(points.Load(28)));\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _529 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _529 = -_529;\n    }\n    float3 _442 = normalize(_231_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _542 = { fa_world_pos, _529, fa_world_tangent, fa_uv, fa_vertex_color, _442, gl_FrontFacing };\n    SurfaceInput param = _542;\n    SurfaceInput _550 = { fa_world_pos, _529, fa_world_tangent, fa_uv, fa_vertex_color, _442, gl_FrontFacing };\n    SurfaceInput param_1 = _550;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _457 = normalize(param_2.normal);\n    float3 _472 = normalize(float3(dot(fa_pre_r0, _457), dot(fa_pre_r1, _457), dot(fa_pre_r2, _457)));\n    float _484 = _472.z;\n    float2 e = _472.xy / ((abs(_472.x) + abs(_472.y)) + abs(_484)).xx;\n    if (_484 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_168",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_272",
            "hlsl_register_b_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
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
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _173_fa_view_proj : packoffset(c0);\n    row_major float4x4 _173_fa_light_vp : packoffset(c4);\n    float4 _173_fa_uv_scale : packoffset(c8);\n    float4 _173_fa_time : packoffset(c9);\n    float4 _173_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _217_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _384_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _208 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_217_fa_joint_rows[_208] * weights[i]);\n        r1 += (_217_fa_joint_rows[_208 + 1] * weights[i]);\n        r2 += (_217_fa_joint_rows[_208 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _114 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _114) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _431 = { mul(float4(position, 1.0f), model).xyz, (((_114 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * _173_fa_uv_scale.xy, color, position };\n    return _431;\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _322 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_322, _173_fa_light_vp).z;\n    fa_pre_r0 = float3(_173_fa_light_vp[0].x, _173_fa_light_vp[1].x, _173_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_173_fa_light_vp[0].y, _173_fa_light_vp[1].y, _173_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_173_fa_light_vp[0].z, _173_fa_light_vp[1].z, _173_fa_light_vp[2].z);\n    gl_Position = mul(_322, _173_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), _384_fa_base_model);\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer points : register(t5);\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _231_fa_camera_pos : packoffset(c0);\n    float4 _231_fa_ambient : packoffset(c1);\n    float4 _231_fa_base_color : packoffset(c2);\n    float4 _231_fa_emissive : packoffset(c3);\n    float4 _231_fa_model_emissive : packoffset(c4);\n    float4 _231_fa_pbr : packoffset(c5);\n    float4 _231_fa_maps : packoffset(c6);\n    float4 _231_fa_fog : packoffset(c7);\n    float4 _231_fa_fog_b : packoffset(c8);\n    float4 _231_fa_fog_c : packoffset(c9);\n    float4 _231_fa_counts : packoffset(c10);\n    float4 _231_fa_env_sky : packoffset(c11);\n    float4 _231_fa_env_horizon : packoffset(c12);\n    float4 _231_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _231_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _601 = base_t;\n    _601.x = _242.x;\n    _601.y = _242.y;\n    _601.z = _242.z;\n    base_t = _601;\n    float4 _257 = (_601 * _231_fa_base_color) * i.vertex_color;\n    float3 _582 = i.world_normal;\n    if (_231_fa_maps.z > 0.5f)\n    {\n        float param_4 = _231_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _290 = fa_tex_fix(param_6, param_7);\n        float3 _294 = (_290 * 2.0f) - 1.0f.xxx;\n        float2 _299 = _294.xy * _231_fa_maps.x;\n        float3 _609 = _294;\n        _609.x = _299.x;\n        _609.y = _299.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _609;\n        _582 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _231_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _328 = fa_tex_fix(param_12, param_13);\n    float4 _612 = mrt;\n    _612.x = _328.x;\n    _612.y = _328.y;\n    _612.z = _328.z;\n    mrt = _612;\n    float param_14 = _231_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _369 = fa_tex_fix(param_16, param_17);\n    float param_18 = _231_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    Surface _594 = { _257.xyz, _257.w, _582, clamp(_231_fa_pbr.x * _328.z, 0.0f, 1.0f), clamp(_231_fa_pbr.y * _328.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_231_fa_maps.y * (_369.x - 1.0f)), _231_fa_emissive.xyz + (_231_fa_model_emissive.xyz * _396) };\n    return _594;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * asfloat(points.Load(28)));\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _529 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _529 = -_529;\n    }\n    float3 _442 = normalize(_231_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _542 = { fa_world_pos, _529, fa_world_tangent, fa_uv, fa_vertex_color, _442, gl_FrontFacing };\n    SurfaceInput param = _542;\n    SurfaceInput _550 = { fa_world_pos, _529, fa_world_tangent, fa_uv, fa_vertex_color, _442, gl_FrontFacing };\n    SurfaceInput param_1 = _550;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _457 = normalize(param_2.normal);\n    float3 _472 = normalize(float3(dot(fa_pre_r0, _457), dot(fa_pre_r1, _457), dot(fa_pre_r2, _457)));\n    float _484 = _472.z;\n    float2 e = _472.xy / ((abs(_472.x) + abs(_472.y)) + abs(_484)).xx;\n    if (_484 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_173",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_217",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_384",
            "hlsl_register_b_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
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
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _159_fa_view_proj : packoffset(c0);\n    row_major float4x4 _159_fa_light_vp : packoffset(c4);\n    float4 _159_fa_uv_scale : packoffset(c8);\n    float4 _159_fa_time : packoffset(c9);\n    float4 _159_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _176_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _100 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _100) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_100 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _159_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = _176_fa_base_model;\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _159_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "inst_name": "_159",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_176",
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
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _164_fa_view_proj : packoffset(c0);\n    row_major float4x4 _164_fa_light_vp : packoffset(c4);\n    float4 _164_fa_uv_scale : packoffset(c8);\n    float4 _164_fa_time : packoffset(c9);\n    float4 _164_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _208_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _288_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _199 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_208_fa_joint_rows[_199] * weights[i]);\n        r1 += (_208_fa_joint_rows[_199 + 1] * weights[i]);\n        r2 += (_208_fa_joint_rows[_199 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _105 = cross(model[1].xyz, model[2].xyz);\n    float _110 = (dot(model[0].xyz, _105) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _383 = { mul(float4(position, 1.0f), model).xyz, (((_105 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _110, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _110), texcoord0 * _164_fa_uv_scale.xy, color, position };\n    return _383;\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), _288_fa_base_model);\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mul(float4(param_8.world_pos, 1.0f), _164_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "inst_name": "_164",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_208",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_288",
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
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          }
        ]
      }
    }
  }
}
