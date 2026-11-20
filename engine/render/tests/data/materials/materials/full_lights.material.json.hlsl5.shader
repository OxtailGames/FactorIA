{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "2b1d34c4081522ff96f7837c5aacca244600e83b6880b1a4b151f4ef1649850c",
  "slang": "hlsl5",
  "params": [
    "base"
  ],
  "textures": [],
  "full": true,
  "shadow": "none",
  "prepass": false,
  "passes": [
    {
      "name": "main",
      "cull": "back",
      "depthTest": true,
      "depthWrite": true,
      "blend": "none",
      "program": "mesh",
      "programSkin": "mesh_skin"
    }
  ],
  "programs": {
    "mesh": {
      "vs": "cbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _99_fa_view_proj : packoffset(c0);\n    row_major float4x4 _99_fa_light_vp : packoffset(c4);\n    float4 _99_fa_uv_scale : packoffset(c8);\n    float4 _99_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_position;\nstatic float3 v_pos;\nstatic float3 v_normal;\nstatic float3 fa_normal;\nstatic float4 v_shadow;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float2 fa_texcoord0;\nstatic float4 fa_tangent;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 v_shadow : TEXCOORD2;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4x4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat3 fa_world_position(float3 p)\n{\n    return mul(float4(p, 1.0f), fa_model).xyz;\n}\n\nfloat3 fa_world_direction(float3 n)\n{\n    float3 _61 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_61 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _61) < 0.0f) ? (-1.0f) : 1.0f));\n}\n\nfloat4 fa_shadow_coord(float3 world)\n{\n    return mul(float4(world, 1.0f), _99_fa_light_vp);\n}\n\nvoid fa_user_main()\n{\n    float3 param = fa_position;\n    float3 _116 = fa_world_position(param);\n    v_pos = _116;\n    float3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    float3 param_2 = _116;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = mul(float4(_116, 1.0f), _99_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    fa_model = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_tangent = stage_input.fa_tangent;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.v_pos = v_pos;\n    stage_output.v_normal = v_normal;\n    stage_output.v_shadow = v_shadow;\n    return stage_output;\n}\n",
      "fs": "struct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _58_fa_light_pos[32] : packoffset(c0);\n    float4 _58_fa_light_color[32] : packoffset(c32);\n    float4 _58_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _180_fa_camera_pos : packoffset(c0);\n    float4 _180_fa_ambient : packoffset(c1);\n    float4 _180_fa_base_color : packoffset(c2);\n    float4 _180_fa_emissive : packoffset(c3);\n    float4 _180_fa_model_emissive : packoffset(c4);\n    float4 _180_fa_pbr : packoffset(c5);\n    float4 _180_fa_maps : packoffset(c6);\n    float4 _180_fa_fog : packoffset(c7);\n    float4 _180_fa_fog_b : packoffset(c8);\n    float4 _180_fa_fog_c : packoffset(c9);\n    float4 _180_fa_counts : packoffset(c10);\n    float4 _180_fa_env_sky : packoffset(c11);\n    float4 _180_fa_env_horizon : packoffset(c12);\n    float4 _180_fa_time : packoffset(c13);\n    float4 _180_fa_layers_a : packoffset(c14);\n    float4 _180_fa_layers_b : packoffset(c15);\n    float4 _180_fa_layers_c : packoffset(c16);\n    float4 _180_fa_layers_d : packoffset(c17);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _631_base : packoffset(c0);\n};\n\nTexture2D<float4> fa_full_shadow_tex : register(t0);\nSamplerState fa_full_shadow_smp : register(s1);\n\nstatic float3 v_normal;\nstatic float3 v_pos;\nstatic float4 v_shadow;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 v_shadow : TEXCOORD2;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(_180_fa_counts.x), 32);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _72 = _58_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_72)\n    {\n        l = normalize(_58_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _90 = _58_fa_light_pos[li].xyz - world_pos;\n        float _92 = length(_90);\n        dist = _92;\n        l = _90 / max(_92, 9.9999997473787516355514526367188e-05f).xxx;\n        float _108 = _92 / max(_58_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _114 = clamp(1.0f - (_108 * _108), 0.0f, 1.0f);\n        atten = _114 * _114;\n        if (_58_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_58_fa_light_dir[li].w, lerp(_58_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_58_fa_light_dir[li].xyz)));\n        }\n    }\n    int _166;\n    if (_72)\n    {\n        _166 = 0;\n    }\n    else\n    {\n        _166 = (_58_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _706 = { l, _58_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _166 };\n    return _706;\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_180_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _194 = coord.xyz / coord.w.xxx;\n    float3 p = _194;\n    float2 suv = (_194.xy * 0.5f) + 0.5f.xx;\n    if (_180_fa_counts.z > 0.5f)\n    {\n        float3 _732 = p;\n        _732.z = (_732.z * 0.5f) + 0.5f;\n        p = _732;\n    }\n    else\n    {\n        float2 _735 = suv;\n        _735.y = 1.0f - _735.y;\n        suv = _735;\n    }\n    bool _226 = suv.x < 0.0f;\n    bool _233;\n    if (!_226)\n    {\n        _233 = suv.x > 1.0f;\n    }\n    else\n    {\n        _233 = _226;\n    }\n    bool _240;\n    if (!_233)\n    {\n        _240 = suv.y < 0.0f;\n    }\n    else\n    {\n        _240 = _233;\n    }\n    bool _247;\n    if (!_240)\n    {\n        _247 = suv.y > 1.0f;\n    }\n    else\n    {\n        _247 = _240;\n    }\n    bool _254;\n    if (!_247)\n    {\n        _254 = p.z > 1.0f;\n    }\n    else\n    {\n        _254 = _247;\n    }\n    if (_254)\n    {\n        return 1.0f;\n    }\n    float _269 = _180_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _269) <= fa_full_shadow_tex.SampleLevel(fa_full_shadow_smp, suv + (float2(float(ix), float(iy)) * _180_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow(float4 coord, float3 n, float3 l)\n{\n    float4 param = coord;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light(int li, float3 world_pos, float3 gn, float4 coord)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _352 = fa_light_sample(param, param_1);\n    float3 _713 = _352.direction;\n    float3 _708 = _352.color;\n    float _715 = _352.attenuation;\n    float _710 = _352.shadow;\n    int _718 = _352.type;\n    if ((_718 == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _713;\n        float _368 = fa_shadow(param_2, param_3, param_4);\n        _710 = _368;\n        _708 = _58_fa_light_color[li].xyz * (_715 * _368);\n    }\n    LightSample _725 = { _713, _708, _715, _710, _352._distance, _718 };\n    return _725;\n}\n\nfloat3 fa_apply_fog(inout float3 result, float3 world_pos)\n{\n    bool _387 = _180_fa_fog.w > 0.0f;\n    bool _395;\n    if (!_387)\n    {\n        _395 = _180_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _395 = _387;\n    }\n    if (_395)\n    {\n        float3 _403 = world_pos - _180_fa_camera_pos.xyz;\n        float _410 = dot(_403, _180_fa_fog_c.xyz);\n        bool _414 = _180_fa_fog_c.w > 0.5f;\n        float _415;\n        if (_414)\n        {\n            _415 = _410;\n        }\n        else\n        {\n            _415 = length(_403);\n        }\n        float _427 = _415 - _180_fa_fog_b.x;\n        if (_427 > 0.0f)\n        {\n            float _436 = _180_fa_fog.w * _427;\n            float tau = _436 * _436;\n            if (_180_fa_fog_b.y > 0.0f)\n            {\n                float _452;\n                if (_414)\n                {\n                    _452 = world_pos.y - (_180_fa_fog_c.y * _410);\n                }\n                else\n                {\n                    _452 = _180_fa_camera_pos.y;\n                }\n                float _473 = lerp(_452, world_pos.y, clamp(_180_fa_fog_b.x / _415, 0.0f, 1.0f));\n                float _477 = world_pos.y - _473;\n                float _482 = _473 - _180_fa_fog_b.z;\n                float _487 = world_pos.y - _180_fa_fog_b.z;\n                bool _490 = _482 <= 0.0f;\n                bool _491 = !_490;\n                bool _497;\n                if (_491)\n                {\n                    _497 = _180_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _497 = _490;\n                }\n                float _498;\n                if (_497)\n                {\n                    _498 = _180_fa_fog_b.y;\n                }\n                else\n                {\n                    _498 = _180_fa_fog_b.y * exp(-min(_180_fa_fog_b.w * _482, 80.0f));\n                }\n                bool _525;\n                if (_491)\n                {\n                    _525 = _180_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _525 = _490;\n                }\n                float _526;\n                if (_525)\n                {\n                    _526 = _180_fa_fog_b.y * _482;\n                }\n                else\n                {\n                    _526 = (_180_fa_fog_b.y * (1.0f - exp(-min(_180_fa_fog_b.w * _482, 80.0f)))) / _180_fa_fog_b.w;\n                }\n                bool _551 = _487 <= 0.0f;\n                bool _558;\n                if (!_551)\n                {\n                    _558 = _180_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _558 = _551;\n                }\n                float _559;\n                if (_558)\n                {\n                    _559 = _180_fa_fog_b.y * _487;\n                }\n                else\n                {\n                    _559 = (_180_fa_fog_b.y * (1.0f - exp(-min(_180_fa_fog_b.w * _487, 80.0f)))) / _180_fa_fog_b.w;\n                }\n                float _586;\n                if (abs(_477) < 0.001000000047497451305389404296875f)\n                {\n                    _586 = _498;\n                }\n                else\n                {\n                    _586 = (_559 - _526) / _477;\n                }\n                tau += (_427 * max(_586, 0.0f));\n            }\n            result = lerp(result, _180_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    float3 _624 = normalize(v_normal);\n    float3 lit = _180_fa_ambient.xyz * _631_base.xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _624;\n        float4 param_3 = v_shadow;\n        LightSample _657 = fa_light(param, param_1, param_2, param_3);\n        lit += ((_631_base.xyz * _657.color) * max(dot(_624, _657.direction), 0.0f));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _680 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = float4(_680, 1.0f);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    v_normal = stage_input.v_normal;\n    v_pos = stage_input.v_pos;\n    v_shadow = stage_input.v_shadow;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_99",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_58",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_180",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_631",
            "hlsl_register_b_n": 5
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_full_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_full_shadow_tex_fa_full_shadow_smp",
            "view_name": "fa_full_shadow_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "cbuffer fa_skin : register(b3)\n{\n    float4 _71_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _217_fa_view_proj : packoffset(c0);\n    row_major float4x4 _217_fa_light_vp : packoffset(c4);\n    float4 _217_fa_uv_scale : packoffset(c8);\n    float4 _217_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_position;\nstatic float3 v_pos;\nstatic float3 v_normal;\nstatic float3 fa_normal;\nstatic float4 v_shadow;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float2 fa_texcoord0;\nstatic float4 fa_tangent;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 v_shadow : TEXCOORD2;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4x4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _61 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_71_fa_joint_rows[_61] * weights[i]);\n        r1 += (_71_fa_joint_rows[_61 + 1] * weights[i]);\n        r2 += (_71_fa_joint_rows[_61 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat3 fa_world_position(float3 p)\n{\n    return mul(float4(p, 1.0f), fa_model).xyz;\n}\n\nfloat3 fa_world_direction(float3 n)\n{\n    float3 _185 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_185 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _185) < 0.0f) ? (-1.0f) : 1.0f));\n}\n\nfloat4 fa_shadow_coord(float3 world)\n{\n    return mul(float4(world, 1.0f), _217_fa_light_vp);\n}\n\nvoid fa_user_main()\n{\n    float3 param = fa_position;\n    float3 _234 = fa_world_position(param);\n    v_pos = _234;\n    float3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    float3 param_2 = _234;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = mul(float4(_234, 1.0f), _217_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_model = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_tangent = stage_input.fa_tangent;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.v_pos = v_pos;\n    stage_output.v_normal = v_normal;\n    stage_output.v_shadow = v_shadow;\n    return stage_output;\n}\n",
      "fs": "struct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _58_fa_light_pos[32] : packoffset(c0);\n    float4 _58_fa_light_color[32] : packoffset(c32);\n    float4 _58_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _180_fa_camera_pos : packoffset(c0);\n    float4 _180_fa_ambient : packoffset(c1);\n    float4 _180_fa_base_color : packoffset(c2);\n    float4 _180_fa_emissive : packoffset(c3);\n    float4 _180_fa_model_emissive : packoffset(c4);\n    float4 _180_fa_pbr : packoffset(c5);\n    float4 _180_fa_maps : packoffset(c6);\n    float4 _180_fa_fog : packoffset(c7);\n    float4 _180_fa_fog_b : packoffset(c8);\n    float4 _180_fa_fog_c : packoffset(c9);\n    float4 _180_fa_counts : packoffset(c10);\n    float4 _180_fa_env_sky : packoffset(c11);\n    float4 _180_fa_env_horizon : packoffset(c12);\n    float4 _180_fa_time : packoffset(c13);\n    float4 _180_fa_layers_a : packoffset(c14);\n    float4 _180_fa_layers_b : packoffset(c15);\n    float4 _180_fa_layers_c : packoffset(c16);\n    float4 _180_fa_layers_d : packoffset(c17);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _631_base : packoffset(c0);\n};\n\nTexture2D<float4> fa_full_shadow_tex : register(t0);\nSamplerState fa_full_shadow_smp : register(s1);\n\nstatic float3 v_normal;\nstatic float3 v_pos;\nstatic float4 v_shadow;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 v_shadow : TEXCOORD2;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(_180_fa_counts.x), 32);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _72 = _58_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_72)\n    {\n        l = normalize(_58_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _90 = _58_fa_light_pos[li].xyz - world_pos;\n        float _92 = length(_90);\n        dist = _92;\n        l = _90 / max(_92, 9.9999997473787516355514526367188e-05f).xxx;\n        float _108 = _92 / max(_58_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _114 = clamp(1.0f - (_108 * _108), 0.0f, 1.0f);\n        atten = _114 * _114;\n        if (_58_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_58_fa_light_dir[li].w, lerp(_58_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_58_fa_light_dir[li].xyz)));\n        }\n    }\n    int _166;\n    if (_72)\n    {\n        _166 = 0;\n    }\n    else\n    {\n        _166 = (_58_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _706 = { l, _58_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _166 };\n    return _706;\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_180_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _194 = coord.xyz / coord.w.xxx;\n    float3 p = _194;\n    float2 suv = (_194.xy * 0.5f) + 0.5f.xx;\n    if (_180_fa_counts.z > 0.5f)\n    {\n        float3 _732 = p;\n        _732.z = (_732.z * 0.5f) + 0.5f;\n        p = _732;\n    }\n    else\n    {\n        float2 _735 = suv;\n        _735.y = 1.0f - _735.y;\n        suv = _735;\n    }\n    bool _226 = suv.x < 0.0f;\n    bool _233;\n    if (!_226)\n    {\n        _233 = suv.x > 1.0f;\n    }\n    else\n    {\n        _233 = _226;\n    }\n    bool _240;\n    if (!_233)\n    {\n        _240 = suv.y < 0.0f;\n    }\n    else\n    {\n        _240 = _233;\n    }\n    bool _247;\n    if (!_240)\n    {\n        _247 = suv.y > 1.0f;\n    }\n    else\n    {\n        _247 = _240;\n    }\n    bool _254;\n    if (!_247)\n    {\n        _254 = p.z > 1.0f;\n    }\n    else\n    {\n        _254 = _247;\n    }\n    if (_254)\n    {\n        return 1.0f;\n    }\n    float _269 = _180_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _269) <= fa_full_shadow_tex.SampleLevel(fa_full_shadow_smp, suv + (float2(float(ix), float(iy)) * _180_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow(float4 coord, float3 n, float3 l)\n{\n    float4 param = coord;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light(int li, float3 world_pos, float3 gn, float4 coord)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _352 = fa_light_sample(param, param_1);\n    float3 _713 = _352.direction;\n    float3 _708 = _352.color;\n    float _715 = _352.attenuation;\n    float _710 = _352.shadow;\n    int _718 = _352.type;\n    if ((_718 == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _713;\n        float _368 = fa_shadow(param_2, param_3, param_4);\n        _710 = _368;\n        _708 = _58_fa_light_color[li].xyz * (_715 * _368);\n    }\n    LightSample _725 = { _713, _708, _715, _710, _352._distance, _718 };\n    return _725;\n}\n\nfloat3 fa_apply_fog(inout float3 result, float3 world_pos)\n{\n    bool _387 = _180_fa_fog.w > 0.0f;\n    bool _395;\n    if (!_387)\n    {\n        _395 = _180_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _395 = _387;\n    }\n    if (_395)\n    {\n        float3 _403 = world_pos - _180_fa_camera_pos.xyz;\n        float _410 = dot(_403, _180_fa_fog_c.xyz);\n        bool _414 = _180_fa_fog_c.w > 0.5f;\n        float _415;\n        if (_414)\n        {\n            _415 = _410;\n        }\n        else\n        {\n            _415 = length(_403);\n        }\n        float _427 = _415 - _180_fa_fog_b.x;\n        if (_427 > 0.0f)\n        {\n            float _436 = _180_fa_fog.w * _427;\n            float tau = _436 * _436;\n            if (_180_fa_fog_b.y > 0.0f)\n            {\n                float _452;\n                if (_414)\n                {\n                    _452 = world_pos.y - (_180_fa_fog_c.y * _410);\n                }\n                else\n                {\n                    _452 = _180_fa_camera_pos.y;\n                }\n                float _473 = lerp(_452, world_pos.y, clamp(_180_fa_fog_b.x / _415, 0.0f, 1.0f));\n                float _477 = world_pos.y - _473;\n                float _482 = _473 - _180_fa_fog_b.z;\n                float _487 = world_pos.y - _180_fa_fog_b.z;\n                bool _490 = _482 <= 0.0f;\n                bool _491 = !_490;\n                bool _497;\n                if (_491)\n                {\n                    _497 = _180_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _497 = _490;\n                }\n                float _498;\n                if (_497)\n                {\n                    _498 = _180_fa_fog_b.y;\n                }\n                else\n                {\n                    _498 = _180_fa_fog_b.y * exp(-min(_180_fa_fog_b.w * _482, 80.0f));\n                }\n                bool _525;\n                if (_491)\n                {\n                    _525 = _180_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _525 = _490;\n                }\n                float _526;\n                if (_525)\n                {\n                    _526 = _180_fa_fog_b.y * _482;\n                }\n                else\n                {\n                    _526 = (_180_fa_fog_b.y * (1.0f - exp(-min(_180_fa_fog_b.w * _482, 80.0f)))) / _180_fa_fog_b.w;\n                }\n                bool _551 = _487 <= 0.0f;\n                bool _558;\n                if (!_551)\n                {\n                    _558 = _180_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _558 = _551;\n                }\n                float _559;\n                if (_558)\n                {\n                    _559 = _180_fa_fog_b.y * _487;\n                }\n                else\n                {\n                    _559 = (_180_fa_fog_b.y * (1.0f - exp(-min(_180_fa_fog_b.w * _487, 80.0f)))) / _180_fa_fog_b.w;\n                }\n                float _586;\n                if (abs(_477) < 0.001000000047497451305389404296875f)\n                {\n                    _586 = _498;\n                }\n                else\n                {\n                    _586 = (_559 - _526) / _477;\n                }\n                tau += (_427 * max(_586, 0.0f));\n            }\n            result = lerp(result, _180_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    float3 _624 = normalize(v_normal);\n    float3 lit = _180_fa_ambient.xyz * _631_base.xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _624;\n        float4 param_3 = v_shadow;\n        LightSample _657 = fa_light(param, param_1, param_2, param_3);\n        lit += ((_631_base.xyz * _657.color) * max(dot(_624, _657.direction), 0.0f));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _680 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = float4(_680, 1.0f);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    v_normal = stage_input.v_normal;\n    v_pos = stage_input.v_pos;\n    v_shadow = stage_input.v_shadow;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_71",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_217",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_58",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_180",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_631",
            "hlsl_register_b_n": 5
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_full_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_full_shadow_tex_fa_full_shadow_smp",
            "view_name": "fa_full_shadow_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    }
  }
}
