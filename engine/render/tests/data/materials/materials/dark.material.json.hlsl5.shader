{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "738bdbaa5d236ca82c68b48e7af94b35c54ba5d6311eabf2bcbbc814ba3d221c",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _258 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _258;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_265, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _232_fa_camera_pos : packoffset(c0);\n    float4 _232_fa_ambient : packoffset(c1);\n    float4 _232_fa_base_color : packoffset(c2);\n    float4 _232_fa_emissive : packoffset(c3);\n    float4 _232_fa_model_emissive : packoffset(c4);\n    float4 _232_fa_pbr : packoffset(c5);\n    float4 _232_fa_maps : packoffset(c6);\n    float4 _232_fa_fog : packoffset(c7);\n    float4 _232_fa_fog_b : packoffset(c8);\n    float4 _232_fa_fog_c : packoffset(c9);\n    float4 _232_fa_counts : packoffset(c10);\n    float4 _232_fa_env_sky : packoffset(c11);\n    float4 _232_fa_env_horizon : packoffset(c12);\n    float4 _232_fa_time : packoffset(c13);\n    float4 _232_fa_cl_vpx : packoffset(c14);\n    float4 _232_fa_cl_vpy : packoffset(c15);\n    float4 _232_fa_cl_vpw : packoffset(c16);\n    float4 _232_fa_cl_fwd : packoffset(c17);\n    float4 _232_fa_cl_grid : packoffset(c18);\n    float4 _232_fa_cl_info : packoffset(c19);\n    float4 _232_fa_layers_a : packoffset(c20);\n    float4 _232_fa_layers_b : packoffset(c21);\n    float4 _232_fa_layers_c : packoffset(c22);\n    float4 _232_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _935_fa_shadow_mat[4] : packoffset(c0);\n    float4 _935_fa_shadow_rect[4] : packoffset(c16);\n    float4 _935_fa_shadow_info[4] : packoffset(c20);\n    float4 _935_fa_shadow_split : packoffset(c24);\n    float4 _935_fa_shadow_cfg : packoffset(c25);\n    float4 _935_fa_shadow_bias : packoffset(c26);\n    float4 _935_fa_shadow_eye : packoffset(c27);\n    float4 _935_fa_shadow_fwd : packoffset(c28);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_irr_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _704 = _232_fa_cl_info.x < 0.0f;\n    bool _711;\n    if (!_704)\n    {\n        _711 = _232_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _711 = _704;\n    }\n    bool _719;\n    if (!_711)\n    {\n        _719 = _232_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _719 = _711;\n    }\n    bool _726;\n    if (!_719)\n    {\n        _726 = _232_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _726 = _719;\n    }\n    bool _733;\n    if (!_726)\n    {\n        _733 = _232_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _733 = _726;\n    }\n    if (_733)\n    {\n        return int2(0, 0);\n    }\n    float4 _743 = float4(world_pos, 1.0f);\n    float _750 = dot(_232_fa_cl_vpw, _743);\n    if (!(_750 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _772 = float2(dot(_232_fa_cl_vpx, _743), dot(_232_fa_cl_vpy, _743)) / _750.xx;\n    int _776 = int(_232_fa_cl_grid.x);\n    int _780 = int(_232_fa_cl_grid.y);\n    int param = (int(_232_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_232_fa_cl_fwd.xyz, world_pos) + _232_fa_cl_fwd.w, _232_fa_cl_grid.w) / _232_fa_cl_grid.w) * _232_fa_cl_grid.z)), 0, int(_232_fa_cl_info.y) - 1) * _780) + clamp(int(floor(((_772.y * 0.5f) + 0.5f) * _232_fa_cl_grid.y)), 0, _780 - 1)) * _776)) + clamp(int(floor(((_772.x * 0.5f) + 0.5f) * _232_fa_cl_grid.x)), 0, _776 - 1);\n    float4 _851 = fa_light_texel(param);\n    return int2(int(_851.x), int(_851.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_232_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1593 = fa_cluster_lookup(param);\n    fa_cl_slot = _1593.x;\n    fa_cl_local = _1593.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1696 = fa_linear_to_srgb(param);\n        c = _1696;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1704 = fa_srgb_to_linear(param_1);\n            c = _1704;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _164;\n    if (i.front_facing)\n    {\n        _164 = i.world_normal;\n    }\n    else\n    {\n        _164 = -i.world_normal;\n    }\n    float3 _188 = normalize(i.world_tangent.xyz - (_164 * dot(_164, i.world_tangent.xyz)));\n    float3 _216 = normalize(((_188 * m.x) + ((cross(_164, _188) * i.world_tangent.w) * m.y)) + (_164 * m.z));\n    float3 _219;\n    if (i.front_facing)\n    {\n        _219 = _216;\n    }\n    else\n    {\n        _219 = -_216;\n    }\n    return _219;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _232_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1735 = fa_tex_fix(param_2, param_3);\n    float4 _2630 = base_t;\n    _2630.x = _1735.x;\n    _2630.y = _1735.y;\n    _2630.z = _1735.z;\n    base_t = _2630;\n    float4 _1749 = (_2630 * _232_fa_base_color) * i.vertex_color;\n    float3 _2567 = i.world_normal;\n    if (_232_fa_maps.z > 0.5f)\n    {\n        float param_4 = _232_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1781 = fa_tex_fix(param_6, param_7);\n        float3 _1785 = (_1781 * 2.0f) - 1.0f.xxx;\n        float2 _1790 = _1785.xy * _232_fa_maps.x;\n        float3 _2638 = _1785;\n        _2638.x = _1790.x;\n        _2638.y = _1790.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2638;\n        _2567 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _232_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1818 = fa_tex_fix(param_12, param_13);\n    float4 _2641 = mrt;\n    _2641.x = _1818.x;\n    _2641.y = _1818.y;\n    _2641.z = _1818.z;\n    mrt = _2641;\n    float4 _1847 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _232_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _1847.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1859 = fa_tex_fix(param_16, param_17);\n    float param_18 = _232_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1889 = fa_tex_fix(param_20, param_21);\n    float _2572 = _232_fa_layers_a.x;\n    float _2573 = _232_fa_layers_a.y;\n    float _2576 = _232_fa_layers_a.z;\n    float _2575 = _232_fa_layers_b.w;\n    float _2578 = _232_fa_layers_c.x;\n    if (_232_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_232_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _2572 *= _1859.y;\n            _2573 *= _1859.z;\n            _2575 *= _1847.w;\n        }\n        if (_232_fa_layers_c.z > 1.5f)\n        {\n            _2576 *= mrt.x;\n            _2578 *= mrt.w;\n        }\n    }\n    Surface _2597 = { _1749.xyz, _1749.w, _2567, clamp(_232_fa_pbr.x * _1818.z, 0.0f, 1.0f), clamp(_232_fa_pbr.y * _1818.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_232_fa_maps.y * (_1859.x - 1.0f)), _232_fa_emissive.xyz + (_232_fa_model_emissive.xyz * _1889), _2572, _2573, _232_fa_layers_b.xyz, _2575, _2576, _232_fa_layers_a.w, _2578, _232_fa_layers_c.y, _232_fa_layers_d.xyz };\n    return _2597;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_232_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _232_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_232_fa_cl_info.x) + int(_232_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_232_fa_counts.y > 4.5f) ? 8 : 4);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _273_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _273_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _313 = dot(d, right);\n    float _317 = dot(d, up);\n    float _328;\n    if (((_313 * _313) + (_317 * _317)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _328 = atan2(_317, _313) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _328 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_328 - floor(_328)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li;\n    int _361 = fa_light_base(param);\n    bool _365 = _232_fa_counts.y > 4.5f;\n    int param_1 = _361;\n    float4 _369 = fa_light_texel(param_1);\n    int param_2 = _361 + 1;\n    float4 _374 = fa_light_texel(param_2);\n    float _377 = _374.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _389 = _365 && (_377 > 2.5f);\n    fa_light_is_area = _389;\n    bool _392 = _377 < 0.5f;\n    float3 l;\n    if (_392)\n    {\n        l = normalize(_369.xyz);\n        if (_365)\n        {\n            int param_3 = _361 + 6;\n            float4 _406 = fa_light_texel(param_3);\n            if (_406.z > 0.5f)\n            {\n                int param_4 = _361 + 4;\n                float4 _416 = fa_light_texel(param_4);\n                int param_5 = _361 + 5;\n                float4 _422 = fa_light_texel(param_5);\n                float2 param_6 = _406.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _416.xyz) * _416.w, (-dot(world_pos, _422.xyz)) * _422.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _454 = _369.xyz - world_pos;\n        float _456 = length(_454);\n        dist = _456;\n        l = _454 / max(_456, 9.9999997473787516355514526367188e-05f).xxx;\n        float reach = _456;\n        if (_389)\n        {\n            int param_8 = _361 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0f);\n        }\n        float _488 = reach / max(_369.w, 0.001000000047497451305389404296875f);\n        float _494 = clamp(1.0f - (_488 * _488), 0.0f, 1.0f);\n        atten = _494 * _494;\n        bool _502 = _377 < 2.5f;\n        if ((_377 > 1.5f) && _502)\n        {\n            int param_9 = _361 + 2;\n            float4 _510 = fa_light_texel(param_9);\n            float _520 = _510.w;\n            int param_10 = _361 + 3;\n            float4 _526 = fa_light_texel(param_10);\n            float _527 = _526.x;\n            float cos_inner = _527;\n            if (_527 > 1.5f)\n            {\n                cos_inner = lerp(_520, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_520, cos_inner, dot(-l, normalize(_510.xyz)));\n        }\n        if (_365 && _502)\n        {\n            int param_11 = _361 + 6;\n            float4 _551 = fa_light_texel(param_11);\n            int param_12 = _361 + 7;\n            float4 _556 = fa_light_texel(param_12);\n            bool _559 = _551.z > 0.5f;\n            bool _566;\n            if (!_559)\n            {\n                _566 = _556.z > 0.5f;\n            }\n            else\n            {\n                _566 = _559;\n            }\n            if (_566)\n            {\n                int param_13 = _361 + 2;\n                float4 _573 = fa_light_texel(param_13);\n                float3 _577 = normalize(_573.xyz);\n                int param_14 = _361 + 4;\n                float4 _582 = fa_light_texel(param_14);\n                int param_15 = _361 + 5;\n                float4 _587 = fa_light_texel(param_15);\n                if (_559)\n                {\n                    float3 _595 = -_454;\n                    float _602 = _573.w;\n                    float _618 = 0.5f / max(dot(_595, _577) * (sqrt(max(1.0f - (_602 * _602), 0.0f)) / max(_602, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                    float2 param_16 = _551.xy;\n                    float2 param_17 = float2(0.5f + (dot(_595, _582.xyz) * _618), 0.5f - (dot(_595, _587.xyz) * _618));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_556.z > 0.5f)\n                {\n                    float2 param_18 = _556.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _577;\n                    float3 param_21 = _582.xyz;\n                    float3 param_22 = _587.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    float3 _2534 = _374.xyz * atten;\n    if (_365)\n    {\n        _2534 *= fa_light_tint;\n    }\n    int _686;\n    if (_392)\n    {\n        _686 = 0;\n    }\n    else\n    {\n        _686 = ((_377 > 1.5f) && (_377 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _2545 = { l, _2534, atten, 1.0f, dist, _686 };\n    return _2545;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _925;\n    if (i == 0)\n    {\n        _925 = _935_fa_shadow_split.x;\n    }\n    else\n    {\n        float _941;\n        if (i == 1)\n        {\n            _941 = _935_fa_shadow_split.y;\n        }\n        else\n        {\n            float _949;\n            if (i == 2)\n            {\n                _949 = _935_fa_shadow_split.z;\n            }\n            else\n            {\n                _949 = _935_fa_shadow_split.w;\n            }\n            _941 = _949;\n        }\n        _925 = _941;\n    }\n    return _925;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _913 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_913), sin(_913)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _987 = max(_935_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _992 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _998 = sqrt(1.0f - (_992 * _992));\n    float _1006 = min(_998 / max(_992, 0.20000000298023223876953125f), 4.0f);\n    float _1011;\n    if (_935_fa_shadow_bias.y > 0.0f)\n    {\n        _1011 = _935_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1011 = 1.5f * _935_fa_shadow_info[ci].x;\n    }\n    float4 _1036 = mul(float4(world + (n * (_1011 * _998)), 1.0f), _935_fa_shadow_mat[ci]);\n    float _1043 = _1036.x;\n    bool _1046 = _1043 < _935_fa_shadow_rect[ci].x;\n    bool _1055;\n    if (!_1046)\n    {\n        _1055 = _1043 > _935_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1055 = _1046;\n    }\n    bool _1064;\n    if (!_1055)\n    {\n        _1064 = _1036.y < _935_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1064 = _1055;\n    }\n    bool _1073;\n    if (!_1064)\n    {\n        _1073 = _1036.y > _935_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1073 = _1064;\n    }\n    bool _1080;\n    if (!_1073)\n    {\n        _1080 = _1036.z > 1.0f;\n    }\n    else\n    {\n        _1080 = _1073;\n    }\n    if (_1080)\n    {\n        return -1.0f;\n    }\n    float _1088;\n    if (_935_fa_shadow_bias.x > 0.0f)\n    {\n        _1088 = _935_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1088 = 1.5f * _935_fa_shadow_info[ci].x;\n    }\n    float _1107 = _1036.z - ((_1088 * (1.0f + (0.5f * _1006))) / _987);\n    float _1116 = ((_935_fa_shadow_info[ci].x * min(_1006, 3.0f)) * 0.5f) / _987;\n    int _1125 = int(_935_fa_shadow_cfg.z + 0.5f);\n    if (_1125 == 1)\n    {\n        float2 param = _1036.xy;\n        float4 param_1 = _935_fa_shadow_rect[ci];\n        float _1136 = fa_shadow_depth(param, param_1);\n        return float(_1107 <= _1136);\n    }\n    float _1143 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _1146 = _1125 == 2;\n    if (_1146)\n    {\n        float _1160 = clamp(((_935_fa_shadow_cfg.w * _987) * 0.25f) / _935_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1143;\n            float2 _1179 = fa_shadow_vogel(param_2, param_3, param_4) * _1160;\n            float2 param_5 = _1036.xy + (_1179 * _935_fa_shadow_bias.zw);\n            float4 param_6 = _935_fa_shadow_rect[ci];\n            float _1190 = fa_shadow_depth(param_5, param_6);\n            if (_1190 < (_1107 - (length(_1179) * _1116)))\n            {\n                sum += _1190;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_1107 - (sum / cnt), 0.0f) * _987) * _935_fa_shadow_cfg.w) / _935_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1234 = _1146 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1234; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1234;\n        float param_9 = _1143;\n        float2 _1253 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1036.xy + (_1253 * _935_fa_shadow_bias.zw);\n        float4 param_11 = _935_fa_shadow_rect[ci];\n        float _1264 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1107 - (length(_1253) * _1116)) <= _1264);\n    }\n    return lit / float(_1234);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_232_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1294 = int(_935_fa_shadow_cfg.x + 0.5f);\n    if (_1294 < 1)\n    {\n        return 1.0f;\n    }\n    float _1309 = dot(world - _935_fa_shadow_eye.xyz, _935_fa_shadow_fwd.xyz);\n    int param = _1294 - 1;\n    if (_1309 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1321 = _1294 > 1;\n    bool _1328;\n    if (_1321)\n    {\n        _1328 = _1309 > _935_fa_shadow_split.x;\n    }\n    else\n    {\n        _1328 = _1321;\n    }\n    if (_1328)\n    {\n        ci = 1;\n    }\n    bool _1332 = _1294 > 2;\n    bool _1339;\n    if (_1332)\n    {\n        _1339 = _1309 > _935_fa_shadow_split.y;\n    }\n    else\n    {\n        _1339 = _1332;\n    }\n    if (_1339)\n    {\n        ci = 2;\n    }\n    bool _1343 = _1294 > 3;\n    bool _1350;\n    if (_1343)\n    {\n        _1350 = _1309 > _935_fa_shadow_split.z;\n    }\n    else\n    {\n        _1350 = _1343;\n    }\n    if (_1350)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1294)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1376 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1376;\n        if (_1376 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_935_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1401;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1401 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1401 = _935_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1420 = _935_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1401, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1431 = clamp((_1309 - (fa_shadow_split_at(param_7) - _1420)) / _1420, 0.0f, 1.0f);\n        if (_1431 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1294)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1452 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1452;\n                if (_1452 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1431);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1621 = fa_light_sample(param, param_1);\n    float3 _2547 = _1621.color;\n    float _2549 = _1621.shadow;\n    if ((_1621.type == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1621.direction;\n        float _1635 = fa_shadow_factor(param_2, param_3);\n        _2549 = _1635;\n        _2547 *= _1635;\n    }\n    LightSample _2564 = { _1621.direction, _2547, _1621.attenuation, _2549, _1621._distance, _1621.type };\n    return _2564;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_935_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1476 = int(_935_fa_shadow_cfg.x + 0.5f);\n    float _1486 = dot(world - _935_fa_shadow_eye.xyz, _935_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1491 = _1476 > 0;\n    bool _1500;\n    if (_1491)\n    {\n        int param = _1476 - 1;\n        _1500 = _1486 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1500 = _1491;\n    }\n    if (_1500)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1507 = _1476 > 1;\n        bool _1514;\n        if (_1507)\n        {\n            _1514 = _1486 > _935_fa_shadow_split.x;\n        }\n        else\n        {\n            _1514 = _1507;\n        }\n        if (_1514)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1520 = _1476 > 2;\n        bool _1527;\n        if (_1520)\n        {\n            _1527 = _1486 > _935_fa_shadow_split.y;\n        }\n        else\n        {\n            _1527 = _1520;\n        }\n        if (_1527)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1533 = _1476 > 3;\n        bool _1540;\n        if (_1533)\n        {\n            _1540 = _1486 > _935_fa_shadow_split.z;\n        }\n        else\n        {\n            _1540 = _1533;\n        }\n        if (_1540)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2401 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2401 = -_2401;\n    }\n    float3 _2014 = normalize(_232_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2414 = { fa_world_pos, _2401, fa_world_tangent, fa_uv, fa_vertex_color, _2014, gl_FrontFacing };\n    SurfaceInput param_1 = _2414;\n    Surface _2022 = fa_standard_surface(param_1);\n    float3 _2432 = _2022.albedo;\n    float _2433 = _2022.alpha;\n    float3 _2434 = _2022.normal;\n    float _2435 = _2022.metallic;\n    float _2436 = _2022.roughness;\n    float _2437 = _2022.occlusion;\n    float3 _2438 = _2022.emission;\n    float _2439 = _2022.clearcoat;\n    float _2440 = _2022.clearcoat_roughness;\n    float3 _2441 = _2022.sheen_color;\n    float _2442 = _2022.sheen_roughness;\n    float _2443 = _2022.anisotropy;\n    float _2444 = _2022.anisotropy_rotation;\n    float _2445 = _2022.specular;\n    float _2446 = _2022.ior;\n    float3 _2447 = _2022.specular_color;\n    SurfaceInput _2422 = { fa_world_pos, _2401, fa_world_tangent, fa_uv, fa_vertex_color, _2014, gl_FrontFacing };\n    SurfaceInput param_2 = _2422;\n    Surface param_3 = _2022;\n    surface(param_2, param_3);\n    _2432 = param_3.albedo;\n    _2433 = param_3.alpha;\n    _2434 = param_3.normal;\n    _2435 = param_3.metallic;\n    _2436 = param_3.roughness;\n    _2437 = param_3.occlusion;\n    _2438 = param_3.emission;\n    _2439 = param_3.clearcoat;\n    _2440 = param_3.clearcoat_roughness;\n    _2441 = param_3.sheen_color;\n    _2442 = param_3.sheen_roughness;\n    _2443 = param_3.anisotropy;\n    _2444 = param_3.anisotropy_rotation;\n    _2445 = param_3.specular;\n    _2446 = param_3.ior;\n    _2447 = param_3.specular_color;\n    float3 result;\n    if (_232_fa_emissive.w > 0.5f)\n    {\n        result = _2432;\n    }\n    else\n    {\n        float3 _2043 = _2434;\n        float3 _2044 = normalize(_2043);\n        _2434 = _2044;\n        float3 param_4 = _2044;\n        float3 lit = (fa_ambient_light(param_4) * _2432) * _2437;\n        int _2063 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2063; ln++)\n        {\n            int param_5 = ln;\n            int param_6 = fa_cl_light(param_5);\n            float3 param_7 = fa_world_pos;\n            float3 param_8 = _2401;\n            LightSample _2085 = fa_light_shadowed(param_6, param_7, param_8);\n            SurfaceInput _2430 = { fa_world_pos, _2401, fa_world_tangent, fa_uv, fa_vertex_color, _2014, gl_FrontFacing };\n            SurfaceInput param_9 = _2430;\n            Surface _2513 = { _2432, _2433, _2434, _2435, _2436, _2437, _2438, _2439, _2440, _2441, _2442, _2443, _2444, _2445, _2446, _2447 };\n            Surface param_10 = _2513;\n            LightSample param_11 = _2085;\n            lit += light(param_9, param_10, param_11);\n        }\n        result = lit;\n    }\n    float3 _2100 = result;\n    float3 _2101 = _2100 + _2438;\n    result = _2101;\n    float3 param_12 = _2101;\n    float3 param_13 = fa_world_pos;\n    result = fa_shadow_debug(param_12, param_13);\n    bool _2110 = _232_fa_fog.w > 0.0f;\n    bool _2117;\n    if (!_2110)\n    {\n        _2117 = _232_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2117 = _2110;\n    }\n    if (_2117)\n    {\n        float3 _2126 = fa_world_pos - _232_fa_camera_pos.xyz;\n        float _2132 = dot(_2126, _232_fa_fog_c.xyz);\n        bool _2136 = _232_fa_fog_c.w > 0.5f;\n        float _2137;\n        if (_2136)\n        {\n            _2137 = _2132;\n        }\n        else\n        {\n            _2137 = length(_2126);\n        }\n        float _2149 = _2137 - _232_fa_fog_b.x;\n        if (_2149 > 0.0f)\n        {\n            float _2158 = _232_fa_fog.w * _2149;\n            float tau = _2158 * _2158;\n            if (_232_fa_fog_b.y > 0.0f)\n            {\n                float _2174;\n                if (_2136)\n                {\n                    _2174 = fa_world_pos.y - (_232_fa_fog_c.y * _2132);\n                }\n                else\n                {\n                    _2174 = _232_fa_camera_pos.y;\n                }\n                float _2195 = lerp(_2174, fa_world_pos.y, clamp(_232_fa_fog_b.x / _2137, 0.0f, 1.0f));\n                float _2199 = fa_world_pos.y - _2195;\n                float _2204 = _2195 - _232_fa_fog_b.z;\n                float _2209 = fa_world_pos.y - _232_fa_fog_b.z;\n                bool _2212 = _2204 <= 0.0f;\n                bool _2213 = !_2212;\n                bool _2219;\n                if (_2213)\n                {\n                    _2219 = _232_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2219 = _2212;\n                }\n                float _2220;\n                if (_2219)\n                {\n                    _2220 = _232_fa_fog_b.y;\n                }\n                else\n                {\n                    _2220 = _232_fa_fog_b.y * exp(-min(_232_fa_fog_b.w * _2204, 80.0f));\n                }\n                bool _2247;\n                if (_2213)\n                {\n                    _2247 = _232_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2247 = _2212;\n                }\n                float _2248;\n                if (_2247)\n                {\n                    _2248 = _232_fa_fog_b.y * _2204;\n                }\n                else\n                {\n                    _2248 = (_232_fa_fog_b.y * (1.0f - exp(-min(_232_fa_fog_b.w * _2204, 80.0f)))) / _232_fa_fog_b.w;\n                }\n                bool _2273 = _2209 <= 0.0f;\n                bool _2280;\n                if (!_2273)\n                {\n                    _2280 = _232_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2280 = _2273;\n                }\n                float _2281;\n                if (_2280)\n                {\n                    _2281 = _232_fa_fog_b.y * _2209;\n                }\n                else\n                {\n                    _2281 = (_232_fa_fog_b.y * (1.0f - exp(-min(_232_fa_fog_b.w * _2209, 80.0f)))) / _232_fa_fog_b.w;\n                }\n                float _2308;\n                if (abs(_2199) < 0.001000000047497451305389404296875f)\n                {\n                    _2308 = _2220;\n                }\n                else\n                {\n                    _2308 = (_2281 - _2248) / _2199;\n                }\n                tau += (_2149 * max(_2308, 0.0f));\n            }\n            result = lerp(result, _232_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2433);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_232",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_935",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _232_fa_camera_pos : packoffset(c0);\n    float4 _232_fa_ambient : packoffset(c1);\n    float4 _232_fa_base_color : packoffset(c2);\n    float4 _232_fa_emissive : packoffset(c3);\n    float4 _232_fa_model_emissive : packoffset(c4);\n    float4 _232_fa_pbr : packoffset(c5);\n    float4 _232_fa_maps : packoffset(c6);\n    float4 _232_fa_fog : packoffset(c7);\n    float4 _232_fa_fog_b : packoffset(c8);\n    float4 _232_fa_fog_c : packoffset(c9);\n    float4 _232_fa_counts : packoffset(c10);\n    float4 _232_fa_env_sky : packoffset(c11);\n    float4 _232_fa_env_horizon : packoffset(c12);\n    float4 _232_fa_time : packoffset(c13);\n    float4 _232_fa_cl_vpx : packoffset(c14);\n    float4 _232_fa_cl_vpy : packoffset(c15);\n    float4 _232_fa_cl_vpw : packoffset(c16);\n    float4 _232_fa_cl_fwd : packoffset(c17);\n    float4 _232_fa_cl_grid : packoffset(c18);\n    float4 _232_fa_cl_info : packoffset(c19);\n    float4 _232_fa_layers_a : packoffset(c20);\n    float4 _232_fa_layers_b : packoffset(c21);\n    float4 _232_fa_layers_c : packoffset(c22);\n    float4 _232_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _935_fa_shadow_mat[4] : packoffset(c0);\n    float4 _935_fa_shadow_rect[4] : packoffset(c16);\n    float4 _935_fa_shadow_info[4] : packoffset(c20);\n    float4 _935_fa_shadow_split : packoffset(c24);\n    float4 _935_fa_shadow_cfg : packoffset(c25);\n    float4 _935_fa_shadow_bias : packoffset(c26);\n    float4 _935_fa_shadow_eye : packoffset(c27);\n    float4 _935_fa_shadow_fwd : packoffset(c28);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_irr_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _704 = _232_fa_cl_info.x < 0.0f;\n    bool _711;\n    if (!_704)\n    {\n        _711 = _232_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _711 = _704;\n    }\n    bool _719;\n    if (!_711)\n    {\n        _719 = _232_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _719 = _711;\n    }\n    bool _726;\n    if (!_719)\n    {\n        _726 = _232_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _726 = _719;\n    }\n    bool _733;\n    if (!_726)\n    {\n        _733 = _232_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _733 = _726;\n    }\n    if (_733)\n    {\n        return int2(0, 0);\n    }\n    float4 _743 = float4(world_pos, 1.0f);\n    float _750 = dot(_232_fa_cl_vpw, _743);\n    if (!(_750 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _772 = float2(dot(_232_fa_cl_vpx, _743), dot(_232_fa_cl_vpy, _743)) / _750.xx;\n    int _776 = int(_232_fa_cl_grid.x);\n    int _780 = int(_232_fa_cl_grid.y);\n    int param = (int(_232_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_232_fa_cl_fwd.xyz, world_pos) + _232_fa_cl_fwd.w, _232_fa_cl_grid.w) / _232_fa_cl_grid.w) * _232_fa_cl_grid.z)), 0, int(_232_fa_cl_info.y) - 1) * _780) + clamp(int(floor(((_772.y * 0.5f) + 0.5f) * _232_fa_cl_grid.y)), 0, _780 - 1)) * _776)) + clamp(int(floor(((_772.x * 0.5f) + 0.5f) * _232_fa_cl_grid.x)), 0, _776 - 1);\n    float4 _851 = fa_light_texel(param);\n    return int2(int(_851.x), int(_851.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_232_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1593 = fa_cluster_lookup(param);\n    fa_cl_slot = _1593.x;\n    fa_cl_local = _1593.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1696 = fa_linear_to_srgb(param);\n        c = _1696;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1704 = fa_srgb_to_linear(param_1);\n            c = _1704;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _164;\n    if (i.front_facing)\n    {\n        _164 = i.world_normal;\n    }\n    else\n    {\n        _164 = -i.world_normal;\n    }\n    float3 _188 = normalize(i.world_tangent.xyz - (_164 * dot(_164, i.world_tangent.xyz)));\n    float3 _216 = normalize(((_188 * m.x) + ((cross(_164, _188) * i.world_tangent.w) * m.y)) + (_164 * m.z));\n    float3 _219;\n    if (i.front_facing)\n    {\n        _219 = _216;\n    }\n    else\n    {\n        _219 = -_216;\n    }\n    return _219;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _232_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1735 = fa_tex_fix(param_2, param_3);\n    float4 _2630 = base_t;\n    _2630.x = _1735.x;\n    _2630.y = _1735.y;\n    _2630.z = _1735.z;\n    base_t = _2630;\n    float4 _1749 = (_2630 * _232_fa_base_color) * i.vertex_color;\n    float3 _2567 = i.world_normal;\n    if (_232_fa_maps.z > 0.5f)\n    {\n        float param_4 = _232_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1781 = fa_tex_fix(param_6, param_7);\n        float3 _1785 = (_1781 * 2.0f) - 1.0f.xxx;\n        float2 _1790 = _1785.xy * _232_fa_maps.x;\n        float3 _2638 = _1785;\n        _2638.x = _1790.x;\n        _2638.y = _1790.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2638;\n        _2567 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _232_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1818 = fa_tex_fix(param_12, param_13);\n    float4 _2641 = mrt;\n    _2641.x = _1818.x;\n    _2641.y = _1818.y;\n    _2641.z = _1818.z;\n    mrt = _2641;\n    float4 _1847 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _232_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _1847.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1859 = fa_tex_fix(param_16, param_17);\n    float param_18 = _232_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1889 = fa_tex_fix(param_20, param_21);\n    float _2572 = _232_fa_layers_a.x;\n    float _2573 = _232_fa_layers_a.y;\n    float _2576 = _232_fa_layers_a.z;\n    float _2575 = _232_fa_layers_b.w;\n    float _2578 = _232_fa_layers_c.x;\n    if (_232_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_232_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _2572 *= _1859.y;\n            _2573 *= _1859.z;\n            _2575 *= _1847.w;\n        }\n        if (_232_fa_layers_c.z > 1.5f)\n        {\n            _2576 *= mrt.x;\n            _2578 *= mrt.w;\n        }\n    }\n    Surface _2597 = { _1749.xyz, _1749.w, _2567, clamp(_232_fa_pbr.x * _1818.z, 0.0f, 1.0f), clamp(_232_fa_pbr.y * _1818.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_232_fa_maps.y * (_1859.x - 1.0f)), _232_fa_emissive.xyz + (_232_fa_model_emissive.xyz * _1889), _2572, _2573, _232_fa_layers_b.xyz, _2575, _2576, _232_fa_layers_a.w, _2578, _232_fa_layers_c.y, _232_fa_layers_d.xyz };\n    return _2597;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_232_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _232_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_232_fa_cl_info.x) + int(_232_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_232_fa_counts.y > 4.5f) ? 8 : 4);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _273_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _273_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _313 = dot(d, right);\n    float _317 = dot(d, up);\n    float _328;\n    if (((_313 * _313) + (_317 * _317)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _328 = atan2(_317, _313) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _328 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_328 - floor(_328)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li;\n    int _361 = fa_light_base(param);\n    bool _365 = _232_fa_counts.y > 4.5f;\n    int param_1 = _361;\n    float4 _369 = fa_light_texel(param_1);\n    int param_2 = _361 + 1;\n    float4 _374 = fa_light_texel(param_2);\n    float _377 = _374.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _389 = _365 && (_377 > 2.5f);\n    fa_light_is_area = _389;\n    bool _392 = _377 < 0.5f;\n    float3 l;\n    if (_392)\n    {\n        l = normalize(_369.xyz);\n        if (_365)\n        {\n            int param_3 = _361 + 6;\n            float4 _406 = fa_light_texel(param_3);\n            if (_406.z > 0.5f)\n            {\n                int param_4 = _361 + 4;\n                float4 _416 = fa_light_texel(param_4);\n                int param_5 = _361 + 5;\n                float4 _422 = fa_light_texel(param_5);\n                float2 param_6 = _406.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _416.xyz) * _416.w, (-dot(world_pos, _422.xyz)) * _422.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _454 = _369.xyz - world_pos;\n        float _456 = length(_454);\n        dist = _456;\n        l = _454 / max(_456, 9.9999997473787516355514526367188e-05f).xxx;\n        float reach = _456;\n        if (_389)\n        {\n            int param_8 = _361 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0f);\n        }\n        float _488 = reach / max(_369.w, 0.001000000047497451305389404296875f);\n        float _494 = clamp(1.0f - (_488 * _488), 0.0f, 1.0f);\n        atten = _494 * _494;\n        bool _502 = _377 < 2.5f;\n        if ((_377 > 1.5f) && _502)\n        {\n            int param_9 = _361 + 2;\n            float4 _510 = fa_light_texel(param_9);\n            float _520 = _510.w;\n            int param_10 = _361 + 3;\n            float4 _526 = fa_light_texel(param_10);\n            float _527 = _526.x;\n            float cos_inner = _527;\n            if (_527 > 1.5f)\n            {\n                cos_inner = lerp(_520, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_520, cos_inner, dot(-l, normalize(_510.xyz)));\n        }\n        if (_365 && _502)\n        {\n            int param_11 = _361 + 6;\n            float4 _551 = fa_light_texel(param_11);\n            int param_12 = _361 + 7;\n            float4 _556 = fa_light_texel(param_12);\n            bool _559 = _551.z > 0.5f;\n            bool _566;\n            if (!_559)\n            {\n                _566 = _556.z > 0.5f;\n            }\n            else\n            {\n                _566 = _559;\n            }\n            if (_566)\n            {\n                int param_13 = _361 + 2;\n                float4 _573 = fa_light_texel(param_13);\n                float3 _577 = normalize(_573.xyz);\n                int param_14 = _361 + 4;\n                float4 _582 = fa_light_texel(param_14);\n                int param_15 = _361 + 5;\n                float4 _587 = fa_light_texel(param_15);\n                if (_559)\n                {\n                    float3 _595 = -_454;\n                    float _602 = _573.w;\n                    float _618 = 0.5f / max(dot(_595, _577) * (sqrt(max(1.0f - (_602 * _602), 0.0f)) / max(_602, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                    float2 param_16 = _551.xy;\n                    float2 param_17 = float2(0.5f + (dot(_595, _582.xyz) * _618), 0.5f - (dot(_595, _587.xyz) * _618));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_556.z > 0.5f)\n                {\n                    float2 param_18 = _556.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _577;\n                    float3 param_21 = _582.xyz;\n                    float3 param_22 = _587.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    float3 _2534 = _374.xyz * atten;\n    if (_365)\n    {\n        _2534 *= fa_light_tint;\n    }\n    int _686;\n    if (_392)\n    {\n        _686 = 0;\n    }\n    else\n    {\n        _686 = ((_377 > 1.5f) && (_377 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _2545 = { l, _2534, atten, 1.0f, dist, _686 };\n    return _2545;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _925;\n    if (i == 0)\n    {\n        _925 = _935_fa_shadow_split.x;\n    }\n    else\n    {\n        float _941;\n        if (i == 1)\n        {\n            _941 = _935_fa_shadow_split.y;\n        }\n        else\n        {\n            float _949;\n            if (i == 2)\n            {\n                _949 = _935_fa_shadow_split.z;\n            }\n            else\n            {\n                _949 = _935_fa_shadow_split.w;\n            }\n            _941 = _949;\n        }\n        _925 = _941;\n    }\n    return _925;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _913 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_913), sin(_913)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _987 = max(_935_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _992 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _998 = sqrt(1.0f - (_992 * _992));\n    float _1006 = min(_998 / max(_992, 0.20000000298023223876953125f), 4.0f);\n    float _1011;\n    if (_935_fa_shadow_bias.y > 0.0f)\n    {\n        _1011 = _935_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1011 = 1.5f * _935_fa_shadow_info[ci].x;\n    }\n    float4 _1036 = mul(float4(world + (n * (_1011 * _998)), 1.0f), _935_fa_shadow_mat[ci]);\n    float _1043 = _1036.x;\n    bool _1046 = _1043 < _935_fa_shadow_rect[ci].x;\n    bool _1055;\n    if (!_1046)\n    {\n        _1055 = _1043 > _935_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1055 = _1046;\n    }\n    bool _1064;\n    if (!_1055)\n    {\n        _1064 = _1036.y < _935_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1064 = _1055;\n    }\n    bool _1073;\n    if (!_1064)\n    {\n        _1073 = _1036.y > _935_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1073 = _1064;\n    }\n    bool _1080;\n    if (!_1073)\n    {\n        _1080 = _1036.z > 1.0f;\n    }\n    else\n    {\n        _1080 = _1073;\n    }\n    if (_1080)\n    {\n        return -1.0f;\n    }\n    float _1088;\n    if (_935_fa_shadow_bias.x > 0.0f)\n    {\n        _1088 = _935_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1088 = 1.5f * _935_fa_shadow_info[ci].x;\n    }\n    float _1107 = _1036.z - ((_1088 * (1.0f + (0.5f * _1006))) / _987);\n    float _1116 = ((_935_fa_shadow_info[ci].x * min(_1006, 3.0f)) * 0.5f) / _987;\n    int _1125 = int(_935_fa_shadow_cfg.z + 0.5f);\n    if (_1125 == 1)\n    {\n        float2 param = _1036.xy;\n        float4 param_1 = _935_fa_shadow_rect[ci];\n        float _1136 = fa_shadow_depth(param, param_1);\n        return float(_1107 <= _1136);\n    }\n    float _1143 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _1146 = _1125 == 2;\n    if (_1146)\n    {\n        float _1160 = clamp(((_935_fa_shadow_cfg.w * _987) * 0.25f) / _935_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1143;\n            float2 _1179 = fa_shadow_vogel(param_2, param_3, param_4) * _1160;\n            float2 param_5 = _1036.xy + (_1179 * _935_fa_shadow_bias.zw);\n            float4 param_6 = _935_fa_shadow_rect[ci];\n            float _1190 = fa_shadow_depth(param_5, param_6);\n            if (_1190 < (_1107 - (length(_1179) * _1116)))\n            {\n                sum += _1190;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_1107 - (sum / cnt), 0.0f) * _987) * _935_fa_shadow_cfg.w) / _935_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1234 = _1146 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1234; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1234;\n        float param_9 = _1143;\n        float2 _1253 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1036.xy + (_1253 * _935_fa_shadow_bias.zw);\n        float4 param_11 = _935_fa_shadow_rect[ci];\n        float _1264 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1107 - (length(_1253) * _1116)) <= _1264);\n    }\n    return lit / float(_1234);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_232_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1294 = int(_935_fa_shadow_cfg.x + 0.5f);\n    if (_1294 < 1)\n    {\n        return 1.0f;\n    }\n    float _1309 = dot(world - _935_fa_shadow_eye.xyz, _935_fa_shadow_fwd.xyz);\n    int param = _1294 - 1;\n    if (_1309 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1321 = _1294 > 1;\n    bool _1328;\n    if (_1321)\n    {\n        _1328 = _1309 > _935_fa_shadow_split.x;\n    }\n    else\n    {\n        _1328 = _1321;\n    }\n    if (_1328)\n    {\n        ci = 1;\n    }\n    bool _1332 = _1294 > 2;\n    bool _1339;\n    if (_1332)\n    {\n        _1339 = _1309 > _935_fa_shadow_split.y;\n    }\n    else\n    {\n        _1339 = _1332;\n    }\n    if (_1339)\n    {\n        ci = 2;\n    }\n    bool _1343 = _1294 > 3;\n    bool _1350;\n    if (_1343)\n    {\n        _1350 = _1309 > _935_fa_shadow_split.z;\n    }\n    else\n    {\n        _1350 = _1343;\n    }\n    if (_1350)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1294)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1376 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1376;\n        if (_1376 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_935_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1401;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1401 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1401 = _935_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1420 = _935_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1401, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1431 = clamp((_1309 - (fa_shadow_split_at(param_7) - _1420)) / _1420, 0.0f, 1.0f);\n        if (_1431 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1294)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1452 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1452;\n                if (_1452 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1431);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1621 = fa_light_sample(param, param_1);\n    float3 _2547 = _1621.color;\n    float _2549 = _1621.shadow;\n    if ((_1621.type == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1621.direction;\n        float _1635 = fa_shadow_factor(param_2, param_3);\n        _2549 = _1635;\n        _2547 *= _1635;\n    }\n    LightSample _2564 = { _1621.direction, _2547, _1621.attenuation, _2549, _1621._distance, _1621.type };\n    return _2564;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_935_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1476 = int(_935_fa_shadow_cfg.x + 0.5f);\n    float _1486 = dot(world - _935_fa_shadow_eye.xyz, _935_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1491 = _1476 > 0;\n    bool _1500;\n    if (_1491)\n    {\n        int param = _1476 - 1;\n        _1500 = _1486 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1500 = _1491;\n    }\n    if (_1500)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1507 = _1476 > 1;\n        bool _1514;\n        if (_1507)\n        {\n            _1514 = _1486 > _935_fa_shadow_split.x;\n        }\n        else\n        {\n            _1514 = _1507;\n        }\n        if (_1514)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1520 = _1476 > 2;\n        bool _1527;\n        if (_1520)\n        {\n            _1527 = _1486 > _935_fa_shadow_split.y;\n        }\n        else\n        {\n            _1527 = _1520;\n        }\n        if (_1527)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1533 = _1476 > 3;\n        bool _1540;\n        if (_1533)\n        {\n            _1540 = _1486 > _935_fa_shadow_split.z;\n        }\n        else\n        {\n            _1540 = _1533;\n        }\n        if (_1540)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2401 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2401 = -_2401;\n    }\n    float3 _2014 = normalize(_232_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2414 = { fa_world_pos, _2401, fa_world_tangent, fa_uv, fa_vertex_color, _2014, gl_FrontFacing };\n    SurfaceInput param_1 = _2414;\n    Surface _2022 = fa_standard_surface(param_1);\n    float3 _2432 = _2022.albedo;\n    float _2433 = _2022.alpha;\n    float3 _2434 = _2022.normal;\n    float _2435 = _2022.metallic;\n    float _2436 = _2022.roughness;\n    float _2437 = _2022.occlusion;\n    float3 _2438 = _2022.emission;\n    float _2439 = _2022.clearcoat;\n    float _2440 = _2022.clearcoat_roughness;\n    float3 _2441 = _2022.sheen_color;\n    float _2442 = _2022.sheen_roughness;\n    float _2443 = _2022.anisotropy;\n    float _2444 = _2022.anisotropy_rotation;\n    float _2445 = _2022.specular;\n    float _2446 = _2022.ior;\n    float3 _2447 = _2022.specular_color;\n    SurfaceInput _2422 = { fa_world_pos, _2401, fa_world_tangent, fa_uv, fa_vertex_color, _2014, gl_FrontFacing };\n    SurfaceInput param_2 = _2422;\n    Surface param_3 = _2022;\n    surface(param_2, param_3);\n    _2432 = param_3.albedo;\n    _2433 = param_3.alpha;\n    _2434 = param_3.normal;\n    _2435 = param_3.metallic;\n    _2436 = param_3.roughness;\n    _2437 = param_3.occlusion;\n    _2438 = param_3.emission;\n    _2439 = param_3.clearcoat;\n    _2440 = param_3.clearcoat_roughness;\n    _2441 = param_3.sheen_color;\n    _2442 = param_3.sheen_roughness;\n    _2443 = param_3.anisotropy;\n    _2444 = param_3.anisotropy_rotation;\n    _2445 = param_3.specular;\n    _2446 = param_3.ior;\n    _2447 = param_3.specular_color;\n    float3 result;\n    if (_232_fa_emissive.w > 0.5f)\n    {\n        result = _2432;\n    }\n    else\n    {\n        float3 _2043 = _2434;\n        float3 _2044 = normalize(_2043);\n        _2434 = _2044;\n        float3 param_4 = _2044;\n        float3 lit = (fa_ambient_light(param_4) * _2432) * _2437;\n        int _2063 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2063; ln++)\n        {\n            int param_5 = ln;\n            int param_6 = fa_cl_light(param_5);\n            float3 param_7 = fa_world_pos;\n            float3 param_8 = _2401;\n            LightSample _2085 = fa_light_shadowed(param_6, param_7, param_8);\n            SurfaceInput _2430 = { fa_world_pos, _2401, fa_world_tangent, fa_uv, fa_vertex_color, _2014, gl_FrontFacing };\n            SurfaceInput param_9 = _2430;\n            Surface _2513 = { _2432, _2433, _2434, _2435, _2436, _2437, _2438, _2439, _2440, _2441, _2442, _2443, _2444, _2445, _2446, _2447 };\n            Surface param_10 = _2513;\n            LightSample param_11 = _2085;\n            lit += light(param_9, param_10, param_11);\n        }\n        result = lit;\n    }\n    float3 _2100 = result;\n    float3 _2101 = _2100 + _2438;\n    result = _2101;\n    float3 param_12 = _2101;\n    float3 param_13 = fa_world_pos;\n    result = fa_shadow_debug(param_12, param_13);\n    bool _2110 = _232_fa_fog.w > 0.0f;\n    bool _2117;\n    if (!_2110)\n    {\n        _2117 = _232_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2117 = _2110;\n    }\n    if (_2117)\n    {\n        float3 _2126 = fa_world_pos - _232_fa_camera_pos.xyz;\n        float _2132 = dot(_2126, _232_fa_fog_c.xyz);\n        bool _2136 = _232_fa_fog_c.w > 0.5f;\n        float _2137;\n        if (_2136)\n        {\n            _2137 = _2132;\n        }\n        else\n        {\n            _2137 = length(_2126);\n        }\n        float _2149 = _2137 - _232_fa_fog_b.x;\n        if (_2149 > 0.0f)\n        {\n            float _2158 = _232_fa_fog.w * _2149;\n            float tau = _2158 * _2158;\n            if (_232_fa_fog_b.y > 0.0f)\n            {\n                float _2174;\n                if (_2136)\n                {\n                    _2174 = fa_world_pos.y - (_232_fa_fog_c.y * _2132);\n                }\n                else\n                {\n                    _2174 = _232_fa_camera_pos.y;\n                }\n                float _2195 = lerp(_2174, fa_world_pos.y, clamp(_232_fa_fog_b.x / _2137, 0.0f, 1.0f));\n                float _2199 = fa_world_pos.y - _2195;\n                float _2204 = _2195 - _232_fa_fog_b.z;\n                float _2209 = fa_world_pos.y - _232_fa_fog_b.z;\n                bool _2212 = _2204 <= 0.0f;\n                bool _2213 = !_2212;\n                bool _2219;\n                if (_2213)\n                {\n                    _2219 = _232_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2219 = _2212;\n                }\n                float _2220;\n                if (_2219)\n                {\n                    _2220 = _232_fa_fog_b.y;\n                }\n                else\n                {\n                    _2220 = _232_fa_fog_b.y * exp(-min(_232_fa_fog_b.w * _2204, 80.0f));\n                }\n                bool _2247;\n                if (_2213)\n                {\n                    _2247 = _232_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2247 = _2212;\n                }\n                float _2248;\n                if (_2247)\n                {\n                    _2248 = _232_fa_fog_b.y * _2204;\n                }\n                else\n                {\n                    _2248 = (_232_fa_fog_b.y * (1.0f - exp(-min(_232_fa_fog_b.w * _2204, 80.0f)))) / _232_fa_fog_b.w;\n                }\n                bool _2273 = _2209 <= 0.0f;\n                bool _2280;\n                if (!_2273)\n                {\n                    _2280 = _232_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2280 = _2273;\n                }\n                float _2281;\n                if (_2280)\n                {\n                    _2281 = _232_fa_fog_b.y * _2209;\n                }\n                else\n                {\n                    _2281 = (_232_fa_fog_b.y * (1.0f - exp(-min(_232_fa_fog_b.w * _2209, 80.0f)))) / _232_fa_fog_b.w;\n                }\n                float _2308;\n                if (abs(_2199) < 0.001000000047497451305389404296875f)\n                {\n                    _2308 = _2220;\n                }\n                else\n                {\n                    _2308 = (_2281 - _2248) / _2199;\n                }\n                tau += (_2149 * max(_2308, 0.0f));\n            }\n            result = lerp(result, _232_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2433);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_232",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_935",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213_fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213_fa_layers_a.x;\n    float _753 = _213_fa_layers_a.y;\n    float _756 = _213_fa_layers_a.z;\n    float _755 = _213_fa_layers_b.w;\n    float _758 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    Surface _777 = { _241.xyz, _241.w, _747, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _752, _753, _213_fa_layers_b.xyz, _755, _756, _213_fa_layers_a.w, _758, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _777;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _671 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _671;\n    SurfaceInput _679 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _679;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _413 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _413;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0f);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213_fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213_fa_layers_a.x;\n    float _753 = _213_fa_layers_a.y;\n    float _756 = _213_fa_layers_a.z;\n    float _755 = _213_fa_layers_b.w;\n    float _758 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    Surface _777 = { _241.xyz, _241.w, _747, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _752, _753, _213_fa_layers_b.xyz, _755, _756, _213_fa_layers_a.w, _758, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _777;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _671 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _671;\n    SurfaceInput _679 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _679;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
