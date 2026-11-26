{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "7c44336a36b0e488acf8da22082448b78ea1f9f5463402bb07a466e45eb7be80",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "vertexAttributes": [
    "color1",
    "uv1"
  ],
  "full": true,
  "shadow": "depth",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float4 v_color [[user(locn0)]];\n    float2 v_uv [[user(locn1)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float2 fa_attr_uv1 [[attribute(9)]];\n    float4 fa_attr_color1 [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float2& vertex_uv1, thread float2& fa_attr_uv1, thread float4& vertex_color1, thread float4& fa_attr_color1)\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_position(thread const float3& p, thread float4x4& fa_model)\n{\n    return (fa_model * float4(p, 1.0)).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(thread float2& vertex_uv1, thread float4& vertex_color1, thread float4x4& fa_model, thread float4& v_color, thread float2& v_uv, thread float4& gl_Position, constant fa_mesh_vs_params& _59, thread float3& fa_position)\n{\n    v_color = vertex_color1;\n    v_uv = vertex_uv1;\n    float3 param = fa_position;\n    gl_Position = _59.fa_view_proj * float4(fa_world_position(param, fa_model), 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _59 [[buffer(0)]])\n{\n    main0_out out = {};\n    float2 vertex_uv1;\n    float4 vertex_color1;\n    fa_inst_begin(vertex_uv1, in.fa_attr_uv1, vertex_color1, in.fa_attr_color1);\n    float4x4 fa_model = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    fa_user_main(vertex_uv1, vertex_color1, fa_model, out.v_color, out.v_uv, out.gl_Position, _59, in.fa_position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 v_color [[user(locn0)]];\n    float2 v_uv [[user(locn1)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(thread float4& fa_frag_color, thread float4& v_color, thread float2& v_uv)\n{\n    fa_frag_color = float4(v_color.xyz * (v_uv.x * 2.0), 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    fa_user_main(out.fa_frag_color, in.v_color, in.v_uv);\n    return out;\n}\n\n",
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
            "type": "vec2",
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
            "inst_name": "_59",
            "msl_buffer_n": 0
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float4 v_color [[user(locn0)]];\n    float2 v_uv [[user(locn1)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n    float2 fa_attr_uv1 [[attribute(11)]];\n    float4 fa_attr_color1 [[attribute(12)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin(thread float2& vertex_uv1, thread float2& fa_attr_uv1, thread float4& vertex_color1, thread float4& fa_attr_color1)\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _64)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _54 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_64.fa_joint_rows[_54] * weights[i]);\n        r1 += (_64.fa_joint_rows[_54 + 1] * weights[i]);\n        r2 += (_64.fa_joint_rows[_54 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_position(thread const float3& p, thread float4x4& fa_model)\n{\n    return (fa_model * float4(p, 1.0)).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(thread float2& vertex_uv1, thread float4& vertex_color1, thread float4x4& fa_model, thread float4& v_color, thread float2& v_uv, thread float4& gl_Position, constant fa_mesh_vs_params& _184, thread float3& fa_position)\n{\n    v_color = vertex_color1;\n    v_uv = vertex_uv1;\n    float3 param = fa_position;\n    gl_Position = _184.fa_view_proj * float4(fa_world_position(param, fa_model), 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _184 [[buffer(0)]], constant fa_skin& _64 [[buffer(3)]])\n{\n    main0_out out = {};\n    float2 vertex_uv1;\n    float4 vertex_color1;\n    fa_inst_begin(vertex_uv1, in.fa_attr_uv1, vertex_color1, in.fa_attr_color1);\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 fa_model = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _64);\n    fa_user_main(vertex_uv1, vertex_color1, fa_model, out.v_color, out.v_uv, out.gl_Position, _184, in.fa_position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float4 v_color [[user(locn0)]];\n    float2 v_uv [[user(locn1)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(thread float4& fa_frag_color, thread float4& v_color, thread float2& v_uv)\n{\n    fa_frag_color = float4(v_color.xyz * (v_uv.x * 2.0), 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    fa_user_main(out.fa_frag_color, in.v_color, in.v_uv);\n    return out;\n}\n\n",
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
            "type": "vec2",
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
            "inst_name": "_64",
            "msl_buffer_n": 3
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_184",
            "msl_buffer_n": 0
          }
        ]
      }
    }
  }
}
