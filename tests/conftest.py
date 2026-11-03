import pytest

def pytest_addoption(parser):
    parser.addoption("--instance-url", action="store", default="", help="Phylum instance to run tests on")

@pytest.fixture
def api_url(request):
    instance_url = request.config.getoption("--instance-url")
    if instance_url == "":
        assert False

    return instance_url.rstrip("/") + "/api/v1"
