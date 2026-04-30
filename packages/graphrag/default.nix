{
  lib,
  python3Packages,
  fetchurl,
}: let
  version = "3.0.9";

  wheel = {
    url,
    hash,
  }:
    fetchurl {inherit url hash;};

  nest-asyncio2 = python3Packages.buildPythonPackage {
    pname = "nest-asyncio2";
    version = "1.7.2";
    format = "wheel";
    src = wheel {
      url = "https://files.pythonhosted.org/packages/c5/3c/3179b85b0e1c3659f0369940200cd6d0fa900e6cefcc7ea0bc6dd0e29ffb/nest_asyncio2-1.7.2-py3-none-any.whl";
      hash = "sha256-9d+nAvP4H2oDhX6aGeK6V4wJRqStQXtMUKJNe6ZB/gE=";
    };

    pythonImportsCheck = ["nest_asyncio2"];
    doCheck = false;
  };

  graphrag-common = python3Packages.buildPythonPackage {
    pname = "graphrag-common";
    inherit version;
    format = "wheel";
    src = wheel {
      url = "https://files.pythonhosted.org/packages/65/ce/7636e27622546c8ca91aa8b036fec957a4f9cc44b2a1da89d3d1f7c89830/graphrag_common-3.0.9-py3-none-any.whl";
      hash = "sha256-ZcLayImSKM924ENhHKAI26MYv+uroUle6wFnEG2Z4fk=";
    };

    dependencies = with python3Packages; [
      python-dotenv
      pyyaml
      toml
    ];

    pythonRelaxDeps = true;
    pythonImportsCheck = ["graphrag_common"];
    doCheck = false;
  };

  graphrag-storage = python3Packages.buildPythonPackage {
    pname = "graphrag-storage";
    inherit version;
    format = "wheel";
    src = wheel {
      url = "https://files.pythonhosted.org/packages/db/bf/cd6b919b6340328ac8a488f29c05465b57a4ce0541f33d9f3b03424745a9/graphrag_storage-3.0.9-py3-none-any.whl";
      hash = "sha256-YmIYWsLwgi0kREMqT6iS04XSHgNvJ6uQh5IulS1s1TQ=";
    };

    dependencies = with python3Packages; [
      aiofiles
      azure-cosmos
      azure-identity
      azure-storage-blob
      pandas
      pydantic
      graphrag-common
    ];

    pythonRelaxDeps = true;
    pythonImportsCheck = ["graphrag_storage"];
    doCheck = false;
  };

  graphrag-cache = python3Packages.buildPythonPackage {
    pname = "graphrag-cache";
    inherit version;
    format = "wheel";
    src = wheel {
      url = "https://files.pythonhosted.org/packages/53/5c/c27302f38a0bb2e9e1c8f26500977084b406bcf66fd1aef0905c3c899c77/graphrag_cache-3.0.9-py3-none-any.whl";
      hash = "sha256-7QMeaMFbOv85D0NOO0FK/bYqP6mfm2b99HaekZ3t3Zo=";
    };

    dependencies = [
      graphrag-common
      graphrag-storage
    ];

    pythonRelaxDeps = true;
    pythonImportsCheck = ["graphrag_cache"];
    doCheck = false;
  };

  graphrag-chunking = python3Packages.buildPythonPackage {
    pname = "graphrag-chunking";
    inherit version;
    format = "wheel";
    src = wheel {
      url = "https://files.pythonhosted.org/packages/d9/c5/51aabcff03995eb0e0994655c78f817d0dca484ae5e612ef226427175532/graphrag_chunking-3.0.9-py3-none-any.whl";
      hash = "sha256-o8DJrdiJgE2r6HrMDEcY0ZKvO4zs1bxVHI9/nN3sH+s=";
    };

    dependencies = [
      python3Packages.pydantic
      graphrag-common
    ];

    pythonRelaxDeps = true;
    pythonImportsCheck = ["graphrag_chunking"];
    doCheck = false;
  };

  graphrag-input = python3Packages.buildPythonPackage {
    pname = "graphrag-input";
    inherit version;
    format = "wheel";
    src = wheel {
      url = "https://files.pythonhosted.org/packages/c9/c0/502bb2b7a31e15f6ebd84cfc7f24329b962b06109e061855a7816811dc9d/graphrag_input-3.0.9-py3-none-any.whl";
      hash = "sha256-vVHOqQLl1bjt9l1A5gp/JjREGXU3eJhrODcXYHPA8GU=";
    };

    dependencies = with python3Packages; [
      markitdown
      pyarrow
      pydantic
      graphrag-common
      graphrag-storage
    ];

    pythonRelaxDeps = true;
    pythonImportsCheck = ["graphrag_input"];
    doCheck = false;
  };

  graphrag-llm = python3Packages.buildPythonPackage {
    pname = "graphrag-llm";
    inherit version;
    format = "wheel";
    src = wheel {
      url = "https://files.pythonhosted.org/packages/65/d4/8a4a3c8bb0f0adbe984ff9670d2c477413bb7573cc19473d30a10f268485/graphrag_llm-3.0.9-py3-none-any.whl";
      hash = "sha256-cvPFd1hLL2Sc+belgkNrrfBQ6l2HxEB8ChFdh9us9H0=";
    };

    dependencies = with python3Packages; [
      azure-identity
      jinja2
      litellm
      pydantic
      typing-extensions
      graphrag-common
      graphrag-cache
      nest-asyncio2
    ];

    pythonRelaxDeps = true;
    pythonImportsCheck = ["graphrag_llm"];
    doCheck = false;
  };

  graphrag-vectors = python3Packages.buildPythonPackage {
    pname = "graphrag-vectors";
    inherit version;
    format = "wheel";
    src = wheel {
      url = "https://files.pythonhosted.org/packages/8f/fd/4c2c300219f53abf80b551fc00d6e131371da9697c5742bb401cae4e9339/graphrag_vectors-3.0.9-py3-none-any.whl";
      hash = "sha256-i8URVyaMijU4UNnzjYrL71z0m6e9nZbffd00IjHo7ow=";
    };

    dependencies = with python3Packages; [
      azure-core
      azure-cosmos
      azure-identity
      azure-search-documents
      lancedb
      numpy
      pyarrow
      pydantic
      graphrag-common
    ];

    pythonRelaxDeps = true;
    pythonImportsCheck = ["graphrag_vectors"];
    doCheck = false;
  };
in
  python3Packages.buildPythonApplication {
    pname = "graphrag";
    inherit version;
    format = "wheel";
    src = wheel {
      url = "https://files.pythonhosted.org/packages/50/58/88906a915d0e318463aef3d75020b4c107784e7dfdc2d8369dd8f2f6ad4e/graphrag-3.0.9-py3-none-any.whl";
      hash = "sha256-0u6Hs28MGtv4QWYNvc9KTEPj9CS3dBmqOJWzlheYpZQ=";
    };

    dependencies = with python3Packages; [
      azure-identity
      azure-search-documents
      azure-storage-blob
      devtools
      graspologic-native
      json-repair
      networkx
      nltk
      numpy
      pandas
      pyarrow
      pydantic
      spacy
      blis
      textblob
      tqdm
      typer
      typing-extensions

      graphrag-common
      graphrag-storage
      graphrag-cache
      graphrag-chunking
      graphrag-input
      graphrag-llm
      graphrag-vectors
    ];

    pythonRelaxDeps = true;
    pythonImportsCheck = ["graphrag"];

    nativeCheckInputs = with python3Packages; [
      pytestCheckHook
    ];

    # Tests require network access and LLM keys
    doCheck = false;

    meta = with lib; {
      description = "Modular graph-based Retrieval-Augmented Generation (RAG) system";
      homepage = "https://github.com/microsoft/graphrag";
      changelog = "https://github.com/microsoft/graphrag/blob/v${version}/CHANGELOG.md";
      license = licenses.mit;
      mainProgram = "graphrag";
    };
  }
