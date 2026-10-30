{
  "format": "factoria.shader/1",
  "engine": "0.1.6",
  "template": "a75dcd870d51444499f61f3cb2010a1b06d96d8916439ce459176478546f3cd8",
  "slang": "hlsl5",
  "params": [
    "alphaCutoff"
  ],
  "textures": [
    "mask"
  ],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _129_fa_view_proj : packoffset(c0);\n    row_major float4x4 _129_fa_light_vp : packoffset(c4);\n    float4 _129_fa_uv_scale : packoffset(c8);\n    float4 _129_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _67 = cross(model[1].xyz, model[2].xyz);\n    float _73 = (dot(model[0].xyz, _67) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _269 = { mul(float4(position, 1.0f), model).xyz, (((_67 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _73, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _73), texcoord0 * _129_fa_uv_scale.xy, color, position };\n    return _269;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _158 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _276 = _158.world_pos;\n    float4 _165 = float4(_276, 1.0f);\n    fa_world_pos = _276;\n    fa_world_normal = _158.world_normal;\n    fa_world_tangent = _158.world_tangent;\n    fa_uv = _158.uv;\n    fa_vertex_color = _158.color;\n    fa_shadow_pos = mul(_165, _129_fa_light_vp);\n    gl_Position = mul(_165, _129_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _148_fa_camera_pos : packoffset(c0);\n    float4 _148_fa_ambient : packoffset(c1);\n    float4 _148_fa_base_color : packoffset(c2);\n    float4 _148_fa_emissive : packoffset(c3);\n    float4 _148_fa_model_emissive : packoffset(c4);\n    float4 _148_fa_pbr : packoffset(c5);\n    float4 _148_fa_maps : packoffset(c6);\n    float4 _148_fa_fog : packoffset(c7);\n    float4 _148_fa_counts : packoffset(c8);\n    float4 _148_fa_env_sky : packoffset(c9);\n    float4 _148_fa_env_horizon : packoffset(c10);\n    float4 _148_fa_time : packoffset(c11);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _567_alphaCutoff : packoffset(c0);\n    float _567_fa_pad0 : packoffset(c0.y);\n    float _567_fa_pad1 : packoffset(c0.z);\n    float _567_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _664_fa_light_pos[32] : packoffset(c0);\n    float4 _664_fa_light_color[32] : packoffset(c32);\n    float4 _664_fa_light_dir[32] : packoffset(c64);\n};\n\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _52;\n    if (i.front_facing)\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    float3 _77 = normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    float3 _105 = normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    float3 _108;\n    if (i.front_facing)\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 _145 = fa_tex.Sample(fa_smp, i.uv);\n    float4 _156 = (_145 * _148_fa_base_color) * i.vertex_color;\n    float3 _973 = i.world_normal;\n    if (_148_fa_maps.z > 0.5f)\n    {\n        float3 _187 = (fa_normal_tex.Sample(fa_smp, i.uv).xyz * 2.0f) - 1.0f.xxx;\n        float2 _192 = _187.xy * _148_fa_maps.x;\n        float3 _990 = _187;\n        _990.x = _192.x;\n        _990.y = _192.y;\n        SurfaceInput param = i;\n        float3 param_1 = _990;\n        _973 = fa_tangent_normal(param, param_1);\n    }\n    float4 _210 = fa_mr_tex.Sample(fa_smp, i.uv);\n    Surface _985 = { _156.xyz, _156.w, _973, clamp(_148_fa_pbr.x * _210.z, 0.0f, 1.0f), clamp(_148_fa_pbr.y * _210.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_148_fa_maps.y * (fa_occlusion_tex.Sample(fa_smp, i.uv).x - 1.0f)), _148_fa_emissive.xyz + (_148_fa_model_emissive.xyz * fa_emissive_tex.Sample(fa_smp, i.uv).xyz) };\n    return _985;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    if (_148_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _277 = fa_shadow_pos.xyz / fa_shadow_pos.w.xxx;\n    float3 p = _277;\n    float2 suv = (_277.xy * 0.5f) + 0.5f.xx;\n    if (_148_fa_counts.z > 0.5f)\n    {\n        float3 _995 = p;\n        _995.z = (_995.z * 0.5f) + 0.5f;\n        p = _995;\n    }\n    else\n    {\n        float2 _998 = suv;\n        _998.y = 1.0f - _998.y;\n        suv = _998;\n    }\n    bool _304 = suv.x < 0.0f;\n    bool _311;\n    if (!_304)\n    {\n        _311 = suv.x > 1.0f;\n    }\n    else\n    {\n        _311 = _304;\n    }\n    bool _318;\n    if (!_311)\n    {\n        _318 = suv.y < 0.0f;\n    }\n    else\n    {\n        _318 = _311;\n    }\n    bool _325;\n    if (!_318)\n    {\n        _325 = suv.y > 1.0f;\n    }\n    else\n    {\n        _325 = _318;\n    }\n    bool _332;\n    if (!_325)\n    {\n        _332 = p.z > 1.0f;\n    }\n    else\n    {\n        _332 = _325;\n    }\n    if (_332)\n    {\n        return 1.0f;\n    }\n    float _346 = _148_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _346) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _148_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _487 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _490 = _487.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_490 * _490, exp2((-9.27999973297119140625f) * ndv)) * _490) + _487.y)) + _487.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _407 = rough * rough;\n    float _440 = 0.60000002384185791015625f * _407;\n    return lerp(lerp(_148_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_148_fa_env_horizon.xyz, _148_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _407)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _440, 0.0500000007450580596923828125f + _440, d.y).xxx), ((_148_fa_env_sky.xyz + _148_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_407 * 0.60000002384185791015625f).xxx);\n}\n\nvoid frag_main()\n{\n    float3 _920 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _920 = -_920;\n    }\n    float3 _550 = _148_fa_camera_pos.xyz - fa_world_pos;\n    float3 _551 = normalize(_550);\n    SurfaceInput _933 = { fa_world_pos, _920, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing };\n    SurfaceInput param = _933;\n    Surface _556 = fa_standard_surface(param);\n    float3 _942 = _556.albedo;\n    float _943 = _556.alpha;\n    float3 _944 = _556.normal;\n    float _945 = _556.metallic;\n    float _946 = _556.roughness;\n    float _947 = _556.occlusion;\n    float3 _948 = _556.emission;\n    SurfaceInput _941 = { fa_world_pos, _920, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing };\n    SurfaceInput param_1 = _941;\n    Surface param_2 = _556;\n    surface(param_1, param_2);\n    _942 = param_2.albedo;\n    _943 = param_2.alpha;\n    _944 = param_2.normal;\n    _945 = param_2.metallic;\n    _946 = param_2.roughness;\n    _947 = param_2.occlusion;\n    _948 = param_2.emission;\n    if (param_2.alpha < _567_alphaCutoff)\n    {\n        discard;\n    }\n    float3 result;\n    if (_148_fa_emissive.w > 0.5f)\n    {\n        result = _942;\n    }\n    else\n    {\n        float3 _589 = normalize(_944);\n        float _596 = clamp(_945, 0.0f, 1.0f);\n        float _600 = clamp(_946, 0.0500000007450580596923828125f, 1.0f);\n        float _604 = _600 * _600;\n        float _608 = _604 * _604;\n        float _614 = max(dot(_589, _551), 9.9999997473787516355514526367188e-05f);\n        float3 _620 = _942 * (1.0f - _596);\n        float3 _628 = lerp(0.039999999105930328369140625f.xxx, _942, _596.xxx);\n        float3 lit = (_148_fa_ambient.xyz * _620) * _947;\n        int _641 = int(_148_fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _641)\n            {\n                break;\n            }\n            float atten = 1.0f;\n            bool _670 = _664_fa_light_color[li].w < 0.5f;\n            if (_670)\n            {\n                l = normalize(_664_fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _687 = _664_fa_light_pos[li].xyz - fa_world_pos;\n                float _690 = length(_687);\n                l = _687 / max(_690, 9.9999997473787516355514526367188e-05f).xxx;\n                float _705 = _690 / max(_664_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n                float _711 = clamp(1.0f - (_705 * _705), 0.0f, 1.0f);\n                atten = _711 * _711;\n                if (_664_fa_light_color[li].w > 1.5f)\n                {\n                    atten *= smoothstep(_664_fa_light_dir[li].w, lerp(_664_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_664_fa_light_dir[li].xyz)));\n                }\n            }\n            float _745 = max(dot(_589, l), 0.0f);\n            if (_670 && (li == 0))\n            {\n                float3 param_3 = _920;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            float3 _764 = normalize(l + _551);\n            float _769 = max(dot(_589, _764), 0.0f);\n            float _782 = ((_769 * _769) * (_608 - 1.0f)) + 1.0f;\n            lit += (((_620 + (((_628 + ((1.0f.xxx - _628) * pow(1.0f - max(dot(_551, _764), 0.0f), 5.0f))) * (((_608 / ((3.1415927410125732421875f * _782) * _782)) * (0.5f / max(lerp((2.0f * _745) * _614, _745 + _614, _604), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _745))) * _664_fa_light_color[li].xyz) * (_745 * atten));\n        }\n        float param_5 = _600;\n        float param_6 = _614;\n        float2 _850 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_551, _589);\n        float param_8 = _600;\n        float3 _868 = lit;\n        float3 _869 = _868 + ((fa_environment(param_7, param_8) * ((_628 * _850.x) + _850.y.xxx)) * _947);\n        lit = _869;\n        result = _869;\n    }\n    result += _948;\n    if (_148_fa_fog.w > 0.0f)\n    {\n        float _893 = _148_fa_fog.w * length(_550);\n        result = lerp(result, _148_fa_fog.xyz, clamp(1.0f - exp((-_893) * _893), 0.0f, 1.0f).xxx);\n    }\n    fa_frag_color = float4(result, _943);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_129",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_148",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_567",
            "hlsl_register_b_n": 5
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_664",
            "hlsl_register_b_n": 2
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
              "hlsl_register_t_n": 0
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 1
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
              "hlsl_register_t_n": 2
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
              "hlsl_register_t_n": 3
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
              "hlsl_register_t_n": 4
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
              "hlsl_register_t_n": 5
            }
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 6
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _134_fa_view_proj : packoffset(c0);\n    row_major float4x4 _134_fa_light_vp : packoffset(c4);\n    float4 _134_fa_uv_scale : packoffset(c8);\n    float4 _134_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _181_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _172 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_181_fa_joint_rows[_172] * weights[i]);\n        r1 += (_181_fa_joint_rows[_172 + 1] * weights[i]);\n        r2 += (_181_fa_joint_rows[_172 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _72 = cross(model[1].xyz, model[2].xyz);\n    float _78 = (dot(model[0].xyz, _72) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _390 = { mul(float4(position, 1.0f), model).xyz, (((_72 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _78, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _78), texcoord0 * _134_fa_uv_scale.xy, color, position };\n    return _390;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _271 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _397 = _271.world_pos;\n    float4 _278 = float4(_397, 1.0f);\n    fa_world_pos = _397;\n    fa_world_normal = _271.world_normal;\n    fa_world_tangent = _271.world_tangent;\n    fa_uv = _271.uv;\n    fa_vertex_color = _271.color;\n    fa_shadow_pos = mul(_278, _134_fa_light_vp);\n    gl_Position = mul(_278, _134_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _148_fa_camera_pos : packoffset(c0);\n    float4 _148_fa_ambient : packoffset(c1);\n    float4 _148_fa_base_color : packoffset(c2);\n    float4 _148_fa_emissive : packoffset(c3);\n    float4 _148_fa_model_emissive : packoffset(c4);\n    float4 _148_fa_pbr : packoffset(c5);\n    float4 _148_fa_maps : packoffset(c6);\n    float4 _148_fa_fog : packoffset(c7);\n    float4 _148_fa_counts : packoffset(c8);\n    float4 _148_fa_env_sky : packoffset(c9);\n    float4 _148_fa_env_horizon : packoffset(c10);\n    float4 _148_fa_time : packoffset(c11);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _567_alphaCutoff : packoffset(c0);\n    float _567_fa_pad0 : packoffset(c0.y);\n    float _567_fa_pad1 : packoffset(c0.z);\n    float _567_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _664_fa_light_pos[32] : packoffset(c0);\n    float4 _664_fa_light_color[32] : packoffset(c32);\n    float4 _664_fa_light_dir[32] : packoffset(c64);\n};\n\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _52;\n    if (i.front_facing)\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    float3 _77 = normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    float3 _105 = normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    float3 _108;\n    if (i.front_facing)\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 _145 = fa_tex.Sample(fa_smp, i.uv);\n    float4 _156 = (_145 * _148_fa_base_color) * i.vertex_color;\n    float3 _973 = i.world_normal;\n    if (_148_fa_maps.z > 0.5f)\n    {\n        float3 _187 = (fa_normal_tex.Sample(fa_smp, i.uv).xyz * 2.0f) - 1.0f.xxx;\n        float2 _192 = _187.xy * _148_fa_maps.x;\n        float3 _990 = _187;\n        _990.x = _192.x;\n        _990.y = _192.y;\n        SurfaceInput param = i;\n        float3 param_1 = _990;\n        _973 = fa_tangent_normal(param, param_1);\n    }\n    float4 _210 = fa_mr_tex.Sample(fa_smp, i.uv);\n    Surface _985 = { _156.xyz, _156.w, _973, clamp(_148_fa_pbr.x * _210.z, 0.0f, 1.0f), clamp(_148_fa_pbr.y * _210.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_148_fa_maps.y * (fa_occlusion_tex.Sample(fa_smp, i.uv).x - 1.0f)), _148_fa_emissive.xyz + (_148_fa_model_emissive.xyz * fa_emissive_tex.Sample(fa_smp, i.uv).xyz) };\n    return _985;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    if (_148_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _277 = fa_shadow_pos.xyz / fa_shadow_pos.w.xxx;\n    float3 p = _277;\n    float2 suv = (_277.xy * 0.5f) + 0.5f.xx;\n    if (_148_fa_counts.z > 0.5f)\n    {\n        float3 _995 = p;\n        _995.z = (_995.z * 0.5f) + 0.5f;\n        p = _995;\n    }\n    else\n    {\n        float2 _998 = suv;\n        _998.y = 1.0f - _998.y;\n        suv = _998;\n    }\n    bool _304 = suv.x < 0.0f;\n    bool _311;\n    if (!_304)\n    {\n        _311 = suv.x > 1.0f;\n    }\n    else\n    {\n        _311 = _304;\n    }\n    bool _318;\n    if (!_311)\n    {\n        _318 = suv.y < 0.0f;\n    }\n    else\n    {\n        _318 = _311;\n    }\n    bool _325;\n    if (!_318)\n    {\n        _325 = suv.y > 1.0f;\n    }\n    else\n    {\n        _325 = _318;\n    }\n    bool _332;\n    if (!_325)\n    {\n        _332 = p.z > 1.0f;\n    }\n    else\n    {\n        _332 = _325;\n    }\n    if (_332)\n    {\n        return 1.0f;\n    }\n    float _346 = _148_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _346) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _148_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _487 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _490 = _487.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_490 * _490, exp2((-9.27999973297119140625f) * ndv)) * _490) + _487.y)) + _487.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _407 = rough * rough;\n    float _440 = 0.60000002384185791015625f * _407;\n    return lerp(lerp(_148_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_148_fa_env_horizon.xyz, _148_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _407)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _440, 0.0500000007450580596923828125f + _440, d.y).xxx), ((_148_fa_env_sky.xyz + _148_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_407 * 0.60000002384185791015625f).xxx);\n}\n\nvoid frag_main()\n{\n    float3 _920 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _920 = -_920;\n    }\n    float3 _550 = _148_fa_camera_pos.xyz - fa_world_pos;\n    float3 _551 = normalize(_550);\n    SurfaceInput _933 = { fa_world_pos, _920, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing };\n    SurfaceInput param = _933;\n    Surface _556 = fa_standard_surface(param);\n    float3 _942 = _556.albedo;\n    float _943 = _556.alpha;\n    float3 _944 = _556.normal;\n    float _945 = _556.metallic;\n    float _946 = _556.roughness;\n    float _947 = _556.occlusion;\n    float3 _948 = _556.emission;\n    SurfaceInput _941 = { fa_world_pos, _920, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing };\n    SurfaceInput param_1 = _941;\n    Surface param_2 = _556;\n    surface(param_1, param_2);\n    _942 = param_2.albedo;\n    _943 = param_2.alpha;\n    _944 = param_2.normal;\n    _945 = param_2.metallic;\n    _946 = param_2.roughness;\n    _947 = param_2.occlusion;\n    _948 = param_2.emission;\n    if (param_2.alpha < _567_alphaCutoff)\n    {\n        discard;\n    }\n    float3 result;\n    if (_148_fa_emissive.w > 0.5f)\n    {\n        result = _942;\n    }\n    else\n    {\n        float3 _589 = normalize(_944);\n        float _596 = clamp(_945, 0.0f, 1.0f);\n        float _600 = clamp(_946, 0.0500000007450580596923828125f, 1.0f);\n        float _604 = _600 * _600;\n        float _608 = _604 * _604;\n        float _614 = max(dot(_589, _551), 9.9999997473787516355514526367188e-05f);\n        float3 _620 = _942 * (1.0f - _596);\n        float3 _628 = lerp(0.039999999105930328369140625f.xxx, _942, _596.xxx);\n        float3 lit = (_148_fa_ambient.xyz * _620) * _947;\n        int _641 = int(_148_fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _641)\n            {\n                break;\n            }\n            float atten = 1.0f;\n            bool _670 = _664_fa_light_color[li].w < 0.5f;\n            if (_670)\n            {\n                l = normalize(_664_fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _687 = _664_fa_light_pos[li].xyz - fa_world_pos;\n                float _690 = length(_687);\n                l = _687 / max(_690, 9.9999997473787516355514526367188e-05f).xxx;\n                float _705 = _690 / max(_664_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n                float _711 = clamp(1.0f - (_705 * _705), 0.0f, 1.0f);\n                atten = _711 * _711;\n                if (_664_fa_light_color[li].w > 1.5f)\n                {\n                    atten *= smoothstep(_664_fa_light_dir[li].w, lerp(_664_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_664_fa_light_dir[li].xyz)));\n                }\n            }\n            float _745 = max(dot(_589, l), 0.0f);\n            if (_670 && (li == 0))\n            {\n                float3 param_3 = _920;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            float3 _764 = normalize(l + _551);\n            float _769 = max(dot(_589, _764), 0.0f);\n            float _782 = ((_769 * _769) * (_608 - 1.0f)) + 1.0f;\n            lit += (((_620 + (((_628 + ((1.0f.xxx - _628) * pow(1.0f - max(dot(_551, _764), 0.0f), 5.0f))) * (((_608 / ((3.1415927410125732421875f * _782) * _782)) * (0.5f / max(lerp((2.0f * _745) * _614, _745 + _614, _604), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _745))) * _664_fa_light_color[li].xyz) * (_745 * atten));\n        }\n        float param_5 = _600;\n        float param_6 = _614;\n        float2 _850 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_551, _589);\n        float param_8 = _600;\n        float3 _868 = lit;\n        float3 _869 = _868 + ((fa_environment(param_7, param_8) * ((_628 * _850.x) + _850.y.xxx)) * _947);\n        lit = _869;\n        result = _869;\n    }\n    result += _948;\n    if (_148_fa_fog.w > 0.0f)\n    {\n        float _893 = _148_fa_fog.w * length(_550);\n        result = lerp(result, _148_fa_fog.xyz, clamp(1.0f - exp((-_893) * _893), 0.0f, 1.0f).xxx);\n    }\n    fa_frag_color = float4(result, _943);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_134",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_181",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_148",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_567",
            "hlsl_register_b_n": 5
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_664",
            "hlsl_register_b_n": 2
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
              "hlsl_register_t_n": 0
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 1
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
              "hlsl_register_t_n": 2
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
              "hlsl_register_t_n": 3
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
              "hlsl_register_t_n": 4
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
              "hlsl_register_t_n": 5
            }
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 6
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    },
    "shadow": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _120_fa_view_proj : packoffset(c0);\n    row_major float4x4 _120_fa_light_vp : packoffset(c4);\n    float4 _120_fa_uv_scale : packoffset(c8);\n    float4 _120_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _58 = cross(model[1].xyz, model[2].xyz);\n    float _64 = (dot(model[0].xyz, _58) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _253 = { mul(float4(position, 1.0f), model).xyz, (((_58 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _64, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _64), texcoord0 * _120_fa_uv_scale.xy, color, position };\n    return _253;\n}\n\nvoid vert_main()\n{\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData _187 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _236 = _187.world_pos;\n    fa_world_pos = _236;\n    fa_world_normal = _187.world_normal;\n    fa_world_tangent = _187.world_tangent;\n    fa_uv = _187.uv;\n    fa_vertex_color = _187.color;\n    gl_Position = mul(float4(_236, 1.0f), _120_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _133_fa_camera_pos : packoffset(c0);\n    float4 _133_fa_ambient : packoffset(c1);\n    float4 _133_fa_base_color : packoffset(c2);\n    float4 _133_fa_emissive : packoffset(c3);\n    float4 _133_fa_model_emissive : packoffset(c4);\n    float4 _133_fa_pbr : packoffset(c5);\n    float4 _133_fa_maps : packoffset(c6);\n    float4 _133_fa_fog : packoffset(c7);\n    float4 _133_fa_counts : packoffset(c8);\n    float4 _133_fa_env_sky : packoffset(c9);\n    float4 _133_fa_env_horizon : packoffset(c10);\n    float4 _133_fa_time : packoffset(c11);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _301_alphaCutoff : packoffset(c0);\n    float _301_fa_pad0 : packoffset(c0.y);\n    float _301_fa_pad1 : packoffset(c0.z);\n    float _301_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _36;\n    if (i.front_facing)\n    {\n        _36 = i.world_normal;\n    }\n    else\n    {\n        _36 = -i.world_normal;\n    }\n    float3 _61 = normalize(i.world_tangent.xyz - (_36 * dot(_36, i.world_tangent.xyz)));\n    float3 _90 = normalize(((_61 * m.x) + ((cross(_36, _61) * i.world_tangent.w) * m.y)) + (_36 * m.z));\n    float3 _93;\n    if (i.front_facing)\n    {\n        _93 = _90;\n    }\n    else\n    {\n        _93 = -_90;\n    }\n    return _93;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 _130 = fa_tex.Sample(fa_smp, i.uv);\n    float4 _141 = (_130 * _133_fa_base_color) * i.vertex_color;\n    float3 _371 = i.world_normal;\n    if (_133_fa_maps.z > 0.5f)\n    {\n        float3 _172 = (fa_normal_tex.Sample(fa_smp, i.uv).xyz * 2.0f) - 1.0f.xxx;\n        float2 _177 = _172.xy * _133_fa_maps.x;\n        float3 _386 = _172;\n        _386.x = _177.x;\n        _386.y = _177.y;\n        SurfaceInput param = i;\n        float3 param_1 = _386;\n        _371 = fa_tangent_normal(param, param_1);\n    }\n    float4 _195 = fa_mr_tex.Sample(fa_smp, i.uv);\n    Surface _383 = { _141.xyz, _141.w, _371, clamp(_133_fa_pbr.x * _195.z, 0.0f, 1.0f), clamp(_133_fa_pbr.y * _195.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_133_fa_maps.y * (fa_occlusion_tex.Sample(fa_smp, i.uv).x - 1.0f)), _133_fa_emissive.xyz + (_133_fa_model_emissive.xyz * fa_emissive_tex.Sample(fa_smp, i.uv).xyz) };\n    return _383;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    float3 _318 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _318 = -_318;\n    }\n    float3 _285 = normalize(_133_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _331 = { fa_world_pos, _318, fa_world_tangent, fa_uv, fa_vertex_color, _285, gl_FrontFacing };\n    SurfaceInput param = _331;\n    SurfaceInput _339 = { fa_world_pos, _318, fa_world_tangent, fa_uv, fa_vertex_color, _285, gl_FrontFacing };\n    SurfaceInput param_1 = _339;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _301_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec4",
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
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec2",
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
            "inst_name": "_120",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_133",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_301",
            "hlsl_register_b_n": 5
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
              "hlsl_register_t_n": 0
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
              "hlsl_register_t_n": 1
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
              "hlsl_register_t_n": 2
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
              "hlsl_register_t_n": 3
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
              "hlsl_register_t_n": 4
            }
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _125_fa_view_proj : packoffset(c0);\n    row_major float4x4 _125_fa_light_vp : packoffset(c4);\n    float4 _125_fa_uv_scale : packoffset(c8);\n    float4 _125_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _172_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _163 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_172_fa_joint_rows[_163] * weights[i]);\n        r1 += (_172_fa_joint_rows[_163 + 1] * weights[i]);\n        r2 += (_172_fa_joint_rows[_163 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _63 = cross(model[1].xyz, model[2].xyz);\n    float _69 = (dot(model[0].xyz, _63) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _374 = { mul(float4(position, 1.0f), model).xyz, (((_63 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _69, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _69), texcoord0 * _125_fa_uv_scale.xy, color, position };\n    return _374;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData _308 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    float3 _357 = _308.world_pos;\n    fa_world_pos = _357;\n    fa_world_normal = _308.world_normal;\n    fa_world_tangent = _308.world_tangent;\n    fa_uv = _308.uv;\n    fa_vertex_color = _308.color;\n    gl_Position = mul(float4(_357, 1.0f), _125_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _133_fa_camera_pos : packoffset(c0);\n    float4 _133_fa_ambient : packoffset(c1);\n    float4 _133_fa_base_color : packoffset(c2);\n    float4 _133_fa_emissive : packoffset(c3);\n    float4 _133_fa_model_emissive : packoffset(c4);\n    float4 _133_fa_pbr : packoffset(c5);\n    float4 _133_fa_maps : packoffset(c6);\n    float4 _133_fa_fog : packoffset(c7);\n    float4 _133_fa_counts : packoffset(c8);\n    float4 _133_fa_env_sky : packoffset(c9);\n    float4 _133_fa_env_horizon : packoffset(c10);\n    float4 _133_fa_time : packoffset(c11);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _301_alphaCutoff : packoffset(c0);\n    float _301_fa_pad0 : packoffset(c0.y);\n    float _301_fa_pad1 : packoffset(c0.z);\n    float _301_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _36;\n    if (i.front_facing)\n    {\n        _36 = i.world_normal;\n    }\n    else\n    {\n        _36 = -i.world_normal;\n    }\n    float3 _61 = normalize(i.world_tangent.xyz - (_36 * dot(_36, i.world_tangent.xyz)));\n    float3 _90 = normalize(((_61 * m.x) + ((cross(_36, _61) * i.world_tangent.w) * m.y)) + (_36 * m.z));\n    float3 _93;\n    if (i.front_facing)\n    {\n        _93 = _90;\n    }\n    else\n    {\n        _93 = -_90;\n    }\n    return _93;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 _130 = fa_tex.Sample(fa_smp, i.uv);\n    float4 _141 = (_130 * _133_fa_base_color) * i.vertex_color;\n    float3 _371 = i.world_normal;\n    if (_133_fa_maps.z > 0.5f)\n    {\n        float3 _172 = (fa_normal_tex.Sample(fa_smp, i.uv).xyz * 2.0f) - 1.0f.xxx;\n        float2 _177 = _172.xy * _133_fa_maps.x;\n        float3 _386 = _172;\n        _386.x = _177.x;\n        _386.y = _177.y;\n        SurfaceInput param = i;\n        float3 param_1 = _386;\n        _371 = fa_tangent_normal(param, param_1);\n    }\n    float4 _195 = fa_mr_tex.Sample(fa_smp, i.uv);\n    Surface _383 = { _141.xyz, _141.w, _371, clamp(_133_fa_pbr.x * _195.z, 0.0f, 1.0f), clamp(_133_fa_pbr.y * _195.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_133_fa_maps.y * (fa_occlusion_tex.Sample(fa_smp, i.uv).x - 1.0f)), _133_fa_emissive.xyz + (_133_fa_model_emissive.xyz * fa_emissive_tex.Sample(fa_smp, i.uv).xyz) };\n    return _383;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    float3 _318 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _318 = -_318;\n    }\n    float3 _285 = normalize(_133_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _331 = { fa_world_pos, _318, fa_world_tangent, fa_uv, fa_vertex_color, _285, gl_FrontFacing };\n    SurfaceInput param = _331;\n    SurfaceInput _339 = { fa_world_pos, _318, fa_world_tangent, fa_uv, fa_vertex_color, _285, gl_FrontFacing };\n    SurfaceInput param_1 = _339;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _301_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec4",
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
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec2",
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
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_125",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_172",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_133",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_301",
            "hlsl_register_b_n": 5
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
              "hlsl_register_t_n": 0
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
              "hlsl_register_t_n": 1
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
              "hlsl_register_t_n": 2
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
              "hlsl_register_t_n": 3
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
              "hlsl_register_t_n": 4
            }
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    }
  }
}
