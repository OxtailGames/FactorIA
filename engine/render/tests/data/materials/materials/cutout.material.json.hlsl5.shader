{
  "format": "factoria.shader/1",
  "engine": "0.1.6",
  "template": "c92b9f1a26adc9a735edf9d88d24268eb2cae4ffeaa00748a36617e70a4776c1",
  "slang": "hlsl5",
  "params": [
    "alphaCutoff"
  ],
  "textures": [
    "mask"
  ],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _127_fa_view_proj : packoffset(c0);\n    row_major float4x4 _127_fa_light_vp : packoffset(c4);\n    float4 _127_fa_uv_scale : packoffset(c8);\n    float4 _127_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_inst_m0 : TEXCOORD4;\n    float4 fa_inst_m1 : TEXCOORD5;\n    float4 fa_inst_m2 : TEXCOORD6;\n    float4 fa_inst_m3 : TEXCOORD7;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_shadow_pos : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0)\n{\n    float3 _65 = cross(model[1].xyz, model[2].xyz);\n    float _71 = (dot(model[0].xyz, _65) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _254 = { mul(float4(position, 1.0f), model).xyz, (((_65 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _71, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _71), texcoord0 * _127_fa_uv_scale.xy, position };\n    return _254;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    VertexData _151 = fa_vertex_data(param, param_1, param_2, param_3, param_4);\n    float3 _260 = _151.world_pos;\n    float4 _158 = float4(_260, 1.0f);\n    fa_world_pos = _260;\n    fa_world_normal = _151.world_normal;\n    fa_world_tangent = _151.world_tangent;\n    fa_uv = _151.uv;\n    fa_shadow_pos = mul(_158, _127_fa_light_vp);\n    gl_Position = mul(_158, _127_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _148_fa_camera_pos : packoffset(c0);\n    float4 _148_fa_ambient : packoffset(c1);\n    float4 _148_fa_base_color : packoffset(c2);\n    float4 _148_fa_emissive : packoffset(c3);\n    float4 _148_fa_model_emissive : packoffset(c4);\n    float4 _148_fa_pbr : packoffset(c5);\n    float4 _148_fa_maps : packoffset(c6);\n    float4 _148_fa_fog : packoffset(c7);\n    float4 _148_fa_counts : packoffset(c8);\n    float4 _148_fa_env_sky : packoffset(c9);\n    float4 _148_fa_env_horizon : packoffset(c10);\n    float4 _148_fa_time : packoffset(c11);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _561_alphaCutoff : packoffset(c0);\n    float _561_fa_pad0 : packoffset(c0.y);\n    float _561_fa_pad1 : packoffset(c0.z);\n    float _561_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _658_fa_light_pos[32] : packoffset(c0);\n    float4 _658_fa_light_color[32] : packoffset(c32);\n    float4 _658_fa_light_dir[32] : packoffset(c64);\n};\n\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_shadow_pos : TEXCOORD4;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _52;\n    if (i.front_facing)\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    float3 _77 = normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    float3 _105 = normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    float3 _108;\n    if (i.front_facing)\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 _145 = fa_tex.Sample(fa_smp, i.uv);\n    float4 _152 = _145 * _148_fa_base_color;\n    float3 _964 = i.world_normal;\n    if (_148_fa_maps.z > 0.5f)\n    {\n        float3 _184 = (fa_normal_tex.Sample(fa_smp, i.uv).xyz * 2.0f) - 1.0f.xxx;\n        float2 _189 = _184.xy * _148_fa_maps.x;\n        float3 _981 = _184;\n        _981.x = _189.x;\n        _981.y = _189.y;\n        SurfaceInput param = i;\n        float3 param_1 = _981;\n        _964 = fa_tangent_normal(param, param_1);\n    }\n    float4 _207 = fa_mr_tex.Sample(fa_smp, i.uv);\n    Surface _976 = { _152.xyz, _152.w, _964, clamp(_148_fa_pbr.x * _207.z, 0.0f, 1.0f), clamp(_148_fa_pbr.y * _207.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_148_fa_maps.y * (fa_occlusion_tex.Sample(fa_smp, i.uv).x - 1.0f)), _148_fa_emissive.xyz + (_148_fa_model_emissive.xyz * fa_emissive_tex.Sample(fa_smp, i.uv).xyz) };\n    return _976;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    if (_148_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _274 = fa_shadow_pos.xyz / fa_shadow_pos.w.xxx;\n    float3 p = _274;\n    float2 suv = (_274.xy * 0.5f) + 0.5f.xx;\n    if (_148_fa_counts.z > 0.5f)\n    {\n        float3 _986 = p;\n        _986.z = (_986.z * 0.5f) + 0.5f;\n        p = _986;\n    }\n    else\n    {\n        float2 _989 = suv;\n        _989.y = 1.0f - _989.y;\n        suv = _989;\n    }\n    bool _301 = suv.x < 0.0f;\n    bool _308;\n    if (!_301)\n    {\n        _308 = suv.x > 1.0f;\n    }\n    else\n    {\n        _308 = _301;\n    }\n    bool _315;\n    if (!_308)\n    {\n        _315 = suv.y < 0.0f;\n    }\n    else\n    {\n        _315 = _308;\n    }\n    bool _322;\n    if (!_315)\n    {\n        _322 = suv.y > 1.0f;\n    }\n    else\n    {\n        _322 = _315;\n    }\n    bool _329;\n    if (!_322)\n    {\n        _329 = p.z > 1.0f;\n    }\n    else\n    {\n        _329 = _322;\n    }\n    if (_329)\n    {\n        return 1.0f;\n    }\n    float _343 = _148_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _343) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _148_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _484 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _487 = _484.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_487 * _487, exp2((-9.27999973297119140625f) * ndv)) * _487) + _484.y)) + _484.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _404 = rough * rough;\n    float _437 = 0.60000002384185791015625f * _404;\n    return lerp(lerp(_148_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_148_fa_env_horizon.xyz, _148_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _404)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _437, 0.0500000007450580596923828125f + _437, d.y).xxx), ((_148_fa_env_sky.xyz + _148_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_404 * 0.60000002384185791015625f).xxx);\n}\n\nvoid frag_main()\n{\n    float3 _914 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _914 = -_914;\n    }\n    float3 _544 = _148_fa_camera_pos.xyz - fa_world_pos;\n    float3 _545 = normalize(_544);\n    SurfaceInput _925 = { fa_world_pos, _914, fa_world_tangent, fa_uv, _545, gl_FrontFacing };\n    SurfaceInput param = _925;\n    Surface _550 = fa_standard_surface(param);\n    float3 _933 = _550.albedo;\n    float _934 = _550.alpha;\n    float3 _935 = _550.normal;\n    float _936 = _550.metallic;\n    float _937 = _550.roughness;\n    float _938 = _550.occlusion;\n    float3 _939 = _550.emission;\n    SurfaceInput _932 = { fa_world_pos, _914, fa_world_tangent, fa_uv, _545, gl_FrontFacing };\n    SurfaceInput param_1 = _932;\n    Surface param_2 = _550;\n    surface(param_1, param_2);\n    _933 = param_2.albedo;\n    _934 = param_2.alpha;\n    _935 = param_2.normal;\n    _936 = param_2.metallic;\n    _937 = param_2.roughness;\n    _938 = param_2.occlusion;\n    _939 = param_2.emission;\n    if (param_2.alpha < _561_alphaCutoff)\n    {\n        discard;\n    }\n    float3 result;\n    if (_148_fa_emissive.w > 0.5f)\n    {\n        result = _933;\n    }\n    else\n    {\n        float3 _583 = normalize(_935);\n        float _590 = clamp(_936, 0.0f, 1.0f);\n        float _594 = clamp(_937, 0.0500000007450580596923828125f, 1.0f);\n        float _598 = _594 * _594;\n        float _602 = _598 * _598;\n        float _608 = max(dot(_583, _545), 9.9999997473787516355514526367188e-05f);\n        float3 _614 = _933 * (1.0f - _590);\n        float3 _622 = lerp(0.039999999105930328369140625f.xxx, _933, _590.xxx);\n        float3 lit = (_148_fa_ambient.xyz * _614) * _938;\n        int _635 = int(_148_fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _635)\n            {\n                break;\n            }\n            float atten = 1.0f;\n            bool _664 = _658_fa_light_color[li].w < 0.5f;\n            if (_664)\n            {\n                l = normalize(_658_fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _681 = _658_fa_light_pos[li].xyz - fa_world_pos;\n                float _684 = length(_681);\n                l = _681 / max(_684, 9.9999997473787516355514526367188e-05f).xxx;\n                float _699 = _684 / max(_658_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n                float _705 = clamp(1.0f - (_699 * _699), 0.0f, 1.0f);\n                atten = _705 * _705;\n                if (_658_fa_light_color[li].w > 1.5f)\n                {\n                    atten *= smoothstep(_658_fa_light_dir[li].w, lerp(_658_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_658_fa_light_dir[li].xyz)));\n                }\n            }\n            float _739 = max(dot(_583, l), 0.0f);\n            if (_664 && (li == 0))\n            {\n                float3 param_3 = _914;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            float3 _758 = normalize(l + _545);\n            float _763 = max(dot(_583, _758), 0.0f);\n            float _776 = ((_763 * _763) * (_602 - 1.0f)) + 1.0f;\n            lit += (((_614 + (((_622 + ((1.0f.xxx - _622) * pow(1.0f - max(dot(_545, _758), 0.0f), 5.0f))) * (((_602 / ((3.1415927410125732421875f * _776) * _776)) * (0.5f / max(lerp((2.0f * _739) * _608, _739 + _608, _598), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _739))) * _658_fa_light_color[li].xyz) * (_739 * atten));\n        }\n        float param_5 = _594;\n        float param_6 = _608;\n        float2 _844 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_545, _583);\n        float param_8 = _594;\n        float3 _862 = lit;\n        float3 _863 = _862 + ((fa_environment(param_7, param_8) * ((_622 * _844.x) + _844.y.xxx)) * _938);\n        lit = _863;\n        result = _863;\n    }\n    result += _939;\n    if (_148_fa_fog.w > 0.0f)\n    {\n        float _887 = _148_fa_fog.w * length(_544);\n        result = lerp(result, _148_fa_fog.xyz, clamp(1.0f - exp((-_887) * _887), 0.0f, 1.0f).xxx);\n    }\n    fa_frag_color = float4(result, _934);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_127",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_148",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_561",
            "hlsl_register_b_n": 5
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_658",
            "hlsl_register_b_n": 2
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
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 6
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          },
          {
            "slot": 6,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _132_fa_view_proj : packoffset(c0);\n    row_major float4x4 _132_fa_light_vp : packoffset(c4);\n    float4 _132_fa_uv_scale : packoffset(c8);\n    float4 _132_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _176_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_inst_m0 : TEXCOORD4;\n    float4 fa_inst_m1 : TEXCOORD5;\n    float4 fa_inst_m2 : TEXCOORD6;\n    float4 fa_inst_m3 : TEXCOORD7;\n    float4 fa_joints : TEXCOORD8;\n    float4 fa_weights : TEXCOORD9;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_shadow_pos : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _167 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_176_fa_joint_rows[_167] * weights[i]);\n        r1 += (_176_fa_joint_rows[_167 + 1] * weights[i]);\n        r2 += (_176_fa_joint_rows[_167 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0)\n{\n    float3 _70 = cross(model[1].xyz, model[2].xyz);\n    float _76 = (dot(model[0].xyz, _70) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _375 = { mul(float4(position, 1.0f), model).xyz, (((_70 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _76, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _76), texcoord0 * _132_fa_uv_scale.xy, position };\n    return _375;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    VertexData _264 = fa_vertex_data(param, param_1, param_2, param_3, param_4);\n    float3 _381 = _264.world_pos;\n    float4 _271 = float4(_381, 1.0f);\n    fa_world_pos = _381;\n    fa_world_normal = _264.world_normal;\n    fa_world_tangent = _264.world_tangent;\n    fa_uv = _264.uv;\n    fa_shadow_pos = mul(_271, _132_fa_light_vp);\n    gl_Position = mul(_271, _132_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _148_fa_camera_pos : packoffset(c0);\n    float4 _148_fa_ambient : packoffset(c1);\n    float4 _148_fa_base_color : packoffset(c2);\n    float4 _148_fa_emissive : packoffset(c3);\n    float4 _148_fa_model_emissive : packoffset(c4);\n    float4 _148_fa_pbr : packoffset(c5);\n    float4 _148_fa_maps : packoffset(c6);\n    float4 _148_fa_fog : packoffset(c7);\n    float4 _148_fa_counts : packoffset(c8);\n    float4 _148_fa_env_sky : packoffset(c9);\n    float4 _148_fa_env_horizon : packoffset(c10);\n    float4 _148_fa_time : packoffset(c11);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _561_alphaCutoff : packoffset(c0);\n    float _561_fa_pad0 : packoffset(c0.y);\n    float _561_fa_pad1 : packoffset(c0.z);\n    float _561_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _658_fa_light_pos[32] : packoffset(c0);\n    float4 _658_fa_light_color[32] : packoffset(c32);\n    float4 _658_fa_light_dir[32] : packoffset(c64);\n};\n\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_shadow_pos : TEXCOORD4;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _52;\n    if (i.front_facing)\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    float3 _77 = normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    float3 _105 = normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    float3 _108;\n    if (i.front_facing)\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 _145 = fa_tex.Sample(fa_smp, i.uv);\n    float4 _152 = _145 * _148_fa_base_color;\n    float3 _964 = i.world_normal;\n    if (_148_fa_maps.z > 0.5f)\n    {\n        float3 _184 = (fa_normal_tex.Sample(fa_smp, i.uv).xyz * 2.0f) - 1.0f.xxx;\n        float2 _189 = _184.xy * _148_fa_maps.x;\n        float3 _981 = _184;\n        _981.x = _189.x;\n        _981.y = _189.y;\n        SurfaceInput param = i;\n        float3 param_1 = _981;\n        _964 = fa_tangent_normal(param, param_1);\n    }\n    float4 _207 = fa_mr_tex.Sample(fa_smp, i.uv);\n    Surface _976 = { _152.xyz, _152.w, _964, clamp(_148_fa_pbr.x * _207.z, 0.0f, 1.0f), clamp(_148_fa_pbr.y * _207.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_148_fa_maps.y * (fa_occlusion_tex.Sample(fa_smp, i.uv).x - 1.0f)), _148_fa_emissive.xyz + (_148_fa_model_emissive.xyz * fa_emissive_tex.Sample(fa_smp, i.uv).xyz) };\n    return _976;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    if (_148_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _274 = fa_shadow_pos.xyz / fa_shadow_pos.w.xxx;\n    float3 p = _274;\n    float2 suv = (_274.xy * 0.5f) + 0.5f.xx;\n    if (_148_fa_counts.z > 0.5f)\n    {\n        float3 _986 = p;\n        _986.z = (_986.z * 0.5f) + 0.5f;\n        p = _986;\n    }\n    else\n    {\n        float2 _989 = suv;\n        _989.y = 1.0f - _989.y;\n        suv = _989;\n    }\n    bool _301 = suv.x < 0.0f;\n    bool _308;\n    if (!_301)\n    {\n        _308 = suv.x > 1.0f;\n    }\n    else\n    {\n        _308 = _301;\n    }\n    bool _315;\n    if (!_308)\n    {\n        _315 = suv.y < 0.0f;\n    }\n    else\n    {\n        _315 = _308;\n    }\n    bool _322;\n    if (!_315)\n    {\n        _322 = suv.y > 1.0f;\n    }\n    else\n    {\n        _322 = _315;\n    }\n    bool _329;\n    if (!_322)\n    {\n        _329 = p.z > 1.0f;\n    }\n    else\n    {\n        _329 = _322;\n    }\n    if (_329)\n    {\n        return 1.0f;\n    }\n    float _343 = _148_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _343) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _148_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _484 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _487 = _484.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_487 * _487, exp2((-9.27999973297119140625f) * ndv)) * _487) + _484.y)) + _484.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _404 = rough * rough;\n    float _437 = 0.60000002384185791015625f * _404;\n    return lerp(lerp(_148_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_148_fa_env_horizon.xyz, _148_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _404)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _437, 0.0500000007450580596923828125f + _437, d.y).xxx), ((_148_fa_env_sky.xyz + _148_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_404 * 0.60000002384185791015625f).xxx);\n}\n\nvoid frag_main()\n{\n    float3 _914 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _914 = -_914;\n    }\n    float3 _544 = _148_fa_camera_pos.xyz - fa_world_pos;\n    float3 _545 = normalize(_544);\n    SurfaceInput _925 = { fa_world_pos, _914, fa_world_tangent, fa_uv, _545, gl_FrontFacing };\n    SurfaceInput param = _925;\n    Surface _550 = fa_standard_surface(param);\n    float3 _933 = _550.albedo;\n    float _934 = _550.alpha;\n    float3 _935 = _550.normal;\n    float _936 = _550.metallic;\n    float _937 = _550.roughness;\n    float _938 = _550.occlusion;\n    float3 _939 = _550.emission;\n    SurfaceInput _932 = { fa_world_pos, _914, fa_world_tangent, fa_uv, _545, gl_FrontFacing };\n    SurfaceInput param_1 = _932;\n    Surface param_2 = _550;\n    surface(param_1, param_2);\n    _933 = param_2.albedo;\n    _934 = param_2.alpha;\n    _935 = param_2.normal;\n    _936 = param_2.metallic;\n    _937 = param_2.roughness;\n    _938 = param_2.occlusion;\n    _939 = param_2.emission;\n    if (param_2.alpha < _561_alphaCutoff)\n    {\n        discard;\n    }\n    float3 result;\n    if (_148_fa_emissive.w > 0.5f)\n    {\n        result = _933;\n    }\n    else\n    {\n        float3 _583 = normalize(_935);\n        float _590 = clamp(_936, 0.0f, 1.0f);\n        float _594 = clamp(_937, 0.0500000007450580596923828125f, 1.0f);\n        float _598 = _594 * _594;\n        float _602 = _598 * _598;\n        float _608 = max(dot(_583, _545), 9.9999997473787516355514526367188e-05f);\n        float3 _614 = _933 * (1.0f - _590);\n        float3 _622 = lerp(0.039999999105930328369140625f.xxx, _933, _590.xxx);\n        float3 lit = (_148_fa_ambient.xyz * _614) * _938;\n        int _635 = int(_148_fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _635)\n            {\n                break;\n            }\n            float atten = 1.0f;\n            bool _664 = _658_fa_light_color[li].w < 0.5f;\n            if (_664)\n            {\n                l = normalize(_658_fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _681 = _658_fa_light_pos[li].xyz - fa_world_pos;\n                float _684 = length(_681);\n                l = _681 / max(_684, 9.9999997473787516355514526367188e-05f).xxx;\n                float _699 = _684 / max(_658_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n                float _705 = clamp(1.0f - (_699 * _699), 0.0f, 1.0f);\n                atten = _705 * _705;\n                if (_658_fa_light_color[li].w > 1.5f)\n                {\n                    atten *= smoothstep(_658_fa_light_dir[li].w, lerp(_658_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_658_fa_light_dir[li].xyz)));\n                }\n            }\n            float _739 = max(dot(_583, l), 0.0f);\n            if (_664 && (li == 0))\n            {\n                float3 param_3 = _914;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            float3 _758 = normalize(l + _545);\n            float _763 = max(dot(_583, _758), 0.0f);\n            float _776 = ((_763 * _763) * (_602 - 1.0f)) + 1.0f;\n            lit += (((_614 + (((_622 + ((1.0f.xxx - _622) * pow(1.0f - max(dot(_545, _758), 0.0f), 5.0f))) * (((_602 / ((3.1415927410125732421875f * _776) * _776)) * (0.5f / max(lerp((2.0f * _739) * _608, _739 + _608, _598), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _739))) * _658_fa_light_color[li].xyz) * (_739 * atten));\n        }\n        float param_5 = _594;\n        float param_6 = _608;\n        float2 _844 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_545, _583);\n        float param_8 = _594;\n        float3 _862 = lit;\n        float3 _863 = _862 + ((fa_environment(param_7, param_8) * ((_622 * _844.x) + _844.y.xxx)) * _938);\n        lit = _863;\n        result = _863;\n    }\n    result += _939;\n    if (_148_fa_fog.w > 0.0f)\n    {\n        float _887 = _148_fa_fog.w * length(_544);\n        result = lerp(result, _148_fa_fog.xyz, clamp(1.0f - exp((-_887) * _887), 0.0f, 1.0f).xxx);\n    }\n    fa_frag_color = float4(result, _934);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_132",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_176",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_148",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_561",
            "hlsl_register_b_n": 5
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_658",
            "hlsl_register_b_n": 2
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
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 6
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          },
          {
            "slot": 6,
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
    "shadow": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _119_fa_view_proj : packoffset(c0);\n    row_major float4x4 _119_fa_light_vp : packoffset(c4);\n    float4 _119_fa_uv_scale : packoffset(c8);\n    float4 _119_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 gl_Position : SV_Position;\n};\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0)\n{\n    float3 _57 = cross(model[1].xyz, model[2].xyz);\n    float _63 = (dot(model[0].xyz, _57) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _239 = { mul(float4(position, 1.0f), model).xyz, (((_57 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _63, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _63), texcoord0 * _119_fa_uv_scale.xy, position };\n    return _239;\n}\n\nvoid vert_main()\n{\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    VertexData _180 = fa_vertex_data(param, param_1, param_2, param_3, param_4);\n    float3 _225 = _180.world_pos;\n    fa_world_pos = _225;\n    fa_world_normal = _180.world_normal;\n    fa_world_tangent = _180.world_tangent;\n    fa_uv = _180.uv;\n    gl_Position = mul(float4(_225, 1.0f), _119_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _133_fa_camera_pos : packoffset(c0);\n    float4 _133_fa_ambient : packoffset(c1);\n    float4 _133_fa_base_color : packoffset(c2);\n    float4 _133_fa_emissive : packoffset(c3);\n    float4 _133_fa_model_emissive : packoffset(c4);\n    float4 _133_fa_pbr : packoffset(c5);\n    float4 _133_fa_maps : packoffset(c6);\n    float4 _133_fa_fog : packoffset(c7);\n    float4 _133_fa_counts : packoffset(c8);\n    float4 _133_fa_env_sky : packoffset(c9);\n    float4 _133_fa_env_horizon : packoffset(c10);\n    float4 _133_fa_time : packoffset(c11);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _295_alphaCutoff : packoffset(c0);\n    float _295_fa_pad0 : packoffset(c0.y);\n    float _295_fa_pad1 : packoffset(c0.z);\n    float _295_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _36;\n    if (i.front_facing)\n    {\n        _36 = i.world_normal;\n    }\n    else\n    {\n        _36 = -i.world_normal;\n    }\n    float3 _61 = normalize(i.world_tangent.xyz - (_36 * dot(_36, i.world_tangent.xyz)));\n    float3 _90 = normalize(((_61 * m.x) + ((cross(_36, _61) * i.world_tangent.w) * m.y)) + (_36 * m.z));\n    float3 _93;\n    if (i.front_facing)\n    {\n        _93 = _90;\n    }\n    else\n    {\n        _93 = -_90;\n    }\n    return _93;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 _130 = fa_tex.Sample(fa_smp, i.uv);\n    float4 _137 = _130 * _133_fa_base_color;\n    float3 _362 = i.world_normal;\n    if (_133_fa_maps.z > 0.5f)\n    {\n        float3 _169 = (fa_normal_tex.Sample(fa_smp, i.uv).xyz * 2.0f) - 1.0f.xxx;\n        float2 _174 = _169.xy * _133_fa_maps.x;\n        float3 _377 = _169;\n        _377.x = _174.x;\n        _377.y = _174.y;\n        SurfaceInput param = i;\n        float3 param_1 = _377;\n        _362 = fa_tangent_normal(param, param_1);\n    }\n    float4 _192 = fa_mr_tex.Sample(fa_smp, i.uv);\n    Surface _374 = { _137.xyz, _137.w, _362, clamp(_133_fa_pbr.x * _192.z, 0.0f, 1.0f), clamp(_133_fa_pbr.y * _192.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_133_fa_maps.y * (fa_occlusion_tex.Sample(fa_smp, i.uv).x - 1.0f)), _133_fa_emissive.xyz + (_133_fa_model_emissive.xyz * fa_emissive_tex.Sample(fa_smp, i.uv).xyz) };\n    return _374;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    float3 _312 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _312 = -_312;\n    }\n    float3 _279 = normalize(_133_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _323 = { fa_world_pos, _312, fa_world_tangent, fa_uv, _279, gl_FrontFacing };\n    SurfaceInput param = _323;\n    SurfaceInput _330 = { fa_world_pos, _312, fa_world_tangent, fa_uv, _279, gl_FrontFacing };\n    SurfaceInput param_1 = _330;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _295_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_119",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_133",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_295",
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
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _124_fa_view_proj : packoffset(c0);\n    row_major float4x4 _124_fa_light_vp : packoffset(c4);\n    float4 _124_fa_uv_scale : packoffset(c8);\n    float4 _124_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _168_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _159 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_168_fa_joint_rows[_159] * weights[i]);\n        r1 += (_168_fa_joint_rows[_159 + 1] * weights[i]);\n        r2 += (_168_fa_joint_rows[_159 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0)\n{\n    float3 _62 = cross(model[1].xyz, model[2].xyz);\n    float _68 = (dot(model[0].xyz, _62) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _360 = { mul(float4(position, 1.0f), model).xyz, (((_62 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _68, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _68), texcoord0 * _124_fa_uv_scale.xy, position };\n    return _360;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    VertexData _301 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6);\n    float3 _346 = _301.world_pos;\n    fa_world_pos = _346;\n    fa_world_normal = _301.world_normal;\n    fa_world_tangent = _301.world_tangent;\n    fa_uv = _301.uv;\n    gl_Position = mul(float4(_346, 1.0f), _124_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _133_fa_camera_pos : packoffset(c0);\n    float4 _133_fa_ambient : packoffset(c1);\n    float4 _133_fa_base_color : packoffset(c2);\n    float4 _133_fa_emissive : packoffset(c3);\n    float4 _133_fa_model_emissive : packoffset(c4);\n    float4 _133_fa_pbr : packoffset(c5);\n    float4 _133_fa_maps : packoffset(c6);\n    float4 _133_fa_fog : packoffset(c7);\n    float4 _133_fa_counts : packoffset(c8);\n    float4 _133_fa_env_sky : packoffset(c9);\n    float4 _133_fa_env_horizon : packoffset(c10);\n    float4 _133_fa_time : packoffset(c11);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _295_alphaCutoff : packoffset(c0);\n    float _295_fa_pad0 : packoffset(c0.y);\n    float _295_fa_pad1 : packoffset(c0.z);\n    float _295_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _36;\n    if (i.front_facing)\n    {\n        _36 = i.world_normal;\n    }\n    else\n    {\n        _36 = -i.world_normal;\n    }\n    float3 _61 = normalize(i.world_tangent.xyz - (_36 * dot(_36, i.world_tangent.xyz)));\n    float3 _90 = normalize(((_61 * m.x) + ((cross(_36, _61) * i.world_tangent.w) * m.y)) + (_36 * m.z));\n    float3 _93;\n    if (i.front_facing)\n    {\n        _93 = _90;\n    }\n    else\n    {\n        _93 = -_90;\n    }\n    return _93;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 _130 = fa_tex.Sample(fa_smp, i.uv);\n    float4 _137 = _130 * _133_fa_base_color;\n    float3 _362 = i.world_normal;\n    if (_133_fa_maps.z > 0.5f)\n    {\n        float3 _169 = (fa_normal_tex.Sample(fa_smp, i.uv).xyz * 2.0f) - 1.0f.xxx;\n        float2 _174 = _169.xy * _133_fa_maps.x;\n        float3 _377 = _169;\n        _377.x = _174.x;\n        _377.y = _174.y;\n        SurfaceInput param = i;\n        float3 param_1 = _377;\n        _362 = fa_tangent_normal(param, param_1);\n    }\n    float4 _192 = fa_mr_tex.Sample(fa_smp, i.uv);\n    Surface _374 = { _137.xyz, _137.w, _362, clamp(_133_fa_pbr.x * _192.z, 0.0f, 1.0f), clamp(_133_fa_pbr.y * _192.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_133_fa_maps.y * (fa_occlusion_tex.Sample(fa_smp, i.uv).x - 1.0f)), _133_fa_emissive.xyz + (_133_fa_model_emissive.xyz * fa_emissive_tex.Sample(fa_smp, i.uv).xyz) };\n    return _374;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    float3 _312 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _312 = -_312;\n    }\n    float3 _279 = normalize(_133_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _323 = { fa_world_pos, _312, fa_world_tangent, fa_uv, _279, gl_FrontFacing };\n    SurfaceInput param = _323;\n    SurfaceInput _330 = { fa_world_pos, _312, fa_world_tangent, fa_uv, _279, gl_FrontFacing };\n    SurfaceInput param_1 = _330;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _295_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_124",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_168",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_133",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_295",
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
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    }
  }
}
