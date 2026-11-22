{
  "format": "factoria.shader/1",
  "engine": "0.34.0",
  "template": "2a036c91eca814b00bd90da318a0a52d7732eea654a0d73b16aa380e38707757",
  "slang": "metal_macos",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_position(thread const float3& p, thread float4x4& fa_model)\n{\n    return (fa_model * float4(p, 1.0)).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_direction(thread const float3& n, thread float4x4& fa_model)\n{\n    float3 _57 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return fast::normalize((((_57 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _57) < 0.0) ? (-1.0) : 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(thread float4x4& fa_model, thread float3& fa_position, thread float3& v_pos, thread float3& v_normal, thread float3& fa_normal, thread float4& gl_Position, constant fa_mesh_vs_params& _113)\n{\n    float3 param = fa_position;\n    float3 _98 = fa_world_position(param, fa_model);\n    v_pos = _98;\n    float3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1, fa_model);\n    gl_Position = _113.fa_view_proj * float4(_98, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _113 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 fa_model = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    fa_user_main(fa_model, in.fa_position, out.v_pos, out.v_normal, in.fa_normal, out.gl_Position, _113);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_tr_a;\n    float4 fa_tr_b;\n    float4 fa_probe_sh[9];\n    float4 fa_atlas;\n    float4 fa_rpa_tile;\n    float4 fa_rpa_pos;\n    float4 fa_rpa_bx;\n    float4 fa_rpa_by;\n    float4 fa_rpa_bz;\n    float4 fa_rpb_tile;\n    float4 fa_rpb_pos;\n    float4 fa_rpb_bx;\n    float4 fa_rpb_by;\n    float4 fa_rpb_bz;\n    float4 fa_gi;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _493 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _496 = _493.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_496 * _496, exp2((-9.27999973297119140625) * ndv)) * _496) + _493.y)) + _493.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_oct_encode(thread const float3& d)\n{\n    float3 _90 = d / float3(fast::max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _93 = _90.x;\n    float _95 = _90.z;\n    float2 e = float2(_93, _95);\n    if (_90.y < 0.0)\n    {\n        e = float2((1.0 - abs(_95)) * ((_93 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_93)) * ((_95 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_atlas_size(texture2d<float> fa_probe_atlas, sampler fa_env_smp)\n{\n    return float2(int2(fa_probe_atlas.get_width(), fa_probe_atlas.get_height()));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_probe_level(thread const float2& origin, thread const float& res, thread const int& lv, thread const float2& e, texture2d<float> fa_probe_atlas, sampler fa_env_smp)\n{\n    float _155;\n    if (lv == 0)\n    {\n        _155 = 0.0;\n    }\n    else\n    {\n        _155 = res + 2.0;\n    }\n    float _166;\n    if (lv == 0)\n    {\n        _166 = 0.0;\n    }\n    else\n    {\n        _166 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return fa_probe_atlas.sample(fa_env_smp, ((((origin + float2(_155, _166)) + float2(1.0)) + (((e * 0.5) + float2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(fa_probe_atlas, fa_env_smp)), level(0.0)).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_probe_radiance(thread const float2& origin, thread const float& res, thread const float3& d, thread const float& rough, texture2d<float> fa_probe_atlas, sampler fa_env_smp)\n{\n    float _215;\n    if (res > 64.5)\n    {\n        _215 = 5.0;\n    }\n    else\n    {\n        _215 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _232 = fast::clamp(rough, 0.0, 1.0) * (_215 - 1.0);\n    int _239 = int(fast::min(floor(_232), _215 - 2.0));\n    float _244 = _232 - float(_239);\n    float3 param = d;\n    float2 _248 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _239;\n    float2 param_4 = _248;\n    float3 _258 = fa_probe_level(param_1, param_2, param_3, param_4, fa_probe_atlas, fa_env_smp);\n    if (_244 < 0.00200000009499490261077880859375)\n    {\n        return _258;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _239 + 1;\n    float2 param_8 = _248;\n    return mix(_258, fa_probe_level(param_5, param_6, param_7, param_8, fa_probe_atlas, fa_env_smp), float3(_244));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_probe_environment(thread const float4& tile, thread const float4& posw, thread const float4& bx, thread const float4& by, thread const float4& bz, thread const float3& d, thread const float& rough, texture2d<float> fa_probe_atlas, sampler fa_env_smp)\n{\n    float2 param = tile.xy;\n    float param_1 = tile.z;\n    float3 param_2 = d;\n    float param_3 = rough;\n    return fa_probe_radiance(param, param_1, param_2, param_3, fa_probe_atlas, fa_env_smp);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, texture2d<float> fa_probe_atlas, sampler fa_env_smp, constant fa_mesh_fs_params& _300)\n{\n    float _314 = (1.0 - _300.fa_rpa_tile.w) - _300.fa_rpb_tile.w;\n    float3 outc = float3(0.0);\n    if (_314 > 0.0005000000237487256526947021484375)\n    {\n        float3 base;\n        if (_300.fa_env_sky.w > 0.5)\n        {\n            float2 param = _300.fa_atlas.zw;\n            float param_1 = 128.0;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3, fa_probe_atlas, fa_env_smp);\n        }\n        else\n        {\n            float _346 = rough * rough;\n            float _378 = 0.60000002384185791015625 * _346;\n            base = mix(mix(_300.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_300.fa_env_horizon.xyz, _300.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _346)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _378, 0.0500000007450580596923828125 + _378, d.y))), ((_300.fa_env_sky.xyz + _300.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_346 * 0.60000002384185791015625));\n        }\n        outc = base * _314;\n    }\n    if (_300.fa_rpa_tile.w > 0.0)\n    {\n        float4 param_4 = _300.fa_rpa_tile;\n        float4 param_5 = _300.fa_rpa_pos;\n        float4 param_6 = _300.fa_rpa_bx;\n        float4 param_7 = _300.fa_rpa_by;\n        float4 param_8 = _300.fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        outc += (fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10, fa_probe_atlas, fa_env_smp) * _300.fa_rpa_tile.w);\n    }\n    if (_300.fa_rpb_tile.w > 0.0)\n    {\n        float4 param_11 = _300.fa_rpb_tile;\n        float4 param_12 = _300.fa_rpb_pos;\n        float4 param_13 = _300.fa_rpb_bx;\n        float4 param_14 = _300.fa_rpb_by;\n        float4 param_15 = _300.fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        outc += (fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17, fa_probe_atlas, fa_env_smp) * _300.fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, texture2d<float> fa_probe_atlas, sampler fa_env_smp, constant fa_mesh_fs_params& _300)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _536 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, fa_probe_atlas, fa_env_smp, _300) * ((f0 * _536.x) + float3(_536.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(texture2d<float> fa_probe_atlas, sampler fa_env_smp, constant fa_mesh_fs_params& _300, thread float3& v_normal, thread float3& v_pos, thread float4& fa_frag_color)\n{\n    float3 _557 = fast::normalize(v_normal);\n    float3 _565 = fast::normalize(_300.fa_camera_pos.xyz - v_pos);\n    float param = 0.100000001490116119384765625;\n    float param_1 = fast::max(dot(_557, _565), 9.9999997473787516355514526367188e-05);\n    float2 _579 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-_565, _557);\n    float param_3 = 0.100000001490116119384765625;\n    float3 param_4 = _557;\n    float3 param_5 = _565;\n    float3 param_6 = float3(1.0);\n    float param_7 = 0.100000001490116119384765625;\n    fa_frag_color = float4(((fa_environment(param_2, param_3, fa_probe_atlas, fa_env_smp, _300) * ((float3(1.0) * _579.x) + float3(_579.y))) * 0.5) + (fa_sky_reflection(param_4, param_5, param_6, param_7, fa_probe_atlas, fa_env_smp, _300) * 0.5), 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _300 [[buffer(1)]], texture2d<float> fa_probe_atlas [[texture(0)]], sampler fa_env_smp [[sampler(10)]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    fa_user_main(fa_probe_atlas, fa_env_smp, _300, in.v_normal, in.v_pos, out.fa_frag_color);\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_113",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_300",
            "msl_buffer_n": 1
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
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 10
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _67)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _57 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_67.fa_joint_rows[_57] * weights[i]);\n        r1 += (_67.fa_joint_rows[_57 + 1] * weights[i]);\n        r2 += (_67.fa_joint_rows[_57 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_position(thread const float3& p, thread float4x4& fa_model)\n{\n    return (fa_model * float4(p, 1.0)).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_direction(thread const float3& n, thread float4x4& fa_model)\n{\n    float3 _181 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return fast::normalize((((_181 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _181) < 0.0) ? (-1.0) : 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(thread float4x4& fa_model, thread float3& fa_position, thread float3& v_pos, thread float3& v_normal, thread float3& fa_normal, thread float4& gl_Position, constant fa_mesh_vs_params& _231)\n{\n    float3 param = fa_position;\n    float3 _216 = fa_world_position(param, fa_model);\n    v_pos = _216;\n    float3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1, fa_model);\n    gl_Position = _231.fa_view_proj * float4(_216, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _231 [[buffer(0)]], constant fa_skin& _67 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 fa_model = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _67);\n    fa_user_main(fa_model, in.fa_position, out.v_pos, out.v_normal, in.fa_normal, out.gl_Position, _231);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_tr_a;\n    float4 fa_tr_b;\n    float4 fa_probe_sh[9];\n    float4 fa_atlas;\n    float4 fa_rpa_tile;\n    float4 fa_rpa_pos;\n    float4 fa_rpa_bx;\n    float4 fa_rpa_by;\n    float4 fa_rpa_bz;\n    float4 fa_rpb_tile;\n    float4 fa_rpb_pos;\n    float4 fa_rpb_bx;\n    float4 fa_rpb_by;\n    float4 fa_rpb_bz;\n    float4 fa_gi;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _493 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _496 = _493.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_496 * _496, exp2((-9.27999973297119140625) * ndv)) * _496) + _493.y)) + _493.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_oct_encode(thread const float3& d)\n{\n    float3 _90 = d / float3(fast::max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _93 = _90.x;\n    float _95 = _90.z;\n    float2 e = float2(_93, _95);\n    if (_90.y < 0.0)\n    {\n        e = float2((1.0 - abs(_95)) * ((_93 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_93)) * ((_95 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_atlas_size(texture2d<float> fa_probe_atlas, sampler fa_env_smp)\n{\n    return float2(int2(fa_probe_atlas.get_width(), fa_probe_atlas.get_height()));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_probe_level(thread const float2& origin, thread const float& res, thread const int& lv, thread const float2& e, texture2d<float> fa_probe_atlas, sampler fa_env_smp)\n{\n    float _155;\n    if (lv == 0)\n    {\n        _155 = 0.0;\n    }\n    else\n    {\n        _155 = res + 2.0;\n    }\n    float _166;\n    if (lv == 0)\n    {\n        _166 = 0.0;\n    }\n    else\n    {\n        _166 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return fa_probe_atlas.sample(fa_env_smp, ((((origin + float2(_155, _166)) + float2(1.0)) + (((e * 0.5) + float2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(fa_probe_atlas, fa_env_smp)), level(0.0)).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_probe_radiance(thread const float2& origin, thread const float& res, thread const float3& d, thread const float& rough, texture2d<float> fa_probe_atlas, sampler fa_env_smp)\n{\n    float _215;\n    if (res > 64.5)\n    {\n        _215 = 5.0;\n    }\n    else\n    {\n        _215 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _232 = fast::clamp(rough, 0.0, 1.0) * (_215 - 1.0);\n    int _239 = int(fast::min(floor(_232), _215 - 2.0));\n    float _244 = _232 - float(_239);\n    float3 param = d;\n    float2 _248 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _239;\n    float2 param_4 = _248;\n    float3 _258 = fa_probe_level(param_1, param_2, param_3, param_4, fa_probe_atlas, fa_env_smp);\n    if (_244 < 0.00200000009499490261077880859375)\n    {\n        return _258;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _239 + 1;\n    float2 param_8 = _248;\n    return mix(_258, fa_probe_level(param_5, param_6, param_7, param_8, fa_probe_atlas, fa_env_smp), float3(_244));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_probe_environment(thread const float4& tile, thread const float4& posw, thread const float4& bx, thread const float4& by, thread const float4& bz, thread const float3& d, thread const float& rough, texture2d<float> fa_probe_atlas, sampler fa_env_smp)\n{\n    float2 param = tile.xy;\n    float param_1 = tile.z;\n    float3 param_2 = d;\n    float param_3 = rough;\n    return fa_probe_radiance(param, param_1, param_2, param_3, fa_probe_atlas, fa_env_smp);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, texture2d<float> fa_probe_atlas, sampler fa_env_smp, constant fa_mesh_fs_params& _300)\n{\n    float _314 = (1.0 - _300.fa_rpa_tile.w) - _300.fa_rpb_tile.w;\n    float3 outc = float3(0.0);\n    if (_314 > 0.0005000000237487256526947021484375)\n    {\n        float3 base;\n        if (_300.fa_env_sky.w > 0.5)\n        {\n            float2 param = _300.fa_atlas.zw;\n            float param_1 = 128.0;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3, fa_probe_atlas, fa_env_smp);\n        }\n        else\n        {\n            float _346 = rough * rough;\n            float _378 = 0.60000002384185791015625 * _346;\n            base = mix(mix(_300.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_300.fa_env_horizon.xyz, _300.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _346)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _378, 0.0500000007450580596923828125 + _378, d.y))), ((_300.fa_env_sky.xyz + _300.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_346 * 0.60000002384185791015625));\n        }\n        outc = base * _314;\n    }\n    if (_300.fa_rpa_tile.w > 0.0)\n    {\n        float4 param_4 = _300.fa_rpa_tile;\n        float4 param_5 = _300.fa_rpa_pos;\n        float4 param_6 = _300.fa_rpa_bx;\n        float4 param_7 = _300.fa_rpa_by;\n        float4 param_8 = _300.fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        outc += (fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10, fa_probe_atlas, fa_env_smp) * _300.fa_rpa_tile.w);\n    }\n    if (_300.fa_rpb_tile.w > 0.0)\n    {\n        float4 param_11 = _300.fa_rpb_tile;\n        float4 param_12 = _300.fa_rpb_pos;\n        float4 param_13 = _300.fa_rpb_bx;\n        float4 param_14 = _300.fa_rpb_by;\n        float4 param_15 = _300.fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        outc += (fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17, fa_probe_atlas, fa_env_smp) * _300.fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, texture2d<float> fa_probe_atlas, sampler fa_env_smp, constant fa_mesh_fs_params& _300)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _536 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, fa_probe_atlas, fa_env_smp, _300) * ((f0 * _536.x) + float3(_536.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(texture2d<float> fa_probe_atlas, sampler fa_env_smp, constant fa_mesh_fs_params& _300, thread float3& v_normal, thread float3& v_pos, thread float4& fa_frag_color)\n{\n    float3 _557 = fast::normalize(v_normal);\n    float3 _565 = fast::normalize(_300.fa_camera_pos.xyz - v_pos);\n    float param = 0.100000001490116119384765625;\n    float param_1 = fast::max(dot(_557, _565), 9.9999997473787516355514526367188e-05);\n    float2 _579 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-_565, _557);\n    float param_3 = 0.100000001490116119384765625;\n    float3 param_4 = _557;\n    float3 param_5 = _565;\n    float3 param_6 = float3(1.0);\n    float param_7 = 0.100000001490116119384765625;\n    fa_frag_color = float4(((fa_environment(param_2, param_3, fa_probe_atlas, fa_env_smp, _300) * ((float3(1.0) * _579.x) + float3(_579.y))) * 0.5) + (fa_sky_reflection(param_4, param_5, param_6, param_7, fa_probe_atlas, fa_env_smp, _300) * 0.5), 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _300 [[buffer(1)]], texture2d<float> fa_probe_atlas [[texture(0)]], sampler fa_env_smp [[sampler(10)]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    fa_user_main(fa_probe_atlas, fa_env_smp, _300, in.v_normal, in.v_pos, out.fa_frag_color);\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_67",
            "msl_buffer_n": 3
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_231",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_300",
            "msl_buffer_n": 1
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
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 10
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
