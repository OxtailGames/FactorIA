{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "1a96f74abba91894e3e539871081c4c1512e5fc182505880c3aee0a78f6adbed",
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
      "vs": "cbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _113_fa_view_proj : packoffset(c0);\n    row_major float4x4 _113_fa_light_vp : packoffset(c4);\n    float4 _113_fa_uv_scale : packoffset(c8);\n    float4 _113_fa_time : packoffset(c9);\n    float4 _113_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_position;\nstatic float3 v_pos;\nstatic float3 v_normal;\nstatic float3 fa_normal;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float2 fa_texcoord0;\nstatic float4 fa_tangent;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4x4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat3 fa_world_position(float3 p)\n{\n    return mul(float4(p, 1.0f), fa_model).xyz;\n}\n\nfloat3 fa_world_direction(float3 n)\n{\n    float3 _57 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_57 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _57) < 0.0f) ? (-1.0f) : 1.0f));\n}\n\nvoid fa_user_main()\n{\n    float3 param = fa_position;\n    float3 _98 = fa_world_position(param);\n    v_pos = _98;\n    float3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    gl_Position = mul(float4(_98, 1.0f), _113_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    fa_model = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_tangent = stage_input.fa_tangent;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.v_pos = v_pos;\n    stage_output.v_normal = v_normal;\n    return stage_output;\n}\n",
      "fs": "cbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _300_fa_camera_pos : packoffset(c0);\n    float4 _300_fa_ambient : packoffset(c1);\n    float4 _300_fa_base_color : packoffset(c2);\n    float4 _300_fa_emissive : packoffset(c3);\n    float4 _300_fa_model_emissive : packoffset(c4);\n    float4 _300_fa_pbr : packoffset(c5);\n    float4 _300_fa_maps : packoffset(c6);\n    float4 _300_fa_fog : packoffset(c7);\n    float4 _300_fa_fog_b : packoffset(c8);\n    float4 _300_fa_fog_c : packoffset(c9);\n    float4 _300_fa_counts : packoffset(c10);\n    float4 _300_fa_env_sky : packoffset(c11);\n    float4 _300_fa_env_horizon : packoffset(c12);\n    float4 _300_fa_time : packoffset(c13);\n    float4 _300_fa_cl_vpx : packoffset(c14);\n    float4 _300_fa_cl_vpy : packoffset(c15);\n    float4 _300_fa_cl_vpw : packoffset(c16);\n    float4 _300_fa_cl_fwd : packoffset(c17);\n    float4 _300_fa_cl_grid : packoffset(c18);\n    float4 _300_fa_cl_info : packoffset(c19);\n    float4 _300_fa_layers_a : packoffset(c20);\n    float4 _300_fa_layers_b : packoffset(c21);\n    float4 _300_fa_layers_c : packoffset(c22);\n    float4 _300_fa_layers_d : packoffset(c23);\n    float4 _300_fa_ct_a : packoffset(c24);\n    float4 _300_fa_ct_b : packoffset(c25);\n    float4 _300_fa_ct_vpx : packoffset(c26);\n    float4 _300_fa_ct_vpy : packoffset(c27);\n    float4 _300_fa_ct_vpw : packoffset(c28);\n    float4 _300_fa_ct_fwd : packoffset(c29);\n    float4 _300_fa_tr_a : packoffset(c30);\n    float4 _300_fa_tr_b : packoffset(c31);\n    float4 _300_fa_probe_sh[9] : packoffset(c32);\n    float4 _300_fa_atlas : packoffset(c41);\n    float4 _300_fa_rpa_tile : packoffset(c42);\n    float4 _300_fa_rpa_pos : packoffset(c43);\n    float4 _300_fa_rpa_bx : packoffset(c44);\n    float4 _300_fa_rpa_by : packoffset(c45);\n    float4 _300_fa_rpa_bz : packoffset(c46);\n    float4 _300_fa_rpb_tile : packoffset(c47);\n    float4 _300_fa_rpb_pos : packoffset(c48);\n    float4 _300_fa_rpb_bx : packoffset(c49);\n    float4 _300_fa_rpb_by : packoffset(c50);\n    float4 _300_fa_rpb_bz : packoffset(c51);\n    float4 _300_fa_gi : packoffset(c52);\n};\n\nTexture2D<float4> fa_probe_atlas : register(t0);\nSamplerState fa_env_smp : register(s10);\n\nstatic float3 v_normal;\nstatic float3 v_pos;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _493 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _496 = _493.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_496 * _496, exp2((-9.27999973297119140625f) * ndv)) * _496) + _493.y)) + _493.zw;\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _90 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _93 = _90.x;\n    float _95 = _90.z;\n    float2 e = float2(_93, _95);\n    if (_90.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_95)) * ((_93 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_93)) * ((_95 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _141_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _141_dummy_parameter)));\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _155;\n    if (lv == 0)\n    {\n        _155 = 0.0f;\n    }\n    else\n    {\n        _155 = res + 2.0f;\n    }\n    float _166;\n    if (lv == 0)\n    {\n        _166 = 0.0f;\n    }\n    else\n    {\n        _166 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_155, _166)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _215;\n    if (res > 64.5f)\n    {\n        _215 = 5.0f;\n    }\n    else\n    {\n        _215 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _232 = clamp(rough, 0.0f, 1.0f) * (_215 - 1.0f);\n    int _239 = int(min(floor(_232), _215 - 2.0f));\n    float _244 = _232 - float(_239);\n    float3 param = d;\n    float2 _248 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _239;\n    float2 param_4 = _248;\n    float3 _258 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_244 < 0.00200000009499490261077880859375f)\n    {\n        return _258;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _239 + 1;\n    float2 param_8 = _248;\n    return lerp(_258, fa_probe_level(param_5, param_6, param_7, param_8), _244.xxx);\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, float3 d, float rough)\n{\n    float2 param = tile.xy;\n    float param_1 = tile.z;\n    float3 param_2 = d;\n    float param_3 = rough;\n    return fa_probe_radiance(param, param_1, param_2, param_3);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _314 = (1.0f - _300_fa_rpa_tile.w) - _300_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_314 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_300_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _300_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _346 = rough * rough;\n            float _378 = 0.60000002384185791015625f * _346;\n            base = lerp(lerp(_300_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_300_fa_env_horizon.xyz, _300_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _346)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _378, 0.0500000007450580596923828125f + _378, d.y).xxx), ((_300_fa_env_sky.xyz + _300_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_346 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _314;\n    }\n    if (_300_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _300_fa_rpa_tile;\n        float4 param_5 = _300_fa_rpa_pos;\n        float4 param_6 = _300_fa_rpa_bx;\n        float4 param_7 = _300_fa_rpa_by;\n        float4 param_8 = _300_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        outc += (fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10) * _300_fa_rpa_tile.w);\n    }\n    if (_300_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _300_fa_rpb_tile;\n        float4 param_12 = _300_fa_rpb_pos;\n        float4 param_13 = _300_fa_rpb_bx;\n        float4 param_14 = _300_fa_rpb_by;\n        float4 param_15 = _300_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        outc += (fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17) * _300_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _536 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _536.x) + _536.y.xxx);\n}\n\nvoid fa_user_main()\n{\n    float3 _557 = normalize(v_normal);\n    float3 _565 = normalize(_300_fa_camera_pos.xyz - v_pos);\n    float param = 0.100000001490116119384765625f;\n    float param_1 = max(dot(_557, _565), 9.9999997473787516355514526367188e-05f);\n    float2 _579 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-_565, _557);\n    float param_3 = 0.100000001490116119384765625f;\n    float3 param_4 = _557;\n    float3 param_5 = _565;\n    float3 param_6 = 1.0f.xxx;\n    float param_7 = 0.100000001490116119384765625f;\n    fa_frag_color = float4(((fa_environment(param_2, param_3) * ((1.0f.xxx * _579.x) + _579.y.xxx)) * 0.5f) + (fa_sky_reflection(param_4, param_5, param_6, param_7) * 0.5f), 1.0f);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    v_normal = stage_input.v_normal;\n    v_pos = stage_input.v_pos;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_113",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_300",
            "hlsl_register_b_n": 1
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "cbuffer fa_skin : register(b3)\n{\n    float4 _67_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _231_fa_view_proj : packoffset(c0);\n    row_major float4x4 _231_fa_light_vp : packoffset(c4);\n    float4 _231_fa_uv_scale : packoffset(c8);\n    float4 _231_fa_time : packoffset(c9);\n    float4 _231_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_position;\nstatic float3 v_pos;\nstatic float3 v_normal;\nstatic float3 fa_normal;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float2 fa_texcoord0;\nstatic float4 fa_tangent;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4x4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _57 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_67_fa_joint_rows[_57] * weights[i]);\n        r1 += (_67_fa_joint_rows[_57 + 1] * weights[i]);\n        r2 += (_67_fa_joint_rows[_57 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat3 fa_world_position(float3 p)\n{\n    return mul(float4(p, 1.0f), fa_model).xyz;\n}\n\nfloat3 fa_world_direction(float3 n)\n{\n    float3 _181 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_181 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _181) < 0.0f) ? (-1.0f) : 1.0f));\n}\n\nvoid fa_user_main()\n{\n    float3 param = fa_position;\n    float3 _216 = fa_world_position(param);\n    v_pos = _216;\n    float3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    gl_Position = mul(float4(_216, 1.0f), _231_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_model = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_tangent = stage_input.fa_tangent;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.v_pos = v_pos;\n    stage_output.v_normal = v_normal;\n    return stage_output;\n}\n",
      "fs": "cbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _300_fa_camera_pos : packoffset(c0);\n    float4 _300_fa_ambient : packoffset(c1);\n    float4 _300_fa_base_color : packoffset(c2);\n    float4 _300_fa_emissive : packoffset(c3);\n    float4 _300_fa_model_emissive : packoffset(c4);\n    float4 _300_fa_pbr : packoffset(c5);\n    float4 _300_fa_maps : packoffset(c6);\n    float4 _300_fa_fog : packoffset(c7);\n    float4 _300_fa_fog_b : packoffset(c8);\n    float4 _300_fa_fog_c : packoffset(c9);\n    float4 _300_fa_counts : packoffset(c10);\n    float4 _300_fa_env_sky : packoffset(c11);\n    float4 _300_fa_env_horizon : packoffset(c12);\n    float4 _300_fa_time : packoffset(c13);\n    float4 _300_fa_cl_vpx : packoffset(c14);\n    float4 _300_fa_cl_vpy : packoffset(c15);\n    float4 _300_fa_cl_vpw : packoffset(c16);\n    float4 _300_fa_cl_fwd : packoffset(c17);\n    float4 _300_fa_cl_grid : packoffset(c18);\n    float4 _300_fa_cl_info : packoffset(c19);\n    float4 _300_fa_layers_a : packoffset(c20);\n    float4 _300_fa_layers_b : packoffset(c21);\n    float4 _300_fa_layers_c : packoffset(c22);\n    float4 _300_fa_layers_d : packoffset(c23);\n    float4 _300_fa_ct_a : packoffset(c24);\n    float4 _300_fa_ct_b : packoffset(c25);\n    float4 _300_fa_ct_vpx : packoffset(c26);\n    float4 _300_fa_ct_vpy : packoffset(c27);\n    float4 _300_fa_ct_vpw : packoffset(c28);\n    float4 _300_fa_ct_fwd : packoffset(c29);\n    float4 _300_fa_tr_a : packoffset(c30);\n    float4 _300_fa_tr_b : packoffset(c31);\n    float4 _300_fa_probe_sh[9] : packoffset(c32);\n    float4 _300_fa_atlas : packoffset(c41);\n    float4 _300_fa_rpa_tile : packoffset(c42);\n    float4 _300_fa_rpa_pos : packoffset(c43);\n    float4 _300_fa_rpa_bx : packoffset(c44);\n    float4 _300_fa_rpa_by : packoffset(c45);\n    float4 _300_fa_rpa_bz : packoffset(c46);\n    float4 _300_fa_rpb_tile : packoffset(c47);\n    float4 _300_fa_rpb_pos : packoffset(c48);\n    float4 _300_fa_rpb_bx : packoffset(c49);\n    float4 _300_fa_rpb_by : packoffset(c50);\n    float4 _300_fa_rpb_bz : packoffset(c51);\n    float4 _300_fa_gi : packoffset(c52);\n};\n\nTexture2D<float4> fa_probe_atlas : register(t0);\nSamplerState fa_env_smp : register(s10);\n\nstatic float3 v_normal;\nstatic float3 v_pos;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 v_pos : TEXCOORD0;\n    float3 v_normal : TEXCOORD1;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _493 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _496 = _493.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_496 * _496, exp2((-9.27999973297119140625f) * ndv)) * _496) + _493.y)) + _493.zw;\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _90 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _93 = _90.x;\n    float _95 = _90.z;\n    float2 e = float2(_93, _95);\n    if (_90.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_95)) * ((_93 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_93)) * ((_95 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _141_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _141_dummy_parameter)));\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _155;\n    if (lv == 0)\n    {\n        _155 = 0.0f;\n    }\n    else\n    {\n        _155 = res + 2.0f;\n    }\n    float _166;\n    if (lv == 0)\n    {\n        _166 = 0.0f;\n    }\n    else\n    {\n        _166 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_155, _166)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _215;\n    if (res > 64.5f)\n    {\n        _215 = 5.0f;\n    }\n    else\n    {\n        _215 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _232 = clamp(rough, 0.0f, 1.0f) * (_215 - 1.0f);\n    int _239 = int(min(floor(_232), _215 - 2.0f));\n    float _244 = _232 - float(_239);\n    float3 param = d;\n    float2 _248 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _239;\n    float2 param_4 = _248;\n    float3 _258 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_244 < 0.00200000009499490261077880859375f)\n    {\n        return _258;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _239 + 1;\n    float2 param_8 = _248;\n    return lerp(_258, fa_probe_level(param_5, param_6, param_7, param_8), _244.xxx);\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, float3 d, float rough)\n{\n    float2 param = tile.xy;\n    float param_1 = tile.z;\n    float3 param_2 = d;\n    float param_3 = rough;\n    return fa_probe_radiance(param, param_1, param_2, param_3);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _314 = (1.0f - _300_fa_rpa_tile.w) - _300_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_314 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_300_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _300_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _346 = rough * rough;\n            float _378 = 0.60000002384185791015625f * _346;\n            base = lerp(lerp(_300_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_300_fa_env_horizon.xyz, _300_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _346)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _378, 0.0500000007450580596923828125f + _378, d.y).xxx), ((_300_fa_env_sky.xyz + _300_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_346 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _314;\n    }\n    if (_300_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _300_fa_rpa_tile;\n        float4 param_5 = _300_fa_rpa_pos;\n        float4 param_6 = _300_fa_rpa_bx;\n        float4 param_7 = _300_fa_rpa_by;\n        float4 param_8 = _300_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        outc += (fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10) * _300_fa_rpa_tile.w);\n    }\n    if (_300_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _300_fa_rpb_tile;\n        float4 param_12 = _300_fa_rpb_pos;\n        float4 param_13 = _300_fa_rpb_bx;\n        float4 param_14 = _300_fa_rpb_by;\n        float4 param_15 = _300_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        outc += (fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17) * _300_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _536 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _536.x) + _536.y.xxx);\n}\n\nvoid fa_user_main()\n{\n    float3 _557 = normalize(v_normal);\n    float3 _565 = normalize(_300_fa_camera_pos.xyz - v_pos);\n    float param = 0.100000001490116119384765625f;\n    float param_1 = max(dot(_557, _565), 9.9999997473787516355514526367188e-05f);\n    float2 _579 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-_565, _557);\n    float param_3 = 0.100000001490116119384765625f;\n    float3 param_4 = _557;\n    float3 param_5 = _565;\n    float3 param_6 = 1.0f.xxx;\n    float param_7 = 0.100000001490116119384765625f;\n    fa_frag_color = float4(((fa_environment(param_2, param_3) * ((1.0f.xxx * _579.x) + _579.y.xxx)) * 0.5f) + (fa_sky_reflection(param_4, param_5, param_6, param_7) * 0.5f), 1.0f);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    v_normal = stage_input.v_normal;\n    v_pos = stage_input.v_pos;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_231",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_300",
            "hlsl_register_b_n": 1
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    }
  }
}
