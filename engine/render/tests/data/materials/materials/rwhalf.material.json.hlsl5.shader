{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "60177e0de1a42674d2e25fce0459f055d4bbaa0faf939ebaf036f3e7d4d67c34",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "kind": "compute",
  "workgroupSize": [
    8,
    8,
    1
  ],
  "buffers": [],
  "images": [
    {
      "name": "acc",
      "binding": 0,
      "format": "rgba16f",
      "access": "readWrite",
      "width": 8,
      "height": 8
    }
  ],
  "programs": {
    "compute": {
      "cs": "struct ComputeInput\n{\n    uint3 global_id;\n    uint3 local_id;\n    uint3 group_id;\n    uint local_index;\n};\n\nstatic const uint3 gl_WorkGroupSize = uint3(8u, 8u, 1u);\n\nRWTexture2D<float4> acc : register(u0);\n\nstatic uint3 gl_WorkGroupID;\nstatic uint3 gl_LocalInvocationID;\nstatic uint3 gl_GlobalInvocationID;\nstatic uint gl_LocalInvocationIndex;\nstruct SPIRV_Cross_Input\n{\n    uint3 gl_WorkGroupID : SV_GroupID;\n    uint3 gl_LocalInvocationID : SV_GroupThreadID;\n    uint3 gl_GlobalInvocationID : SV_DispatchThreadID;\n    uint gl_LocalInvocationIndex : SV_GroupIndex;\n};\n\nuint2 spvImageSize(RWTexture2D<float4> Tex, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(ret.x, ret.y);\n    Param = 0u;\n    return ret;\n}\n\nvoid compute(ComputeInput i)\n{\n    int2 _24 = int2(i.global_id.xy);\n    uint _31_dummy_parameter;\n    int2 _31 = int2(spvImageSize(acc, _31_dummy_parameter));\n    bool _39 = _24.x >= _31.x;\n    bool _49;\n    if (!_39)\n    {\n        _49 = _24.y >= _31.y;\n    }\n    else\n    {\n        _49 = _39;\n    }\n    if (_49)\n    {\n        return;\n    }\n    acc[_24] = acc[_24] + float4(0.5f, 1.0f, 2.0f, 3.0f);\n}\n\nvoid comp_main()\n{\n    ComputeInput _100 = { gl_GlobalInvocationID, gl_LocalInvocationID, gl_WorkGroupID, gl_LocalInvocationIndex };\n    ComputeInput param = _100;\n    compute(param);\n}\n\n[numthreads(8, 8, 1)]\nvoid main(SPIRV_Cross_Input stage_input)\n{\n    gl_WorkGroupID = stage_input.gl_WorkGroupID;\n    gl_LocalInvocationID = stage_input.gl_LocalInvocationID;\n    gl_GlobalInvocationID = stage_input.gl_GlobalInvocationID;\n    gl_LocalInvocationIndex = stage_input.gl_LocalInvocationIndex;\n    comp_main();\n}\n",
      "reflection": {
        "compute_func": {
          "entry_point": "main",
          "d3d11_target": "cs_5_0"
        },
        "views": [
          {
            "storage_image": {
              "slot": 0,
              "stage": "compute",
              "name": "acc",
              "type": "2d",
              "access_format": "RGBA16F",
              "writeonly": false,
              "hlsl_register_u_n": 0
            }
          }
        ]
      }
    }
  }
}
