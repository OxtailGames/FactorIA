{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5803d023b1c011299e7caeb3dafe645d0b88230997a6bd7a8ad8bad27e396a28",
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
      "fs": "struct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _216_fa_camera_pos : packoffset(c0);\n    float4 _216_fa_ambient : packoffset(c1);\n    float4 _216_fa_base_color : packoffset(c2);\n    float4 _216_fa_emissive : packoffset(c3);\n    float4 _216_fa_model_emissive : packoffset(c4);\n    float4 _216_fa_pbr : packoffset(c5);\n    float4 _216_fa_maps : packoffset(c6);\n    float4 _216_fa_fog : packoffset(c7);\n    float4 _216_fa_fog_b : packoffset(c8);\n    float4 _216_fa_fog_c : packoffset(c9);\n    float4 _216_fa_counts : packoffset(c10);\n    float4 _216_fa_env_sky : packoffset(c11);\n    float4 _216_fa_env_horizon : packoffset(c12);\n    float4 _216_fa_time : packoffset(c13);\n    float4 _216_fa_cl_vpx : packoffset(c14);\n    float4 _216_fa_cl_vpy : packoffset(c15);\n    float4 _216_fa_cl_vpw : packoffset(c16);\n    float4 _216_fa_cl_fwd : packoffset(c17);\n    float4 _216_fa_cl_grid : packoffset(c18);\n    float4 _216_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _656_base : packoffset(c0);\n};\n\nTexture2D<float4> fa_full_light_tex : register(t1);\nSamplerState fa_full_shadow_smp : register(s1);\nTexture2D<float4> fa_full_shadow_tex : register(t0);\n\nstatic float3 v_normal;\nstatic float3 v_pos;\nstatic float4 v_shadow;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 v_shadow : TEXCOORD2;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(_216_fa_counts.x), 32);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_full_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _81 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _88 = fa_light_texel(param_1);\n    float _94 = _88.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _102 = _94 < 0.5f;\n    float3 l;\n    if (_102)\n    {\n        l = normalize(_81.xyz);\n    }\n    else\n    {\n        float3 _114 = _81.xyz - world_pos;\n        float _116 = length(_114);\n        dist = _116;\n        l = _114 / max(_116, 9.9999997473787516355514526367188e-05f).xxx;\n        float _131 = _116 / max(_81.w, 0.001000000047497451305389404296875f);\n        float _137 = clamp(1.0f - (_131 * _131), 0.0f, 1.0f);\n        atten = _137 * _137;\n        if (_94 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _152 = fa_light_texel(param_2);\n            float _162 = _152.w;\n            int param_3 = (li * 4) + 3;\n            float4 _169 = fa_light_texel(param_3);\n            float _171 = _169.x;\n            float cos_inner = _171;\n            if (_171 > 1.5f)\n            {\n                cos_inner = lerp(_162, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_162, cos_inner, dot(-l, normalize(_152.xyz)));\n        }\n    }\n    int _202;\n    if (_102)\n    {\n        _202 = 0;\n    }\n    else\n    {\n        _202 = (_94 > 1.5f) ? 2 : 1;\n    }\n    LightSample _731 = { l, _88.xyz * atten, atten, 1.0f, dist, _202 };\n    return _731;\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_216_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _231 = coord.xyz / coord.w.xxx;\n    float3 p = _231;\n    float2 suv = (_231.xy * 0.5f) + 0.5f.xx;\n    if (_216_fa_counts.z > 0.5f)\n    {\n        float3 _760 = p;\n        _760.z = (_760.z * 0.5f) + 0.5f;\n        p = _760;\n    }\n    else\n    {\n        float2 _763 = suv;\n        _763.y = 1.0f - _763.y;\n        suv = _763;\n    }\n    bool _261 = suv.x < 0.0f;\n    bool _268;\n    if (!_261)\n    {\n        _268 = suv.x > 1.0f;\n    }\n    else\n    {\n        _268 = _261;\n    }\n    bool _275;\n    if (!_268)\n    {\n        _275 = suv.y < 0.0f;\n    }\n    else\n    {\n        _275 = _268;\n    }\n    bool _282;\n    if (!_275)\n    {\n        _282 = suv.y > 1.0f;\n    }\n    else\n    {\n        _282 = _275;\n    }\n    bool _289;\n    if (!_282)\n    {\n        _289 = p.z > 1.0f;\n    }\n    else\n    {\n        _289 = _282;\n    }\n    if (_289)\n    {\n        return 1.0f;\n    }\n    float _304 = _216_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _304) <= fa_full_shadow_tex.SampleLevel(fa_full_shadow_smp, suv + (float2(float(ix), float(iy)) * _216_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow(float4 coord, float3 n, float3 l)\n{\n    float4 param = coord;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light(int li, float3 world_pos, float3 gn, float4 coord)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _381 = fa_light_sample(param, param_1);\n    float3 _738 = _381.direction;\n    float3 _733 = _381.color;\n    float _735 = _381.shadow;\n    int _743 = _381.type;\n    if ((_743 == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _738;\n        float _397 = fa_shadow(param_2, param_3, param_4);\n        _735 = _397;\n        _733 *= _397;\n    }\n    LightSample _750 = { _738, _733, _381.attenuation, _735, _381._distance, _743 };\n    return _750;\n}\n\nfloat3 fa_apply_fog(inout float3 result, float3 world_pos)\n{\n    bool _411 = _216_fa_fog.w > 0.0f;\n    bool _419;\n    if (!_411)\n    {\n        _419 = _216_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _419 = _411;\n    }\n    if (_419)\n    {\n        float3 _428 = world_pos - _216_fa_camera_pos.xyz;\n        float _435 = dot(_428, _216_fa_fog_c.xyz);\n        bool _439 = _216_fa_fog_c.w > 0.5f;\n        float _440;\n        if (_439)\n        {\n            _440 = _435;\n        }\n        else\n        {\n            _440 = length(_428);\n        }\n        float _452 = _440 - _216_fa_fog_b.x;\n        if (_452 > 0.0f)\n        {\n            float _461 = _216_fa_fog.w * _452;\n            float tau = _461 * _461;\n            if (_216_fa_fog_b.y > 0.0f)\n            {\n                float _477;\n                if (_439)\n                {\n                    _477 = world_pos.y - (_216_fa_fog_c.y * _435);\n                }\n                else\n                {\n                    _477 = _216_fa_camera_pos.y;\n                }\n                float _498 = lerp(_477, world_pos.y, clamp(_216_fa_fog_b.x / _440, 0.0f, 1.0f));\n                float _502 = world_pos.y - _498;\n                float _507 = _498 - _216_fa_fog_b.z;\n                float _512 = world_pos.y - _216_fa_fog_b.z;\n                bool _515 = _507 <= 0.0f;\n                bool _516 = !_515;\n                bool _522;\n                if (_516)\n                {\n                    _522 = _216_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _522 = _515;\n                }\n                float _523;\n                if (_522)\n                {\n                    _523 = _216_fa_fog_b.y;\n                }\n                else\n                {\n                    _523 = _216_fa_fog_b.y * exp(-min(_216_fa_fog_b.w * _507, 80.0f));\n                }\n                bool _550;\n                if (_516)\n                {\n                    _550 = _216_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _550 = _515;\n                }\n                float _551;\n                if (_550)\n                {\n                    _551 = _216_fa_fog_b.y * _507;\n                }\n                else\n                {\n                    _551 = (_216_fa_fog_b.y * (1.0f - exp(-min(_216_fa_fog_b.w * _507, 80.0f)))) / _216_fa_fog_b.w;\n                }\n                bool _576 = _512 <= 0.0f;\n                bool _583;\n                if (!_576)\n                {\n                    _583 = _216_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _583 = _576;\n                }\n                float _584;\n                if (_583)\n                {\n                    _584 = _216_fa_fog_b.y * _512;\n                }\n                else\n                {\n                    _584 = (_216_fa_fog_b.y * (1.0f - exp(-min(_216_fa_fog_b.w * _512, 80.0f)))) / _216_fa_fog_b.w;\n                }\n                float _611;\n                if (abs(_502) < 0.001000000047497451305389404296875f)\n                {\n                    _611 = _523;\n                }\n                else\n                {\n                    _611 = (_584 - _551) / _502;\n                }\n                tau += (_452 * max(_611, 0.0f));\n            }\n            result = lerp(result, _216_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    float3 _649 = normalize(v_normal);\n    float3 lit = _216_fa_ambient.xyz * _656_base.xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _649;\n        float4 param_3 = v_shadow;\n        LightSample _682 = fa_light(param, param_1, param_2, param_3);\n        lit += ((_656_base.xyz * _682.color) * max(dot(_649, _682.direction), 0.0f));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _705 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = float4(_705, 1.0f);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    v_normal = stage_input.v_normal;\n    v_pos = stage_input.v_pos;\n    v_shadow = stage_input.v_shadow;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_216",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_656",
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
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_full_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 1
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
            "name": "fa_full_light_tex_fa_full_shadow_smp",
            "view_name": "fa_full_light_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
          },
          {
            "slot": 1,
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
      "fs": "struct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _216_fa_camera_pos : packoffset(c0);\n    float4 _216_fa_ambient : packoffset(c1);\n    float4 _216_fa_base_color : packoffset(c2);\n    float4 _216_fa_emissive : packoffset(c3);\n    float4 _216_fa_model_emissive : packoffset(c4);\n    float4 _216_fa_pbr : packoffset(c5);\n    float4 _216_fa_maps : packoffset(c6);\n    float4 _216_fa_fog : packoffset(c7);\n    float4 _216_fa_fog_b : packoffset(c8);\n    float4 _216_fa_fog_c : packoffset(c9);\n    float4 _216_fa_counts : packoffset(c10);\n    float4 _216_fa_env_sky : packoffset(c11);\n    float4 _216_fa_env_horizon : packoffset(c12);\n    float4 _216_fa_time : packoffset(c13);\n    float4 _216_fa_cl_vpx : packoffset(c14);\n    float4 _216_fa_cl_vpy : packoffset(c15);\n    float4 _216_fa_cl_vpw : packoffset(c16);\n    float4 _216_fa_cl_fwd : packoffset(c17);\n    float4 _216_fa_cl_grid : packoffset(c18);\n    float4 _216_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _656_base : packoffset(c0);\n};\n\nTexture2D<float4> fa_full_light_tex : register(t1);\nSamplerState fa_full_shadow_smp : register(s1);\nTexture2D<float4> fa_full_shadow_tex : register(t0);\n\nstatic float3 v_normal;\nstatic float3 v_pos;\nstatic float4 v_shadow;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 v_shadow : TEXCOORD2;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(_216_fa_counts.x), 32);\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_full_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _81 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _88 = fa_light_texel(param_1);\n    float _94 = _88.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _102 = _94 < 0.5f;\n    float3 l;\n    if (_102)\n    {\n        l = normalize(_81.xyz);\n    }\n    else\n    {\n        float3 _114 = _81.xyz - world_pos;\n        float _116 = length(_114);\n        dist = _116;\n        l = _114 / max(_116, 9.9999997473787516355514526367188e-05f).xxx;\n        float _131 = _116 / max(_81.w, 0.001000000047497451305389404296875f);\n        float _137 = clamp(1.0f - (_131 * _131), 0.0f, 1.0f);\n        atten = _137 * _137;\n        if (_94 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _152 = fa_light_texel(param_2);\n            float _162 = _152.w;\n            int param_3 = (li * 4) + 3;\n            float4 _169 = fa_light_texel(param_3);\n            float _171 = _169.x;\n            float cos_inner = _171;\n            if (_171 > 1.5f)\n            {\n                cos_inner = lerp(_162, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_162, cos_inner, dot(-l, normalize(_152.xyz)));\n        }\n    }\n    int _202;\n    if (_102)\n    {\n        _202 = 0;\n    }\n    else\n    {\n        _202 = (_94 > 1.5f) ? 2 : 1;\n    }\n    LightSample _731 = { l, _88.xyz * atten, atten, 1.0f, dist, _202 };\n    return _731;\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_216_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _231 = coord.xyz / coord.w.xxx;\n    float3 p = _231;\n    float2 suv = (_231.xy * 0.5f) + 0.5f.xx;\n    if (_216_fa_counts.z > 0.5f)\n    {\n        float3 _760 = p;\n        _760.z = (_760.z * 0.5f) + 0.5f;\n        p = _760;\n    }\n    else\n    {\n        float2 _763 = suv;\n        _763.y = 1.0f - _763.y;\n        suv = _763;\n    }\n    bool _261 = suv.x < 0.0f;\n    bool _268;\n    if (!_261)\n    {\n        _268 = suv.x > 1.0f;\n    }\n    else\n    {\n        _268 = _261;\n    }\n    bool _275;\n    if (!_268)\n    {\n        _275 = suv.y < 0.0f;\n    }\n    else\n    {\n        _275 = _268;\n    }\n    bool _282;\n    if (!_275)\n    {\n        _282 = suv.y > 1.0f;\n    }\n    else\n    {\n        _282 = _275;\n    }\n    bool _289;\n    if (!_282)\n    {\n        _289 = p.z > 1.0f;\n    }\n    else\n    {\n        _289 = _282;\n    }\n    if (_289)\n    {\n        return 1.0f;\n    }\n    float _304 = _216_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _304) <= fa_full_shadow_tex.SampleLevel(fa_full_shadow_smp, suv + (float2(float(ix), float(iy)) * _216_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow(float4 coord, float3 n, float3 l)\n{\n    float4 param = coord;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light(int li, float3 world_pos, float3 gn, float4 coord)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _381 = fa_light_sample(param, param_1);\n    float3 _738 = _381.direction;\n    float3 _733 = _381.color;\n    float _735 = _381.shadow;\n    int _743 = _381.type;\n    if ((_743 == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _738;\n        float _397 = fa_shadow(param_2, param_3, param_4);\n        _735 = _397;\n        _733 *= _397;\n    }\n    LightSample _750 = { _738, _733, _381.attenuation, _735, _381._distance, _743 };\n    return _750;\n}\n\nfloat3 fa_apply_fog(inout float3 result, float3 world_pos)\n{\n    bool _411 = _216_fa_fog.w > 0.0f;\n    bool _419;\n    if (!_411)\n    {\n        _419 = _216_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _419 = _411;\n    }\n    if (_419)\n    {\n        float3 _428 = world_pos - _216_fa_camera_pos.xyz;\n        float _435 = dot(_428, _216_fa_fog_c.xyz);\n        bool _439 = _216_fa_fog_c.w > 0.5f;\n        float _440;\n        if (_439)\n        {\n            _440 = _435;\n        }\n        else\n        {\n            _440 = length(_428);\n        }\n        float _452 = _440 - _216_fa_fog_b.x;\n        if (_452 > 0.0f)\n        {\n            float _461 = _216_fa_fog.w * _452;\n            float tau = _461 * _461;\n            if (_216_fa_fog_b.y > 0.0f)\n            {\n                float _477;\n                if (_439)\n                {\n                    _477 = world_pos.y - (_216_fa_fog_c.y * _435);\n                }\n                else\n                {\n                    _477 = _216_fa_camera_pos.y;\n                }\n                float _498 = lerp(_477, world_pos.y, clamp(_216_fa_fog_b.x / _440, 0.0f, 1.0f));\n                float _502 = world_pos.y - _498;\n                float _507 = _498 - _216_fa_fog_b.z;\n                float _512 = world_pos.y - _216_fa_fog_b.z;\n                bool _515 = _507 <= 0.0f;\n                bool _516 = !_515;\n                bool _522;\n                if (_516)\n                {\n                    _522 = _216_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _522 = _515;\n                }\n                float _523;\n                if (_522)\n                {\n                    _523 = _216_fa_fog_b.y;\n                }\n                else\n                {\n                    _523 = _216_fa_fog_b.y * exp(-min(_216_fa_fog_b.w * _507, 80.0f));\n                }\n                bool _550;\n                if (_516)\n                {\n                    _550 = _216_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _550 = _515;\n                }\n                float _551;\n                if (_550)\n                {\n                    _551 = _216_fa_fog_b.y * _507;\n                }\n                else\n                {\n                    _551 = (_216_fa_fog_b.y * (1.0f - exp(-min(_216_fa_fog_b.w * _507, 80.0f)))) / _216_fa_fog_b.w;\n                }\n                bool _576 = _512 <= 0.0f;\n                bool _583;\n                if (!_576)\n                {\n                    _583 = _216_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _583 = _576;\n                }\n                float _584;\n                if (_583)\n                {\n                    _584 = _216_fa_fog_b.y * _512;\n                }\n                else\n                {\n                    _584 = (_216_fa_fog_b.y * (1.0f - exp(-min(_216_fa_fog_b.w * _512, 80.0f)))) / _216_fa_fog_b.w;\n                }\n                float _611;\n                if (abs(_502) < 0.001000000047497451305389404296875f)\n                {\n                    _611 = _523;\n                }\n                else\n                {\n                    _611 = (_584 - _551) / _502;\n                }\n                tau += (_452 * max(_611, 0.0f));\n            }\n            result = lerp(result, _216_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    float3 _649 = normalize(v_normal);\n    float3 lit = _216_fa_ambient.xyz * _656_base.xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _649;\n        float4 param_3 = v_shadow;\n        LightSample _682 = fa_light(param, param_1, param_2, param_3);\n        lit += ((_656_base.xyz * _682.color) * max(dot(_649, _682.direction), 0.0f));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _705 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = float4(_705, 1.0f);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    v_normal = stage_input.v_normal;\n    v_pos = stage_input.v_pos;\n    v_shadow = stage_input.v_shadow;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_216",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_656",
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
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_full_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 1
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
            "name": "fa_full_light_tex_fa_full_shadow_smp",
            "view_name": "fa_full_light_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
          },
          {
            "slot": 1,
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
