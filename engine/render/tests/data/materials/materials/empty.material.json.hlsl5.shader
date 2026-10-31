{
  "format": "factoria.shader/1",
  "engine": "0.1.6",
  "template": "a75dcd870d51444499f61f3cb2010a1b06d96d8916439ce459176478546f3cd8",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _129_fa_view_proj : packoffset(c0);\n    row_major float4x4 _129_fa_light_vp : packoffset(c4);\n    float4 _129_fa_uv_scale : packoffset(c8);\n    float4 _129_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _67 = cross(model[1].xyz, model[2].xyz);\n    float _73 = (dot(model[0].xyz, _67) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_67 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _73, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _73), texcoord0 * _129_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _158 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _158.world_pos;\n    float4 _165 = float4(_267, 1.0f);\n    fa_world_pos = _267;\n    fa_world_normal = _158.world_normal;\n    fa_world_tangent = _158.world_tangent;\n    fa_uv = _158.uv;\n    fa_vertex_color = _158.color;\n    fa_shadow_pos = mul(_165, _129_fa_light_vp);\n    gl_Position = mul(_165, _129_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _136_fa_camera_pos : packoffset(c0);\n    float4 _136_fa_ambient : packoffset(c1);\n    float4 _136_fa_base_color : packoffset(c2);\n    float4 _136_fa_emissive : packoffset(c3);\n    float4 _136_fa_model_emissive : packoffset(c4);\n    float4 _136_fa_pbr : packoffset(c5);\n    float4 _136_fa_maps : packoffset(c6);\n    float4 _136_fa_fog : packoffset(c7);\n    float4 _136_fa_counts : packoffset(c8);\n    float4 _136_fa_env_sky : packoffset(c9);\n    float4 _136_fa_env_horizon : packoffset(c10);\n    float4 _136_fa_time : packoffset(c11);\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _642_fa_light_pos[32] : packoffset(c0);\n    float4 _642_fa_light_color[32] : packoffset(c32);\n    float4 _642_fa_light_dir[32] : packoffset(c64);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _52;\n    if (i.front_facing)\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    float3 _77 = normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    float3 _105 = normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    float3 _108;\n    if (i.front_facing)\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 _133 = fa_tex.Sample(fa_smp, i.uv);\n    float4 _144 = (_133 * _136_fa_base_color) * i.vertex_color;\n    float3 _951 = i.world_normal;\n    if (_136_fa_maps.z > 0.5f)\n    {\n        float3 _176 = (fa_normal_tex.Sample(fa_smp, i.uv).xyz * 2.0f) - 1.0f.xxx;\n        float2 _181 = _176.xy * _136_fa_maps.x;\n        float3 _968 = _176;\n        _968.x = _181.x;\n        _968.y = _181.y;\n        SurfaceInput param = i;\n        float3 param_1 = _968;\n        _951 = fa_tangent_normal(param, param_1);\n    }\n    float4 _199 = fa_mr_tex.Sample(fa_smp, i.uv);\n    Surface _963 = { _144.xyz, _144.w, _951, clamp(_136_fa_pbr.x * _199.z, 0.0f, 1.0f), clamp(_136_fa_pbr.y * _199.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_136_fa_maps.y * (fa_occlusion_tex.Sample(fa_smp, i.uv).x - 1.0f)), _136_fa_emissive.xyz + (_136_fa_model_emissive.xyz * fa_emissive_tex.Sample(fa_smp, i.uv).xyz) };\n    return _963;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    if (_136_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _266 = fa_shadow_pos.xyz / fa_shadow_pos.w.xxx;\n    float3 p = _266;\n    float2 suv = (_266.xy * 0.5f) + 0.5f.xx;\n    if (_136_fa_counts.z > 0.5f)\n    {\n        float3 _973 = p;\n        _973.z = (_973.z * 0.5f) + 0.5f;\n        p = _973;\n    }\n    else\n    {\n        float2 _976 = suv;\n        _976.y = 1.0f - _976.y;\n        suv = _976;\n    }\n    bool _293 = suv.x < 0.0f;\n    bool _300;\n    if (!_293)\n    {\n        _300 = suv.x > 1.0f;\n    }\n    else\n    {\n        _300 = _293;\n    }\n    bool _307;\n    if (!_300)\n    {\n        _307 = suv.y < 0.0f;\n    }\n    else\n    {\n        _307 = _300;\n    }\n    bool _314;\n    if (!_307)\n    {\n        _314 = suv.y > 1.0f;\n    }\n    else\n    {\n        _314 = _307;\n    }\n    bool _321;\n    if (!_314)\n    {\n        _321 = p.z > 1.0f;\n    }\n    else\n    {\n        _321 = _314;\n    }\n    if (_321)\n    {\n        return 1.0f;\n    }\n    float _335 = _136_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _335) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _136_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _476 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _479 = _476.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_479 * _479, exp2((-9.27999973297119140625f) * ndv)) * _479) + _476.y)) + _476.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _396 = rough * rough;\n    float _429 = 0.60000002384185791015625f * _396;\n    return lerp(lerp(_136_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_136_fa_env_horizon.xyz, _136_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _396)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _429, 0.0500000007450580596923828125f + _429, d.y).xxx), ((_136_fa_env_sky.xyz + _136_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_396 * 0.60000002384185791015625f).xxx);\n}\n\nvoid frag_main()\n{\n    float3 _898 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _898 = -_898;\n    }\n    float3 _539 = _136_fa_camera_pos.xyz - fa_world_pos;\n    float3 _540 = normalize(_539);\n    SurfaceInput _911 = { fa_world_pos, _898, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing };\n    SurfaceInput param = _911;\n    Surface _545 = fa_standard_surface(param);\n    float3 _920 = _545.albedo;\n    float _921 = _545.alpha;\n    float3 _922 = _545.normal;\n    float _923 = _545.metallic;\n    float _924 = _545.roughness;\n    float _925 = _545.occlusion;\n    float3 _926 = _545.emission;\n    SurfaceInput _919 = { fa_world_pos, _898, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing };\n    SurfaceInput param_1 = _919;\n    Surface param_2 = _545;\n    surface(param_1, param_2);\n    _920 = param_2.albedo;\n    _921 = param_2.alpha;\n    _922 = param_2.normal;\n    _923 = param_2.metallic;\n    _924 = param_2.roughness;\n    _925 = param_2.occlusion;\n    _926 = param_2.emission;\n    float3 result;\n    if (_136_fa_emissive.w > 0.5f)\n    {\n        result = _920;\n    }\n    else\n    {\n        float3 _567 = normalize(_922);\n        float _574 = clamp(_923, 0.0f, 1.0f);\n        float _578 = clamp(_924, 0.0500000007450580596923828125f, 1.0f);\n        float _582 = _578 * _578;\n        float _586 = _582 * _582;\n        float _592 = max(dot(_567, _540), 9.9999997473787516355514526367188e-05f);\n        float3 _598 = _920 * (1.0f - _574);\n        float3 _606 = lerp(0.039999999105930328369140625f.xxx, _920, _574.xxx);\n        float3 lit = (_136_fa_ambient.xyz * _598) * _925;\n        int _619 = int(_136_fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _619)\n            {\n                break;\n            }\n            float atten = 1.0f;\n            bool _648 = _642_fa_light_color[li].w < 0.5f;\n            if (_648)\n            {\n                l = normalize(_642_fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _665 = _642_fa_light_pos[li].xyz - fa_world_pos;\n                float _668 = length(_665);\n                l = _665 / max(_668, 9.9999997473787516355514526367188e-05f).xxx;\n                float _683 = _668 / max(_642_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n                float _689 = clamp(1.0f - (_683 * _683), 0.0f, 1.0f);\n                atten = _689 * _689;\n                if (_642_fa_light_color[li].w > 1.5f)\n                {\n                    atten *= smoothstep(_642_fa_light_dir[li].w, lerp(_642_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_642_fa_light_dir[li].xyz)));\n                }\n            }\n            float _723 = max(dot(_567, l), 0.0f);\n            if (_648 && (li == 0))\n            {\n                float3 param_3 = _898;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            float3 _742 = normalize(l + _540);\n            float _747 = max(dot(_567, _742), 0.0f);\n            float _760 = ((_747 * _747) * (_586 - 1.0f)) + 1.0f;\n            lit += (((_598 + (((_606 + ((1.0f.xxx - _606) * pow(1.0f - max(dot(_540, _742), 0.0f), 5.0f))) * (((_586 / ((3.1415927410125732421875f * _760) * _760)) * (0.5f / max(lerp((2.0f * _723) * _592, _723 + _592, _582), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _723))) * _642_fa_light_color[li].xyz) * (_723 * atten));\n        }\n        float param_5 = _578;\n        float param_6 = _592;\n        float2 _828 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_540, _567);\n        float param_8 = _578;\n        float3 _846 = lit;\n        float3 _847 = _846 + ((fa_environment(param_7, param_8) * ((_606 * _828.x) + _828.y.xxx)) * _925);\n        lit = _847;\n        result = _847;\n    }\n    result += _926;\n    if (_136_fa_fog.w > 0.0f)\n    {\n        float _871 = _136_fa_fog.w * length(_539);\n        result = lerp(result, _136_fa_fog.xyz, clamp(1.0f - exp((-_871) * _871), 0.0f, 1.0f).xxx);\n    }\n    fa_frag_color = float4(result, _921);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_129",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_136",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_642",
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
          }
        ],
        "samplers": [
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _134_fa_view_proj : packoffset(c0);\n    row_major float4x4 _134_fa_light_vp : packoffset(c4);\n    float4 _134_fa_uv_scale : packoffset(c8);\n    float4 _134_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _181_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _172 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_181_fa_joint_rows[_172] * weights[i]);\n        r1 += (_181_fa_joint_rows[_172 + 1] * weights[i]);\n        r2 += (_181_fa_joint_rows[_172 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _72 = cross(model[1].xyz, model[2].xyz);\n    float _78 = (dot(model[0].xyz, _72) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _381 = { mul(float4(position, 1.0f), model).xyz, (((_72 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _78, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _78), texcoord0 * _134_fa_uv_scale.xy, color, position };\n    return _381;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _271 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _388 = _271.world_pos;\n    float4 _278 = float4(_388, 1.0f);\n    fa_world_pos = _388;\n    fa_world_normal = _271.world_normal;\n    fa_world_tangent = _271.world_tangent;\n    fa_uv = _271.uv;\n    fa_vertex_color = _271.color;\n    fa_shadow_pos = mul(_278, _134_fa_light_vp);\n    gl_Position = mul(_278, _134_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _136_fa_camera_pos : packoffset(c0);\n    float4 _136_fa_ambient : packoffset(c1);\n    float4 _136_fa_base_color : packoffset(c2);\n    float4 _136_fa_emissive : packoffset(c3);\n    float4 _136_fa_model_emissive : packoffset(c4);\n    float4 _136_fa_pbr : packoffset(c5);\n    float4 _136_fa_maps : packoffset(c6);\n    float4 _136_fa_fog : packoffset(c7);\n    float4 _136_fa_counts : packoffset(c8);\n    float4 _136_fa_env_sky : packoffset(c9);\n    float4 _136_fa_env_horizon : packoffset(c10);\n    float4 _136_fa_time : packoffset(c11);\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _642_fa_light_pos[32] : packoffset(c0);\n    float4 _642_fa_light_color[32] : packoffset(c32);\n    float4 _642_fa_light_dir[32] : packoffset(c64);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _52;\n    if (i.front_facing)\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    float3 _77 = normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    float3 _105 = normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    float3 _108;\n    if (i.front_facing)\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 _133 = fa_tex.Sample(fa_smp, i.uv);\n    float4 _144 = (_133 * _136_fa_base_color) * i.vertex_color;\n    float3 _951 = i.world_normal;\n    if (_136_fa_maps.z > 0.5f)\n    {\n        float3 _176 = (fa_normal_tex.Sample(fa_smp, i.uv).xyz * 2.0f) - 1.0f.xxx;\n        float2 _181 = _176.xy * _136_fa_maps.x;\n        float3 _968 = _176;\n        _968.x = _181.x;\n        _968.y = _181.y;\n        SurfaceInput param = i;\n        float3 param_1 = _968;\n        _951 = fa_tangent_normal(param, param_1);\n    }\n    float4 _199 = fa_mr_tex.Sample(fa_smp, i.uv);\n    Surface _963 = { _144.xyz, _144.w, _951, clamp(_136_fa_pbr.x * _199.z, 0.0f, 1.0f), clamp(_136_fa_pbr.y * _199.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_136_fa_maps.y * (fa_occlusion_tex.Sample(fa_smp, i.uv).x - 1.0f)), _136_fa_emissive.xyz + (_136_fa_model_emissive.xyz * fa_emissive_tex.Sample(fa_smp, i.uv).xyz) };\n    return _963;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    if (_136_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _266 = fa_shadow_pos.xyz / fa_shadow_pos.w.xxx;\n    float3 p = _266;\n    float2 suv = (_266.xy * 0.5f) + 0.5f.xx;\n    if (_136_fa_counts.z > 0.5f)\n    {\n        float3 _973 = p;\n        _973.z = (_973.z * 0.5f) + 0.5f;\n        p = _973;\n    }\n    else\n    {\n        float2 _976 = suv;\n        _976.y = 1.0f - _976.y;\n        suv = _976;\n    }\n    bool _293 = suv.x < 0.0f;\n    bool _300;\n    if (!_293)\n    {\n        _300 = suv.x > 1.0f;\n    }\n    else\n    {\n        _300 = _293;\n    }\n    bool _307;\n    if (!_300)\n    {\n        _307 = suv.y < 0.0f;\n    }\n    else\n    {\n        _307 = _300;\n    }\n    bool _314;\n    if (!_307)\n    {\n        _314 = suv.y > 1.0f;\n    }\n    else\n    {\n        _314 = _307;\n    }\n    bool _321;\n    if (!_314)\n    {\n        _321 = p.z > 1.0f;\n    }\n    else\n    {\n        _321 = _314;\n    }\n    if (_321)\n    {\n        return 1.0f;\n    }\n    float _335 = _136_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _335) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _136_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _476 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _479 = _476.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_479 * _479, exp2((-9.27999973297119140625f) * ndv)) * _479) + _476.y)) + _476.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _396 = rough * rough;\n    float _429 = 0.60000002384185791015625f * _396;\n    return lerp(lerp(_136_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_136_fa_env_horizon.xyz, _136_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _396)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _429, 0.0500000007450580596923828125f + _429, d.y).xxx), ((_136_fa_env_sky.xyz + _136_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_396 * 0.60000002384185791015625f).xxx);\n}\n\nvoid frag_main()\n{\n    float3 _898 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _898 = -_898;\n    }\n    float3 _539 = _136_fa_camera_pos.xyz - fa_world_pos;\n    float3 _540 = normalize(_539);\n    SurfaceInput _911 = { fa_world_pos, _898, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing };\n    SurfaceInput param = _911;\n    Surface _545 = fa_standard_surface(param);\n    float3 _920 = _545.albedo;\n    float _921 = _545.alpha;\n    float3 _922 = _545.normal;\n    float _923 = _545.metallic;\n    float _924 = _545.roughness;\n    float _925 = _545.occlusion;\n    float3 _926 = _545.emission;\n    SurfaceInput _919 = { fa_world_pos, _898, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing };\n    SurfaceInput param_1 = _919;\n    Surface param_2 = _545;\n    surface(param_1, param_2);\n    _920 = param_2.albedo;\n    _921 = param_2.alpha;\n    _922 = param_2.normal;\n    _923 = param_2.metallic;\n    _924 = param_2.roughness;\n    _925 = param_2.occlusion;\n    _926 = param_2.emission;\n    float3 result;\n    if (_136_fa_emissive.w > 0.5f)\n    {\n        result = _920;\n    }\n    else\n    {\n        float3 _567 = normalize(_922);\n        float _574 = clamp(_923, 0.0f, 1.0f);\n        float _578 = clamp(_924, 0.0500000007450580596923828125f, 1.0f);\n        float _582 = _578 * _578;\n        float _586 = _582 * _582;\n        float _592 = max(dot(_567, _540), 9.9999997473787516355514526367188e-05f);\n        float3 _598 = _920 * (1.0f - _574);\n        float3 _606 = lerp(0.039999999105930328369140625f.xxx, _920, _574.xxx);\n        float3 lit = (_136_fa_ambient.xyz * _598) * _925;\n        int _619 = int(_136_fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _619)\n            {\n                break;\n            }\n            float atten = 1.0f;\n            bool _648 = _642_fa_light_color[li].w < 0.5f;\n            if (_648)\n            {\n                l = normalize(_642_fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _665 = _642_fa_light_pos[li].xyz - fa_world_pos;\n                float _668 = length(_665);\n                l = _665 / max(_668, 9.9999997473787516355514526367188e-05f).xxx;\n                float _683 = _668 / max(_642_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n                float _689 = clamp(1.0f - (_683 * _683), 0.0f, 1.0f);\n                atten = _689 * _689;\n                if (_642_fa_light_color[li].w > 1.5f)\n                {\n                    atten *= smoothstep(_642_fa_light_dir[li].w, lerp(_642_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_642_fa_light_dir[li].xyz)));\n                }\n            }\n            float _723 = max(dot(_567, l), 0.0f);\n            if (_648 && (li == 0))\n            {\n                float3 param_3 = _898;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            float3 _742 = normalize(l + _540);\n            float _747 = max(dot(_567, _742), 0.0f);\n            float _760 = ((_747 * _747) * (_586 - 1.0f)) + 1.0f;\n            lit += (((_598 + (((_606 + ((1.0f.xxx - _606) * pow(1.0f - max(dot(_540, _742), 0.0f), 5.0f))) * (((_586 / ((3.1415927410125732421875f * _760) * _760)) * (0.5f / max(lerp((2.0f * _723) * _592, _723 + _592, _582), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _723))) * _642_fa_light_color[li].xyz) * (_723 * atten));\n        }\n        float param_5 = _578;\n        float param_6 = _592;\n        float2 _828 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_540, _567);\n        float param_8 = _578;\n        float3 _846 = lit;\n        float3 _847 = _846 + ((fa_environment(param_7, param_8) * ((_606 * _828.x) + _828.y.xxx)) * _925);\n        lit = _847;\n        result = _847;\n    }\n    result += _926;\n    if (_136_fa_fog.w > 0.0f)\n    {\n        float _871 = _136_fa_fog.w * length(_539);\n        result = lerp(result, _136_fa_fog.xyz, clamp(1.0f - exp((-_871) * _871), 0.0f, 1.0f).xxx);\n    }\n    fa_frag_color = float4(result, _921);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_134",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_181",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_136",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_642",
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
          }
        ],
        "samplers": [
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    }
  }
}
