{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "f6bab862063fc78fa36c872857ecf1496db0539b9f7c615323d4db57d82028e1",
  "slang": "hlsl5",
  "params": [],
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
      "vs": "cbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _113_fa_view_proj : packoffset(c0);\n    row_major float4x4 _113_fa_light_vp : packoffset(c4);\n    float4 _113_fa_uv_scale : packoffset(c8);\n    float4 _113_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_position;\nstatic float3 v_pos;\nstatic float3 v_normal;\nstatic float3 fa_normal;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float2 fa_texcoord0;\nstatic float4 fa_tangent;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4x4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat3 fa_world_position(float3 p)\n{\n    return mul(float4(p, 1.0f), fa_model).xyz;\n}\n\nfloat3 fa_world_direction(float3 n)\n{\n    float3 _57 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_57 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _57) < 0.0f) ? (-1.0f) : 1.0f));\n}\n\nvoid fa_user_main()\n{\n    float3 param = fa_position;\n    float3 _98 = fa_world_position(param);\n    v_pos = _98;\n    float3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    gl_Position = mul(float4(_98, 1.0f), _113_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    fa_model = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_tangent = stage_input.fa_tangent;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.v_pos = v_pos;\n    stage_output.v_normal = v_normal;\n    return stage_output;\n}\n",
      "fs": "cbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _35_fa_camera_pos : packoffset(c0);\n    float4 _35_fa_ambient : packoffset(c1);\n    float4 _35_fa_base_color : packoffset(c2);\n    float4 _35_fa_emissive : packoffset(c3);\n    float4 _35_fa_model_emissive : packoffset(c4);\n    float4 _35_fa_pbr : packoffset(c5);\n    float4 _35_fa_maps : packoffset(c6);\n    float4 _35_fa_fog : packoffset(c7);\n    float4 _35_fa_fog_b : packoffset(c8);\n    float4 _35_fa_fog_c : packoffset(c9);\n    float4 _35_fa_counts : packoffset(c10);\n    float4 _35_fa_env_sky : packoffset(c11);\n    float4 _35_fa_env_horizon : packoffset(c12);\n    float4 _35_fa_time : packoffset(c13);\n    float4 _35_fa_cl_vpx : packoffset(c14);\n    float4 _35_fa_cl_vpy : packoffset(c15);\n    float4 _35_fa_cl_vpw : packoffset(c16);\n    float4 _35_fa_cl_fwd : packoffset(c17);\n    float4 _35_fa_cl_grid : packoffset(c18);\n    float4 _35_fa_cl_info : packoffset(c19);\n    float4 _35_fa_layers_a : packoffset(c20);\n    float4 _35_fa_layers_b : packoffset(c21);\n    float4 _35_fa_layers_c : packoffset(c22);\n    float4 _35_fa_layers_d : packoffset(c23);\n};\n\nTextureCube<float4> fa_env_tex : register(t0);\nSamplerState fa_env_smp : register(s10);\n\nstatic float3 v_normal;\nstatic float3 v_pos;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid fa_inst_load()\n{\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _155 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _159 = _155.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_159 * _159, exp2((-9.27999973297119140625f) * ndv)) * _159) + _155.y)) + _155.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_35_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _35_fa_env_horizon.w).xyz;\n    }\n    float _73 = rough * rough;\n    float _106 = 0.60000002384185791015625f * _73;\n    return lerp(lerp(_35_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_35_fa_env_horizon.xyz, _35_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _73)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _106, 0.0500000007450580596923828125f + _106, d.y).xxx), ((_35_fa_env_sky.xyz + _35_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_73 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _200 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _200.x) + _200.y.xxx);\n}\n\nvoid fa_user_main()\n{\n    float3 _221 = normalize(v_normal);\n    float3 _230 = normalize(_35_fa_camera_pos.xyz - v_pos);\n    float param = 0.100000001490116119384765625f;\n    float param_1 = max(dot(_221, _230), 9.9999997473787516355514526367188e-05f);\n    float2 _244 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-_230, _221);\n    float param_3 = 0.100000001490116119384765625f;\n    float3 param_4 = _221;\n    float3 param_5 = _230;\n    float3 param_6 = 1.0f.xxx;\n    float param_7 = 0.100000001490116119384765625f;\n    fa_frag_color = float4(((fa_environment(param_2, param_3) * ((1.0f.xxx * _244.x) + _244.y.xxx)) * 0.5f) + (fa_sky_reflection(param_4, param_5, param_6, param_7) * 0.5f), 1.0f);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    v_normal = stage_input.v_normal;\n    v_pos = stage_input.v_pos;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_113",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_35",
            "hlsl_register_b_n": 1
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 10
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
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
      "vs": "cbuffer fa_skin : register(b3)\n{\n    float4 _67_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _231_fa_view_proj : packoffset(c0);\n    row_major float4x4 _231_fa_light_vp : packoffset(c4);\n    float4 _231_fa_uv_scale : packoffset(c8);\n    float4 _231_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_position;\nstatic float3 v_pos;\nstatic float3 v_normal;\nstatic float3 fa_normal;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float2 fa_texcoord0;\nstatic float4 fa_tangent;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4x4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _57 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_67_fa_joint_rows[_57] * weights[i]);\n        r1 += (_67_fa_joint_rows[_57 + 1] * weights[i]);\n        r2 += (_67_fa_joint_rows[_57 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat3 fa_world_position(float3 p)\n{\n    return mul(float4(p, 1.0f), fa_model).xyz;\n}\n\nfloat3 fa_world_direction(float3 n)\n{\n    float3 _181 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_181 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _181) < 0.0f) ? (-1.0f) : 1.0f));\n}\n\nvoid fa_user_main()\n{\n    float3 param = fa_position;\n    float3 _216 = fa_world_position(param);\n    v_pos = _216;\n    float3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    gl_Position = mul(float4(_216, 1.0f), _231_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_model = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_tangent = stage_input.fa_tangent;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.v_pos = v_pos;\n    stage_output.v_normal = v_normal;\n    return stage_output;\n}\n",
      "fs": "cbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _35_fa_camera_pos : packoffset(c0);\n    float4 _35_fa_ambient : packoffset(c1);\n    float4 _35_fa_base_color : packoffset(c2);\n    float4 _35_fa_emissive : packoffset(c3);\n    float4 _35_fa_model_emissive : packoffset(c4);\n    float4 _35_fa_pbr : packoffset(c5);\n    float4 _35_fa_maps : packoffset(c6);\n    float4 _35_fa_fog : packoffset(c7);\n    float4 _35_fa_fog_b : packoffset(c8);\n    float4 _35_fa_fog_c : packoffset(c9);\n    float4 _35_fa_counts : packoffset(c10);\n    float4 _35_fa_env_sky : packoffset(c11);\n    float4 _35_fa_env_horizon : packoffset(c12);\n    float4 _35_fa_time : packoffset(c13);\n    float4 _35_fa_cl_vpx : packoffset(c14);\n    float4 _35_fa_cl_vpy : packoffset(c15);\n    float4 _35_fa_cl_vpw : packoffset(c16);\n    float4 _35_fa_cl_fwd : packoffset(c17);\n    float4 _35_fa_cl_grid : packoffset(c18);\n    float4 _35_fa_cl_info : packoffset(c19);\n    float4 _35_fa_layers_a : packoffset(c20);\n    float4 _35_fa_layers_b : packoffset(c21);\n    float4 _35_fa_layers_c : packoffset(c22);\n    float4 _35_fa_layers_d : packoffset(c23);\n};\n\nTextureCube<float4> fa_env_tex : register(t0);\nSamplerState fa_env_smp : register(s10);\n\nstatic float3 v_normal;\nstatic float3 v_pos;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid fa_inst_load()\n{\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _155 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _159 = _155.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_159 * _159, exp2((-9.27999973297119140625f) * ndv)) * _159) + _155.y)) + _155.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_35_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _35_fa_env_horizon.w).xyz;\n    }\n    float _73 = rough * rough;\n    float _106 = 0.60000002384185791015625f * _73;\n    return lerp(lerp(_35_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_35_fa_env_horizon.xyz, _35_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _73)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _106, 0.0500000007450580596923828125f + _106, d.y).xxx), ((_35_fa_env_sky.xyz + _35_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_73 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _200 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _200.x) + _200.y.xxx);\n}\n\nvoid fa_user_main()\n{\n    float3 _221 = normalize(v_normal);\n    float3 _230 = normalize(_35_fa_camera_pos.xyz - v_pos);\n    float param = 0.100000001490116119384765625f;\n    float param_1 = max(dot(_221, _230), 9.9999997473787516355514526367188e-05f);\n    float2 _244 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-_230, _221);\n    float param_3 = 0.100000001490116119384765625f;\n    float3 param_4 = _221;\n    float3 param_5 = _230;\n    float3 param_6 = 1.0f.xxx;\n    float param_7 = 0.100000001490116119384765625f;\n    fa_frag_color = float4(((fa_environment(param_2, param_3) * ((1.0f.xxx * _244.x) + _244.y.xxx)) * 0.5f) + (fa_sky_reflection(param_4, param_5, param_6, param_7) * 0.5f), 1.0f);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    v_normal = stage_input.v_normal;\n    v_pos = stage_input.v_pos;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_67",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_231",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_35",
            "hlsl_register_b_n": 1
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 10
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    }
  }
}
