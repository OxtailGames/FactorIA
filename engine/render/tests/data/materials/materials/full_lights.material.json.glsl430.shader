{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5803d023b1c011299e7caeb3dafe645d0b88230997a6bd7a8ad8bad27e396a28",
  "slang": "glsl430",
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
      "vs": "#version 430\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 0) out vec3 v_pos;\nlayout(location = 1) out vec3 v_normal;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 2) out vec4 v_shadow;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 4) in vec4 fa_color;\nmat4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nvec3 fa_world_position(vec3 p)\n{\n    return (fa_model * vec4(p, 1.0)).xyz;\n}\n\nvec3 fa_world_direction(vec3 n)\n{\n    vec3 _61 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_61 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _61) < 0.0) ? (-1.0) : 1.0));\n}\n\nvec4 fa_shadow_coord(vec3 world)\n{\n    return mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(world, 1.0);\n}\n\nvoid fa_user_main()\n{\n    vec3 param = fa_position;\n    vec3 _116 = fa_world_position(param);\n    v_pos = _116;\n    vec3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    vec3 param_2 = _116;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_116, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    fa_model = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    fa_user_main();\n}\n\n",
      "fs": "#version 430\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_full_light_tex_fa_full_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_full_shadow_tex_fa_full_shadow_smp;\n\nlayout(location = 1) in vec3 v_normal;\nlayout(location = 0) in vec3 v_pos;\nlayout(location = 2) in vec4 v_shadow;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_full_light_tex_fa_full_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _81 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _88 = fa_light_texel(param_1);\n    float _94 = _88.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _102 = _94 < 0.5;\n    vec3 l;\n    if (_102)\n    {\n        l = normalize(_81.xyz);\n    }\n    else\n    {\n        vec3 _114 = _81.xyz - world_pos;\n        float _116 = length(_114);\n        dist = _116;\n        l = _114 / vec3(max(_116, 9.9999997473787516355514526367188e-05));\n        float _131 = _116 / max(_81.w, 0.001000000047497451305389404296875);\n        float _137 = clamp(1.0 - (_131 * _131), 0.0, 1.0);\n        atten = _137 * _137;\n        if (_94 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _152 = fa_light_texel(param_2);\n            float _162 = _152.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _169 = fa_light_texel(param_3);\n            float _171 = _169.x;\n            float cos_inner = _171;\n            if (_171 > 1.5)\n            {\n                cos_inner = mix(_162, 1.0, 0.25);\n            }\n            atten *= smoothstep(_162, cos_inner, dot(-l, normalize(_152.xyz)));\n        }\n    }\n    int _202;\n    if (_102)\n    {\n        _202 = 0;\n    }\n    else\n    {\n        _202 = (_94 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _88.xyz * atten, atten, 1.0, dist, _202);\n}\n\nfloat fa_shadow_pcf(vec4 coord, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _231 = coord.xyz / vec3(coord.w);\n    vec3 p = _231;\n    vec2 suv = (_231.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[10].z > 0.5)\n    {\n        vec3 _760 = p;\n        _760.z = (_760.z * 0.5) + 0.5;\n        p = _760;\n    }\n    else\n    {\n        vec2 _763 = suv;\n        _763.y = 1.0 - _763.y;\n        suv = _763;\n    }\n    bool _261 = suv.x < 0.0;\n    bool _268;\n    if (!_261)\n    {\n        _268 = suv.x > 1.0;\n    }\n    else\n    {\n        _268 = _261;\n    }\n    bool _275;\n    if (!_268)\n    {\n        _275 = suv.y < 0.0;\n    }\n    else\n    {\n        _275 = _268;\n    }\n    bool _282;\n    if (!_275)\n    {\n        _282 = suv.y > 1.0;\n    }\n    else\n    {\n        _282 = _275;\n    }\n    bool _289;\n    if (!_282)\n    {\n        _289 = p.z > 1.0;\n    }\n    else\n    {\n        _289 = _282;\n    }\n    if (_289)\n    {\n        return 1.0;\n    }\n    float _304 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _304) <= textureLod(fa_full_shadow_tex_fa_full_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[10].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nfloat fa_shadow(vec4 coord, vec3 n, vec3 l)\n{\n    vec4 param = coord;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light(int li, vec3 world_pos, vec3 gn, vec4 coord)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _381 = fa_light_sample(param, param_1);\n    vec3 _738 = _381.direction;\n    vec3 _733 = _381.color;\n    float _735 = _381.shadow;\n    int _743 = _381.type;\n    if ((_743 == 0) && (li == 0))\n    {\n        vec4 param_2 = coord;\n        vec3 param_3 = gn;\n        vec3 param_4 = _738;\n        float _397 = fa_shadow(param_2, param_3, param_4);\n        _735 = _397;\n        _733 *= _397;\n    }\n    return LightSample(_738, _733, _381.attenuation, _735, _381._distance, _743);\n}\n\nvec3 fa_apply_fog(inout vec3 result, vec3 world_pos)\n{\n    bool _411 = fa_mesh_fs_params[7].w > 0.0;\n    bool _419;\n    if (!_411)\n    {\n        _419 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _419 = _411;\n    }\n    if (_419)\n    {\n        vec3 _428 = world_pos - fa_mesh_fs_params[0].xyz;\n        float _435 = dot(_428, fa_mesh_fs_params[9].xyz);\n        bool _439 = fa_mesh_fs_params[9].w > 0.5;\n        float _440;\n        if (_439)\n        {\n            _440 = _435;\n        }\n        else\n        {\n            _440 = length(_428);\n        }\n        float _452 = _440 - fa_mesh_fs_params[8].x;\n        if (_452 > 0.0)\n        {\n            float _461 = fa_mesh_fs_params[7].w * _452;\n            float tau = _461 * _461;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _477;\n                if (_439)\n                {\n                    _477 = world_pos.y - (fa_mesh_fs_params[9].y * _435);\n                }\n                else\n                {\n                    _477 = fa_mesh_fs_params[0].y;\n                }\n                float _498 = mix(_477, world_pos.y, clamp(fa_mesh_fs_params[8].x / _440, 0.0, 1.0));\n                float _502 = world_pos.y - _498;\n                float _507 = _498 - fa_mesh_fs_params[8].z;\n                float _512 = world_pos.y - fa_mesh_fs_params[8].z;\n                bool _515 = _507 <= 0.0;\n                bool _516 = !_515;\n                bool _522;\n                if (_516)\n                {\n                    _522 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _522 = _515;\n                }\n                float _523;\n                if (_522)\n                {\n                    _523 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _523 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _507, 80.0));\n                }\n                bool _550;\n                if (_516)\n                {\n                    _550 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _550 = _515;\n                }\n                float _551;\n                if (_550)\n                {\n                    _551 = fa_mesh_fs_params[8].y * _507;\n                }\n                else\n                {\n                    _551 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _507, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _576 = _512 <= 0.0;\n                bool _583;\n                if (!_576)\n                {\n                    _583 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _583 = _576;\n                }\n                float _584;\n                if (_583)\n                {\n                    _584 = fa_mesh_fs_params[8].y * _512;\n                }\n                else\n                {\n                    _584 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _512, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _611;\n                if (abs(_502) < 0.001000000047497451305389404296875)\n                {\n                    _611 = _523;\n                }\n                else\n                {\n                    _611 = (_584 - _551) / _502;\n                }\n                tau += (_452 * max(_611, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    vec3 _649 = normalize(v_normal);\n    vec3 lit = fa_mesh_fs_params[1].xyz * fa_material[0].xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        vec3 param_1 = v_pos;\n        vec3 param_2 = _649;\n        vec4 param_3 = v_shadow;\n        LightSample _682 = fa_light(param, param_1, param_2, param_3);\n        lit += ((fa_material[0].xyz * _682.color) * max(dot(_649, _682.direction), 0.0));\n    }\n    vec3 param_4 = lit;\n    vec3 param_5 = v_pos;\n    vec3 _705 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = vec4(_705, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_99",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_216",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 20,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_656",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
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
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_full_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering"
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
            "sampler_slot": 1,
            "glsl_name": "fa_full_light_tex_fa_full_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_tex_fa_full_shadow_smp",
            "view_name": "fa_full_shadow_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_full_shadow_tex_fa_full_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nuniform vec4 fa_skin[192];\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 0) out vec3 v_pos;\nlayout(location = 1) out vec3 v_normal;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 2) out vec4 v_shadow;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 4) in vec4 fa_color;\nmat4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _61 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_61 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_61 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_61 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec3 fa_world_position(vec3 p)\n{\n    return (fa_model * vec4(p, 1.0)).xyz;\n}\n\nvec3 fa_world_direction(vec3 n)\n{\n    vec3 _185 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_185 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _185) < 0.0) ? (-1.0) : 1.0));\n}\n\nvec4 fa_shadow_coord(vec3 world)\n{\n    return mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(world, 1.0);\n}\n\nvoid fa_user_main()\n{\n    vec3 param = fa_position;\n    vec3 _234 = fa_world_position(param);\n    v_pos = _234;\n    vec3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    vec3 param_2 = _234;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_234, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_model = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    fa_user_main();\n}\n\n",
      "fs": "#version 430\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_full_light_tex_fa_full_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_full_shadow_tex_fa_full_shadow_smp;\n\nlayout(location = 1) in vec3 v_normal;\nlayout(location = 0) in vec3 v_pos;\nlayout(location = 2) in vec4 v_shadow;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_full_light_tex_fa_full_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _81 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _88 = fa_light_texel(param_1);\n    float _94 = _88.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _102 = _94 < 0.5;\n    vec3 l;\n    if (_102)\n    {\n        l = normalize(_81.xyz);\n    }\n    else\n    {\n        vec3 _114 = _81.xyz - world_pos;\n        float _116 = length(_114);\n        dist = _116;\n        l = _114 / vec3(max(_116, 9.9999997473787516355514526367188e-05));\n        float _131 = _116 / max(_81.w, 0.001000000047497451305389404296875);\n        float _137 = clamp(1.0 - (_131 * _131), 0.0, 1.0);\n        atten = _137 * _137;\n        if (_94 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _152 = fa_light_texel(param_2);\n            float _162 = _152.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _169 = fa_light_texel(param_3);\n            float _171 = _169.x;\n            float cos_inner = _171;\n            if (_171 > 1.5)\n            {\n                cos_inner = mix(_162, 1.0, 0.25);\n            }\n            atten *= smoothstep(_162, cos_inner, dot(-l, normalize(_152.xyz)));\n        }\n    }\n    int _202;\n    if (_102)\n    {\n        _202 = 0;\n    }\n    else\n    {\n        _202 = (_94 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _88.xyz * atten, atten, 1.0, dist, _202);\n}\n\nfloat fa_shadow_pcf(vec4 coord, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _231 = coord.xyz / vec3(coord.w);\n    vec3 p = _231;\n    vec2 suv = (_231.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[10].z > 0.5)\n    {\n        vec3 _760 = p;\n        _760.z = (_760.z * 0.5) + 0.5;\n        p = _760;\n    }\n    else\n    {\n        vec2 _763 = suv;\n        _763.y = 1.0 - _763.y;\n        suv = _763;\n    }\n    bool _261 = suv.x < 0.0;\n    bool _268;\n    if (!_261)\n    {\n        _268 = suv.x > 1.0;\n    }\n    else\n    {\n        _268 = _261;\n    }\n    bool _275;\n    if (!_268)\n    {\n        _275 = suv.y < 0.0;\n    }\n    else\n    {\n        _275 = _268;\n    }\n    bool _282;\n    if (!_275)\n    {\n        _282 = suv.y > 1.0;\n    }\n    else\n    {\n        _282 = _275;\n    }\n    bool _289;\n    if (!_282)\n    {\n        _289 = p.z > 1.0;\n    }\n    else\n    {\n        _289 = _282;\n    }\n    if (_289)\n    {\n        return 1.0;\n    }\n    float _304 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _304) <= textureLod(fa_full_shadow_tex_fa_full_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[10].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nfloat fa_shadow(vec4 coord, vec3 n, vec3 l)\n{\n    vec4 param = coord;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light(int li, vec3 world_pos, vec3 gn, vec4 coord)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _381 = fa_light_sample(param, param_1);\n    vec3 _738 = _381.direction;\n    vec3 _733 = _381.color;\n    float _735 = _381.shadow;\n    int _743 = _381.type;\n    if ((_743 == 0) && (li == 0))\n    {\n        vec4 param_2 = coord;\n        vec3 param_3 = gn;\n        vec3 param_4 = _738;\n        float _397 = fa_shadow(param_2, param_3, param_4);\n        _735 = _397;\n        _733 *= _397;\n    }\n    return LightSample(_738, _733, _381.attenuation, _735, _381._distance, _743);\n}\n\nvec3 fa_apply_fog(inout vec3 result, vec3 world_pos)\n{\n    bool _411 = fa_mesh_fs_params[7].w > 0.0;\n    bool _419;\n    if (!_411)\n    {\n        _419 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _419 = _411;\n    }\n    if (_419)\n    {\n        vec3 _428 = world_pos - fa_mesh_fs_params[0].xyz;\n        float _435 = dot(_428, fa_mesh_fs_params[9].xyz);\n        bool _439 = fa_mesh_fs_params[9].w > 0.5;\n        float _440;\n        if (_439)\n        {\n            _440 = _435;\n        }\n        else\n        {\n            _440 = length(_428);\n        }\n        float _452 = _440 - fa_mesh_fs_params[8].x;\n        if (_452 > 0.0)\n        {\n            float _461 = fa_mesh_fs_params[7].w * _452;\n            float tau = _461 * _461;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _477;\n                if (_439)\n                {\n                    _477 = world_pos.y - (fa_mesh_fs_params[9].y * _435);\n                }\n                else\n                {\n                    _477 = fa_mesh_fs_params[0].y;\n                }\n                float _498 = mix(_477, world_pos.y, clamp(fa_mesh_fs_params[8].x / _440, 0.0, 1.0));\n                float _502 = world_pos.y - _498;\n                float _507 = _498 - fa_mesh_fs_params[8].z;\n                float _512 = world_pos.y - fa_mesh_fs_params[8].z;\n                bool _515 = _507 <= 0.0;\n                bool _516 = !_515;\n                bool _522;\n                if (_516)\n                {\n                    _522 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _522 = _515;\n                }\n                float _523;\n                if (_522)\n                {\n                    _523 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _523 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _507, 80.0));\n                }\n                bool _550;\n                if (_516)\n                {\n                    _550 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _550 = _515;\n                }\n                float _551;\n                if (_550)\n                {\n                    _551 = fa_mesh_fs_params[8].y * _507;\n                }\n                else\n                {\n                    _551 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _507, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _576 = _512 <= 0.0;\n                bool _583;\n                if (!_576)\n                {\n                    _583 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _583 = _576;\n                }\n                float _584;\n                if (_583)\n                {\n                    _584 = fa_mesh_fs_params[8].y * _512;\n                }\n                else\n                {\n                    _584 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _512, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _611;\n                if (abs(_502) < 0.001000000047497451305389404296875)\n                {\n                    _611 = _523;\n                }\n                else\n                {\n                    _611 = (_584 - _551) / _502;\n                }\n                tau += (_452 * max(_611, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    vec3 _649 = normalize(v_normal);\n    vec3 lit = fa_mesh_fs_params[1].xyz * fa_material[0].xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        vec3 param_1 = v_pos;\n        vec3 param_2 = _649;\n        vec4 param_3 = v_shadow;\n        LightSample _682 = fa_light(param, param_1, param_2, param_3);\n        lit += ((fa_material[0].xyz * _682.color) * max(dot(_649, _682.direction), 0.0));\n    }\n    vec3 param_4 = lit;\n    vec3 param_5 = v_pos;\n    vec3 _705 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = vec4(_705, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_71",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_217",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_216",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 20,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_656",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
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
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_full_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering"
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
            "sampler_slot": 1,
            "glsl_name": "fa_full_light_tex_fa_full_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_tex_fa_full_shadow_smp",
            "view_name": "fa_full_shadow_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_full_shadow_tex_fa_full_shadow_smp"
          }
        ]
      }
    }
  }
}
