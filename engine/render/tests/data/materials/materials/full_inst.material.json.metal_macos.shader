{
  "format": "factoria.shader/1",
  "engine": "0.34.0",
  "template": "2a036c91eca814b00bd90da318a0a52d7732eea654a0d73b16aa380e38707757",
  "slang": "metal_macos",
  "params": [
    "boost"
  ],
  "textures": [
    "height"
  ],
  "instanced": [
    {
      "name": "raise",
      "vec4": 0,
      "offset": 0,
      "components": 1
    },
    {
      "name": "tint",
      "vec4": 1,
      "offset": 0,
      "components": 4
    }
  ],
  "instanceVec4": 2,
  "full": true,
  "shadow": "custom",
  "prepass": true,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float2 v_uv [[user(locn2)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_inst_d0 [[attribute(9)]];\n    float4 fa_inst_d1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_position(thread const float3& p, thread float4x4& fa_model)\n{\n    return (fa_model * float4(p, 1.0)).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(thread float& raise, thread float4x4& fa_model, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, thread float2& fa_texcoord0, thread float3& fa_position, thread float2& v_uv, thread float4& gl_Position, constant fa_mesh_vs_params& _107)\n{\n    float3 param = fa_position;\n    v_uv = fa_texcoord0;\n    gl_Position = _107.fa_view_proj * float4(fa_world_position(param, fa_model) + float3(0.0, raise + (fa_vs_height.sample(fa_vs_height_smp, fa_texcoord0, level(0.0)).x * 0.100000001490116119384765625), 0.0), 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _107 [[buffer(0)]], texture2d<float> fa_vs_height [[texture(0)]], sampler fa_vs_height_smp [[sampler(6)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4x4 fa_model = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    fa_user_main(raise, fa_model, fa_vs_height, fa_vs_height_smp, in.fa_texcoord0, in.fa_position, out.v_uv, out.gl_Position, _107);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float2 v_uv [[user(locn2)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(thread float4& tint, texture2d<float> height, sampler height_smp, thread float2& v_uv, thread float4& fa_frag_color, constant fa_material& _64)\n{\n    fa_frag_color = float4((tint.xyz * _64.boost) * height.sample(height_smp, v_uv).x, 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_material& _64 [[buffer(5)]], texture2d<float> height [[texture(0)]], sampler height_smp [[sampler(2)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    fa_user_main(tint, height, height_smp, in.v_uv, out.fa_frag_color, _64);\n    return out;\n}\n\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_107",
            "msl_buffer_n": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_64",
            "msl_buffer_n": 5
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float2 v_uv [[user(locn2)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n    float4 fa_inst_d0 [[attribute(11)]];\n    float4 fa_inst_d1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _78)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _69 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_78.fa_joint_rows[_69] * weights[i]);\n        r1 += (_78.fa_joint_rows[_69 + 1] * weights[i]);\n        r2 += (_78.fa_joint_rows[_69 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_position(thread const float3& p, thread float4x4& fa_model)\n{\n    return (fa_model * float4(p, 1.0)).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(thread float& raise, thread float4x4& fa_model, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, thread float2& fa_texcoord0, thread float3& fa_position, thread float2& v_uv, thread float4& gl_Position, constant fa_mesh_vs_params& _227)\n{\n    float3 param = fa_position;\n    v_uv = fa_texcoord0;\n    gl_Position = _227.fa_view_proj * float4(fa_world_position(param, fa_model) + float3(0.0, raise + (fa_vs_height.sample(fa_vs_height_smp, fa_texcoord0, level(0.0)).x * 0.100000001490116119384765625), 0.0), 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _227 [[buffer(0)]], constant fa_skin& _78 [[buffer(3)]], texture2d<float> fa_vs_height [[texture(0)]], sampler fa_vs_height_smp [[sampler(6)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 fa_model = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _78);\n    fa_user_main(raise, fa_model, fa_vs_height, fa_vs_height_smp, in.fa_texcoord0, in.fa_position, out.v_uv, out.gl_Position, _227);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float2 v_uv [[user(locn2)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(thread float4& tint, texture2d<float> height, sampler height_smp, thread float2& v_uv, thread float4& fa_frag_color, constant fa_material& _64)\n{\n    fa_frag_color = float4((tint.xyz * _64.boost) * height.sample(height_smp, v_uv).x, 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_material& _64 [[buffer(5)]], texture2d<float> height [[texture(0)]], sampler height_smp [[sampler(2)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    fa_user_main(tint, height, height_smp, in.v_uv, out.fa_frag_color, _64);\n    return out;\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 12,
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
            "inst_name": "_78",
            "msl_buffer_n": 3
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_227",
            "msl_buffer_n": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_64",
            "msl_buffer_n": 5
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "prepass": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_inst_d0 [[attribute(9)]];\n    float4 fa_inst_d1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _144)\n{\n    float3 _84 = cross(model[1].xyz, model[2].xyz);\n    float _90 = (dot(model[0].xyz, _84) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_84 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _90, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _90), texcoord0 * _144.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _144, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _173 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _144);\n    float3 _334 = _173.world_pos;\n    float4 _184 = float4(_334, 1.0);\n    fa_world_pos = _334;\n    fa_world_normal = _173.world_normal;\n    fa_world_tangent = _173.world_tangent;\n    fa_uv = _173.uv;\n    fa_vertex_color = _173.color;\n    fa_pre_depth = -(_144.fa_light_vp * _184).z;\n    fa_pre_r0 = float3(_144.fa_light_vp[0].x, _144.fa_light_vp[1].x, _144.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_144.fa_light_vp[0].y, _144.fa_light_vp[1].y, _144.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_144.fa_light_vp[0].z, _144.fa_light_vp[1].z, _144.fa_light_vp[2].z);\n    gl_Position = _144.fa_view_proj * _184;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _144 [[buffer(0)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _144, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_tr_a;\n    float4 fa_tr_b;\n    float4 fa_probe_sh[9];\n    float4 fa_atlas;\n    float4 fa_rpa_tile;\n    float4 fa_rpa_pos;\n    float4 fa_rpa_bx;\n    float4 fa_rpa_by;\n    float4 fa_rpa_bz;\n    float4 fa_rpb_tile;\n    float4 fa_rpb_pos;\n    float4 fa_rpb_bx;\n    float4 fa_rpb_by;\n    float4 fa_rpb_bz;\n    float4 fa_gi;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _240 = fa_linear_to_srgb(param);\n        c = _240;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _249 = fa_srgb_to_linear(param_1);\n            c = _249;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _65;\n    if (bool(i.front_facing))\n    {\n        _65 = i.world_normal;\n    }\n    else\n    {\n        _65 = -i.world_normal;\n    }\n    float3 _89 = fast::normalize(i.world_tangent.xyz - (_65 * dot(_65, i.world_tangent.xyz)));\n    float3 _117 = fast::normalize(((_89 * m.x) + ((cross(_65, _89) * i.world_tangent.w) * m.y)) + (_65 * m.z));\n    float3 _120;\n    if (bool(i.front_facing))\n    {\n        _120 = _117;\n    }\n    else\n    {\n        _120 = -_117;\n    }\n    return _120;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _135, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _135.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _289 = fa_tex_fix(param_2, param_3);\n    float4 _845 = base_t;\n    _845.x = _289.x;\n    _845.y = _289.y;\n    _845.z = _289.z;\n    base_t = _845;\n    float4 _305 = (_845 * _135.fa_base_color) * i.vertex_color;\n    float3 _800 = i.world_normal;\n    if (_135.fa_maps.z > 0.5)\n    {\n        float param_4 = _135.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _339 = fa_tex_fix(param_6, param_7);\n        float3 _343 = (_339 * 2.0) - float3(1.0);\n        float2 _348 = _343.xy * _135.fa_maps.x;\n        float3 _853 = _343;\n        _853.x = _348.x;\n        _853.y = _348.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _853;\n        _800 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _135.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _377 = fa_tex_fix(param_12, param_13);\n    float4 _856 = mrt;\n    _856.x = _377.x;\n    _856.y = _377.y;\n    _856.z = _377.z;\n    mrt = _856;\n    float4 _407 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _135.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _407.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _419 = fa_tex_fix(param_16, param_17);\n    float param_18 = _135.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _449 = fa_tex_fix(param_20, param_21);\n    float _805 = _135.fa_layers_a.x;\n    float _806 = _135.fa_layers_a.y;\n    float _809 = _135.fa_layers_a.z;\n    float _808 = _135.fa_layers_b.w;\n    float _811 = _135.fa_layers_c.x;\n    if (_135.fa_layers_c.z > 0.5)\n    {\n        if (mod(_135.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _805 *= _419.y;\n            _806 *= _419.z;\n            _808 *= _407.w;\n        }\n        if (_135.fa_layers_c.z > 1.5)\n        {\n            _809 *= mrt.x;\n            _811 *= mrt.w;\n        }\n    }\n    return Surface{ _305.xyz, _305.w, _800, fast::clamp(_135.fa_pbr.x * _377.z, 0.0, 1.0), fast::clamp(_135.fa_pbr.y * _377.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_135.fa_maps.y * (_419.x - 1.0)), _135.fa_emissive.xyz + (_135.fa_model_emissive.xyz * _449), _805, _806, _135.fa_layers_b.xyz, _808, _809, _135.fa_layers_a.w, _811, _135.fa_layers_c.y, _135.fa_layers_d.xyz, _135.fa_tr_a.x, _135.fa_tr_a.y, _135.fa_tr_b.xyz, _135.fa_tr_a.z };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_lod_dither(constant fa_mesh_fs_params& _135, thread float4& gl_FragCoord)\n{\n    if (_135.fa_gi.w != 0.0)\n    {\n        float _157 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _160;\n        if (_135.fa_gi.w > 0.0)\n        {\n            _160 = _157 >= _135.fa_gi.w;\n        }\n        else\n        {\n            _160 = _157 < (-_135.fa_gi.w);\n        }\n        if (_160)\n        {\n            discard_fragment();\n        }\n    }\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _135 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _695 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _695 = -_695;\n    }\n    float3 _601 = fast::normalize(_135.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _695, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _601, short(gl_FrontFacing) };\n    Surface _606 = fa_standard_surface(param, _135, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _719 = _606.normal;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _695, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _601, short(gl_FrontFacing) };\n    Surface param_2 = _606;\n    surface(param_1, param_2);\n    _719 = param_2.normal;\n    fa_lod_dither(_135, gl_FragCoord);\n    float3 _617 = fast::normalize(_719);\n    float3 _632 = fast::normalize(float3(dot(in.fa_pre_r0, _617), dot(in.fa_pre_r1, _617), dot(in.fa_pre_r2, _617)));\n    float _644 = _632.z;\n    float2 e = _632.xy / float2((abs(_632.x) + abs(_632.y)) + abs(_644));\n    if (_644 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_144",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_135",
            "msl_buffer_n": 1
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
              "msl_texture_n": 0
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
              "msl_texture_n": 1
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
              "msl_texture_n": 2
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
              "msl_texture_n": 3
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
              "msl_texture_n": 4
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n    float4 fa_inst_d0 [[attribute(11)]];\n    float4 fa_inst_d1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _196)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _187 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_196.fa_joint_rows[_187] * weights[i]);\n        r1 += (_196.fa_joint_rows[_187 + 1] * weights[i]);\n        r2 += (_196.fa_joint_rows[_187 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _149)\n{\n    float3 _89 = cross(model[1].xyz, model[2].xyz);\n    float _95 = (dot(model[0].xyz, _89) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_89 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _95, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _95), texcoord0 * _149.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _149, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _286 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _149);\n    float3 _454 = _286.world_pos;\n    float4 _297 = float4(_454, 1.0);\n    fa_world_pos = _454;\n    fa_world_normal = _286.world_normal;\n    fa_world_tangent = _286.world_tangent;\n    fa_uv = _286.uv;\n    fa_vertex_color = _286.color;\n    fa_pre_depth = -(_149.fa_light_vp * _297).z;\n    fa_pre_r0 = float3(_149.fa_light_vp[0].x, _149.fa_light_vp[1].x, _149.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_149.fa_light_vp[0].y, _149.fa_light_vp[1].y, _149.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_149.fa_light_vp[0].z, _149.fa_light_vp[1].z, _149.fa_light_vp[2].z);\n    gl_Position = _149.fa_view_proj * _297;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _149 [[buffer(0)]], constant fa_skin& _196 [[buffer(3)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _196);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _149, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_tr_a;\n    float4 fa_tr_b;\n    float4 fa_probe_sh[9];\n    float4 fa_atlas;\n    float4 fa_rpa_tile;\n    float4 fa_rpa_pos;\n    float4 fa_rpa_bx;\n    float4 fa_rpa_by;\n    float4 fa_rpa_bz;\n    float4 fa_rpb_tile;\n    float4 fa_rpb_pos;\n    float4 fa_rpb_bx;\n    float4 fa_rpb_by;\n    float4 fa_rpb_bz;\n    float4 fa_gi;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float3 fa_world_pos [[user(locn2)]];\n    float3 fa_world_normal [[user(locn3)]];\n    float4 fa_world_tangent [[user(locn4)]];\n    float2 fa_uv [[user(locn5)]];\n    float4 fa_vertex_color [[user(locn6)]];\n    float fa_pre_depth [[user(locn7)]];\n    float3 fa_pre_r0 [[user(locn8)]];\n    float3 fa_pre_r1 [[user(locn9)]];\n    float3 fa_pre_r2 [[user(locn10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _240 = fa_linear_to_srgb(param);\n        c = _240;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _249 = fa_srgb_to_linear(param_1);\n            c = _249;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _65;\n    if (bool(i.front_facing))\n    {\n        _65 = i.world_normal;\n    }\n    else\n    {\n        _65 = -i.world_normal;\n    }\n    float3 _89 = fast::normalize(i.world_tangent.xyz - (_65 * dot(_65, i.world_tangent.xyz)));\n    float3 _117 = fast::normalize(((_89 * m.x) + ((cross(_65, _89) * i.world_tangent.w) * m.y)) + (_65 * m.z));\n    float3 _120;\n    if (bool(i.front_facing))\n    {\n        _120 = _117;\n    }\n    else\n    {\n        _120 = -_117;\n    }\n    return _120;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _135, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _135.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _289 = fa_tex_fix(param_2, param_3);\n    float4 _845 = base_t;\n    _845.x = _289.x;\n    _845.y = _289.y;\n    _845.z = _289.z;\n    base_t = _845;\n    float4 _305 = (_845 * _135.fa_base_color) * i.vertex_color;\n    float3 _800 = i.world_normal;\n    if (_135.fa_maps.z > 0.5)\n    {\n        float param_4 = _135.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _339 = fa_tex_fix(param_6, param_7);\n        float3 _343 = (_339 * 2.0) - float3(1.0);\n        float2 _348 = _343.xy * _135.fa_maps.x;\n        float3 _853 = _343;\n        _853.x = _348.x;\n        _853.y = _348.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _853;\n        _800 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _135.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _377 = fa_tex_fix(param_12, param_13);\n    float4 _856 = mrt;\n    _856.x = _377.x;\n    _856.y = _377.y;\n    _856.z = _377.z;\n    mrt = _856;\n    float4 _407 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _135.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _407.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _419 = fa_tex_fix(param_16, param_17);\n    float param_18 = _135.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _449 = fa_tex_fix(param_20, param_21);\n    float _805 = _135.fa_layers_a.x;\n    float _806 = _135.fa_layers_a.y;\n    float _809 = _135.fa_layers_a.z;\n    float _808 = _135.fa_layers_b.w;\n    float _811 = _135.fa_layers_c.x;\n    if (_135.fa_layers_c.z > 0.5)\n    {\n        if (mod(_135.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _805 *= _419.y;\n            _806 *= _419.z;\n            _808 *= _407.w;\n        }\n        if (_135.fa_layers_c.z > 1.5)\n        {\n            _809 *= mrt.x;\n            _811 *= mrt.w;\n        }\n    }\n    return Surface{ _305.xyz, _305.w, _800, fast::clamp(_135.fa_pbr.x * _377.z, 0.0, 1.0), fast::clamp(_135.fa_pbr.y * _377.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_135.fa_maps.y * (_419.x - 1.0)), _135.fa_emissive.xyz + (_135.fa_model_emissive.xyz * _449), _805, _806, _135.fa_layers_b.xyz, _808, _809, _135.fa_layers_a.w, _811, _135.fa_layers_c.y, _135.fa_layers_d.xyz, _135.fa_tr_a.x, _135.fa_tr_a.y, _135.fa_tr_b.xyz, _135.fa_tr_a.z };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_lod_dither(constant fa_mesh_fs_params& _135, thread float4& gl_FragCoord)\n{\n    if (_135.fa_gi.w != 0.0)\n    {\n        float _157 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _160;\n        if (_135.fa_gi.w > 0.0)\n        {\n            _160 = _157 >= _135.fa_gi.w;\n        }\n        else\n        {\n            _160 = _157 < (-_135.fa_gi.w);\n        }\n        if (_160)\n        {\n            discard_fragment();\n        }\n    }\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _135 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    float3 _695 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _695 = -_695;\n    }\n    float3 _601 = fast::normalize(_135.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _695, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _601, short(gl_FrontFacing) };\n    Surface _606 = fa_standard_surface(param, _135, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _719 = _606.normal;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _695, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _601, short(gl_FrontFacing) };\n    Surface param_2 = _606;\n    surface(param_1, param_2);\n    _719 = param_2.normal;\n    fa_lod_dither(_135, gl_FragCoord);\n    float3 _617 = fast::normalize(_719);\n    float3 _632 = fast::normalize(float3(dot(in.fa_pre_r0, _617), dot(in.fa_pre_r1, _617), dot(in.fa_pre_r2, _617)));\n    float _644 = _632.z;\n    float2 e = _632.xy / float2((abs(_632.x) + abs(_632.y)) + abs(_644));\n    if (_644 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 12,
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
            "inst_name": "_149",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_196",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_135",
            "msl_buffer_n": 1
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
              "msl_texture_n": 0
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
              "msl_texture_n": 1
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
              "msl_texture_n": 2
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
              "msl_texture_n": 3
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
              "msl_texture_n": 4
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float2 v_uv [[user(locn2)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float2 fa_texcoord0 [[attribute(6)]];\n    float4 fa_inst_d0 [[attribute(9)]];\n    float4 fa_inst_d1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_position(thread const float3& p, thread float4x4& fa_model)\n{\n    return (fa_model * float4(p, 1.0)).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(thread float& raise, thread float4x4& fa_model, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, thread float2& fa_texcoord0, thread float3& fa_position, thread float2& v_uv, thread float4& gl_Position, constant fa_mesh_vs_params& _107)\n{\n    float3 param = fa_position;\n    v_uv = fa_texcoord0;\n    gl_Position = _107.fa_light_vp * float4(fa_world_position(param, fa_model) + float3(0.0, raise + (fa_vs_height.sample(fa_vs_height_smp, fa_texcoord0, level(0.0)).x * 0.100000001490116119384765625), 0.0), 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _107 [[buffer(0)]], texture2d<float> fa_vs_height [[texture(0)]], sampler fa_vs_height_smp [[sampler(6)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4x4 fa_model = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    fa_user_main(raise, fa_model, fa_vs_height, fa_vs_height_smp, in.fa_texcoord0, in.fa_position, out.v_uv, out.gl_Position, _107);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float2 v_uv [[user(locn2)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(thread float4& tint, texture2d<float> height, sampler height_smp, thread float2& v_uv, thread float4& fa_frag_color, constant fa_material& _71)\n{\n    float4 _55 = height.sample(height_smp, v_uv);\n    float _56 = _55.x;\n    if (_56 < 0.00999999977648258209228515625)\n    {\n        discard_fragment();\n    }\n    fa_frag_color = float4((tint.xyz * _71.boost) * _56, 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_material& _71 [[buffer(5)]], texture2d<float> height [[texture(0)]], sampler height_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    fa_user_main(tint, height, height_smp, in.v_uv, out.fa_frag_color, _71);\n    out.fa_frag_color = float4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n    return out;\n}\n\n",
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
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec4",
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
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec2",
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
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_107",
            "msl_buffer_n": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_71",
            "msl_buffer_n": 5
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float4 fa_inst_v0 [[user(locn0)]];\n    float4 fa_inst_v1 [[user(locn1)]];\n    float2 v_uv [[user(locn2)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float4 fa_joints [[attribute(5)]];\n    float4 fa_weights [[attribute(6)]];\n    float2 fa_texcoord0 [[attribute(8)]];\n    float4 fa_inst_d0 [[attribute(11)]];\n    float4 fa_inst_d1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float& raise, thread float4& tint, thread float4& fa_inst_d0, thread float4& fa_inst_d1, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _78)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _69 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_78.fa_joint_rows[_69] * weights[i]);\n        r1 += (_78.fa_joint_rows[_69 + 1] * weights[i]);\n        r2 += (_78.fa_joint_rows[_69 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_position(thread const float3& p, thread float4x4& fa_model)\n{\n    return (fa_model * float4(p, 1.0)).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(thread float& raise, thread float4x4& fa_model, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, thread float2& fa_texcoord0, thread float3& fa_position, thread float2& v_uv, thread float4& gl_Position, constant fa_mesh_vs_params& _227)\n{\n    float3 param = fa_position;\n    v_uv = fa_texcoord0;\n    gl_Position = _227.fa_light_vp * float4(fa_world_position(param, fa_model) + float3(0.0, raise + (fa_vs_height.sample(fa_vs_height_smp, fa_texcoord0, level(0.0)).x * 0.100000001490116119384765625), 0.0), 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _227 [[buffer(0)]], constant fa_skin& _78 [[buffer(3)]], texture2d<float> fa_vs_height [[texture(0)]], sampler fa_vs_height_smp [[sampler(6)]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_begin(raise, tint, in.fa_inst_d0, in.fa_inst_d1, out.fa_inst_v0, out.fa_inst_v1);\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 fa_model = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _78);\n    fa_user_main(raise, fa_model, fa_vs_height, fa_vs_height_smp, in.fa_texcoord0, in.fa_position, out.v_uv, out.gl_Position, _227);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 fa_inst_v0 [[user(locn0), flat]];\n    float4 fa_inst_v1 [[user(locn1), flat]];\n    float2 v_uv [[user(locn2)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& raise, thread float4& tint)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& raise, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, raise, tint);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(thread float4& tint, texture2d<float> height, sampler height_smp, thread float2& v_uv, thread float4& fa_frag_color, constant fa_material& _71)\n{\n    float4 _55 = height.sample(height_smp, v_uv);\n    float _56 = _55.x;\n    if (_56 < 0.00999999977648258209228515625)\n    {\n        discard_fragment();\n    }\n    fa_frag_color = float4((tint.xyz * _71.boost) * _56, 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_material& _71 [[buffer(5)]], texture2d<float> height [[texture(0)]], sampler height_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float raise;\n    float4 tint;\n    fa_inst_load(raise, tint, in.fa_inst_v0, in.fa_inst_v1);\n    fa_user_main(tint, height, height_smp, in.v_uv, out.fa_frag_color, _71);\n    out.fa_frag_color = float4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n    return out;\n}\n\n",
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
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec4",
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
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec2",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 12,
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
            "inst_name": "_78",
            "msl_buffer_n": 3
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_227",
            "msl_buffer_n": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_71",
            "msl_buffer_n": 5
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    }
  }
}
