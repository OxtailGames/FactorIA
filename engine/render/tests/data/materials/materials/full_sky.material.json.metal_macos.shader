{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "7254e74e29af6bafcca869852868d8b8b5eac24171f4f425b9ec9fdb31dab17f",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _155 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _159 = _155.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_159 * _159, exp2((-9.27999973297119140625) * ndv)) * _159) + _155.y)) + _155.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _35, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_35.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _35.fa_env_horizon.w)).xyz;\n    }\n    float _73 = rough * rough;\n    float _106 = 0.60000002384185791015625 * _73;\n    return mix(mix(_35.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_35.fa_env_horizon.xyz, _35.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _73)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _106, 0.0500000007450580596923828125 + _106, d.y))), ((_35.fa_env_sky.xyz + _35.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_73 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _35, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _200 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _35, fa_env_tex, fa_env_smp) * ((f0 * _200.x) + float3(_200.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(constant fa_mesh_fs_params& _35, texturecube<float> fa_env_tex, sampler fa_env_smp, thread float3& v_normal, thread float3& v_pos, thread float4& fa_frag_color)\n{\n    float3 _221 = fast::normalize(v_normal);\n    float3 _230 = fast::normalize(_35.fa_camera_pos.xyz - v_pos);\n    float param = 0.100000001490116119384765625;\n    float param_1 = fast::max(dot(_221, _230), 9.9999997473787516355514526367188e-05);\n    float2 _244 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-_230, _221);\n    float param_3 = 0.100000001490116119384765625;\n    float3 param_4 = _221;\n    float3 param_5 = _230;\n    float3 param_6 = float3(1.0);\n    float param_7 = 0.100000001490116119384765625;\n    fa_frag_color = float4(((fa_environment(param_2, param_3, _35, fa_env_tex, fa_env_smp) * ((float3(1.0) * _244.x) + float3(_244.y))) * 0.5) + (fa_sky_reflection(param_4, param_5, param_6, param_7, _35, fa_env_tex, fa_env_smp) * 0.5), 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _35 [[buffer(1)]], texturecube<float> fa_env_tex [[texture(0)]], sampler fa_env_smp [[sampler(10)]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    fa_user_main(_35, fa_env_tex, fa_env_smp, in.v_normal, in.v_pos, out.fa_frag_color);\n    return out;\n}\n\n",
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
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_35",
            "msl_buffer_n": 1
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _67)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _57 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_67.fa_joint_rows[_57] * weights[i]);\n        r1 += (_67.fa_joint_rows[_57 + 1] * weights[i]);\n        r2 += (_67.fa_joint_rows[_57 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_position(thread const float3& p, thread float4x4& fa_model)\n{\n    return (fa_model * float4(p, 1.0)).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_direction(thread const float3& n, thread float4x4& fa_model)\n{\n    float3 _181 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return fast::normalize((((_181 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _181) < 0.0) ? (-1.0) : 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(thread float4x4& fa_model, thread float3& fa_position, thread float3& v_pos, thread float3& v_normal, thread float3& fa_normal, thread float4& gl_Position, constant fa_mesh_vs_params& _231)\n{\n    float3 param = fa_position;\n    float3 _216 = fa_world_position(param, fa_model);\n    v_pos = _216;\n    float3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1, fa_model);\n    gl_Position = _231.fa_view_proj * float4(_216, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _231 [[buffer(0)]], constant fa_skin& _67 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 fa_model = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _67);\n    fa_user_main(fa_model, in.fa_position, out.v_pos, out.v_normal, in.fa_normal, out.gl_Position, _231);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _155 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _159 = _155.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_159 * _159, exp2((-9.27999973297119140625) * ndv)) * _159) + _155.y)) + _155.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _35, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_35.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _35.fa_env_horizon.w)).xyz;\n    }\n    float _73 = rough * rough;\n    float _106 = 0.60000002384185791015625 * _73;\n    return mix(mix(_35.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_35.fa_env_horizon.xyz, _35.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _73)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _106, 0.0500000007450580596923828125 + _106, d.y))), ((_35.fa_env_sky.xyz + _35.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_73 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _35, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _200 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _35, fa_env_tex, fa_env_smp) * ((f0 * _200.x) + float3(_200.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(constant fa_mesh_fs_params& _35, texturecube<float> fa_env_tex, sampler fa_env_smp, thread float3& v_normal, thread float3& v_pos, thread float4& fa_frag_color)\n{\n    float3 _221 = fast::normalize(v_normal);\n    float3 _230 = fast::normalize(_35.fa_camera_pos.xyz - v_pos);\n    float param = 0.100000001490116119384765625;\n    float param_1 = fast::max(dot(_221, _230), 9.9999997473787516355514526367188e-05);\n    float2 _244 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-_230, _221);\n    float param_3 = 0.100000001490116119384765625;\n    float3 param_4 = _221;\n    float3 param_5 = _230;\n    float3 param_6 = float3(1.0);\n    float param_7 = 0.100000001490116119384765625;\n    fa_frag_color = float4(((fa_environment(param_2, param_3, _35, fa_env_tex, fa_env_smp) * ((float3(1.0) * _244.x) + float3(_244.y))) * 0.5) + (fa_sky_reflection(param_4, param_5, param_6, param_7, _35, fa_env_tex, fa_env_smp) * 0.5), 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _35 [[buffer(1)]], texturecube<float> fa_env_tex [[texture(0)]], sampler fa_env_smp [[sampler(10)]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    fa_user_main(_35, fa_env_tex, fa_env_smp, in.v_normal, in.v_pos, out.fa_frag_color);\n    return out;\n}\n\n",
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
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_35",
            "msl_buffer_n": 1
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
