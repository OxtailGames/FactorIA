{
  "format": "factoria.shader/1",
  "engine": "0.39.0",
  "template": "60177e0de1a42674d2e25fce0459f055d4bbaa0faf939ebaf036f3e7d4d67c34",
  "slang": "hlsl5",
  "params": [
    "factor",
    "offset"
  ],
  "textures": [],
  "kind": "compute",
  "workgroupSize": [
    64,
    1,
    1
  ],
  "buffers": [
    {
      "name": "items",
      "binding": 0,
      "stride": 24,
      "access": "readWrite",
      "fields": [
        {
          "name": "value",
          "type": "float",
          "offset": 0
        },
        {
          "name": "pos",
          "type": "vec2",
          "offset": 8
        },
        {
          "name": "id",
          "type": "uint",
          "offset": 16
        },
        {
          "name": "steps",
          "type": "int",
          "offset": 20
        }
      ]
    }
  ],
  "programs": {
    "compute": {
      "cs": "struct ComputeInput\n{\n    uint3 global_id;\n    uint3 local_id;\n    uint3 group_id;\n    uint local_index;\n};\n\nstruct items_item\n{\n    float value;\n    float2 pos;\n    uint id;\n    int steps;\n};\n\nstatic const uint3 gl_WorkGroupSize = uint3(64u, 1u, 1u);\n\nRWByteAddressBuffer items : register(u0);\ncbuffer fa_material : register(b0)\n{\n    float _35_factor : packoffset(c0);\n    float _35_fa_pad0 : packoffset(c0.y);\n    float _35_fa_pad1 : packoffset(c0.z);\n    float _35_fa_pad2 : packoffset(c0.w);\n    float2 _35_offset : packoffset(c1);\n    float _35_fa_pad3 : packoffset(c1.z);\n    float _35_fa_pad4 : packoffset(c1.w);\n};\n\n\nstatic uint3 gl_WorkGroupID;\nstatic uint3 gl_LocalInvocationID;\nstatic uint3 gl_GlobalInvocationID;\nstatic uint gl_LocalInvocationIndex;\nstruct SPIRV_Cross_Input\n{\n    uint3 gl_WorkGroupID : SV_GroupID;\n    uint3 gl_LocalInvocationID : SV_GroupThreadID;\n    uint3 gl_GlobalInvocationID : SV_DispatchThreadID;\n    uint gl_LocalInvocationIndex : SV_GroupIndex;\n};\n\nvoid compute(ComputeInput i)\n{\n    items.Store(i.global_id.x * 24 + 0, asuint(asfloat(items.Load(i.global_id.x * 24 + 0)) * _35_factor));\n    items.Store2(i.global_id.x * 24 + 8, asuint(asfloat(items.Load2(i.global_id.x * 24 + 8)) + _35_offset));\n    items.Store(i.global_id.x * 24 + 16, i.global_id.x);\n    items.Store(i.global_id.x * 24 + 20, uint(int(items.Load(i.global_id.x * 24 + 20)) + 1));\n}\n\nvoid comp_main()\n{\n    ComputeInput _94 = { gl_GlobalInvocationID, gl_LocalInvocationID, gl_WorkGroupID, gl_LocalInvocationIndex };\n    ComputeInput param = _94;\n    compute(param);\n}\n\n[numthreads(64, 1, 1)]\nvoid main(SPIRV_Cross_Input stage_input)\n{\n    gl_WorkGroupID = stage_input.gl_WorkGroupID;\n    gl_LocalInvocationID = stage_input.gl_LocalInvocationID;\n    gl_GlobalInvocationID = stage_input.gl_GlobalInvocationID;\n    gl_LocalInvocationIndex = stage_input.gl_LocalInvocationIndex;\n    comp_main();\n}\n",
      "reflection": {
        "compute_func": {
          "entry_point": "main",
          "d3d11_target": "cs_5_0"
        },
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "compute",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_35",
            "hlsl_register_b_n": 0
          }
        ],
        "views": [
          {
            "storage_buffer": {
              "slot": 0,
              "stage": "compute",
              "size": 24,
              "align": 8,
              "struct_name": "fa_items_buf",
              "inst_name": "items",
              "inner_struct_name": "items_item",
              "readonly": false,
              "hlsl_register_u_n": 0
            }
          }
        ]
      }
    }
  }
}
